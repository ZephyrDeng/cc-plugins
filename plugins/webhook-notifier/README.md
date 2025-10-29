# Webhook Notifier

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/your-repo/webhook-notifier)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

通用 webhook 通知插件，用于 Claude Code 会话事件通知。在会话结束或特定事件发生时，自动向配置的 webhook 端点发送 HTTP POST 请求，支持飞书、Slack、Discord、钉钉等任何接受 POST 请求的 webhook 服务。

## 特性

- ✨ **自动通知**: 会话结束时自动发送通知，无需手动触发
- 🌐 **通用兼容**: 支持任何接受 POST 请求的 webhook 端点
- 📊 **丰富上下文**: 包含会话信息、项目状态、Git 信息等详细数据
- 🔧 **灵活配置**: 自定义 webhook URL、超时时间、payload 内容
- 📝 **完整日志**: 记录所有通知发送历史，便于审计和调试
- 🧪 **测试工具**: 内置测试命令，快速验证配置正确性

## 目录

- [快速开始](#快速开始)
- [安装](#安装)
- [配置](#配置)
- [使用指南](#使用指南)
- [命令参考](#命令参考)
- [Payload 格式](#payload-格式)
- [集成示例](#集成示例)
- [故障排除](#故障排除)
- [最佳实践](#最佳实践)
- [技术细节](#技术细节)

## 快速开始

### 1. 安装插件

```bash
# 如果还没有添加市场，先添加
/plugin marketplace add /path/to/claude-plugins

# 安装插件
/plugin install webhook-notifier
```

### 2. 配置 Webhook URL

使用配置向导快速设置：

```bash
/webhook-config
```

或手动编辑配置文件 `~/.claude/settings.json`：

```json
{
  "webhook-notifier": {
    "webhook_url": "https://your-webhook-endpoint.com/notify",
    "enabled": true
  }
}
```

### 3. 测试配置

```bash
/webhook-test
```

如果配置正确，你的 webhook 端点将收到一条测试通知消息。

## 安装

### 前置要求

- Claude Code 版本 ≥ 1.0.0
- Bash shell（用于 hook 脚本执行）
- curl 命令行工具（用于发送 HTTP 请求）
- 有效的 webhook URL（飞书、Slack、自建服务等）

### 安装步骤

#### 方法一：通过插件市场（推荐）

```bash
# 添加插件市场（如果未添加）
/plugin marketplace add /path/to/claude-plugins

# 安装插件
/plugin install webhook-notifier

# 验证安装
/plugin list
```

#### 方法二：手动安装

```bash
# 克隆仓库
git clone https://github.com/your-repo/claude-plugins.git

# 复制插件到 Claude Code 插件目录
cp -r claude-plugins/plugins/webhook-notifier ~/.claude/plugins/

# 重启 Claude Code 或重新加载配置
```

## 配置

### 配置文件位置

插件配置位于 `~/.claude/settings.json` 文件的 `webhook-notifier` 部分。

### 完整配置示例

```json
{
  "webhook-notifier": {
    "webhook_url": "https://your-webhook-endpoint.com/notify",
    "enabled": true,
    "timeout": 10,
    "log_level": "info",
    "log_directory": "~/.claude/webhook-notifier/logs",
    "payload_config": {
      "include_session_id": true,
      "include_reason": true,
      "include_transcript_path": true,
      "include_project_info": true,
      "include_git_info": true,
      "custom_fields": {}
    }
  }
}
```

### 配置项说明

#### webhook_url（必需）

要接收通知的 webhook URL。

**示例**：
```json
"webhook_url": "https://your-webhook-endpoint.com/notify"
```

**飞书示例**：
```json
"webhook_url": "https://open.feishu.cn/open-apis/bot/v2/hook/your-token"
```

**Slack 示例**：
```json
"webhook_url": "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

#### enabled（可选）

是否启用插件。设置为 `false` 可以临时禁用通知，无需删除配置。

**默认值**: `true`

#### timeout（可选）

HTTP 请求超时时间（秒）。

**默认值**: `10`
**范围**: 1-60

#### log_level（可选）

日志详细程度。

**可选值**: `debug`, `info`, `warn`, `error`
**默认值**: `info`

#### log_directory（可选）

日志文件存储目录。

**默认值**: `~/.claude/webhook-notifier/logs`

#### payload_config（可选）

控制发送的 payload 内容。

**字段说明**：
- `include_session_id`: 是否包含会话 ID（默认 true）
- `include_reason`: 是否包含结束原因（默认 true）
- `include_transcript_path`: 是否包含会话记录路径（默认 true）
- `include_project_info`: 是否包含项目信息（默认 true）
- `include_git_info`: 是否包含 Git 信息（默认 true）
- `custom_fields`: 自定义额外字段（JSON 对象）

**示例**：
```json
"payload_config": {
  "include_session_id": true,
  "include_reason": true,
  "include_transcript_path": false,
  "include_project_info": true,
  "include_git_info": true,
  "custom_fields": {
    "team": "engineering",
    "environment": "production"
  }
}
```

## 使用指南

### 配置向导

使用交互式配置向导快速设置插件：

```bash
/webhook-config
```

向导会引导你完成：
1. 输入 webhook URL
2. 选择日志级别
3. 设置超时时间
4. 配置 payload 内容
5. 启用/禁用插件
6. 自动测试配置

### 发送测试通知

验证配置是否正确：

```bash
/webhook-test
```

测试通知包含：
- 测试时间戳
- 当前项目信息
- 会话配置摘要

### 查看发送历史

查看最近的通知发送记录：

```bash
# 查看最近 20 条记录
/webhook-logs

# 查看最近 50 条记录
/webhook-logs --limit 50

# 只显示错误
/webhook-logs --errors-only

# 查看特定日期的日志
/webhook-logs --date 2025-01-29
```

### 临时禁用通知

如果需要临时停止发送通知：

```bash
# 方法一：编辑配置文件
# 将 "enabled": true 改为 "enabled": false

# 方法二：使用配置向导
/webhook-config
# 选择禁用选项
```

## 命令参考

### /webhook-config

**功能**: 交互式配置向导

**用法**:
```bash
/webhook-config
```

**操作流程**:
1. 显示当前配置
2. 提供修改选项（webhook URL、日志级别、超时等）
3. 保存配置到 `~/.claude/settings.json`
4. 可选：发送测试通知验证

**适用场景**:
- 首次设置插件
- 更新 webhook URL
- 调整日志和超时配置

---

### /webhook-test

**功能**: 发送测试通知

**用法**:
```bash
/webhook-test
```

**返回信息**:
- ✅ 发送成功：显示响应状态码
- ❌ 发送失败：显示错误详情和建议

**测试 Payload**:
```json
{
  "event": "test",
  "timestamp": "2025-01-29T10:30:00Z",
  "session": {
    "id": "test-session",
    "reason": "manual_test"
  },
  "project": {
    "directory": "/Users/username/project",
    "git_branch": "main"
  },
  "source": "claude-code-webhook-notifier"
}
```

**适用场景**:
- 验证 webhook URL 是否有效
- 测试网络连接
- 确认通知格式正确

---

### /webhook-logs

**功能**: 查看通知发送历史

**用法**:
```bash
/webhook-logs [--limit N] [--errors-only] [--date YYYY-MM-DD]
```

**参数**:
- `--limit N`: 显示最近 N 条记录（默认 20，最大 100）
- `--errors-only`: 只显示失败的请求
- `--date YYYY-MM-DD`: 查看特定日期的日志

**示例**:
```bash
# 查看最近 20 条记录
/webhook-logs

# 查看最近 50 条记录
/webhook-logs --limit 50

# 只显示错误
/webhook-logs --errors-only

# 查看特定日期的日志
/webhook-logs --date 2025-01-29
```

**日志格式**:
```
[2025-01-29 10:30:00] ✅ SUCCESS - Session ended (200 OK)
[2025-01-29 10:45:00] ❌ FAILED - Connection timeout (timeout after 10s)
```

**日志文件位置**:
- 成功日志: `~/.claude/webhook-notifier/logs/YYYY-MM-DD.log`
- 错误日志: `~/.claude/webhook-notifier/logs/errors.log`

## Payload 格式

### 完整 Payload 示例

```json
{
  "event": "session_end",
  "timestamp": "2025-01-29T10:30:45.123Z",
  "session": {
    "id": "f7c8d9e0-a1b2-c3d4-e5f6-789012345678",
    "reason": "user_stop",
    "transcript_path": "/Users/username/.claude/sessions/2025-01-29_session.md"
  },
  "project": {
    "directory": "/Users/username/projects/my-app",
    "git_branch": "feature/webhook-integration",
    "git_repo": "https://github.com/username/my-app.git",
    "git_commit": "a1b2c3d4e5f6789012345678901234567890abcd"
  },
  "source": "claude-code-webhook-notifier"
}
```

### 字段说明

#### event（字符串）

事件类型标识符。

**可能值**:
- `session_end`: 会话正常结束
- `session_error`: 会话因错误中断
- `test`: 测试通知

#### timestamp（ISO 8601 字符串）

事件发生的时间戳，使用 UTC 时区。

**格式**: `YYYY-MM-DDTHH:mm:ss.sssZ`
**示例**: `2025-01-29T10:30:45.123Z`

#### session（对象）

会话相关信息。

**字段**:
- `id` (字符串): 唯一会话标识符（UUID）
- `reason` (字符串): 结束原因
  - `user_stop`: 用户主动结束
  - `completed`: 任务完成
  - `error`: 发生错误
  - `timeout`: 会话超时
- `transcript_path` (字符串|可选): 会话记录文件的绝对路径

#### project（对象）

项目上下文信息。

**字段**:
- `directory` (字符串): 项目根目录绝对路径
- `git_branch` (字符串|null): 当前 Git 分支名称
- `git_repo` (字符串|null): Git 远程仓库 URL
- `git_commit` (字符串|null): 当前 commit 的 SHA-1 哈希值（完整 40 字符）

#### source（字符串）

消息来源标识，固定为 `claude-code-webhook-notifier`。

## 集成示例

### 飞书机器人

#### 1. 创建飞书机器人

1. 在飞书群聊中点击 **设置** > **群机器人** > **添加机器人**
2. 选择 **自定义机器人**（通过 Webhook 接入）
3. 配置机器人名称和描述
4. 复制生成的 Webhook 地址

#### 2. 配置插件

```json
{
  "webhook-notifier": {
    "webhook_url": "https://open.feishu.cn/open-apis/bot/v2/hook/your-token",
    "enabled": true
  }
}
```

#### 3. 测试连接

```bash
/webhook-test
```

#### 4. 自定义消息格式（可选）

飞书接收的 payload 可以通过中间服务转换为飞书消息格式：

```json
{
  "msg_type": "interactive",
  "card": {
    "header": {
      "title": {
        "content": "🤖 Claude Code 会话结束",
        "tag": "plain_text"
      }
    },
    "elements": [
      {
        "tag": "div",
        "text": {
          "content": "会话 ID: {{session.id}}\n项目: {{project.directory}}\n分支: {{project.git_branch}}",
          "tag": "lark_md"
        }
      }
    ]
  }
}
```

---

### Slack 应用

#### 1. 创建 Slack Webhook

1. 访问 [Slack API](https://api.slack.com/apps)
2. 创建新应用或选择已有应用
3. 启用 **Incoming Webhooks**
4. 点击 **Add New Webhook to Workspace**
5. 选择目标频道并授权
6. 复制 Webhook URL

#### 2. 配置插件

```json
{
  "webhook-notifier": {
    "webhook_url": "https://hooks.slack.com/services/YOUR/WEBHOOK/URL",
    "enabled": true
  }
}
```

#### 3. 自定义消息格式（可选）

Slack 接收的 payload 可以转换为 Slack Block Kit 格式：

```json
{
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "🤖 Claude Code Session Ended"
      }
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*Session ID:*\n{{session.id}}"
        },
        {
          "type": "mrkdwn",
          "text": "*Project:*\n{{project.directory}}"
        }
      ]
    }
  ]
}
```

---

### Discord Webhook

#### 1. 创建 Discord Webhook

1. 在 Discord 服务器中，选择频道并点击 **编辑频道**
2. 进入 **整合** > **Webhook**
3. 点击 **新建 Webhook**
4. 自定义名称和头像
5. 复制 Webhook URL

#### 2. 配置插件

```json
{
  "webhook-notifier": {
    "webhook_url": "https://discord.com/api/webhooks/YOUR/WEBHOOK/URL",
    "enabled": true
  }
}
```

#### 3. 自定义消息格式（可选）

Discord 接收的 payload 可以转换为 Discord Embed 格式：

```json
{
  "embeds": [
    {
      "title": "🤖 Claude Code Session Ended",
      "color": 5814783,
      "fields": [
        {
          "name": "Session ID",
          "value": "{{session.id}}",
          "inline": true
        },
        {
          "name": "Project",
          "value": "{{project.directory}}",
          "inline": true
        }
      ],
      "timestamp": "{{timestamp}}"
    }
  ]
}
```

---

### 自建服务

如果你有自己的后端服务，可以直接接收插件的 JSON payload。

#### 示例：Node.js Express 服务

```javascript
const express = require('express');
const app = express();

app.use(express.json());

app.post('/webhook/claude-code', (req, res) => {
  const { event, timestamp, session, project } = req.body;

  console.log(`[${timestamp}] Event: ${event}`);
  console.log(`Session: ${session.id}`);
  console.log(`Project: ${project.directory}`);

  // 处理通知逻辑
  // 例如：存储到数据库、发送邮件、更新仪表板等

  res.status(200).json({ success: true });
});

app.listen(3000, () => {
  console.log('Webhook server listening on port 3000');
});
```

#### 配置插件

```json
{
  "webhook-notifier": {
    "webhook_url": "http://your-server.com:3000/webhook/claude-code",
    "enabled": true
  }
}
```

#### 安全建议

- 使用 HTTPS 加密传输
- 添加身份验证（Token、签名等）
- 实施速率限制
- 记录和监控异常访问

---

### 钉钉机器人

#### 1. 创建钉钉机器人

1. 在钉钉群聊中点击 **群设置** > **智能群助手** > **添加机器人**
2. 选择 **自定义**（通过 Webhook 接入）
3. 配置机器人信息和安全设置
4. 复制 Webhook 地址

#### 2. 配置插件

```json
{
  "webhook-notifier": {
    "webhook_url": "https://oapi.dingtalk.com/robot/send?access_token=YOUR_TOKEN",
    "enabled": true
  }
}
```

## 故障排除

### 问题：未收到通知

**症状**: 会话结束后没有收到任何通知消息。

**诊断步骤**:

1. **检查插件是否启用**
   ```bash
   # 查看配置文件
   cat ~/.claude/settings.json | grep -A 10 webhook-notifier

   # 确认 "enabled": true
   ```

2. **验证 webhook URL**
   ```bash
   /webhook-test
   ```

3. **检查日志文件**
   ```bash
   /webhook-logs --errors-only
   ```

4. **手动测试 webhook**
   ```bash
   curl -X POST "https://your-webhook-url.com" \
     -H "Content-Type: application/json" \
     -d '{"event":"test","timestamp":"2025-01-29T10:00:00Z","source":"claude-code-webhook-notifier"}'
   ```

**常见原因**:
- `enabled` 设置为 `false`
- webhook URL 格式错误或已过期
- 网络连接问题
- 防火墙或代理阻止请求

**解决方案**:
- 使用 `/webhook-config` 重新配置
- 在相应平台重新生成 webhook URL
- 检查网络连接和代理设置

---

### 问题：通知发送失败（超时）

**症状**: 日志显示 "Connection timeout" 或 "timeout after Xs"。

**诊断步骤**:

1. **检查超时设置**
   ```json
   {
     "webhook-notifier": {
       "timeout": 10  // 当前超时时间（秒）
     }
   }
   ```

2. **测试网络延迟**
   ```bash
   # 测试到 webhook 端点的延迟
   curl -o /dev/null -s -w "Time: %{time_total}s\n" \
     "https://your-webhook-url.com"
   ```

3. **查看错误日志**
   ```bash
   tail -f ~/.claude/webhook-notifier/logs/errors.log
   ```

**解决方案**:
- 增加超时时间（例如 20-30 秒）
- 检查网络连接质量
- 使用更稳定的网络环境
- 考虑使用 VPN 或代理

---

### 问题：收到通知但格式不正确

**症状**: 收到通知，但内容显示异常或字段缺失。

**诊断步骤**:

1. **检查 payload 配置**
   ```json
   {
     "webhook-notifier": {
       "payload_config": {
         "include_session_id": true,
         "include_project_info": true
       }
     }
   }
   ```

2. **查看发送的原始 payload**
   ```bash
   # 启用 debug 日志
   # 在 settings.json 中设置:
   "log_level": "debug"

   # 然后查看日志
   tail -f ~/.claude/webhook-notifier/logs/$(date +%Y-%m-%d).log
   ```

3. **验证 webhook 平台支持的格式**
   - 查看飞书/Slack/Discord 的官方文档
   - 确认 payload 格式与平台要求匹配

**解决方案**:
- 使用中间服务转换 payload 格式（见[集成示例](#集成示例)）
- 调整 `payload_config` 配置
- 联系平台技术支持确认格式要求

---

### 问题：日志文件过大

**症状**: `~/.claude/webhook-notifier/logs/` 目录占用大量磁盘空间。

**诊断步骤**:

1. **检查日志文件大小**
   ```bash
   du -sh ~/.claude/webhook-notifier/logs/
   ls -lh ~/.claude/webhook-notifier/logs/
   ```

2. **检查日志级别**
   ```json
   {
     "log_level": "debug"  // debug 会产生大量日志
   }
   ```

**解决方案**:

- **降低日志级别**:
  ```json
  {
    "log_level": "info"  // 或 "warn"
  }
  ```

- **定期清理旧日志**:
  ```bash
  # 删除 30 天前的日志
  find ~/.claude/webhook-notifier/logs/ -name "*.log" -mtime +30 -delete
  ```

- **设置 logrotate（Linux）**:
  ```bash
  # /etc/logrotate.d/webhook-notifier
  /Users/*/.claude/webhook-notifier/logs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
  }
  ```

---

### 问题：Hook 脚本未执行

**症状**: 会话结束但 hook 脚本没有触发通知。

**诊断步骤**:

1. **检查 hook 配置**
   ```bash
   cat ~/.claude/plugins/webhook-notifier/hooks/hooks.json
   ```

2. **验证脚本权限**
   ```bash
   ls -l ~/.claude/plugins/webhook-notifier/hooks/*.sh
   # 应该有执行权限（-rwxr-xr-x）
   ```

3. **手动运行脚本测试**
   ```bash
   bash ~/.claude/plugins/webhook-notifier/hooks/webhook-notify.sh
   ```

4. **检查 Claude Code 日志**
   - 查看 Claude Code 的主日志
   - 搜索 "webhook-notifier" 相关信息

**常见原因**:
- hook 配置文件格式错误
- 脚本没有执行权限
- Claude Code 未正确加载插件

**解决方案**:
```bash
# 重新设置权限
chmod +x ~/.claude/plugins/webhook-notifier/hooks/*.sh

# 重新加载插件
/plugin reload webhook-notifier

# 或重启 Claude Code
```

## 最佳实践

### 1. 安全性

**保护 Webhook URL**

Webhook URL 包含敏感的认证令牌，应当妥善保管：

- ✅ **使用环境变量**（生产环境）:
  ```bash
  export WEBHOOK_URL="https://your-webhook-url.com"
  # 在配置中引用: "${WEBHOOK_URL}"
  ```

- ✅ **限制文件权限**:
  ```bash
  chmod 600 ~/.claude/settings.json
  ```

- ✅ **不要提交到版本控制**:
  ```gitignore
  # .gitignore
  .claude/settings.json
  ```

- ❌ **避免在日志中记录完整 URL**:
  插件会自动脱敏 URL，仅显示前缀和后缀。

**定期轮换 Webhook**

建议每 3-6 个月重新生成 webhook URL：

1. 在飞书/Slack 中重新创建机器人
2. 更新配置文件中的 URL
3. 使用 `/webhook-test` 验证新 URL
4. 删除旧的机器人

---

### 2. 性能优化

**控制通知频率**

如果你的工作流会产生大量会话：

- **批量会话**: 考虑只在重要会话结束时发送通知
- **调整 hook 触发条件**: 修改 `hooks.json` 中的事件过滤规则
- **使用异步发送**: 插件默认异步发送，不会阻塞会话结束

**优化超时设置**

根据网络环境调整超时时间：

- **快速网络**: 5-10 秒
- **一般网络**: 10-15 秒
- **慢速/不稳定网络**: 20-30 秒

---

### 3. 日志管理

**日志级别选择**

根据使用场景选择合适的日志级别：

| 级别 | 适用场景 | 日志量 |
|------|---------|--------|
| `debug` | 开发调试、问题排查 | 大 |
| `info` | 正常使用（推荐） | 中 |
| `warn` | 只记录警告和错误 | 小 |
| `error` | 只记录错误 | 最小 |

**自动化日志清理**

设置定时任务自动清理旧日志：

```bash
# macOS (添加到 crontab)
crontab -e

# 每周日凌晨 2 点清理 30 天前的日志
0 2 * * 0 find ~/.claude/webhook-notifier/logs/ -name "*.log" -mtime +30 -delete
```

---

### 4. 多环境配置

**开发环境 vs 生产环境**

使用不同的 webhook URL 区分环境：

```json
{
  "webhook-notifier": {
    "webhook_url": "https://dev-webhook.com",
    "enabled": true,
    "custom_fields": {
      "environment": "development"
    }
  }
}
```

**按项目自定义**

在项目的 `.claude/settings.json` 中覆盖全局配置：

```json
{
  "webhook-notifier": {
    "webhook_url": "https://project-specific-webhook.com",
    "log_level": "debug",
    "custom_fields": {
      "project": "my-app",
      "team": "engineering"
    }
  }
}
```

---

### 5. 团队协作

**统一配置模板**

为团队创建标准配置模板：

```json
{
  "webhook-notifier": {
    "webhook_url": "https://team-webhook.com",
    "enabled": true,
    "timeout": 15,
    "log_level": "info",
    "custom_fields": {
      "team": "engineering",
      "project": "shared"
    }
  }
}
```

**文档化内部流程**

在团队文档中记录：
- Webhook URL 的获取方式
- 日志查看和排查流程
- 通知格式和含义
- 应急联系方式

---

### 6. 监控和告警

**设置关键指标**

监控以下指标：
- 通知发送成功率（目标 >99%）
- 平均发送延迟（目标 <2 秒）
- 错误率趋势

**告警规则**

考虑设置以下告警：
- 连续 3 次发送失败
- 单日错误率 >10%
- 发送延迟 >10 秒

**定期审查**

每月检查：
- 错误日志中的常见问题
- 是否有 webhook URL 需要更新
- 配置是否需要优化

## 技术细节

### 架构设计

```
┌─────────────────┐
│  Claude Code    │
│    Session      │
└────────┬────────┘
         │ Stop/SessionEnd Event
         ↓
┌─────────────────┐
│  Hook System    │
│  hooks.json     │
└────────┬────────┘
         │ Trigger
         ↓
┌─────────────────────────┐
│  webhook-notify.sh      │
│  - Read config          │
│  - Build payload        │
│  - Send HTTP POST       │
└────────┬────────────────┘
         │ HTTP POST
         ↓
┌──────────────────────────────┐
│  Your Webhook Endpoint       │
│  - 飞书 Bot                   │
│  - Slack App                 │
│  - Discord Webhook           │
│  - 自建服务                   │
│  - 其他 HTTP 端点             │
└──────────────────────────────┘
```

### Hook 事件

插件监听以下 Claude Code 事件：

#### Stop 事件

**触发时机**: 主代理完成响应，准备结束会话

**用途**:
- 在会话完全结束前发送通知
- 收集会话摘要信息
- 记录会话统计数据

#### SessionEnd 事件

**触发时机**: 会话正式结束

**用途**:
- 发送最终通知
- 更新会话状态
- 清理临时资源

### HTTP 请求详情

**请求方法**: POST

**Content-Type**: application/json

**请求头**:
```
Content-Type: application/json
User-Agent: webhook-notifier/1.0.0
```

**请求体**: JSON payload（见 [Payload 格式](#payload-格式)）

**超时处理**:
- 连接超时: `timeout` 配置值的 1/3
- 读取超时: `timeout` 配置值的 2/3
- 总超时: `timeout` 配置值

**重试策略**:
- 不进行自动重试（避免重复通知）
- 记录失败到错误日志
- 建议手动排查和重新发送

### 错误处理

插件使用分层错误处理策略：

**级别 1: 配置错误**
- webhook URL 缺失或格式错误
- 配置文件解析失败
- 行为: 记录错误，禁用插件，通知用户

**级别 2: 网络错误**
- 连接超时
- DNS 解析失败
- 行为: 记录错误，保留 payload 供排查

**级别 3: 服务端错误**
- 4xx 客户端错误（配置问题）
- 5xx 服务端错误（临时故障）
- 行为: 记录详细错误信息和响应体

**错误日志格式**:
```
[2025-01-29 10:30:00] ERROR: Failed to send webhook
  URL: https://your-webhook-endpoint.com/notify
  Status: 500 Internal Server Error
  Response: {"error":"internal server error"}
  Payload: {"event":"session_end",...}
```

### 日志系统

**日志文件结构**:
```
~/.claude/webhook-notifier/logs/
├── 2025-01-29.log          # 当日所有日志
├── 2025-01-28.log          # 按日期分文件
├── errors.log              # 所有错误的汇总
└── debug.log               # debug 级别日志（仅在 log_level=debug 时）
```

**日志格式**:
```
[YYYY-MM-DD HH:mm:ss] LEVEL: Message
  Context: Additional information
  Details: Structured data
```

**日志轮转**:
- 按日期自动创建新文件
- 不自动删除旧文件（需手动清理或使用 logrotate）
- 错误日志单独存储便于快速排查

### 性能特性

**异步发送**:
- 使用后台进程发送通知
- 不阻塞会话结束流程
- 发送延迟 <100ms

**内存占用**:
- 脚本执行: ~2-5 MB
- 日志文件: 取决于日志级别和频率
  - info 级别: ~100KB/天
  - debug 级别: ~1MB/天

**网络带宽**:
- 单次 payload: ~1-2 KB
- 平均每会话: ~3-5 KB（含 HTTP 开销）

### 扩展性

**自定义字段**

通过 `custom_fields` 添加业务相关的自定义信息：

```json
{
  "webhook-notifier": {
    "payload_config": {
      "custom_fields": {
        "team": "engineering",
        "environment": "production",
        "priority": "high"
      }
    }
  }
}
```

**Hook 脚本定制**

可以修改 `webhook-notify.sh` 实现自定义逻辑：

```bash
# 添加自定义字段
additional_info=$(get_custom_info)
payload=$(jq -n \
  --arg event "session_end" \
  --arg custom "$additional_info" \
  '{event: $event, custom_field: $custom}')
```

**中间服务转换**

如果目标 webhook 服务需要特定的格式，可以实现中间服务进行 payload 转换：

```
Claude Code → 中间服务 → 目标 Webhook
                ↓
          格式转换、路由、过滤等
```

## 贡献

我们欢迎社区贡献！如果你有改进建议或发现问题：

1. 查看现有 [Issues](https://github.com/your-repo/webhook-notifier/issues)
2. 创建新的 Issue 描述问题或建议
3. 提交 Pull Request（请遵循代码规范）

### 开发环境设置

```bash
# 克隆仓库
git clone https://github.com/your-repo/webhook-notifier.git
cd webhook-notifier

# 安装到本地进行测试
cp -r . ~/.claude/plugins/webhook-notifier/

# 运行测试
bash test/test_webhook.sh
```

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 变更日志

查看 [CHANGELOG.md](CHANGELOG.md) 了解版本历史和更新内容。

## 支持

如果遇到问题或需要帮助：

- 📖 查看本文档的 [故障排除](#故障排除) 部分
- 🐛 提交 [Issue](https://github.com/your-repo/webhook-notifier/issues)
- 💬 加入讨论组或社区频道
- 📧 联系维护者: your-email@example.com

---

**让 AI 开发更高效，让团队协作更透明！** ✨
