# /webhook-test - 测试通知功能

发送测试通知，验证 Webhook 和 macOS 通知配置是否正确。

## 🚀 首次使用

**重要**：此命令首次使用需要安装依赖（仅需一次）

如果看到依赖缺失提示，请执行：
```bash
cd ${CLAUDE_PLUGIN_ROOT}
npm install
```

安装完成后即可使用测试功能。

## 功能说明

此命令支持测试所有已启用的通知器：
- **macOS 通知** - 发送系统通知到通知中心
- **Webhook 通知** - 发送 HTTP POST 请求到配置的 URL
- **全部测试** - 测试所有启用的通知器

## 命令选项

- 无参数 - 测试所有启用的通知器
- `--notifier macos` - 仅测试 macOS 通知
- `--notifier webhook` - 仅测试 Webhook 通知
- `--notifier all` - 测试所有通知器（默认）

## 使用示例

### 测试所有通知器
```bash
/webhook-test
```

### 仅测试 macOS 通知
```bash
/webhook-test --notifier macos
```

### 仅测试 Webhook
```bash
/webhook-test --notifier webhook
```

## 测试内容

### macOS 通知测试
发送系统通知到 macOS 通知中心，包含：
- 标题：配置的通知标题
- 副标题："等待输入"
- 消息：测试消息内容
- 声音：配置的通知声音

### Webhook 通知测试
发送 HTTP POST 请求到配置的 Webhook URL，包含：
```json
{
  "event": "notification",
  "notification_type": "waiting_for_input",
  "message": "This is a test notification",
  "timestamp": "2025-10-31T08:00:00.000Z",
  "session": {
    "id": "test-cli-1234567890"
  },
  "project": {
    "directory": "/current/working/directory",
    "git_branch": "main",
    "git_commit": "abc123..."
  }
}
```

## 检查结果

执行命令后，检查以下内容：

1. **终端输出** - 查看是否显示 "✅ Test completed successfully!"
2. **macOS 通知中心** - 应该看到测试通知弹窗（如果启用）
3. **日志文件** - `~/.claude/webhook-notifier/logs/`
   ```bash
   /webhook-logs --lines 10
   ```
4. **Webhook 端点** - 检查服务端是否收到测试请求

## 故障排除

### 依赖缺失
如果看到 "缺少必需的依赖" 提示：
```bash
cd ${CLAUDE_PLUGIN_ROOT}
npm install
```

### macOS 通知未显示
- 检查配置：`/webhook-config --show`
- 验证 macos.enabled 是否为 true
- 检查系统通知权限

### Webhook 测试失败
- 验证 URL 配置正确
- 检查网络连接
- 查看详细日志：`/webhook-logs --level error`

## 相关命令

- `/webhook-config` - 配置通知系统
- `/webhook-logs` - 查看通知历史和错误日志

---

**执行方式：**

```bash
bash ${CLAUDE_PLUGIN_ROOT}/commands/webhook-test-wrapper.sh "$@"
```
