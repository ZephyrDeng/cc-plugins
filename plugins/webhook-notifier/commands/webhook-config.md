# /webhook-config - 配置 Webhook 通知

交互式配置 webhook notifier 插件的 URL 和选项。

## 功能说明

此命令提供交互式界面来配置 webhook notifier，包括：
- Webhook URL 设置
- 超时时间配置
- Payload 选项配置
- 启用/禁用通知

## 使用方法

```bash
/webhook-config
```

命令会引导您完成配置过程，并自动更新 `~/.claude/settings.json` 文件。

## 配置选项

### 必需配置
- **webhook_url**: Webhook 通知的目标 URL

### 可选配置
- **enabled**: 启用或禁用通知（默认: true）
- **timeout**: HTTP 请求超时时间（秒，默认: 10）
- **log_level**: 日志级别（info/debug，默认: info）

### Payload 配置
- **include_session_id**: 包含会话 ID（默认: true）
- **include_reason**: 包含结束原因（默认: true）
- **include_transcript_path**: 包含会话记录路径（默认: true）
- **include_project_info**: 包含项目信息（默认: true）
- **include_git_info**: 包含 Git 信息（默认: true）

## 配置文件位置

配置会保存到 `~/.claude/settings.json`，格式如下：

```json
{
  "webhook-notifier": {
    "webhook_url": "https://your-webhook-endpoint.com/notify",
    "enabled": true,
    "timeout": 10,
    "log_level": "info",
    "payload_config": {
      "include_session_id": true,
      "include_reason": true,
      "include_transcript_path": true,
      "include_project_info": true,
      "include_git_info": true
    }
  }
}
```

## 快速配置

如果您只想设置 webhook URL，可以直接编辑配置文件：

```bash
# 使用 jq 修改配置
jq '.["webhook-notifier"].webhook_url = "https://your-webhook.com/notify"' \
  ~/.claude/settings.json > ~/.claude/settings.json.tmp && \
  mv ~/.claude/settings.json.tmp ~/.claude/settings.json
```

或者手动编辑 `~/.claude/settings.json` 文件。

## 验证配置

配置完成后，建议运行测试命令验证：

```bash
/webhook-test
```

## 相关命令

- `/webhook-test` - 发送测试通知验证配置
- `/webhook-logs` - 查看通知发送历史

---

现在让我提供一个简单的配置脚本来帮助用户快速设置。请告诉用户使用以下步骤：

1. **编辑配置文件**
   ```bash
   # 使用您喜欢的编辑器打开配置
   code ~/.claude/settings.json  # 或 vim、nano 等
   ```

2. **添加或修改 webhook-notifier 配置节**
   复制 `${CLAUDE_PLUGIN_ROOT}/templates/settings.json` 中的配置模板

3. **设置 webhook URL**
   将 `webhook_url` 修改为您的实际 webhook 端点

4. **运行测试**
   ```bash
   /webhook-test
   ```

## 配置示例

### 基础配置
```json
{
  "webhook-notifier": {
    "webhook_url": "https://api.example.com/webhooks/claude-sessions",
    "enabled": true,
    "timeout": 10
  }
}
```

### 完整配置
```json
{
  "webhook-notifier": {
    "webhook_url": "https://api.example.com/webhooks/claude-sessions",
    "enabled": true,
    "timeout": 15,
    "log_level": "debug",
    "log_directory": "~/.claude/webhook-notifier/logs",
    "payload_config": {
      "include_session_id": true,
      "include_reason": true,
      "include_transcript_path": true,
      "include_project_info": true,
      "include_git_info": true,
      "custom_fields": {
        "team": "engineering",
        "environment": "production"
      }
    }
  }
}
```

## 安全建议

1. **HTTPS 连接**: 始终使用 HTTPS webhook URL 确保数据传输安全
2. **敏感信息**: 如果使用认证，避免在配置中硬编码 API keys
3. **日志管理**: 定期清理日志文件，避免敏感信息泄露

## 故障排除

### 配置未生效
- 确认配置文件格式正确（JSON 格式）
- 检查是否有语法错误（多余的逗号等）
- 重启 Claude Code 使配置生效

### 无法找到配置文件
```bash
# 创建配置目录
mkdir -p ~/.claude

# 从模板复制配置
cp ${CLAUDE_PLUGIN_ROOT}/templates/settings.json ~/.claude/settings.json
```
