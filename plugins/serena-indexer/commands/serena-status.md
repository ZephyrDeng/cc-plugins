---
name: serena-status
description: "查询 Serena 索引状态和健康度，提供详细的索引统计信息"
category: monitoring
complexity: simple
mcp-servers: [serena]
personas: [monitor]
---

# /serena-status - Serena 索引状态查询

## Triggers
- 需要检查索引是否最新
- 索引响应变慢时诊断
- 定期维护和监控
- 验证索引完整性

## Usage
```
/serena-status [options]

Options:
  --detailed          # 显示详细的统计信息
  --health           # 执行健康度检查
  --performance      # 显示性能指标
  --format json|table|markdown  # 输出格式
```

## Behavioral Flow
1. **索引检测**: 检查 .serena 目录和元数据文件
2. **统计分析**: 分析索引文件大小、符号数量、更新时间
3. **健康评估**: 评估索引完整性和性能状态
4. **建议输出**: 提供维护建议和优化选项

## Examples

### 基本状态查询
```
/serena-status
# 输出：
# 📊 Serena 索引状态
#
# 项目: /Users/zephyr/my-project
# 状态: ✅ 健康
# 上次索引: 2小时前 (2025-10-15 17:30:45)
# 索引文件: 94 个 Go 文件
# 提取符号: 1,248 个
#  - 函数: 453 个
#  - 类: 127 个
#  - 变量: 668 个
# 索引大小: 12.3 MB
#
# 建议: 索引状态良好，无需更新
```

### 详细状态查询
```
/serena-status --detailed
# 输出：
# 📊 Serena 详细索引状态
#
# 🗂️ 索引文件信息:
# - project_index.json: 8.2 MB (主索引)
# - symbols_functions.json: 2.1 MB (函数符号)
# - symbols_classes.json: 1.8 MB (类符号)
# - symbols_variables.json: 3.2 MB (变量符号)
# - metadata.json: 15.6 KB (元数据)
#
# 📈 性能指标:
# - 平均查询时间: 45ms
# - 内存占用: 23.4 MB
# - 缓存命中率: 87%
# - 并发查询支持: ✅
#
# 🔄 更新历史:
# - 最后更新: 2025-10-15 17:30:45
# - 更新耗时: 4m 32s
# - 更新原因: 15 个文件变更
# - 更新策略: 增量更新
#
# 💡 优化建议:
# - 索引质量优秀，性能良好
# - 建议定期执行完整性检查
# - 可考虑启用智能缓存优化
```

### 健康检查
```
/serena-status --health
# 输出：
# 🔍 Serena 索引健康检查
#
# ✅ 索引完整性: 通过
# ✅ 符号可访问性: 通过
# ✅ 文件同步状态: 通过
# ✅ 缓存状态: 优秀
# ⚠️ 索引年龄: 2小时 (建议<6小时)
# ✅ 磁盘空间: 充足 (1.2GB 可用)
# ✅ 权限设置: 正常
#
# 🎯 总体健康度: 95/100 (优秀)
#
# 📋 维护建议:
# - 索引状态良好，建议保持当前配置
# - 可设置自动更新策略以保持索引新鲜度
```

### 性能分析
```
/serena-status --performance
# 输出：
# ⚡ Serena 性能分析
#
# 📊 响应时间统计:
# - 平均查询时间: 45ms
# - 95% 分位时间: 89ms
# - 最慢查询: 234ms (查找复杂符号)
# - 最快查询: 12ms (简单函数查找)
#
# 💾 内存使用分析:
# - 索引加载: 23.4 MB
# - 缓存占用: 8.7 MB
# - 查询缓存: 5.2 MB
# - 总内存占用: 37.3 MB
#
# 🚀 性能优化建议:
# - 索引性能优秀，无需优化
# - 可增加缓存大小以提升命中率
# - 考虑启用并行查询以提升复杂查询性能
```

## Output Format Options

### JSON 格式
```
/serena-status --format json
# 输出结构化的 JSON 数据，便于程序化处理
```

### Table 格式
```
/serena-status --format table
# 输出表格格式，便于快速浏览
```

### Markdown 格式
```
/serena-status --format markdown
# 输出 Markdown 格式，便于文档生成
```

## Integration with Other Commands
- 与 `/serena-index` 配合使用进行索引管理
- 与 `/serena-cleanup` 配合进行性能优化
- 支持 pipe 输出到其他工具

## Error Handling
- 索引不存在时提供清晰的指导
- 权限问题时提供解决方案
- 磁盘空间不足时发出警告
- 索引损坏时建议重建