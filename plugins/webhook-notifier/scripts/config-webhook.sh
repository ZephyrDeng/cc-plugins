#!/usr/bin/env bash

set -euo pipefail

# ============================================================================
# Webhook Notifier Configuration Script (Non-Interactive)
# ============================================================================
# 命令行参数配置 webhook notifier 插件
# 支持 Claude Code 非交互环境
# ============================================================================

readonly CONFIG_DIR="${HOME}/.claude/webhook-notifier"
readonly CONFIG_FILE="${CONFIG_DIR}/config.json"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 默认值
DEFAULT_TIMEOUT=10
DEFAULT_LOG_LEVEL="info"
DEFAULT_ENABLED=true

# 打印函数
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Webhook Notifier 配置工具${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $*${NC}"
}

print_error() {
    echo -e "${RED}❌ $*${NC}" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

# 显示帮助信息
show_help() {
    cat << EOF
用法: $(basename "$0") [OPTIONS]

命令行配置 Webhook Notifier 插件

必需参数（首次配置）：
  --url URL                    设置 Webhook URL

可选配置参数：
  --enable                     启用通知（默认）
  --disable                    禁用通知
  --timeout SECONDS            超时时间秒数（默认：10）
  --log-level LEVEL           日志级别：debug|info|warn|error（默认：info）

Payload 配置（默认全部启用）：
  --include-session-id         包含会话 ID
  --no-include-session-id      不包含会话 ID
  --include-reason             包含结束原因
  --no-include-reason          不包含结束原因
  --include-transcript         包含会话记录路径
  --no-include-transcript      不包含会话记录路径
  --include-project            包含项目信息
  --no-include-project         不包含项目信息
  --include-git                包含 Git 信息
  --no-include-git             不包含 Git 信息

操作命令：
  --show                       显示当前配置
  --default                    创建默认配置（带占位符）
  --test                       配置完成后发送测试通知
  --help                       显示此帮助信息

示例：
  # 快速配置
  $(basename "$0") --url https://example.com/webhook --enable

  # 完整配置
  $(basename "$0") \\
    --url https://example.com/webhook \\
    --enable \\
    --timeout 15 \\
    --log-level debug \\
    --include-session-id \\
    --include-reason \\
    --no-include-transcript \\
    --test

  # 查看配置
  $(basename "$0") --show

  # 只修改超时时间
  $(basename "$0") --timeout 30

配置文件：${CONFIG_FILE}
日志目录：${CONFIG_DIR}/logs

EOF
}

# 确保配置目录存在
ensure_config_dir() {
    mkdir -p "${CONFIG_DIR}"
    mkdir -p "${CONFIG_DIR}/logs"
}

# 读取现有配置
read_existing_config() {
    if [[ -f "${CONFIG_FILE}" ]]; then
        cat "${CONFIG_FILE}"
    else
        echo "{}"
    fi
}

# 从配置中获取值
get_config_value() {
    local key="$1"
    local default="${2:-}"
    local config="$3"

    if command -v jq &> /dev/null; then
        local value
        value=$(echo "${config}" | jq -r ".${key} // empty")
        if [[ -n "${value}" && "${value}" != "null" ]]; then
            echo "${value}"
        else
            echo "${default}"
        fi
    else
        echo "${default}"
    fi
}

# 验证 URL
validate_url() {
    local url="$1"

    if [[ ! "${url}" =~ ^https?:// ]]; then
        print_error "URL 格式无效：必须以 http:// 或 https:// 开头"
        return 1
    fi

    if [[ "${url}" == *"your-webhook-endpoint.com"* ]]; then
        print_error "URL 无效：请提供真实的 Webhook URL"
        return 1
    fi

    return 0
}

# 验证日志级别
validate_log_level() {
    local level="$1"
    case "${level}" in
        debug|info|warn|error)
            return 0
            ;;
        *)
            print_error "日志级别无效：必须是 debug, info, warn 或 error"
            return 1
            ;;
    esac
}

# 验证超时时间
validate_timeout() {
    local timeout="$1"
    if ! [[ "${timeout}" =~ ^[0-9]+$ ]]; then
        print_error "超时时间无效：必须是正整数"
        return 1
    fi
    if [[ "${timeout}" -lt 1 || "${timeout}" -gt 300 ]]; then
        print_error "超时时间无效：必须在 1-300 秒之间"
        return 1
    fi
    return 0
}

# 保存配置
save_config() {
    local config="$1"

    if command -v jq &> /dev/null; then
        echo "${config}" | jq . > "${CONFIG_FILE}"
    else
        echo "${config}" > "${CONFIG_FILE}"
    fi
}

# 显示当前配置
show_config() {
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        print_warning "配置文件不存在"
        print_info "运行 '$(basename "$0") --default' 创建默认配置"
        return 1
    fi

    echo ""
    print_info "当前配置："
    echo ""

    if command -v jq &> /dev/null; then
        jq . "${CONFIG_FILE}"
    else
        cat "${CONFIG_FILE}"
    fi

    echo ""
    return 0
}

# 创建默认配置
create_default_config() {
    ensure_config_dir

    local default_config
    if command -v jq &> /dev/null; then
        default_config=$(jq -n \
            --arg url "https://your-webhook-endpoint.com/notify" \
            --argjson enabled "${DEFAULT_ENABLED}" \
            --argjson timeout "${DEFAULT_TIMEOUT}" \
            --arg log_level "${DEFAULT_LOG_LEVEL}" \
            '{
                webhook_url: $url,
                enabled: $enabled,
                timeout: $timeout,
                log_level: $log_level,
                payload_config: {
                    include_session_id: true,
                    include_reason: true,
                    include_transcript_path: true,
                    include_project_info: true,
                    include_git_info: true,
                    custom_fields: {}
                }
            }')
    else
        default_config='{
    "webhook_url": "https://your-webhook-endpoint.com/notify",
    "enabled": true,
    "timeout": 10,
    "log_level": "info",
    "payload_config": {
        "include_session_id": true,
        "include_reason": true,
        "include_transcript_path": true,
        "include_project_info": true,
        "include_git_info": true,
        "custom_fields": {}
    }
}'
    fi

    save_config "${default_config}"
    print_success "默认配置已创建"
    print_warning "请使用 --url 参数设置真实的 Webhook URL"
    show_config
}

