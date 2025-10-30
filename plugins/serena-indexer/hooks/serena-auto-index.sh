#!/bin/bash

# Serena 自动索引 Hook 脚本
# 支持智能索引决策，避免不必要的重复索引

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[Serena Hook]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[Serena Hook]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[Serena Hook]${NC} $1"
}

log_error() {
    echo -e "${RED}[Serena Hook]${NC} $1" >&2
}

# 获取脚本参数
HOOK_TYPE="${1:-session-start}"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SERENA_DIR="$PROJECT_ROOT/.serena"
INDEX_METADATA="$SERENA_DIR/metadata.json"

log_info "Hook 触发: $HOOK_TYPE"
log_info "项目路径: $PROJECT_ROOT"

# 检查是否为 Git 仓库
if [[ ! -d "$PROJECT_ROOT/.git" ]]; then
    log_info "非 Git 仓库，跳过索引检查"
    exit 0
fi

# 检查 Serena MCP 是否配置
if ! command -v uvx &> /dev/null; then
    log_info "uvx 工具未安装，跳过索引检查"
    exit 0
fi

# 检查 Serena MCP 是否已启用
check_serena_mcp_enabled() {
    # 方案 1: 检查用户级配置 (~/.claude.json)
    if [[ -f ~/.claude.json ]]; then
        if jq -e '.mcpServers | has("serena")' ~/.claude.json &>/dev/null 2>&1; then
            return 0
        fi
    fi
    
    # 方案 2: 检查项目级配置 (.mcp.json)
    if [[ -f "$PROJECT_ROOT/.mcp.json" ]]; then
        if jq -e 'has("serena")' "$PROJECT_ROOT/.mcp.json" &>/dev/null 2>&1; then
            return 0
        fi
    fi
    
    # 方案 3: 检查旧版配置位置（兼容性）
    if [[ -f ~/.claude/mcp.json ]]; then
        if jq -e 'has("serena")' ~/.claude/mcp.json &>/dev/null 2>&1; then
            return 0
        fi
    fi
    
    return 1
}

# 检查 metadata.json 文件完整性
validate_metadata() {
    if [[ ! -f "$INDEX_METADATA" ]]; then
        return 1
    fi
    
    # 检查文件是否为有效的 JSON
    if ! jq empty "$INDEX_METADATA" 2>/dev/null; then
        log_warning "metadata.json 文件损坏，将重新创建"
        rm -f "$INDEX_METADATA"
        return 1
    fi
    
    return 0
}

# 检查是否需要智能索引决策
should_skip_index() {
    local index_age_threshold=3600  # 1小时
    local change_threshold=10       # 10个文件变更

    # 如果索引不存在，需要索引
    if ! validate_metadata; then
        return 1
    fi

    # 检查索引年龄
    local current_time=$(date +%s)
    local index_time=$(jq -r '.timestamp // 0' "$INDEX_METADATA" 2>/dev/null)
    if [[ -z "$index_time" || "$index_time" == "null" ]]; then
        index_time=0
    fi
    local index_age=$((current_time - index_time))

    if [[ $index_age -lt $index_age_threshold ]]; then
        log_info "索引仍然新鲜（$(($index_age / 60))分钟前），跳过索引"
        return 0
    fi

    # 检查文件变更数量
    local changed_files
    changed_files=$(cd "$PROJECT_ROOT" && git diff --name-only HEAD~1 2>/dev/null | wc -l || echo 0)

    if [[ $changed_files -lt $change_threshold ]]; then
        log_info "文件变更较少（$changed_files 个），跳过索引"
        return 0
    fi

    return 1
}

# 执行索引
run_index() {
    log_info "开始 Serena 索引..."

    # 创建 .serena 目录
    mkdir -p "$SERENA_DIR"

    # 执行索引命令
    cd "$PROJECT_ROOT"

    if uvx --from git+https://github.com/oraios/serena serena project index 2>&1 | while IFS= read -r line; do
        log_info "索引: $line"
    done; then
        # 创建索引元数据
        local metadata_content=$(cat <<EOF
{
  "timestamp": $(date +%s),
  "hook_type": "$HOOK_TYPE",
  "project_root": "$PROJECT_ROOT",
  "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "files_indexed": $(find . -name "*.go" -o -name "*.py" -o -name "*.js" -o -name "*.ts" | wc -l),
  "index_size": $(du -sh "$SERENA_DIR" 2>/dev/null | cut -f1 || echo "unknown"),
  "status": "completed"
}
EOF
        )

        echo "$metadata_content" > "$INDEX_METADATA"
        log_success "Serena 索引完成"
        return 0
    else
        log_error "Serena 索引失败"
        return 1
    fi
}

# 主逻辑
main() {
    case "$HOOK_TYPE" in
        "session-start")
            log_info "会话开始 - 检查索引状态"
            
            # 优化：如果 Serena MCP 未启用，跳过索引检查
            if ! check_serena_mcp_enabled; then
                log_info "Serena MCP 未启用，跳过索引检查"
                exit 0
            fi
            
            if should_skip_index; then
                log_success "索引检查完成，无需更新"
            else
                log_info "需要更新索引"
                run_index
            fi
            ;;
        "pre-tool")
            log_info "Serena 工具使用前 - 快速检查"
            # PreToolUse hook 执行更快的检查
            if validate_metadata; then
                local timestamp=$(jq -r '.timestamp // 0' "$INDEX_METADATA" 2>/dev/null)
                if [[ -z "$timestamp" || "$timestamp" == "null" ]]; then
                    timestamp=0
                fi
                local index_age=$(($(date +%s) - timestamp))
                if [[ $index_age -lt 7200 ]]; then  # 2小时内不重新索引
                    log_success "索引仍然新鲜，继续使用工具"
                else
                    log_warning "索引可能过期，建议手动运行 /serena-index"
                fi
            else
                log_warning "未找到索引，建议手动运行 /serena-index"
            fi
            ;;
        *)
            log_error "未知的 hook 类型: $HOOK_TYPE"
            exit 1
            ;;
    esac
}

# 错误处理
trap 'log_error "Hook 执行过程中发生错误"' ERR

# 执行主逻辑
main "$@"