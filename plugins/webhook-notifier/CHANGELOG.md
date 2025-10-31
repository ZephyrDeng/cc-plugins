# Changelog

All notable changes to the webhook-notifier plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-10-31

### 🎉 重大更新 - TypeScript 完全重写

#### Added
- ✨ **TypeScript 5.3+ 重写**: 完整类型系统，工业级代码质量
- 🔔 **macOS 原生通知**: 系统级通知支持，可交互操作按钮
- 🛠️ **强大 CLI 工具**:
  - `webhook test` - 测试通知配置
  - `webhook config` - 配置管理（显示/初始化/验证）
  - `webhook logs` - 查看通知日志
- 📝 **YAML 配置系统**: 人性化配置格式，支持环境变量
- 🔧 **多通知器架构**: 可同时启用 Webhook + macOS 通知
- ⚡ **重试机制**: Webhook 支持可配置的重试策略
- 🛡️ **Zod Schema 验证**: 运行时配置验证，确保正确性
- 📊 **结构化日志**: JSON 格式日志，支持按日期轮转
- 🎨 **消息模板系统**: 自定义通知标题、副标题和消息格式

#### Changed
- 🏗️ **构建策略优化**: 预构建分发，用户安装即用（scripts/bin/）
- 📦 **配置格式**: JSON → YAML，更易读易维护
- 🔄 **双模式运行**: Hook 模式（自动触发）+ CLI 模式（手动测试）
- 📂 **项目结构**: 模块化 TypeScript 架构，清晰分层

#### Breaking Changes
- ⚠️ 配置格式从 JSON 改为 YAML（.webhookrc.yaml）
- ⚠️ Webhook URL 配置路径变更
- ⚠️ Hook 脚本接口变更（现在调用 TypeScript 编译后的可执行文件）
- ⚠️ 构建产物从 dist/ 移至 scripts/bin/（预构建分发）

#### Migration Notes
- 旧版 1.x 用户需要重新创建配置文件
- 使用 `webhook config --init` 生成新配置
- 参考 README 中的配置示例进行迁移

## [1.2.0] - 2025-01-30

### Added
- 🎯 **智能上下文提取**: Notification 事件现在包含 Claude 最后一条消息和问题类型识别
- 🔍 **消息类型识别**: 自动识别 question（问题）、confirmation（确认）、choice（选择）、info（信息）四种类型
- ⚙️ **新增配置选项**:
  - `include_notification_context`: 控制是否包含上下文信息（默认 true）
  - `notification_context_length`: 上下文消息最大字符数（默认 200）
- 🛡️ **智能降级机制**: transcript 文件不可读或提取失败时自动降级为基本通知
- 📖 **详细文档**: README 中完整说明了上下文功能的使用和配置方法

### Changed
- 📦 **Payload 增强**: notification 事件 payload 新增可选的 `context` 字段
- 📊 **配置模板更新**: 添加了上下文相关的配置项和示例

### Technical Details
- 新增 `extract_last_message()` 函数实现 transcript 解析和消息类型识别
- 支持有/无 jq 工具的双路径实现，确保兼容性
- 读取最后 30 行 transcript 以提高性能
- 使用正则表达式进行中英文问题类型识别
- context 字段仅在成功提取时包含，保持 payload 灵活性

### Benefits
- 📱 **无需打开应用**: 在通知中直接看到 Claude 在等什么
- 💡 **更快决策**: 了解上下文后可以更快做出响应
- 🎚️ **灵活控制**: 可根据需要启用或禁用上下文功能
- 🔒 **可靠性保证**: 降级机制确保通知始终能够发送

### Performance
- 平均额外开销: 20-60ms（包含文件读取和文本处理）
- 内存占用: 可忽略不计（只读取最后 30 行）
- 兼容性: ✅ 完全向后兼容，新字段为可选

## [1.1.0] - 2025-01-30

### Added
- ⏰ **Notification Hook 支持**: 新增 Notification 事件监听,当 Claude 等待用户输入时自动发送通知
- 🔔 **实时提醒功能**: 在以下场景立即通知用户:
  - Claude 等待您确认方案时
  - Claude 等待您选择选项时
  - Claude 等待您输入时(输入框空闲 60 秒)
  - Claude 需要您授权使用工具时
- ⚙️ **新增配置选项**: `enable_notification_hook` 控制是否启用 Notification 通知
- 📊 **新增 Payload 格式**: notification 事件专用 payload 格式,包含 `notification_type` 和 `message` 字段
- 📝 **完善文档**: README 中详细说明 Notification 功能的使用场景和配置方法

### Changed
- 🔄 **脚本增强**: webhook-notify.sh 支持多事件类型处理,根据事件动态构建 payload
- 📋 **配置模板更新**: 添加 `enable_notification_hook` 配置项示例
- 📖 **Hooks 描述更新**: 支持 Notification, Stop, SessionEnd 三种事件类型

### Technical Details
- notification 事件使用 `build_notification_payload()` 函数构建专用 payload
- session_end 事件使用 `build_session_end_payload()` 函数(原 `build_payload`)
- 事件类型检测和配置检查逻辑优化,支持选择性启用不同类型通知

