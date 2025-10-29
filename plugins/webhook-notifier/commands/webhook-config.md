# /webhook-config - 配置 Webhook 通知

命令行配置 webhook notifier 插件的 URL 和选项。

## 功能说明

此命令支持通过命令行参数配置 webhook 通知系统：
- Webhook URL 设置
- 超时时间配置
- 日志级别设置
- Payload 选项配置
- 启用/禁用通知
- 配置完成后可选发送测试通知

配置文件：`~/.claude/webhook-notifier/config.json`
日志目录：`~/.claude/webhook-notifier/logs`

## 命令行参数

### 必需参数（首次配置）
- `--url URL` - 设置 Webhook URL

### 可选配置参数
- `--enable` - 启用通知（默认）
- `--disable` - 禁用通知
- `--timeout SECONDS` - 超时时间秒数（默认：10）
- `--log-level LEVEL` - 日志级别：debug|info|warn|error（默认：info）

### Payload 配置（默认全部启用）
- `--include-session-id` / `--no-include-session-id` - 包含/不包含会话 ID
- `--include-reason` / `--no-include-reason` - 包含/不包含结束原因
- `--include-transcript` / `--no-include-transcript` - 包含/不包含会话记录路径
- `--include-project` / `--no-include-project` - 包含/不包含项目信息
- `--include-git` / `--no-include-git` - 包含/不包含 Git 信息

### 操作命令
- `--show` - 显示当前配置
- `--default` - 创建默认配置（带占位符）
- `--test` - 配置完成后发送测试通知
- `--help` - 显示帮助信息

## 使用示例

### 快速配置
```bash
/webhook-config --url https://example.com/webhook --enable
```

### 完整配置
```bash
/webhook-config \
  --url https://example.com/webhook \
  --enable \
  --timeout 15 \
  --log-level debug \
  --include-session-id \
  --include-reason \
  --no-include-transcript \
  --test
```

### 查看当前配置
```bash
/webhook-config --show
```

### 创建默认配置
```bash
/webhook-config --default
```

### 只修改超时时间
```bash
/webhook-config --timeout 30
```

### 禁用通知
```bash
/webhook-config --disable
```

## 配置文件格式

配置以 JSON 格式保存：

```json
{
  "webhook_url": "https://example.com/webhook",
  "enabled": true,
  "timeout": 10,
  "log_level": "info",
  "payload_config": {
    "include_session_id": true,
    "include_reason": true,
    "include_transcript_path": true,
    "include_project_info": true,
    "include_git_info": true,
    "custom_fields": {}
  }
}
```

## 验证规则

- **URL 格式**：必须以 `http://` 或 `https://` 开头
- **超时时间**：1-300 秒之间的正整数
- **日志级别**：必须是 `debug`、`info`、`warn` 或 `error` 之一

## 相关命令

- `/webhook-test` - 发送测试通知验证配置
- `/webhook-logs` - 查看通知发送历史

## 故障排除

### 配置文件不存在
运行 `/webhook-config --default` 创建默认配置文件。

### URL 格式错误
确保 URL 以 `http://` 或 `https://` 开头。

### 查看详细日志
使用 `/webhook-logs` 查看通知发送历史和错误日志。

---

**执行方式：**

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/config-webhook.sh "$@"
```
