#!/usr/bin/env bash

set -euo pipefail

# ============================================================================
# Webhook Notifier Log Viewer
# ============================================================================
# 查看 webhook 通知日志
# ============================================================================

readonly LOG_DIR="${HOME}/.claude/webhook-notifier/logs"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m'

# 打印函数
print_error() {
    echo -e "${RED}❌ $*${NC}" >&2
}

print_info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

# 使用说明
usage() {
    cat <<EOF
用法: $(basename "$0") [选项] [日期]

查看 webhook notifier 日志

选项:
  --errors        只显示错误日志
  --tail N        显示最近 N 条记录（默认 20）
  --help          显示此帮助信息

参数:
  日期            指定日期 (格式: YYYY-MM-DD)，默认为今天

示例:
  $(basename "$0")                    # 查看今天的日志
  $(basename "$0") 2025-01-29         # 查看指定日期的日志
  $(basename "$0") --errors           # 只显示错误日志
  $(basename "$0") --tail 50          # 显示最近 50 条记录

日志文件位置: ${LOG_DIR}
EOF
    exit 0
}

# 格式化日志行
format_log_line() {
    local line="$1"

    # 提取时间戳、级别和消息
    if [[ "${line}" =~ \[([^\]]+)\]\ (INFO|ERROR|TEST):\ (.+) ]]; then
        local timestamp="${BASH_REMATCH[1]}"
        local level="${BASH_REMATCH[2]}"
        local message="${BASH_REMATCH[3]}"

        case "${level}" in
            INFO)
                echo -e "${GRAY}[${timestamp}]${NC} ${GREEN}✅ ${message}${NC}"
                ;;
            ERROR)
                echo -e "${GRAY}[${timestamp}]${NC} ${RED}❌ ${message}${NC}"
                ;;
            TEST)
                if [[ "${message}" =~ FAILED ]]; then
                    echo -e "${GRAY}[${timestamp}]${NC} ${RED}🧪 ${message}${NC}"
                else
                    echo -e "${GRAY}[${timestamp}]${NC} ${BLUE}🧪 ${message}${NC}"
                fi
                ;;
            *)
                echo "${line}"
                ;;
        esac
    else
        echo "${line}"
    fi
}

# 显示日志文件
show_log_file() {
    local log_file="$1"
    local tail_count="${2:-}"

    if [[ ! -f "${log_file}" ]]; then
        print_error "日志文件不存在: ${log_file}"
        return 1
    fi

    local file_size=$(wc -l < "${log_file}")

    if [[ "${file_size}" -eq 0 ]]; then
        print_info "日志文件为空"
        return 0
    fi

    print_info "日志文件: ${log_file} (共 ${file_size} 行)"
    echo ""

    if [[ -n "${tail_count}" ]]; then
        tail -n "${tail_count}" "${log_file}" | while IFS= read -r line; do
            format_log_line "${line}"
        done
    else
        cat "${log_file}" | while IFS= read -r line; do
            format_log_line "${line}"
        done
    fi
}

# 显示错误日志
show_error_logs() {
    local errors_file="${LOG_DIR}/errors.log"

    if [[ ! -f "${errors_file}" ]]; then
        print_info "没有错误日志"
        return 0
    fi

    local error_count=$(wc -l < "${errors_file}")

    if [[ "${error_count}" -eq 0 ]]; then
        print_info "没有错误记录"
        return 0
    fi

    print_info "错误日志: ${errors_file} (共 ${error_count} 条)"
    echo ""

    cat "${errors_file}" | while IFS= read -r line; do
        format_log_line "${line}"
    done
}

# 主函数
main() {
    local show_errors_only=false
    local tail_count=""
    local target_date=""

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --errors)
                show_errors_only=true
                shift
                ;;
            --tail)
                if [[ -z "${2:-}" ]] || [[ ! "${2}" =~ ^[0-9]+$ ]]; then
                    print_error "--tail 需要一个数字参数"
                    exit 1
                fi
                tail_count="$2"
                shift 2
                ;;
            --help|-h)
                usage
                ;;
            *)
                # 假设是日期
                if [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                    target_date="$1"
                else
                    print_error "无效的参数或日期格式: $1"
                    echo ""
                    usage
                fi
                shift
                ;;
        esac
    done

    # 检查日志目录
    if [[ ! -d "${LOG_DIR}" ]]; then
        print_error "日志目录不存在: ${LOG_DIR}"
        print_info "请先运行 /webhook-test 生成日志"
        exit 1
    fi

    # 显示错误日志
    if [[ "${show_errors_only}" == true ]]; then
        show_error_logs
        exit 0
    fi

    # 确定目标日期
    if [[ -z "${target_date}" ]]; then
        target_date=$(date '+%Y-%m-%d')
    fi

    # 显示指定日期的日志
    local log_file="${LOG_DIR}/${target_date}.log"
    show_log_file "${log_file}" "${tail_count}"
}

# 执行主函数
main "$@"
