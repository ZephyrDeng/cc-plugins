#!/usr/bin/env bash

set -euo pipefail

# 读取配置
CONFIG_FILE="${HOME}/.claude/webhook-notifier/config.json"
LOG_DIR="${HOME}/.claude/webhook-notifier/logs"

mkdir -p "${LOG_DIR}"

# 读取 webhook URL
read_config() {
    local key="$1"
    local default="${2:-}"

    if [[ ! -f "${CONFIG_FILE}" ]]; then
        echo "${default}"
        return
    fi

    if command -v jq &> /dev/null; then
        jq -r ".${key} // \"${default}\"" "${CONFIG_FILE}" 2>/dev/null || echo "${default}"
    else
        echo "${default}"
    fi
}

webhook_url=$(read_config "webhook_url" "")
if [[ -z "${webhook_url}" || "${webhook_url}" == "https://your-webhook-endpoint.com/notify" ]]; then
    echo "❌ Webhook URL 未配置"
    echo ""
    echo "请先运行: /webhook-config"
    exit 1
fi

# 构建测试 payload
timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
cwd=$(pwd)
git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
git_repo=$(git config --get remote.origin.url 2>/dev/null || echo "")
git_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "")

payload=$(cat <<EOF
{
  "event": "test_notification",
  "timestamp": "${timestamp}",
  "session": {
    "id": "test-session-$(date +%s)",
    "reason": "manual_test",
    "transcript_path": "${HOME}/.claude/test/transcript.jsonl"
  },
  "project": {
    "directory": "${cwd}",
    "git_branch": "${git_branch}",
    "git_repo": "${git_repo}",
    "git_commit": "${git_commit}"
  },
  "source": "claude-code-webhook-notifier",
  "test": true
}
EOF
)

echo "🔄 发送测试 webhook 到: ${webhook_url}"
echo ""

# 发送请求
timeout=$(read_config "timeout" "10")
response=$(curl -X POST \
    -H "Content-Type: application/json" \
    -H "User-Agent: Claude-Code-Webhook-Notifier-Test/1.0" \
    -d "${payload}" \
    --max-time "${timeout}" \
    --silent \
    --write-out "\n%{http_code}" \
    "${webhook_url}" 2>&1)

http_code=$(echo "${response}" | tail -n 1)
response_body=$(echo "${response}" | sed '$d')

# 记录日志
log_file="${LOG_DIR}/$(date '+%Y-%m-%d').log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] TEST: Sent to ${webhook_url} - HTTP ${http_code}" >> "${log_file}"

# 显示结果
if [[ "${http_code}" -ge 200 && "${http_code}" -lt 300 ]]; then
    echo "✅ 测试成功！"
    echo ""
    echo "HTTP 状态码: ${http_code}"
    if [[ -n "${response_body}" ]]; then
        echo "响应内容: ${response_body}"
    fi
    echo ""
    echo "📝 日志已记录到: ${log_file}"
else
    echo "❌ 测试失败"
    echo ""
    echo "HTTP 状态码: ${http_code}"
    if [[ -n "${response_body}" ]]; then
        echo "错误信息: ${response_body}"
    fi
    echo ""
    echo "📝 错误日志: ${LOG_DIR}/errors.log"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] TEST FAILED: ${webhook_url} - HTTP ${http_code}: ${response_body}" >> "${LOG_DIR}/errors.log"
    exit 1
fi
