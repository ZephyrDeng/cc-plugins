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

### 测试日志格式
```
[2025-01-29 15:00:00] TEST: Sent to https://api.example.com/notify - HTTP 200
[2025-01-29 15:05:00] TEST FAILED: https://api.example.com/notify - HTTP 404: Not Found
```

## 命令行查看

### 查看今天的日志
```bash
cat ~/.claude/webhook-notifier/logs/$(date '+%Y-%m-%d').log
```

### 查看错误日志
```bash
cat ~/.claude/webhook-notifier/logs/errors.log
```

### 实时监控日志（tail -f）
```bash
tail -f ~/.claude/webhook-notifier/logs/$(date '+%Y-%m-%d').log
```

### 搜索特定内容
```bash
# 查找所有失败的通知
grep "ERROR" ~/.claude/webhook-notifier/logs/*.log

# 查找特定 URL 的日志
grep "api.example.com" ~/.claude/webhook-notifier/logs/*.log

# 查找今天的测试记录
grep "TEST" ~/.claude/webhook-notifier/logs/$(date '+%Y-%m-%d').log
```

## 日志分析

### 统计成功率
```bash
# 计算今天的成功和失败次数
today=$(date '+%Y-%m-%d')
success=$(grep "successfully" ~/.claude/webhook-notifier/logs/${today}.log | wc -l)
failed=$(grep "failed" ~/.claude/webhook-notifier/logs/${today}.log | wc -l)
echo "成功: ${success}, 失败: ${failed}"
```

### 查看最近的错误
```bash
tail -20 ~/.claude/webhook-notifier/logs/errors.log
```

### 按日期范围查看
```bash
# 查看最近 7 天的日志
for i in {0..6}; do
  date=$(date -v-${i}d '+%Y-%m-%d' 2>/dev/null || date -d "${i} days ago" '+%Y-%m-%d')
  log_file=~/.claude/webhook-notifier/logs/${date}.log
  if [[ -f "${log_file}" ]]; then
    echo "=== ${date} ==="
    cat "${log_file}"
    echo ""
  fi
done
```

## Debug 模式

如果启用了 debug 日志级别（在配置中设置 `"log_level": "debug"`），还会记录：
- 完整的 payload 内容到 `payloads.log`
- 更详细的执行过程信息

查看 payload 日志：
```bash
cat ~/.claude/webhook-notifier/logs/payloads.log | jq .
```

## 日志管理

### 清理旧日志
```bash
# 删除 30 天前的日志
find ~/.claude/webhook-notifier/logs/ -name "*.log" -mtime +30 -delete
```

### 归档日志
```bash
# 压缩上个月的日志
last_month=$(date -v-1m '+%Y-%m' 2>/dev/null || date -d "last month" '+%Y-%m')
cd ~/.claude/webhook-notifier/logs/
tar -czf archive-${last_month}.tar.gz ${last_month}-*.log
rm ${last_month}-*.log
```

### 日志轮转
建议定期清理或归档日志文件，避免占用过多磁盘空间：

```bash
# 添加到 crontab，每周日凌晨清理 30 天前的日志
0 0 * * 0 find ~/.claude/webhook-notifier/logs/ -name "*.log" -mtime +30 -delete
```

## 故障排除

### 无日志文件
```
问题: 日志目录不存在或没有日志文件
解决:
1. 检查插件是否正确安装
2. 运行 /webhook-test 生成测试日志
3. 检查权限: ls -la ~/.claude/webhook-notifier/logs/
```

### 日志写入失败
```
问题: 日志无法写入
解决:
1. 检查目录权限: chmod 755 ~/.claude/webhook-notifier/logs/
2. 检查磁盘空间: df -h
3. 检查文件权限问题
```

### 日志内容不完整
```
问题: 日志信息缺失或不完整
解决:
1. 启用 debug 模式获取更多信息
2. 检查脚本执行权限
3. 查看系统日志: cat /var/log/system.log | grep webhook
```

## 相关命令

- `/webhook-test` - 生成测试日志
- `/webhook-config` - 配置日志级别和目录

---

如需实时监控，建议使用：
```bash
# 持续监控今天的日志
tail -f ~/.claude/webhook-notifier/logs/$(date '+%Y-%m-%d').log
```
