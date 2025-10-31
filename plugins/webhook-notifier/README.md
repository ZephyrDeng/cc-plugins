# Webhook Notifier 2.0

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/your-repo/webhook-notifier)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.3-blue)](https://www.typescriptlang.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

现代化的 Claude Code 通知系统，使用 TypeScript 重写，支持 Webhook 和 macOS 原生通知。

## ✨ 特性

- 🚀 **现代 TypeScript**: 完全使用 TypeScript 5.3+ 重写，类型安全
- 🔄 **双模式运行**: Hook 模式（自动）+ CLI 模式（手动）
- 📝 **YAML 配置**: 人性化的 YAML 配置，支持环境变量
- 🎯 **智能通知**:
  - Notification 事件：Claude 等待输入时通知
  - Session End 事件：会话结束时通知
- 🌐 **多种通知器**:
  - Webhook：支持任何 HTTP endpoint（飞书、Slack、Discord等）
  - macOS：原生系统通知（可交互）
- 🛠️ **强大 CLI**:
  - `webhook test` - 测试通知配置
  - `webhook config` - 配置管理（显示/初始化/验证）
  - `webhook logs` - 查看通知日志
- 📊 **完整日志**: 结构化 JSON 日志，支持按日期轮转
- 🔧 **高度可配置**: 细粒度控制每个通知器和事件
- ⚡ **重试机制**: Webhook 支持可配置的重试策略
- 🛡️ **类型安全**: Zod schema 运行时验证，确保配置正确

## 🎯 重写亮点

### 从 1.x 到 2.0 的改进

**技术栈升级**:
- ✅ Bash → TypeScript 5.3+
- ✅ 无类型 → 完整类型系统
- ✅ JSON → YAML 配置
- ✅ 单一通知器 → 多通知器架构

**新增功能**:
- ✅ CLI 工具集成
- ✅ macOS 原生通知支持
- ✅ 上下文智能提取
- ✅ 消息类型识别
- ✅ 配置验证和管理
- ✅ 结构化日志系统

## 📦 快速开始

### 安装

```bash
# 通过插件市场安装（推荐）
/plugin marketplace add /path/to/cc-plugins
/plugin install webhook-notifier

# 或手动克隆（预构建版本，无需编译）
git clone https://github.com/your-repo/webhook-notifier.git
cd webhook-notifier
# 插件已预构建，可直接使用！
```

### 初始化配置

```bash
# 创建配置文件
node dist/index.js config --init

# 这将在当前目录创建 .webhookrc.yaml
```

### 配置示例

```yaml
# .webhookrc.yaml
logging:
  level: info
  directory: ./logs
  format: json
  rotation: daily

events:
  notification:
    enabled: true
    extract_context: true
    context_length: 200
  session_end:
    enabled: true

notifiers:
  webhook:
    enabled: true
    url: https://your-webhook-endpoint.com/notify
    timeout: 10
    retry:
      max_attempts: 3
      backoff: exponential

  macos:
    enabled: true
    title: Claude Code
    sound: default
    actions:
      - label: Open Project
        action: open_project
```

### 测试配置

```bash
# 测试所有通知器
node dist/index.js test

# 测试特定通知器
node dist/index.js test --notifier webhook
node dist/index.js test --notifier macos
```

## 🔧 CLI 命令

### `webhook test`

测试通知配置，发送测试通知到所有启用的通知器。

```bash
# 测试所有通知器
webhook test

# 测试特定通知器
webhook test --notifier webhook
webhook test --notifier macos
webhook test --notifier all
```

### `webhook config`

管理配置文件。

```bash
# 显示当前配置
webhook config --show

# 初始化配置文件
webhook config --init

# 验证配置有效性
webhook config --validate
```

### `webhook logs`

查看通知日志。

```bash
# 查看最近 20 条日志
webhook logs

# 查看最近 50 条日志
webhook logs --lines 50

# 过滤特定级别
webhook logs --level error

# 实时跟踪（开发中）
webhook logs --follow
```

## 📝 配置详解

### 配置文件位置

配置文件搜索顺序：
1. `./webhookrc.yaml` （项目根目录）
2. `./.webhookrc.yaml` （项目根目录，隐藏文件）
3. `~/.claude/.webhookrc.yaml` （用户目录）

### 完整配置结构

```yaml
# 日志配置
logging:
  level: info          # debug | info | warn | error
  directory: ./logs    # 日志目录，支持 ~ 展开
  format: json         # json | text
  rotation: daily      # daily | none

# 事件配置
events:
  notification:
    enabled: true               # 是否启用 Notification 事件
    extract_context: true       # 是否提取对话上下文
    context_length: 200         # 上下文最大字符数

  session_end:
    enabled: true               # 是否启用 Session End 事件

# 通知器配置
notifiers:
  # Webhook 通知器
  webhook:
    enabled: true
    url: https://your-endpoint.com/notify
    timeout: 10                 # 超时时间（秒）
    headers:                     # 自定义请求头
      Authorization: Bearer ${TOKEN}
      X-Custom-Header: value
    retry:
      max_attempts: 3           # 最大重试次数
      backoff: exponential      # exponential | linear | none

  # macOS 通知器
  macos:
    enabled: true
    title: Claude Code          # 通知标题
    subtitle: Session Update    # 通知副标题（可选）
    sound: default              # 通知声音：default | none | Ping | ...
    actions:                     # 通知操作按钮
      - label: Open Project
        action: open_project
      - label: View Logs
        action: view_logs
    templates:                   # 消息模板
      notification: "Claude is waiting for input"
      session_end: "Session ended: {{reason}}"
```

### 环境变量支持

配置文件支持 `${VAR}` 格式的环境变量：

```yaml
notifiers:
  webhook:
    url: ${WEBHOOK_URL}
    headers:
      Authorization: Bearer ${API_TOKEN}
```

## 📊 通知 Payload

### Notification 事件（带上下文）

```json
{
  "event": "notification",
  "notification_type": "waiting_for_input",
  "message": "Claude is waiting for your input",
  "context": {
    "last_message": "我建议使用 React。您同意吗？",
    "message_type": "confirmation"
  },
  "timestamp": "2025-10-30T10:30:00.000Z",
  "session": {
    "id": "abc123-def456-789"
  },
  "project": {
    "directory": "/path/to/project",
    "git_branch": "main",
    "git_commit": "a1b2c3d4..."
  }
}
```

### Session End 事件

```json
{
  "event": "session_end",
  "reason": "user_stop",
  "timestamp": "2025-10-30T10:35:00.000Z",
  "session": {
    "id": "abc123-def456-789",
    "transcript_path": "/path/to/transcript.jsonl"
  },
  "project": {
    "directory": "/path/to/project",
    "git_branch": "main",
    "git_commit": "a1b2c3d4..."
  }
}
```

## 🔌 集成示例

### 飞书 Webhook

```yaml
notifiers:
  webhook:
    enabled: true
    url: https://open.feishu.cn/open-apis/bot/v2/hook/your-token
    timeout: 10
```

### Slack Webhook

```yaml
notifiers:
  webhook:
    enabled: true
    url: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
    timeout: 10
```

### Discord Webhook

```yaml
notifiers:
  webhook:
    enabled: true
    url: https://discord.com/api/webhooks/YOUR/WEBHOOK/URL
    timeout: 10
```

### macOS 通知（带操作）

```yaml
notifiers:
  macos:
    enabled: true
    title: Claude Code
    sound: Ping
    actions:
      - label: Open Terminal
        action: open_terminal
      - label: Copy Session ID
        action: copy_session_id
```

## 🛠️ 开发

### 构建

```bash
# 开发模式（带 watch）
npm run dev

# 生产构建
npm run build

# 类型检查
npm run typecheck

# 代码检查
npm run lint

# 格式化代码
npm run format
```

### 测试

```bash
# 运行所有测试
npm test

# 或直接运行测试脚本
./scripts/test-all.sh
```

### 项目结构

```
webhook-notifier/
├── src/
│   ├── cli/              # CLI 命令实现
│   │   ├── test.ts       # test 命令
│   │   ├── config.ts     # config 命令
│   │   └── logs.ts       # logs 命令
│   ├── core/             # 核心功能
│   │   ├── config.ts     # 配置管理
│   │   ├── logger.ts     # 日志系统
│   │   └── hook-handler.ts  # Hook 处理器
│   ├── extractors/       # 信息提取器
│   │   ├── context.ts    # 上下文提取
│   │   └── git.ts        # Git 信息提取
│   ├── notifiers/        # 通知器实现
│   │   ├── base.ts       # 抽象基类
│   │   ├── webhook.ts    # Webhook 通知器
│   │   └── macos.ts      # macOS 通知器
│   ├── types/            # 类型定义
│   │   ├── config.ts     # 配置 Schema
│   │   ├── hook-events.ts # Hook 事件类型
│   │   └── payload.ts    # Payload 类型
│   ├── hook.ts           # Hook 模式入口
│   └── index.ts          # 主入口
├── scripts/
│   ├── build.js          # 构建脚本
│   └── test-all.sh       # 测试脚本
├── hooks/                # Claude Code Hook 配置
│   ├── hooks.json        # Hook 配置
│   └── webhook-notify.sh # Shell wrapper
├── scripts/bin/          # 预构建可执行文件 ⭐
│   ├── index.js          # 主入口（已构建）
│   └── index.js.map      # Source map
├── logs/                 # 日志文件
└── package.json
```

## 🐛 故障排除

### CLI 命令不可用

```bash
# 插件已预构建，无需执行 npm install/build
# 直接检查可执行文件
ls -l scripts/bin/index.js

# 如需重新构建（开发者）
npm install
npm run build
```

### 配置验证失败

```bash
# 验证配置
webhook config --validate

# 查看详细错误信息
# 错误信息会列出所有配置问题
```

### 通知未发送

```bash
# 1. 检查事件是否启用
webhook config --show

# 2. 测试通知器
webhook test

# 3. 查看日志
webhook logs --level error

# 4. 检查 Hook 配置
cat hooks/hooks.json
```

### macOS 通知不显示

```bash
# 1. 检查系统通知权限
# 系统设置 → 通知 → 确保终端/Node.js 有通知权限

# 2. 测试 macOS 通知
webhook test --notifier macos

# 3. 检查配置
webhook config --show | grep -A 10 macos
```

## 📝 更新日志

查看 [CHANGELOG.md](CHANGELOG.md) 了解详细更新历史。

### v2.0.0 (2025-10-30)

**重大更新**:
- ✨ 完全使用 TypeScript 重写
- ✨ 新增 CLI 工具集
- ✨ 新增 macOS 原生通知支持
- ✨ YAML 配置系统
- ✨ 结构化日志系统
- ✨ 智能上下文提取
- ✨ 消息类型识别
- ✨ 配置验证和管理

**Breaking Changes**:
- 配置格式从 JSON 改为 YAML
- Webhook URL 配置路径变更
- Hook 脚本接口变更

**迁移指南**: 参见 [MIGRATION.md](MIGRATION.md)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 开发指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 代码规范

- 使用 TypeScript
- 遵循 Biome 代码风格
- 添加适当的类型注解
- 编写清晰的注释

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

- [node-notifier](https://github.com/mikaelbr/node-notifier) - macOS 通知支持
- [Commander.js](https://github.com/tj/commander.js) - CLI 框架
- [Zod](https://github.com/colinhacks/zod) - Schema 验证

---

**让 AI 开发更高效！** ✨
