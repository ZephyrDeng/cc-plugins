# /webhook-config - 配置 Webhook 通知

交互式配置 webhook notifier 插件的 URL 和选项。

## 功能说明

此命令会引导您完成以下配置：
- Webhook URL 设置
- 超时时间配置
- 日志级别设置
- Payload 选项配置
- 启用/禁用通知
- 配置完成后可选发送测试通知

配置文件：`~/.claude/webhook-notifier/config.json`

## 相关命令

- `/webhook-test` - 发送测试通知验证配置
- `/webhook-logs` - 查看通知发送历史

---

请执行配置脚本：

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/config-webhook.sh
```