# 发送测试通知
send_test_notification() {
    print_info "发送测试通知..."
    echo ""

    if [[ -x "${SCRIPT_DIR}/test-webhook.sh" ]]; then
        bash "${SCRIPT_DIR}/test-webhook.sh"
    else
        print_warning "测试脚本不存在或无执行权限"
        print_info "请手动运行: /webhook-test"
    fi
}

# 主函数
main() {
    local webhook_url=""
    local enabled=""
    local timeout=""
    local log_level=""
    local include_session_id=""
    local include_reason=""
    local include_transcript=""
    local include_project=""
    local include_git=""
    local show_only=false
    local create_default=false
    local run_test=false
    local has_updates=false

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --url)
                webhook_url="$2"
                shift 2
                ;;
            --enable)
                enabled="true"
                shift
                ;;
            --disable)
                enabled="false"
                shift
                ;;
            --timeout)
                timeout="$2"
                shift 2
                ;;
            --log-level)
                log_level="$2"
                shift 2
                ;;
            --include-session-id)
                include_session_id="true"
                shift
                ;;
            --no-include-session-id)
                include_session_id="false"
                shift
                ;;
            --include-reason)
                include_reason="true"
                shift
                ;;
            --no-include-reason)
                include_reason="false"
                shift
                ;;
            --include-transcript)
                include_transcript="true"
                shift
                ;;
            --no-include-transcript)
                include_transcript="false"
                shift
                ;;
            --include-project)
                include_project="true"
                shift
                ;;
            --no-include-project)
                include_project="false"
                shift
                ;;
            --include-git)
                include_git="true"
                shift
                ;;
            --no-include-git)
                include_git="false"
                shift
                ;;
            --show)
                show_only=true
                shift
                ;;
            --default)
                create_default=true
                shift
                ;;
            --test)
                run_test=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "未知参数: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done

    # 处理 --show 命令
    if [[ "${show_only}" == "true" ]]; then
        show_config
        exit $?
    fi

    # 处理 --default 命令
    if [[ "${create_default}" == "true" ]]; then
        create_default_config
        exit 0
    fi

    # 如果没有任何参数，显示帮助或当前配置
    if [[ -z "${webhook_url}" && -z "${enabled}" && -z "${timeout}" && -z "${log_level}" && \
          -z "${include_session_id}" && -z "${include_reason}" && -z "${include_transcript}" && \
          -z "${include_project}" && -z "${include_git}" ]]; then
        if [[ -f "${CONFIG_FILE}" ]]; then
            show_config
        else
            print_header
            print_info "配置文件不存在"
            print_info "使用 --help 查看帮助，或 --default 创建默认配置"
        fi
        exit 0
    fi

    print_header
    ensure_config_dir

    # 读取现有配置
    local existing_config=$(read_existing_config)

    # 验证参数
    if [[ -n "${webhook_url}" ]]; then
        validate_url "${webhook_url}" || exit 1
        has_updates=true
    else
        webhook_url=$(get_config_value 'webhook_url' '' "${existing_config}")
    fi

    if [[ -n "${timeout}" ]]; then
        validate_timeout "${timeout}" || exit 1
        has_updates=true
    else
        timeout=$(get_config_value 'timeout' "${DEFAULT_TIMEOUT}" "${existing_config}")
    fi

    if [[ -n "${log_level}" ]]; then
        validate_log_level "${log_level}" || exit 1
        has_updates=true
    else
        log_level=$(get_config_value 'log_level' "${DEFAULT_LOG_LEVEL}" "${existing_config}")
    fi

    if [[ -n "${enabled}" ]]; then
        has_updates=true
    else
        enabled=$(get_config_value 'enabled' "${DEFAULT_ENABLED}" "${existing_config}")
    fi

    # 处理 payload 配置
    [[ -n "${include_session_id}" ]] && has_updates=true || include_session_id=$(get_config_value 'payload_config.include_session_id' 'true' "${existing_config}")
    [[ -n "${include_reason}" ]] && has_updates=true || include_reason=$(get_config_value 'payload_config.include_reason' 'true' "${existing_config}")
    [[ -n "${include_transcript}" ]] && has_updates=true || include_transcript=$(get_config_value 'payload_config.include_transcript_path' 'true' "${existing_config}")
    [[ -n "${include_project}" ]] && has_updates=true || include_project=$(get_config_value 'payload_config.include_project_info' 'true' "${existing_config}")
    [[ -n "${include_git}" ]] && has_updates=true || include_git=$(get_config_value 'payload_config.include_git_info' 'true' "${existing_config}")

    # 检查 URL 是否有效
    if [[ -z "${webhook_url}" ]]; then
        print_error "缺少 Webhook URL"
        print_info "使用 --url 参数设置 Webhook URL"
        exit 1
    fi

    # 构建新配置
    local new_config
    if command -v jq &> /dev/null; then
        new_config=$(jq -n \
            --arg url "${webhook_url}" \
            --argjson enabled "${enabled}" \
            --argjson timeout "${timeout}" \
            --arg log_level "${log_level}" \
            --argjson inc_sid "${include_session_id}" \
            --argjson inc_reason "${include_reason}" \
            --argjson inc_trans "${include_transcript}" \
            --argjson inc_proj "${include_project}" \
            --argjson inc_git "${include_git}" \
            '{
                webhook_url: $url,
                enabled: $enabled,
                timeout: $timeout,
                log_level: $log_level,
                payload_config: {
                    include_session_id: $inc_sid,
                    include_reason: $inc_reason,
                    include_transcript_path: $inc_trans,
                    include_project_info: $inc_proj,
                    include_git_info: $inc_git,
                    custom_fields: {}
                }
            }')
    else
        new_config=$(cat <<EOF
{
    "webhook_url": "${webhook_url}",
    "enabled": ${enabled},
    "timeout": ${timeout},
    "log_level": "${log_level}",
    "payload_config": {
        "include_session_id": ${include_session_id},
        "include_reason": ${include_reason},
        "include_transcript_path": ${include_transcript},
        "include_project_info": ${include_project},
        "include_git_info": ${include_git},
        "custom_fields": {}
    }
}
EOF
)
    fi

    # 保存配置
    print_info "保存配置..."
    save_config "${new_config}"
    print_success "配置已保存到: ${CONFIG_FILE}"

    # 显示新配置
    show_config

    # 发送测试通知
    if [[ "${run_test}" == "true" ]]; then
        echo ""
        send_test_notification
    fi

    echo ""
    print_success "配置完成！"
}

# 执行主函数
main "$@"
