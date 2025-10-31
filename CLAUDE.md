# Claude Code Plugins - 专业化插件集合

这是一个符合 wshobson/agents 标准的 Claude Code 插件仓库，专注于提供高质量的专业化 AI 代理和工具。

## 🎯 项目愿景

为 Claude Code 用户提供最专业、最高效的开发辅助工具集。通过精心设计的插件生态系统，让 AI 驱动的开发变得简单、强大且可靠。

## 🏗️ 核心架构

### 插件系统设计
- **模块化架构**: 每个插件专注单一功能域，确保最小化资源占用
- **标准化结构**: 统一的目录组织和配置格式
- **专业化代理**: 深度领域专家，提供精准的解决方案
- **工作流集成**: 多代理协作，处理复杂的开发任务

### 核心组件
1. **Agents (AI 代理)**: 专业化AI助手，具备特定领域深度知识
2. **Commands (命令)**: 自定义斜杠命令，扩展 Claude Code 功能
3. **Hooks (钩子)**: 事件驱动的自动化工作流
4. **MCP Servers**: 外部工具和服务集成

## 📦 可用插件

### 🔍 Serena Indexer (索引管理)
专业的 Serena 索引管理插件，提供异步索引、智能更新和健康监控。

**核心功能**:
- 智能初始化：自动识别项目类型，优化索引配置
- 增量重建：智能变更检测，高效更新索引
- 状态监控：实时索引健康检查和性能监控
- 错误恢复：自动检测和修复索引损坏问题

**命令**:
- `/serena-index` - 索引管理和初始化
- `/serena-status` - 索引状态查询
- `/serena-cleanup` - 索引清理优化

### 🔔 Webhook Notifier (通知系统)
现代化的通知系统，使用 TypeScript 5.3+ 开发，支持多种通知方式。

**核心功能**:
- 双模式运行：Hook 模式（自动）+ CLI 模式（手动）
- 智能通知：Notification 事件和 Session End 事件
- 多种通知器：Webhook（飞书/Slack/Discord）+ macOS 原生通知
- 强大 CLI：测试、配置管理、日志查看
- YAML 配置：人性化配置，支持环境变量

**命令**:
- `/webhook-test` - 测试通知配置
- `/webhook-config` - 配置管理
- `/webhook-logs` - 查看通知日志

## 📁 项目结构

```
cc-plugins/
├── .claude-plugin/
│   └── marketplace.json          # 市场配置文件
├── plugins/                       # 插件目录
│   ├── serena-indexer/           # Serena 索引管理 ⭐
│   │   ├── .claude-plugin.json   # 插件配置
│   │   ├── README.md             # 插件文档
│   │   ├── CHANGELOG.md          # 更新日志
│   │   ├── agents/               # AI 代理
│   │   │   ├── serena-indexer.md
│   │   │   └── serena-monitor.md
│   │   ├── commands/             # 用户命令
│   │   │   ├── serena-index.md
│   │   │   ├── serena-status.md
│   │   │   └── serena-cleanup.md
│   │   ├── hooks/                # 自动化钩子
│   │   │   ├── hooks.json
│   │   │   └── serena-auto-index.sh
│   │   ├── mcp.json              # MCP 配置
│   │   └── templates/            # 配置模板
│   │       └── settings.json
│   └── webhook-notifier/         # Webhook 通知系统 ⭐
│       ├── README.md             # 插件文档
│       ├── CHANGELOG.md          # 更新日志
│       ├── package.json          # NPM 配置
│       ├── tsconfig.json         # TypeScript 配置
│       ├── biome.json            # 代码规范配置
│       ├── src/                  # TypeScript 源码
│       │   ├── cli/              # CLI 命令
│       │   ├── core/             # 核心功能
│       │   ├── extractors/       # 信息提取器
│       │   ├── notifiers/        # 通知器实现
│       │   └── types/            # 类型定义
│       ├── scripts/              # 构建和测试脚本
│       ├── hooks/                # Claude Code Hook
│       ├── commands/             # 命令定义
│       └── templates/            # 配置模板
├── .claude/                      # Claude 配置
├── CLAUDE.md                     # 本文件
└── README.md                     # 项目说明
```

## 🎨 设计原则

### 1. 专业性 (Professionalism)
每个代理都经过精心设计，具备真实的专业领域知识和实践经验。

### 2. 效率性 (Efficiency)
最小化 token 使用，最大化输出质量，确保快速响应。

### 3. 可靠性 (Reliability)
严格的测试和质量保证，确保每个组件都能稳定工作。

### 4. 可扩展性 (Extensibility)
模块化设计，便于添加新功能和自定义扩展。

### 5. 用户友好 (User-Friendly)
直观的命令设计和清晰的文档，降低学习成本。

## 🔧 开发规范

### 插件开发标准
- **结构一致性**: 所有插件遵循统一的目录结构
- **配置标准化**: 使用 `.claude-plugin.json` 标准配置格式
- **文档完整性**: 每个插件都有详细的 README 和 CHANGELOG
- **质量保证**: 必须通过功能和性能测试

### 代码质量要求
- **清晰性**: 代码结构清晰，易于理解和维护
- **模块化**: 功能解耦，便于复用和测试
- **错误处理**: 完善的错误检测和恢复机制
- **性能优化**: 高效的执行和资源管理
- **类型安全**: TypeScript 项目必须有完整的类型定义

## 🌟 核心优势

1. **深度集成**: 与 Claude Code 无缝集成，提供原生体验
2. **专业品质**: 工业级质量，适合生产环境使用
3. **持续更新**: 定期更新和优化，保持技术领先
4. **完善文档**: 详细的使用说明和故障排除指南
5. **现代技术**: 使用 TypeScript、YAML 等现代技术栈

## 🚀 快速开始

### 安装市场
```bash
# 添加本地市场
/plugin marketplace add /path/to/cc-plugins

# 安装插件
/plugin install serena-indexer
/plugin install webhook-notifier
```

### Serena Indexer 使用
```bash
# 生成配置并初始化索引
/serena-index --generate-config

# 查看索引状态
/serena-status --detailed

# 智能更新索引
/serena-index --smart

# 清理优化
/serena-cleanup --cache-only
```

### Webhook Notifier 使用
```bash
# 初始化配置
/webhook-config --init

# 测试通知
/webhook-test

# 查看日志
/webhook-logs --lines 20
```

## 🤝 贡献指南

我们欢迎社区贡献！贡献新插件时请遵循：

1. 在 `plugins/` 目录下创建新的插件目录
2. 包含必需的 `.claude-plugin.json` 配置文件
3. 提供 `agents/` 和 `commands/` 目录
4. 编写完整的 README 和 CHANGELOG 文档
5. 确保代码质量和测试覆盖

详见 [CONTRIBUTING.md](./CONTRIBUTING.md)（如有）。

## 📄 许可证

本项目采用 MIT 许可证，详见 [LICENSE](./LICENSE) 文件。

---

**让 AI 为开发赋能，让创造变得简单！** ✨