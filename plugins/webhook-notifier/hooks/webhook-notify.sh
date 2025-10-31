#!/usr/bin/env bash

set -euo pipefail

# ============================================================================
# Webhook Notifier Hook Wrapper
# ============================================================================
# 这是一个简单的 wrapper 脚本，用于调用 TypeScript 编译后的主程序
#
# Hook Events: Notification, Stop, SessionEnd
# Input: JSON from stdin containing event info
# Output: JSON to stdout for Claude Code
# ============================================================================

# 常量定义
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$SCRIPT_DIR/..}"
readonly MAIN_SCRIPT="${PLUGIN_ROOT}/dist/index.js"
readonly LOG_DIR="${HOME}/.claude/webhook-notifier/logs"

# 确保日志目录存在
mkdir -p "${LOG_DIR}"

# 日志函数（用于 wrapper 自己的错误）
log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] WRAPPER ERROR: $*" >> "${LOG_DIR}/wrapper-errors.log" 2>&1
}

# 验证 Node.js
if ! command -v node &> /dev/null; then
    log_error "Node.js is not installed or not in PATH"
    echo '{"continue": true, "systemMessage": "Webhook notifier error: Node.js not found"}' 2>/dev/null
    exit 1
fi

# 验证主程序存在
if [[ ! -f "${MAIN_SCRIPT}" ]]; then
    log_error "Main script not found at: ${MAIN_SCRIPT}"
    log_error "Please run: cd ${PLUGIN_ROOT} && npm run build"
    echo '{"continue": true, "systemMessage": "Webhook notifier error: Not built yet"}' 2>/dev/null
    exit 1
fi

# 调用主程序（从 stdin 读取，输出到 stdout）
# 主程序会处理所有逻辑：配置读取、日志记录、通知发送等
node "${MAIN_SCRIPT}" 2>> "${LOG_DIR}/wrapper-errors.log"

# 返回主程序的退出码
exit $?
