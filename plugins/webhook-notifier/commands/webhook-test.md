# /webhook-test - 测试 Webhook 通知

发送测试 webhook 通知，验证配置是否正确。

## 功能说明

此命令会立即发送一个测试 webhook 通知到配置的 URL，帮助您验证：
- Webhook URL 是否可达
- Payload 格式是否正确
- 服务端接收是否正常

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

## 相关命令

- `/webhook-config` - 配置 webhook URL 和选项
- `/webhook-logs` - 查看发送历史和错误日志

---

请执行测试脚本：

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/test-webhook.sh
```
