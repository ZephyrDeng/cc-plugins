---
name: serena-cleanup
description: "清理 Serena 索引数据，移除过期、损坏或冗余的索引文件以优化性能"
category: maintenance
complexity: standard
mcp-servers: [serena]
personas: [maintainer]
---

# /serena-cleanup - Serena 索引清理

## Triggers
- 索引文件过大影响性能
- 磁盘空间不足
- 索引数据损坏需要重建
- 项目结构调整后的清理工作
- 定期维护和优化

## Usage
```
/serena-cleanup [options]

Options:
  --dry-run          # 预览将要删除的文件，不实际删除
  --aggressive       # 激进清理，删除更多缓存文件
  --force           # 强制清理，不询问确认
  --backup          # 清理前创建备份
  --keep-days N     # 保留最近N天的索引（默认：7天）
  --cache-only      # 仅清理缓存文件，保留主索引
  --all             # 清理所有索引数据（重建用）
```

## Behavioral Flow
1. **安全检查**: 验证操作安全性和权限
2. **扫描分析**: 识别过期、损坏和冗余文件
3. **空间计算**: 计算可释放的磁盘空间
4. **用户确认**: 显示清理计划并请求确认（除非使用 --force）
5. **执行清理**: 安全删除标识的文件
6. **状态更新**: 更新索引元数据

## Examples

### 基本清理
```
/serena-cleanup
# 输出：
# 🔍 扫描索引数据...
#
# 📊 发现可清理文件:
# - 过期索引: 3 个文件 (45.2 MB)
# - 临时文件: 12 个文件 (8.7 MB)
# - 缓存文件: 156 个文件 (23.1 MB)
# - 损坏文件: 1 个文件 (2.3 MB)
#
# 💾 总计可释放: 79.3 MB
#
# ❓ 确认清理这些文件吗？[y/N]
```

### 预览清理
```
/serena-cleanup --dry-run
# 输出：
# 🔍 Serena 索引清理预览
#
# 📋 将要清理的文件:
# - .serena/cache_old/ (23.4 MB) - 过期缓存
# - .serena/tmp_20251015/ (12.7 MB) - 临时文件
# - .serena/index_backup.json (8.9 MB) - 旧备份
# - .serena/symbols_corrupt.json (2.1 MB) - 损坏文件
#
# 💾 可释放空间: 47.1 MB
# ⚠️ 这只是预览，不会实际删除文件
```

### 激进清理
```
/serena-cleanup --aggressive --keep-days 3
# 输出：
# 🧹 Serena 激进清理模式
#
# 📊 清理策略:
# - 保留最近: 3 天的索引
# - 清理范围: 所有缓存、备份、临时文件
# - 激进选项: 包括部分有用的缓存文件
#
# 📋 发现清理目标:
# - 过期索引: 8 个文件 (67.3 MB)
# - 缓存文件: 234 个文件 (45.8 MB)
# - 临时文件: 19 个文件 (15.2 MB)
# - 日志文件: 45 个文件 (8.9 MB)
#
# 💾 总计可释放: 137.2 MB
# ⚠️ 激进清理可能影响首次查询性能
```

### 仅清理缓存
```
/serena-cleanup --cache-only
# 输出：
# 🧹 Serena 缓存清理
#
# 📊 缓存文件统计:
# - 查询缓存: 89 个文件 (23.4 MB)
# - 符号缓存: 156 个文件 (34.7 MB)
# - 元数据缓存: 23 个文件 (5.6 MB)
# - 临时缓存: 67 个文件 (12.3 MB)
#
# 💾 可释放缓存空间: 76.0 MB
# ✅ 主索引文件将保留
```

### 备份清理
```
/serena-cleanup --backup
# 输出：
# 💾 创建清理备份...
# ✅ 备份已创建: .serena/backup_20251015_183022.tar.gz (89.2 MB)
#
# 🧹 执行清理操作...
# 📊 清理统计:
# - 删除文件: 167 个
# - 释放空间: 79.3 MB
# - 保留索引: ✅ 正常
#
# 🔒 备份位置: .serena/backup_20251015_183022.tar.gz
# ⚠️ 备份将在30天后自动删除
```

### 全部清理
```
/serena-cleanup --all --force
# 输出：
# ⚠️ 警告：将删除所有索引数据！
# 🗑️ 清理范围: .serena/ 目录下的所有文件
# 💾 将释放空间: 245.6 MB
#
# 🔄 执行全部清理...
# ✅ 索引数据已完全清理
#
# 📝 后续步骤:
# 1. 运行 /serena-index 重建索引
# 2. 验证索引完整性: /serena-status --health
# 3. 测试查询功能
```

## Cleanup Targets

### 过期索引
- 超过保留期的旧索引文件
- 版本过时的索引数据
- 项目结构调整后的无效索引

### 缓存文件
- 查询结果缓存
- 符号解析缓存
- 临时计算缓存

### 临时文件
- 索引过程中生成的临时文件
- 中间处理结果
- 调试和日志文件

### 损坏文件
- 无法读取的索引文件
- 格式错误的数据文件
- 不完整的索引片段

## Safety Features

### 自动备份
- 清理前自动创建备份
- 备份文件自动过期清理
- 支持自定义备份保留策略

### 权限检查
- 验证文件删除权限
- 检查索引文件完整性
- 防止误删重要数据

### 操作回滚
- 支持从备份恢复
- 清理日志记录
- 错误时自动回滚

## Configuration Options

清理行为可以通过环境变量配置：

```bash
# 默认保留天数
export SERENA_CLEANUP_KEEP_DAYS=7

# 备份保留天数
export SERENA_BACKUP_RETENTION_DAYS=30

# 自动备份阈值 (MB)
export SERENA_AUTO_BACKUP_THRESHOLD=100

# 激进清理模式
export SERENA_AGGRESSIVE_CLEANUP=false
```

## Integration with Monitoring

清理操作会生成详细报告：
- 清理统计信息
- 性能改进建议
- 后续维护计划

## Error Handling

### 权限不足
```
❌ 权限不足，无法删除索引文件
💡 解决方案:
   1. 检查文件权限: ls -la .serena/
   2. 修复权限: chmod -R 755 .serena/
   3. 使用 sudo 重新运行 (不推荐)
```

### 磁盘空间不足
```
❌ 磁盘空间不足，无法创建备份
💡 解决方案:
   1. 使用 --no-backup 跳过备份
   2. 清理其他文件释放空间
   3. 使用外部存储设备
```

### 索引正在使用
```
⚠️ 检测到索引正在被使用
💡 建议操作:
   1. 等待当前查询完成
   2. 使用 --force 强制清理
   3. 重启 Claude Code 后重试
```