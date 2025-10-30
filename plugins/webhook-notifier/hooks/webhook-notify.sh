#!/usr/bin/env bash

set -euo pipefail

# ============================================================================
# Webhook Notifier Hook Script
# ============================================================================
# 在 Claude Code 会话事件发生时发送 webhook 通知
#
# Hook Events: Notification, Stop, SessionEnd
# Input: JSON from stdin containing event info
# Output: HTTP POST to configured webhook URL
# ============================================================================

# 常量定义
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$SCRIPT_DIR/..}"
readonly LOG_DIR="${HOME}/.claude/webhook-notifier/logs"
readonly CONFIG_FILE="${HOME}/.claude/webhook-notifier/config.json"

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
        # 使用 if-then-else 避免 // 操作符将 false 当作 null 处理
        jq -r "if has(\"${key}\") then .${key} | tostring else \"${default}\" end" "${CONFIG_FILE}" 2>/dev/null || echo "${default}"
    elif command -v python3 &> /dev/null; then
        python3 -c "import json,sys; cfg=json.load(open('${CONFIG_FILE}')); val=cfg.get('${key}'); print(str(val) if val is not None else '${default}')" 2>/dev/null || echo "${default}"
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

# 从 transcript 提取最后一条 assistant 消息
extract_last_message() {
    local transcript_path="$1"
    local max_length="${2:-200}"

    # 检查文件是否存在
    if [[ ! -f "${transcript_path}" ]]; then
        echo ""
        return 1
    fi

    # 检查文件是否可读
    if [[ ! -r "${transcript_path}" ]]; then
        echo ""
        return 1
    fi

    local last_message=""
    local msg_type="info"

    # 尝试使用 jq 提取最后的 assistant 消息
    if command -v jq &> /dev/null; then
        # 读取最后 30 行，查找最后一条 role="assistant" 的消息
        last_message=$(tail -30 "${transcript_path}" 2>/dev/null | \
            jq -r 'select(.role=="assistant") | .content' 2>/dev/null | \
            tail -1 | \
            head -c "${max_length}")
    else
        # 降级：使用 grep 和基本文本处理
        last_message=$(tail -30 "${transcript_path}" 2>/dev/null | \
            grep -o '"role":"assistant","content":"[^"]*"' 2>/dev/null | \
            tail -1 | \
            sed 's/.*"content":"\(.*\)"/\1/' | \
            head -c "${max_length}")
    fi

    # 如果提取失败，返回空
    if [[ -z "${last_message}" ]]; then
        echo ""
        return 1
    fi

    # 识别消息类型
    # 1. Question: 包含问号或疑问词
    if echo "${last_message}" | grep -qE '[?？]|吗|呢|如何|怎么|什么|哪'; then
        msg_type="question"
    # 2. Confirmation: 包含确认相关词
    elif echo "${last_message}" | grep -qE '是否|同意|确认|可以吗'; then
        msg_type="confirmation"
    # 3. Choice: 包含选项标记
    elif echo "${last_message}" | grep -qE '[0-9]\.|选择|或者|还是'; then
        msg_type="choice"
    fi

    # 返回 JSON 格式的上下文信息
    if command -v jq &> /dev/null; then
        jq -n \
            --arg msg "${last_message}" \
            --arg type "${msg_type}" \
            '{"last_message": $msg, "message_type": $type}'
    else
        # 降级：手动构建 JSON（需要转义特殊字符）
        local escaped_msg=$(echo "${last_message}" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')
        echo "{\"last_message\": \"${escaped_msg}\", \"message_type\": \"${msg_type}\"}"
    fi

    return 0
}

# 构建 notification payload
build_notification_payload() {
    local hook_input="$1"

    # 从 hook input 提取信息
    local notification_message=$(echo "${hook_input}" | jq -r '.notification_message // "Claude is waiting for your input"')
    local notification_type=$(echo "${hook_input}" | jq -r '.notification_type // "waiting_for_input"')
    local session_id=$(echo "${hook_input}" | jq -r '.session_id // ""')
    local transcript_path=$(echo "${hook_input}" | jq -r '.transcript_path // ""')
    local cwd=$(echo "${hook_input}" | jq -r '.cwd // ""')
    local project_dir="${CLAUDE_PROJECT_DIR:-$cwd}"

    # 获取 git 信息
    local git_info=$(get_git_info "${project_dir}")

    # 检查是否启用上下文提取
    local include_context=$(read_config "include_notification_context" "true")
    local context_length=$(read_config "notification_context_length" "200")

    # 尝试提取上下文信息
    local context_json=""
    if [[ "${include_context}" == "true" && -n "${transcript_path}" ]]; then
        context_json=$(extract_last_message "${transcript_path}" "${context_length}")
    fi

    # 构建 payload
    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    # 根据是否有上下文构建不同的 payload
    if [[ -n "${context_json}" ]]; then
        cat <<EOF
{
  "event": "notification",
  "notification_type": "${notification_type}",
  "message": "${notification_message}",
  "context": ${context_json},
  "timestamp": "${timestamp}",
  "session": {
    "id": "${session_id}"
  },
  "project": {
    "directory": "${project_dir}",
    ${git_info}
  },
  "source": "claude-code-webhook-notifier"
}
EOF
    else
        # 降级：不包含 context 字段
        cat <<EOF
{
  "event": "notification",
  "notification_type": "${notification_type}",
  "message": "${notification_message}",
  "timestamp": "${timestamp}",
  "session": {
    "id": "${session_id}"
  },
  "project": {
    "directory": "${project_dir}",
    ${git_info}
  },
  "source": "claude-code-webhook-notifier"
}
EOF
    fi
}

# 构建 session_end payload
build_session_end_payload() {
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
    response_body=$(echo "${response}" | sed '$d')

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

    # 读取 hook input from stdin (Claude Code 总是通过 stdin 传递 JSON 数据)
    local hook_input
    hook_input=$(cat)

    # 获取事件类型
    local hook_event=$(echo "${hook_input}" | jq -r '.hook_event_name // ""')

    # 验证事件类型并检查是否启用
    case "${hook_event}" in
        "Notification")
            local enable_notification=$(read_config "enable_notification_hook" "true")
            if [[ "${enable_notification}" != "true" ]]; then
                log_info "Notification hook is disabled"
                exit 0
            fi
            log_info "Processing Notification event"
            ;;
        "Stop"|"SessionEnd")
            log_info "Processing ${hook_event} event"
            ;;
        *)
            log_info "Ignoring unsupported event: ${hook_event}"
            exit 0
            ;;
    esac

    # 根据事件类型构建不同的 payload
    local payload
    if [[ "${hook_event}" == "Notification" ]]; then
        payload=$(build_notification_payload "${hook_input}")
    else
        payload=$(build_session_end_payload "${hook_input}")
    fi

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