### Benefits
- 🎯 **更及时的响应**: 不再需要等到会话结束才知道 Claude 在等待输入
- 💪 **提高效率**: 及时返回处理 Claude 的等待,避免时间浪费
- 🎛️ **灵活控制**: 可根据需要启用或禁用 Notification 通知,避免通知过于频繁

## [1.0.0] - 2025-01-29

### Added
- 🎉 Initial release of webhook-notifier plugin
- ✅ Automatic webhook notifications on Claude Code session end
- 🔗 Simple webhook integration with configurable endpoint
- 🎯 Stop and SessionEnd hook triggers
- 🧪 `/webhook-test` command for testing webhook configuration
- ⚙️ `/webhook-config` command for interactive configuration
- 📝 `/webhook-logs` command for viewing notification history
- 📊 Comprehensive payload including session info, project details, and git metadata
- 🔍 Debug mode with detailed payload logging
- ⏱️ Configurable timeout and retry settings
- 📁 Structured logging with daily rotation (YYYY-MM-DD.log format)
- ❌ Dedicated error logging (errors.log)
- 🌐 Template-based webhook service integration
- 📦 Complete plugin structure with hooks, commands, and scripts

### Features

#### Core Functionality
- Automatic webhook notification on session completion
- No-retry strategy to avoid blocking session end
- Full session context capture (ID, reason, transcript path)
- Project information extraction (directory, git branch, repo, commit)

#### Commands
- **Test Command**: Send test notifications with sample payload
- **Config Command**: Documentation and configuration guide
- **Logs Command**: View notification history and error logs

#### Configuration
- Simple webhook URL configuration
- Configurable timeout (default: 10 seconds)
- Log level control (info/debug)
- Flexible payload customization

#### Developer Experience
- Clear installation instructions
- Comprehensive documentation
- Easy local testing workflow
- Detailed error messages and logging

### Technical Details

#### Architecture
- Shell-based implementation for maximum compatibility
- JSON configuration via ~/.claude/settings.json
- Hook-based event system (Stop, SessionEnd)
- Modular script organization (hooks, commands, scripts)

#### Dependencies
- curl - HTTP client for webhook requests
- jq - JSON processing (optional, falls back to python3)
- git - Project metadata extraction

#### File Structure
```
webhook-notifier/
├── .claude-plugin.json          # Plugin metadata
├── README.md                     # Documentation
├── CHANGELOG.md                  # Version history
├── commands/                     # User commands
│   ├── webhook-test.md
│   ├── webhook-config.md
│   └── webhook-logs.md
├── hooks/                        # Hook configuration
│   ├── hooks.json
│   └── webhook-notify.sh
├── templates/                    # Configuration templates
│   └── settings.json
└── scripts/                      # Utility scripts
    └── test-webhook.sh
```

### Configuration Schema

```json
{
  "webhook-notifier": {
    "webhook_url": "string (your webhook endpoint URL)",
    "enabled": "boolean (default: true)",
    "timeout": "number (default: 10)",
    "log_level": "string (info|debug, default: info)",
    "log_directory": "string (default: ~/.claude/webhook-notifier/logs)",
    "payload_config": {
      "include_session_id": "boolean (default: true)",
      "include_reason": "boolean (default: true)",
      "include_transcript_path": "boolean (default: true)",
      "include_project_info": "boolean (default: true)",
      "include_git_info": "boolean (default: true)",
      "custom_fields": "object (default: {})"
    }
  }
}
```

### Payload Format

```json
{
  "event": "session_end",
  "timestamp": "2025-01-29T12:34:56Z",
  "session": {
    "id": "abc123",
    "reason": "clear|logout|exit|other",
    "transcript_path": "/path/to/transcript.jsonl"
  },
  "project": {
    "directory": "/path/to/project",
    "git_branch": "main",
    "git_repo": "https://github.com/org/repo.git",
    "git_commit": "abc123"
  },
  "source": "claude-code-webhook-notifier"
}
```

### Known Limitations
- No authentication mechanism (relies on webhook URL security)
- No built-in retry on failure (by design)
- Requires curl for HTTP requests
- URL encoding is basic (may need enhancement for complex URLs)

### Security Considerations
- Webhook URLs should use HTTPS for production
- No sensitive credentials stored in configuration
- Logs may contain session and project information
- Regular log cleanup recommended

---

## [Unreleased]

### Planned Features
- Authentication support (Bearer tokens, API keys)
- Configurable retry strategies
- Webhook signature verification
- Custom payload templates
- Interactive configuration wizard
- Notification filtering options
- Statistical dashboard
- Webhook health monitoring

---

## Versioning Notes

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality
- **PATCH** version for backwards-compatible bug fixes

[1.2.0]: https://github.com/ZephyrDeng/cc-plugins/releases/tag/webhook-notifier-v1.2.0
[1.1.0]: https://github.com/ZephyrDeng/cc-plugins/releases/tag/webhook-notifier-v1.1.0
[1.0.0]: https://github.com/ZephyrDeng/cc-plugins/releases/tag/webhook-notifier-v1.0.0
[Unreleased]: https://github.com/ZephyrDeng/cc-plugins/compare/webhook-notifier-v1.2.0...HEAD
