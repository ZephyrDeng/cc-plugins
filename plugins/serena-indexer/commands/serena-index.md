---
name: serena-index
description: "异步执行 Serena 项目索引，为项目建立语义理解和代码符号索引"
category: project
complexity: standard
mcp-servers: [serena]
personas: [architect]
---

# /serena-index - Serena 项目索引

## Triggers
- 项目首次使用 Serena MCP 时需要建立索引
- 代码库发生重大变更后需要重新索引
- 手动请求项目索引更新
- 新项目 onboarding 流程的一部分
- 索引工具响应变慢时需要重新索引

## Usage
```
/serena-index [project-path] [options]

Options:
  --generate-config   # 生成 .serena/project.yml 配置文件
  --reindex          # 强制重新索引，清除旧索引数据
  --setup-hooks      # 配置自动索引 hook（会话开始时自动索引）
  --status           # 查询当前索引状态和健康度
  --smart            # 智能决策（仅在需要时索引）
  --verify           # 验证索引完整性
  --cleanup          # 清理过期索引数据
```

## 环境要求
- 项目必须是 Git 仓库（需要 `.git` 目录）
- Python 环境和 uvx 工具可用
- 磁盘空间充足（索引文件可能较大）
- Serena MCP 已配置并启用

## Behavioral Flow
1. **环境检测**: 验证 Git 仓库、Python 环境、Serena MCP 配置
2. **配置准备**: 可选生成 `.serena/project.yml` 配置文件
3. **委托执行**: 将索引任务委托给 serena-indexer agent 异步执行
4. **进度监控**: 跟踪索引进度和统计信息
5. **完成验证**: 验证索引数据完整性和可用性

Key behaviors:
- 自动检测项目是否配置了 Serena MCP
- 使用 Task agent 异步执行，不阻塞主工作流
- 提供清晰的进度反馈和完成状态
- 支持配置文件生成和重新索引
- 索引数据存储在 `.serena/` 目录

## MCP Integration
- **Serena MCP**: 执行 `uvx --from git+https://github.com/oraios/serena serena project index`
- **Sequential MCP**: 用于复杂的索引状态分析和验证

## Tool Coordination
- **Task**: 委托给 serena-indexer agent 进行异步索引执行
- **Bash**: 检查 MCP 配置和执行索引命令
- **Read**: 读取项目配置文件验证 Serena 可用性

## Key Patterns
- **异步执行**: Task(serena-indexer) → 不阻塞主流程
- **配置管理**: 生成配置 → 执行索引 → 验证完成
- **环境验证**: Git 检查 → Python 检查 → MCP 配置检查
- **错误处理**: 优雅处理索引失败，提供清晰错误信息和解决方案

## Examples

### 基本用法
```
/serena-index
# 自动检测当前项目并异步执行索引
# 索引数据将存储在 .serena/ 目录
```

### 首次使用（生成配置）
```
/serena-index --generate-config
# 首先生成 .serena/project.yml 配置文件
# 然后执行项目索引
```

### 指定项目路径
```
/serena-index /path/to/project
# 为指定路径的项目执行索引
```

### 重新索引
```
/serena-index --reindex
# 强制重新索引，清除旧索引数据
# 适用于代码库发生重大变更的情况
```

### 配置自动索引 Hook
```
/serena-index --setup-hooks
# 交互流程：
# ? 选择配置范围:
#   > 全局配置（所有项目）: ~/.claude/settings.json
#     项目配置（仅当前项目）: .claude/settings.json
# ? 选择触发时机:
#   > SessionStart（会话开始时）
#     PreToolUse（使用 Serena MCP 工具前）
#     仅手动触发
# ? 选择索引策略:
#     总是索引
#   > 智能判断（推荐）
#     仅手动触发
# ✅ Hook 配置已创建: .claude/settings.json
# ✅ Hook 脚本已创建: .claude/hooks/serena-auto-index.sh
#
# 下次会话开始或使用 Serena MCP 工具时，hook 将自动检查并更新索引
```

### 查询索引状态
```
/serena-index --status
# 输出：
# 📊 Serena 索引状态
#
# 项目: /path/to/your/project
# 上次索引: 2小时前 (2025-10-15 17:30:45)
# 索引文件: 94 个 Go 文件
# 提取符号: 1,248 个（函数: 453, 类: 127, 变量: 668）
# 索引大小: 12.3 MB
# 健康度: ✅ 良好（索引新鲜，数据完整）
#
# 建议: 无需重新索引
```

### 智能索引
```
/serena-index --smart
# 智能判断是否需要重新索引
# 如果索引新鲜且文件变更少，则跳过索引
# 输出：
# 🔍 检查索引状态...
# ✅ 索引仍然新鲜（2小时前），跳过索引
# 或
# 🔄 检测到 15 个文件变更，正在更新索引...
```

### 验证索引完整性
```
/serena-index --verify
# 验证索引数据是否完整和可访问
# 输出：
# 🔍 正在验证索引完整性...
# ✅ 索引数据完整，所有符号可访问
# 或
# ❌ 检测到索引损坏，建议重新索引
```

### 清理旧索引
```
/serena-index --cleanup
# 清理过期或损坏的索引数据
# 输出：
# 🗑️ 清理旧索引数据...
# ✅ 已清理 45.2 MB 过期索引
```

## 索引输出
- **索引位置**: `.serena/` 目录
- **日志文件**: `.claude/doc/serena_index_log.md`
- **统计信息**: 文件数量、符号数量、执行时长
- **错误报告**: 详细的错误堆栈和解决建议

## Boundaries

**Will:**
- 自动检测 Serena MCP 配置状态和 Git 仓库
- 异步执行索引命令，不阻塞主工作流
- 可选生成项目配置文件 `.serena/project.yml`
- 生成自动索引 hook 脚本（--setup-hooks）
- 查询索引状态和健康度（--status）
- 智能决策是否需要重新索引（--smart）
- 验证索引完整性（--verify）
- 清理过期索引数据（--cleanup）
- 提供清晰的进度和状态反馈
- 验证索引完成和项目可用性
- 处理索引失败并提供解决方案
- 询问用户偏好（hook 范围、触发时机、索引策略）

**Will Not:**
- 在未配置 Serena MCP 时强制执行索引
- 在非 Git 仓库中执行索引
- 在索引过程中占用主对话流程
- 覆盖用户的 MCP 配置设置
- 修改项目源代码文件
- 在用户未确认的情况下安装 hook
- 强制使用特定的索引策略