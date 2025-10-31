#!/usr/bin/env bash
# Webhook Logs Wrapper - 智能依赖检查和日志查看

# 确定插件目录
if [ -n "$CLAUDE_PLUGIN_ROOT" ]; then
    PLUGIN_DIR="$CLAUDE_PLUGIN_ROOT"
else
    # 如果环境变量未设置，使用脚本所在目录的父目录
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
fi

NODE_MODULES="$PLUGIN_DIR/node_modules"

# 检查 node_modules 是否存在
if [ ! -d "$NODE_MODULES" ] || [ ! -d "$NODE_MODULES/node-notifier" ]; then
    echo "⚠️  缺少必需的依赖"
    echo ""
    echo "此插件需要安装 node-notifier 依赖才能正常运行。"
    echo ""
    echo "📦 需要安装的依赖："
    echo "   - node-notifier (macOS 系统通知支持)"
    echo ""
    echo "💡 请让 Claude 执行以下命令安装依赖："
    echo ""
    echo "   cd \"$PLUGIN_DIR\""
    echo "   npm install"
    echo ""
    echo "安装完成后，即可使用 /webhook-logs 查看通知日志。"
    exit 1
fi

# 依赖已安装，执行日志命令
exec node "$PLUGIN_DIR/scripts/bin/index.js" logs "$@"
