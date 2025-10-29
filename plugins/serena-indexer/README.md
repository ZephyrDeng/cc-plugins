# Serena Indexer Plugin

专业的 Serena 索引管理插件，为 Claude Code 提供异步索引初始化、智能重建和自动化维护功能。

## 🚀 快速开始

### 安装插件

```bash
# 添加市场（如果尚未添加）
/plugin marketplace add wshobson/agents

# 安装 Serena Indexer 插件
/plugin install serena-indexer
```

### 基础使用

```bash
# 首次使用 - 初始化索引
/serena-index --generate-config

# 查看索引状态
/serena-status

# 智能更新索引（仅在需要时）
/serena-index --smart
```

## 📋 功能概览

### 核心命令

| 命令 | 功能 | 适用场景 |
|------|------|----------|
| `/serena-index` | 异步索引初始化和重建 | 项目首次使用、重大变更后 |
| `/serena-status` | 索引状态查询和健康检查 | 监控索引状态、性能分析 |
| `/serena-cleanup` | 索引数据清理和优化 | 磁盘空间管理、性能优化 |

### 专业代理

- **Serena Indexer**: 异步索引执行专家
- **Serena Monitor**: 索引健康监控专家

### 自动化功能

- **智能索引决策**: 自动判断是否需要更新索引
- **自动维护钩子**: 会话开始时自动检查索引状态
- **性能优化**: 自动清理缓存和优化索引结构

## 🎯 使用场景

### 1. 项目初始化
```bash
# 新项目首次设置
/serena-index --generate-config

# 输出示例：
# ✅ 配置文件已生成: .serena/project.yml
# 🚀 开始 Serena 索引...
# ✅ 索引完成！处理了 156 个文件，提取了 1,247 个符号
```

### 2. 日常开发
```bash
# 智能更新（推荐日常使用）
/serena-index --smart

# 输出示例：
# 🔍 检查索引状态...
# ✅ 索引仍然新鲜（1小时前），跳过索引
# 或
# 🔄 检测到 12 个文件变更，正在更新索引...
```

### 3. 性能监控
```bash
# 查看详细状态
/serena-status --detailed

# 输出示例：
# 📊 Serena 详细索引状态
# 状态: ✅ 健康 | 索引大小: 23.4 MB | 符号数量: 1,847
# 性能: 平均查询 45ms | 缓存命中率 87% | 内存占用 34MB
```

### 4. 问题诊断
```bash
# 健康检查
/serena-status --health

# 清理优化
/serena-cleanup --cache-only

# 强制重建（问题解决）
/serena-index --reindex --force
```

## ⚙️ 高级配置

### 环境变量配置

```bash
# 索引性能调优
export SERENA_CACHE_ENABLED=true
export SERENA_PARALLEL_WORKERS=4
export SERENA_LOG_LEVEL=info

# 清理策略配置
export SERENA_CLEANUP_KEEP_DAYS=7
export SERENA_AUTO_BACKUP_THRESHOLD=100
```

### 索引策略配置

在 `.serena/project.yml` 中自定义索引行为：

```yaml
# 项目配置示例
project:
  name: "my-awesome-project"
  type: "go"

# 索引策略
indexing:
  strategy: "smart"  # full, incremental, smart
  include_patterns:
    - "*.go"
    - "*.md"
    - "*.yaml"
  exclude_patterns:
    - "vendor/*"
    - "*.pb.go"
    - "*_test.go"

# 性能配置
performance:
  parallel_workers: 4
  cache_size: "100MB"
  timeout: 600  # 秒

# 监控配置
monitoring:
  health_check_interval: 3600  # 秒
  auto_cleanup: true
  performance_tracking: true
```

### 自动化钩子配置

```bash
# 设置自动索引（推荐）
/serena-index --setup-hooks

# 交互式配置：
# ? 选择配置范围: 项目配置（仅当前项目）
# ? 选择触发时机: SessionStart（会话开始时）
# ? 选择索引策略: 智能判断（推荐）
# ✅ Hook 配置已完成
```

## 🔧 故障排除

### 常见问题

#### 1. 索引失败
```bash
❌ 索引执行失败

解决方案：
1. 检查环境：Python、uvx 工具是否安装
2. 验证权限：确保 .serena 目录可写
3. 清理重试：/serena-cleanup --all && /serena-index
4. 查看日志：检查详细错误信息
```

#### 2. 性能问题
```bash
⚠️ 查询响应变慢

诊断步骤：
1. 检查状态：/serena-status --performance
2. 清理缓存：/serena-cleanup --cache-only
3. 重建索引：/serena-index --reindex
4. 调整配置：减少并行工作线程数
```

#### 3. 磁盘空间不足
```bash
💾 磁盘空间不足

解决方案：
1. 清理数据：/serena-cleanup --aggressive
2. 手动清理：删除 .serena/backup_*.tar.gz
3. 调整策略：减少索引保留天数
4. 扩容存储：移动索引到更大分区
```

### 调试模式

```bash
# 启用详细日志
export SERENA_LOG_LEVEL=debug

# 执行索引并查看详细输出
/serena-index 2>&1 | tee serena-index.log

# 分析日志文件
grep -E "(ERROR|WARN|FAIL)" serena-index.log
```

## 📊 性能优化建议

### 1. 索引策略优化
- **小项目** (< 100 文件): 使用完整索引，更新频率低
- **中型项目** (100-1000 文件): 使用智能索引，增量更新
- **大型项目** (> 1000 文件): 使用智能索引，并行处理

### 2. 缓存策略
- **开发环境**: 启用大缓存，优先性能
- **CI/CD 环境**: 禁用缓存，节省空间
- **生产环境**: 平衡缓存大小和性能

### 3. 监控频率
- **活跃项目**: 每日健康检查
- **稳定项目**: 每周状态检查
- **维护模式**: 按需检查

## 🔗 集成示例

### 与 Git 工作流集成
```bash
# 在 .git/hooks/post-merge 中添加：
#!/bin/bash
/serena-index --smart &
```

### 与 CI/CD 集成
```yaml
# GitHub Actions 示例
- name: Update Serena Index
  run: |
    claude /serena-index --smart
    claude /serena-status --health
```

### 与 IDE 集成
```bash
# VS Code 任务配置
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Update Serena Index",
      "type": "shell",
      "command": "claude",
      "args": ["/serena-index", "--smart"]
    }
  ]
}
```

## 📈 监控和报告

### 健康度评分
```yaml
评分体系:
  90-100: 优秀 - 无需关注
  80-89: 良好 - 建议优化
  70-79: 一般 - 需要关注
  <70: 较差 - 需要立即处理
```

### 性能基准
```yaml
性能指标:
  查询响应时间:
    优秀: <50ms
    良好: 50-100ms
    一般: 100-200ms
    较差: >200ms

  缓存命中率:
    优秀: >90%
    良好: 80-90%
    一般: 70-80%
    较差: <70%
```

## 🤝 贡献和支持

### 报告问题
- 使用 GitHub Issues 报告 bug
- 提供详细的错误日志和环境信息
- 包含重现步骤和预期行为

### 功能请求
- 描述新功能的用例和价值
- 提供设计建议和实现思路
- 考虑向后兼容性

### 开发贡献
- Fork 项目并创建功能分支
- 遵循代码规范和测试要求
- 提交 Pull Request 并描述变更内容

## 📄 许可证

本项目采用 MIT 许可证，详见 [LICENSE](../../LICENSE) 文件。

---

**让 Serena 索引为你的开发效率赋能！** 🚀