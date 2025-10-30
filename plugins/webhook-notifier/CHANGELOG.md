# Changelog

All notable changes to the webhook-notifier plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.1.0]: https://github.com/ZephyrDeng/cc-plugins/releases/tag/webhook-notifier-v1.1.0
[1.0.0]: https://github.com/ZephyrDeng/cc-plugins/releases/tag/webhook-notifier-v1.0.0
[Unreleased]: https://github.com/ZephyrDeng/cc-plugins/compare/webhook-notifier-v1.1.0...HEAD
