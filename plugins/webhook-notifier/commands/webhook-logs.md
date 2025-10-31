# /webhook-logs - 查看通知日志

查看通知系统的发送历史和错误日志。

## 🚀 首次使用

**重要**：此命令首次使用需要安装依赖（仅需一次）

如果看到依赖缺失提示，请执行：
```bash
cd ${CLAUDE_PLUGIN_ROOT}
npm install
```

安装完成后即可查看日志。

## 功能说明

此命令显示通知系统的日志信息，帮助您：
- 查看 macOS 和 Webhook 通知发送历史
- 排查发送失败问题
- 监控通知状态和性能

## 命令选项

- 无参数 - 显示最近 20 条日志
- `--lines N` - 显示最近 N 条日志
- `--level LEVEL` - 过滤特定级别（debug/info/warn/error）
- `--follow` - 实时跟踪日志（开发中）

## 使用示例

### 查看最近日志
```bash
/webhook-logs
```

### 查看最近 50 条
```bash
/webhook-logs --lines 50
```

### 仅查看错误
```bash
/webhook-logs --level error
```

## 日志文件位置

日志文件存储在 `~/.claude/webhook-notifier/logs/` 目录：

```
~/.claude/webhook-notifier/logs/
├── 2025-10-31.log          # 按日期记录（JSON 格式）
├── errors.log               # 错误专用日志
```

## 日志格式

日志采用 JSON 格式，便于程序解析：

### 标准日志示例
```json
{
  "timestamp": "2025-10-31T08:00:00.000Z",
  "level": "info",
  "message": "Processing Notification event"
}
{
  "timestamp": "2025-10-31T08:00:01.000Z",
  "level": "info",
  "message": "Sending notifications via 1 notifiers"
}
{
  "timestamp": "2025-10-31T08:00:05.000Z",
  "level": "info",
  "message": "macOS notification sent successfully"
}
```

### 错误日志示例
```json
{
  "timestamp": "2025-10-31T08:05:00.000Z",
  "level": "error",
  "message": "macOS notification failed",
  "meta": {
    "error": "Message property is required"
  }
}
```

## 故障排除

### 依赖缺失
如果看到 "缺少必需的依赖" 提示：
```bash
cd ${CLAUDE_PLUGIN_ROOT}
npm install
```

### 日志目录不存在
日志目录会自动创建，如果遇到权限问题：
```bash
mkdir -p ~/.claude/webhook-notifier/logs
chmod 755 ~/.claude/webhook-notifier/logs
```

### 日志太大
日志按天轮转，旧日志可以手动删除：
```bash
rm ~/.claude/webhook-notifier/logs/2025-10-*.log
```

## 相关命令

- `/webhook-test` - 生成测试日志
- `/webhook-config` - 配置日志级别和目录

---

**执行方式：**

```bash
bash ${CLAUDE_PLUGIN_ROOT}/commands/webhook-logs-wrapper.sh "$@"
```
