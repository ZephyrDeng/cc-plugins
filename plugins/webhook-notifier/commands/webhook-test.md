# /webhook-test - 测试 Webhook 通知

发送测试 webhook 通知，验证配置是否正确。

## 功能说明

此命令会立即发送一个测试 webhook 通知到配置的 URL，帮助您验证：
- Webhook URL 是否可达
- Payload 格式是否正确
- 服务端接收是否正常

## 使用方法

```bash
/webhook-test
```

## 测试 Payload 示例

测试通知会包含以下信息：

```json
{
  "event": "test_notification",
  "timestamp": "2025-01-29T12:34:56Z",
  "session": {
    "id": "test-session-id",
    "reason": "manual_test",
    "transcript_path": "/path/to/test/transcript.jsonl"
  },
  "project": {
    "directory": "/current/working/directory",
    "git_branch": "main",
    "git_repo": "https://github.com/your-org/your-repo.git",
    "git_commit": "abc123"
  },
  "source": "claude-code-webhook-notifier",
  "test": true
}
```

## 检查结果

执行命令后，检查以下内容：
1. **终端输出** - 查看是否显示成功消息
2. **日志文件** - `~/.claude/webhook-notifier/logs/YYYY-MM-DD.log`
3. **服务端** - 检查您的 webhook 端点是否收到测试请求

## 常见问题

### 配置未设置
```
错误: Webhook URL not configured
解决: 运行 /webhook-config 配置 webhook URL
```

### 连接超时
```
错误: Connection timeout
解决: 检查网络连接和 webhook URL 是否正确
```

### HTTP 错误
```
错误: HTTP 4xx/5xx
解决: 检查服务端日志，确认接收端点是否正常工作
```

## 相关命令

- `/webhook-config` - 配置 webhook URL 和选项
- `/webhook-logs` - 查看发送历史和错误日志

---

现在让我创建测试脚本来实现这个功能。请使用以下 bash 脚本发送测试通知：

```bash
#!/usr/bin/env bash

set -euo pipefail

# 读取配置
CONFIG_FILE="${HOME}/.claude/settings.json"
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
        jq -r ".\"webhook-notifier\".${key} // \"${default}\"" "${CONFIG_FILE}" 2>/dev/null || echo "${default}"
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
response_body=$(echo "${response}" | head -n -1)

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
```

将此脚本保存为 `${CLAUDE_PLUGIN_ROOT}/scripts/test-webhook.sh` 并赋予执行权限。
