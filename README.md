# Claude Code Plugins - 专业化插件集合

一个符合 wshobson/agents 标准的 Claude Code 插件仓库，专注于提供高质量的专业化开发工具。

## 🏗️ 项目结构

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json          # 市场配置文件
├── plugins/                       # 插件目录
│   └── serena-indexer/           # Serena 索引管理插件
│       ├── .claude-plugin.json   # 插件配置
│       ├── README.md             # 插件文档
│       ├── CHANGELOG.md          # 更新日志
│       ├── agents/               # AI 代理
│       │   ├── serena-indexer.md
│       │   └── serena-monitor.md
│       ├── commands/             # 用户命令
│       │   ├── serena-index.md
│       │   ├── serena-status.md
│       │   └── serena-cleanup.md
│       ├── hooks/                # 自动化钩子
│       │   ├── hooks.json
│       │   └── serena-auto-index.sh
│       ├── mcp.json              # MCP 配置
│       └── templates/            # 配置模板
│           └── settings.json
├── .claude/                      # Claude 配置
├── CLAUDE.md                     # 项目说明
└── README.md                     # 本文件
```

## 📦 可用插件

本市场目前包含以下插件。更多详细信息，请参阅各插件目录内的 `README.md` 文件。

- **`serena-indexer`**: 一个专业的 Serena 索引管理插件，提供异步索引、智能更新和健康监控等功能。

## 💿 安装和使用

### 1. 添加市场

```bash
/plugin marketplace add ZephyrDeng/cc-plugins
```

### 2. 安装插件

```bash
/plugin install serena-indexer
```

### 3. 使用插件

插件安装后，可使用 `/help serena-indexer` 查看该插件的详细命令和用法。

```bash
# 例如，初始化索引
/serena-index --generate-config
```

## 🔧 开发标准

本项目严格遵循 wshobson/agents 仓库的标准：

- ✅ 标准化的目录结构
- ✅ 完整的插件配置文件
- ✅ 专业的 AI 代理定义
- ✅ 规范的命令格式
- ✅ 完善的文档体系

## 🤝 贡献

欢迎提交新的插件！请确保遵循项目的标准结构：

1. 在 `plugins/` 目录下创建新的插件目录
2. 包含必需的 `.claude-plugin.json` 配置文件
3. 提供 `agents/` 和 `commands/` 目录
4. 编写完整的 README 文档

## 📄 许可证

MIT License