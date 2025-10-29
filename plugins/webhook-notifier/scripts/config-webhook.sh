#!/usr/bin/env bash

set -euo pipefail

# ============================================================================
# Webhook Notifier Configuration Script
# ============================================================================
# 交互式配置 webhook notifier 插件
# ============================================================================

readonly CONFIG_DIR="${HOME}/.claude/webhook-notifier"
readonly CONFIG_FILE="${CONFIG_DIR}/config.json"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# 打印函数
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Webhook Notifier 配置向导${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $*${NC}"
}

print_error() {
    echo -e "${RED}❌ $*${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

# 确保配置目录存在
ensure_config_dir() {
    mkdir -p "${CONFIG_DIR}"
    mkdir -p "${CONFIG_DIR}/logs"
}

# 读取现有配置
read_existing_config() {
    if [[ -f "${CONFIG_FILE}" ]]; then
        if command -v jq &> /dev/null; then
            cat "${CONFIG_FILE}"
        else
            echo "{}"
        fi
    else
        echo "{}"
    fi
}

# 获取配置值
get_config_value() {
    local key="$1"
    local default="${2:-}"
    local config="$3"

    if command -v jq &> /dev/null; then
        echo "${config}" | jq -r ".${key} // \"${default}\""
    else
        echo "${default}"
    fi
}

# 提示输入
prompt_input() {
    local prompt="$1"
    local default="$2"
    local value

    if [[ -n "${default}" ]]; then
        read -p "${prompt} [${default}]: " value
        echo "${value:-$default}"
    else
        read -p "${prompt}: " value
        echo "${value}"
    fi
}

# 提示 yes/no
prompt_yes_no() {
    local prompt="$1"
    local default="$2"
    local response

    if [[ "${default}" == "true" ]]; then
        read -p "${prompt} [Y/n]: " response
        response="${response:-y}"
    else
        read -p "${prompt} [y/N]: " response
        response="${response:-n}"
    fi

    case "${response}" in
        [Yy]|[Yy][Ee][Ss]) echo "true" ;;
        *) echo "false" ;;
    esac
}

# 验证 URL
validate_url() {
    local url="$1"

    if [[ ! "${url}" =~ ^https?:// ]]; then
        return 1
    fi

    if [[ "${url}" == "https://your-webhook-endpoint.com/notify" ]]; then
        return 1
    fi

    return 0
}

# 保存配置
save_config() {
    local webhook_url="$1"
    local enabled="$2"
    local timeout="$3"
    local log_level="$4"
    local include_session_id="$5"
    local include_reason="$6"
    local include_transcript="$7"
    local include_project="$8"
    local include_git="$9"

    if command -v jq &> /dev/null; then
        jq -n \
            --arg url "${webhook_url}" \
            --arg enabled "${enabled}" \
            --arg timeout "${timeout}" \
            --arg log_level "${log_level}" \
            --arg inc_sid "${include_session_id}" \
            --arg inc_reason "${include_reason}" \
            --arg inc_trans "${include_transcript}" \
            --arg inc_proj "${include_project}" \
            --arg inc_git "${include_git}" \
            '{
                webhook_url: $url,
                enabled: ($enabled == "true"),
                timeout: ($timeout | tonumber),
                log_level: $log_level,
                payload_config: {
                    include_session_id: ($inc_sid == "true"),
                    include_reason: ($inc_reason == "true"),
                    include_transcript_path: ($inc_trans == "true"),
                    include_project_info: ($inc_proj == "true"),
                    include_git_info: ($inc_git == "true"),
                    custom_fields: {}
                }
            }' > "${CONFIG_FILE}"
    else
        # Fallback: 使用 python
        python3 <<EOF
import json
config = {
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
with open("${CONFIG_FILE}", "w") as f:
    json.dump(config, f, indent=2)
EOF
    fi
}

# 显示当前配置
show_current_config() {
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        print_warning "配置文件不存在"
        return
    fi

    echo ""
    print_info "当前配置："
    echo ""

    if command -v jq &> /dev/null; then
        cat "${CONFIG_FILE}" | jq .
    else
        cat "${CONFIG_FILE}"
    fi

    echo ""
}

# 主配置流程
main() {
    print_header

    ensure_config_dir

    # 读取现有配置
    local existing_config=$(read_existing_config)

    # 显示当前配置
    if [[ -f "${CONFIG_FILE}" ]]; then
        show_current_config
        echo ""
        if [[ "$(prompt_yes_no '是否修改现有配置？' 'true')" == "false" ]]; then
            print_info "保持现有配置不变"
            exit 0
        fi
        echo ""
    fi

    # 获取配置输入
    print_info "基本配置"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local webhook_url
    while true; do
        webhook_url=$(prompt_input "Webhook URL" "$(get_config_value 'webhook_url' '' "${existing_config}")")

        if validate_url "${webhook_url}"; then
            break
        else
            print_error "URL 格式无效，请输入有效的 HTTP/HTTPS URL"
        fi
    done

    local enabled=$(prompt_yes_no "启用通知" "$(get_config_value 'enabled' 'true' "${existing_config}")")

    local timeout=$(prompt_input "超时时间（秒）" "$(get_config_value 'timeout' '10' "${existing_config}")")

    echo ""
    print_info "日志配置"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo "日志级别选项: debug, info, warn, error"
    local log_level=$(prompt_input "日志级别" "$(get_config_value 'log_level' 'info' "${existing_config}")")

    echo ""
    print_info "Payload 配置"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local include_session_id=$(prompt_yes_no "包含会话 ID" "$(get_config_value 'payload_config.include_session_id' 'true' "${existing_config}")")
    local include_reason=$(prompt_yes_no "包含结束原因" "$(get_config_value 'payload_config.include_reason' 'true' "${existing_config}")")
    local include_transcript=$(prompt_yes_no "包含会话记录路径" "$(get_config_value 'payload_config.include_transcript_path' 'true' "${existing_config}")")
    local include_project=$(prompt_yes_no "包含项目信息" "$(get_config_value 'payload_config.include_project_info' 'true' "${existing_config}")")
    local include_git=$(prompt_yes_no "包含 Git 信息" "$(get_config_value 'payload_config.include_git_info' 'true' "${existing_config}")")

    # 保存配置
    echo ""
    print_info "保存配置..."

    save_config "${webhook_url}" "${enabled}" "${timeout}" "${log_level}" \
        "${include_session_id}" "${include_reason}" "${include_transcript}" \
        "${include_project}" "${include_git}"

    print_success "配置已保存到: ${CONFIG_FILE}"

    # 显示新配置
    show_current_config

    # 询问是否测试
    echo ""
    if [[ "$(prompt_yes_no '是否发送测试通知？' 'true')" == "true" ]]; then
        echo ""
        print_info "发送测试通知..."
        echo ""

        if [[ -x "${SCRIPT_DIR}/test-webhook.sh" ]]; then
            bash "${SCRIPT_DIR}/test-webhook.sh"
        else
            print_warning "测试脚本不存在或无执行权限"
            print_info "请手动运行: /webhook-test"
        fi
    fi

    echo ""
    print_success "配置完成！"
    print_info "配置文件: ${CONFIG_FILE}"
    print_info "日志目录: ${CONFIG_DIR}/logs"
    echo ""
}

# 执行主函数
main "$@"
