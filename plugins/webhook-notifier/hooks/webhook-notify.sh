#!/usr/bin/env bash

set -euo pipefail

# ============================================================================
# Webhook Notifier Hook Script
# ============================================================================
# 在 Claude Code 会话结束时发送 webhook 通知
#
# Hook Events: Stop, SessionEnd
# Input: JSON from stdin containing session info
# Output: HTTP POST to configured webhook URL
# ============================================================================

# 常量定义
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$SCRIPT_DIR/..}"
readonly LOG_DIR="${HOME}/.claude/webhook-notifier/logs"
readonly CONFIG_FILE="${HOME}/.claude/settings.json"

# 确保日志目录存在
mkdir -p "${LOG_DIR}"

# 日志函数
log_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] INFO: $*" | tee -a "${LOG_DIR}/$(date '+%Y-%m-%d').log"
}

log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ERROR: $*" | tee -a "${LOG_DIR}/errors.log" "${LOG_DIR}/$(date '+%Y-%m-%d').log" >&2
}

# 读取配置
read_config() {
    local key="$1"
    local default="${2:-}"

    if [[ ! -f "${CONFIG_FILE}" ]]; then
        echo "${default}"
        return
    fi

    # 使用 jq 或 python 读取配置
    if command -v jq &> /dev/null; then
        jq -r ".\"webhook-notifier\".${key} // \"${default}\"" "${CONFIG_FILE}" 2>/dev/null || echo "${default}"
    elif command -v python3 &> /dev/null; then
        python3 -c "import json,sys; cfg=json.load(open('${CONFIG_FILE}')); print(cfg.get('webhook-notifier',{}).get('${key}','${default}'))" 2>/dev/null || echo "${default}"
    else
        echo "${default}"
    fi
}

# 获取 git 信息
get_git_info() {
    local project_dir="$1"
    local git_branch=""
    local git_repo=""
    local git_commit=""

    if [[ -d "${project_dir}/.git" ]]; then
        cd "${project_dir}"
        git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        git_repo=$(git config --get remote.origin.url 2>/dev/null || echo "")
        git_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "")
    fi

    # 返回 JSON 片段
    cat <<EOF
"git_branch": "${git_branch}",
"git_repo": "${git_repo}",
"git_commit": "${git_commit}"
EOF
}

# 构建 webhook payload
build_payload() {
    local hook_input="$1"

    # 从 hook input 提取信息
    local session_id=$(echo "${hook_input}" | jq -r '.session_id // ""')
    local reason=$(echo "${hook_input}" | jq -r '.reason // "unknown"')
    local transcript_path=$(echo "${hook_input}" | jq -r '.transcript_path // ""')
    local cwd=$(echo "${hook_input}" | jq -r '.cwd // ""')
    local project_dir="${CLAUDE_PROJECT_DIR:-$cwd}"

    # 获取 git 信息
    local git_info=$(get_git_info "${project_dir}")

    # 读取配置
    local include_session_id=$(read_config "payload_config.include_session_id" "true")
    local include_reason=$(read_config "payload_config.include_reason" "true")
    local include_transcript=$(read_config "payload_config.include_transcript_path" "true")
    local include_project=$(read_config "payload_config.include_project_info" "true")
    local include_git=$(read_config "payload_config.include_git_info" "true")

    # 构建 payload
    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    cat <<EOF
{
  "event": "session_end",
  "timestamp": "${timestamp}",
  "session": {
    "id": "${session_id}",
    "reason": "${reason}",
    "transcript_path": "${transcript_path}"
  },
  "project": {
    "directory": "${project_dir}",
    ${git_info}
  },
  "source": "claude-code-webhook-notifier"
}
EOF
}

# 发送 webhook
send_webhook() {
    local webhook_url="$1"
    local payload="$2"
    local timeout=$(read_config "timeout" "10")

    log_info "Sending webhook to: ${webhook_url}"

    # 发送 POST 请求
    local response
    local http_code

    response=$(curl -X POST \
        -H "Content-Type: application/json" \
        -H "User-Agent: Claude-Code-Webhook-Notifier/1.0" \
        -d "${payload}" \
        --max-time "${timeout}" \
        --silent \
        --write-out "\n%{http_code}" \
        "${webhook_url}" 2>&1)

    http_code=$(echo "${response}" | tail -n 1)
    response_body=$(echo "${response}" | head -n -1)

    if [[ "${http_code}" -ge 200 && "${http_code}" -lt 300 ]]; then
        log_info "Webhook sent successfully (HTTP ${http_code})"
        return 0
    else
        log_error "Webhook failed (HTTP ${http_code}): ${response_body}"
        return 1
    fi
}

# 主函数
main() {
    # 检查是否启用
    local enabled=$(read_config "enabled" "true")
    if [[ "${enabled}" != "true" ]]; then
        log_info "Webhook notifier is disabled"
        exit 0
    fi

    # 读取 webhook URL
    local webhook_url=$(read_config "webhook_url" "")
    if [[ -z "${webhook_url}" || "${webhook_url}" == "https://your-webhook-endpoint.com/notify" ]]; then
        log_error "Webhook URL not configured. Please run: /webhook-config"
        exit 1
    fi

    # 读取 hook input from stdin
    local hook_input
    if [[ -p /dev/stdin ]]; then
        hook_input=$(cat)
    else
        log_error "No input provided via stdin"
        exit 1
    fi

    # 验证这是一个 Stop 或 SessionEnd 事件
    local hook_event=$(echo "${hook_input}" | jq -r '.hook_event_name // ""')
    if [[ "${hook_event}" != "Stop" && "${hook_event}" != "SessionEnd" ]]; then
        log_info "Ignoring event: ${hook_event}"
        exit 0
    fi

    log_info "Processing ${hook_event} event"

    # 构建 payload
    local payload
    payload=$(build_payload "${hook_input}")

    # 记录 payload（仅在 debug 模式）
    local log_level=$(read_config "log_level" "info")
    if [[ "${log_level}" == "debug" ]]; then
        echo "${payload}" >> "${LOG_DIR}/payloads.log"
    fi

    # 发送 webhook
    if send_webhook "${webhook_url}" "${payload}"; then
        log_info "Webhook notification completed successfully"
        exit 0
    else
        log_error "Webhook notification failed"
        exit 1
    fi
}

# 执行主函数
main "$@"
