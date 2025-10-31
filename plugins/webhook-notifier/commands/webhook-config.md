# /webhook-config - 配置 Webhook 通知

配置和管理 webhook-notifier 插件，支持 macOS 原生通知和 Webhook 通知。

## 🚀 首次使用

**重要**：此插件首次使用需要安装依赖（仅需一次）

如果看到依赖缺失提示，请执行：
```bash
cd ${CLAUDE_PLUGIN_ROOT}
npm install
```

安装完成后即可使用所有功能。

## 功能说明

此命令支持配置通知系统的所有选项：
- 查看和验证当前配置
- 初始化默认配置文件
- 管理 Webhook 和 macOS 通知设置

配置文件：`${CLAUDE_PLUGIN_ROOT}/.webhookrc.yaml`（YAML 格式）
日志目录：`~/.claude/webhook-notifier/logs`

## 命令选项

### 配置管理
- `--show` - 显示当前配置（包括配置文件路径和所有设置）
- `--init` - 初始化默认配置文件（创建 .webhookrc.yaml）
- `--validate` - 验证配置文件有效性

## 配置文件说明

插件使用 YAML 格式配置文件，支持以下位置：
1. `${CLAUDE_PLUGIN_ROOT}/.webhookrc.yaml`（推荐）
2. `~/webhookrc.yaml`
3. `~/.claude/webhook-notifier/config.yaml`

## 使用示例

### 查看当前配置
```bash
/webhook-config --show
```

### 初始化配置文件
```bash
/webhook-config --init
```

### 验证配置有效性
```bash
/webhook-config --validate
```

### 手动编辑配置
配置文件位于 `${CLAUDE_PLUGIN_ROOT}/.webhookrc.yaml`，可以直接编辑：

```yaml
# 日志配置
logging:
  level: info                # debug | info | warn | error
  directory: ~/.claude/webhook-notifier/logs
  format: json               # json | text
  rotation: daily            # daily | size

# 事件配置
events:
  notification:
    enabled: true            # 启用 Notification 事件（Claude 等待输入时）
    extract_context: true    # 提取对话上下文
    context_length: 200      # 上下文最大长度
  session_end:
    enabled: true            # 启用 Session End 事件（会话结束时）

# 通知器配置
notifiers:
  # Webhook 通知器
  webhook:
    enabled: false           # 是否启用 Webhook
    url: https://your-webhook.com/notify  # Webhook URL（启用时必需）
    timeout: 10              # 超时时间（秒）

  # macOS 原生通知
  macos:
    enabled: true            # 启用 macOS 通知
    title: Claude Code       # 通知标题
    sound: default           # 通知声音：default | Ping | Glass | Hero
    actions:                 # 点击通知时的操作
      - label: Open Terminal
        command: open -a Terminal
    templates:               # 通知模板
      notification:
        title: "{{title}}"
        subtitle: "等待输入"
        message: "{{last_message}}"
      session_end:
        title: "{{title}}"
        subtitle: "会话结束"
        message: "原因: {{reason}}"
```

## 配置验证规则

- **Webhook URL**: 启用 webhook 时必须提供有效的 URL
- **日志级别**: 必须是 `debug`、`info`、`warn` 或 `error` 之一
- **macOS 通知**: 仅在 macOS 平台可用

## 相关命令

- `/webhook-test` - 发送测试通知验证配置
- `/webhook-logs` - 查看通知发送历史

## 故障排除

### 依赖缺失错误
如果看到 "缺少必需的依赖" 提示：

```bash
cd ${CLAUDE_PLUGIN_ROOT}
npm install
```

安装完成后重新运行命令。

### 配置文件不存在
运行 `/webhook-config --init` 创建默认配置文件。

### 配置验证失败
使用 `/webhook-config --validate` 查看详细的验证错误信息。

### Webhook URL 错误
- 启用 webhook 时必须提供有效的 URL
- URL 必须以 `http://` 或 `https://` 开头
- 如果不使用 webhook，设置 `enabled: false` 即可

### macOS 通知不显示
- 确保在 macOS 系统上运行
- 检查系统通知权限（系统设置 → 通知）
- 运行 `/webhook-test --notifier macos` 测试

### 查看详细日志
使用 `/webhook-logs` 查看通知发送历史和错误日志。

---

**执行方式：**

```bash
bash ${CLAUDE_PLUGIN_ROOT}/commands/webhook-config-wrapper.sh "$@"
```
