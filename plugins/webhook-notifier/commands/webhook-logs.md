# /webhook-logs - 查看 Webhook 通知日志

查看 webhook 通知的发送历史和错误日志。

## 功能说明

此命令显示 webhook notifier 的日志信息，帮助您：
- 查看通知发送历史
- 排查发送失败问题
- 监控通知状态

## 使用方法

### 查看今天的日志
```bash
/webhook-logs
```

### 查看特定日期的日志
```bash
/webhook-logs 2025-01-29
```

### 查看错误日志
```bash
/webhook-logs --errors
```

### 查看最近 N 条记录
```bash
/webhook-logs --tail 20
```

## 日志文件位置

日志文件存储在 `~/.claude/webhook-notifier/logs/` 目录：

```
~/.claude/webhook-notifier/logs/
├── 2025-01-29.log          # 按日期记录
├── 2025-01-30.log
├── errors.log               # 错误专用日志
└── payloads.log            # Payload 记录（debug 模式）
```

## 日志格式

### 标准日志格式
```
[2025-01-29 14:30:45] INFO: Processing Stop event
[2025-01-29 14:30:45] INFO: Sending webhook to: https://api.example.com/notify
[2025-01-29 14:30:46] INFO: Webhook sent successfully (HTTP 200)
[2025-01-29 14:30:46] INFO: Webhook notification completed successfully
```

### 错误日志格式
```
[2025-01-29 14:35:22] ERROR: Webhook failed (HTTP 500): Internal Server Error
[2025-01-29 14:40:15] ERROR: Connection timeout after 10 seconds
[2025-01-29 14:45:30] ERROR: Webhook URL not configured
```

## 相关命令

- `/webhook-test` - 生成测试日志
- `/webhook-config` - 配置日志级别和目录

---

请执行日志查看脚本：

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/show-logs.sh "$@"
```
