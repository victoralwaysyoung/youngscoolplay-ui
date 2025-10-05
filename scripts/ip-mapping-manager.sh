#!/bin/bash

# YoungsCoolPlay UI IP 映射管理脚本
# 用于动态管理 IP 地址与 vless 账号的映射关系

set -euo pipefail

# 配置文件路径
NGINX_CONF_DIR="/etc/nginx/conf.d"
IP_MAPPING_CONF="${NGINX_CONF_DIR}/ip-mapping.conf"
MAPPING_DB="/var/lib/youngscoolplay/ip-mappings.json"
BACKUP_DIR="/var/backups/youngscoolplay/nginx"
LOG_FILE="/var/log/youngscoolplay/ip-mapping.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"
}

# 检查依赖
check_dependencies() {
    local deps=("nginx" "jq" "curl")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "依赖 $dep 未安装"
            exit 1
        fi
    done
}

# 创建必要目录
create_directories() {
    mkdir -p "$(dirname "$MAPPING_DB")"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
}

# 初始化映射数据库
init_mapping_db() {
    if [[ ! -f "$MAPPING_DB" ]]; then
        cat > "$MAPPING_DB" << 'EOF'
{
  "version": "1.0",
  "last_updated": "",
  "mappings": {},
  "accounts": {},
  "statistics": {
    "total_mappings": 0,
    "active_accounts": 0,
    "last_cleanup": ""
  }
}
EOF
        log "初始化映射数据库: $MAPPING_DB"
    fi
}

# 生成 UUID
generate_uuid() {
    if command -v uuidgen &> /dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    else
        # 备用方法
        cat /proc/sys/kernel/random/uuid
    fi
}

# 添加 IP 映射
add_mapping() {
    local ip="$1"
    local account_id="$2"
    local account_type="${3:-standard}"
    local uuid="${4:-$(generate_uuid)}"
    
    # 验证 IP 格式
    if ! [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        error "无效的 IP 地址格式: $ip"
        return 1
    fi
    
    # 检查 IP 是否已存在
    if jq -e ".mappings[\"$ip\"]" "$MAPPING_DB" > /dev/null 2>&1; then
        warn "IP $ip 已存在映射，将更新现有映射"
    fi
    
    # 更新数据库
    local temp_file=$(mktemp)
    jq --arg ip "$ip" \
       --arg account_id "$account_id" \
       --arg account_type "$account_type" \
       --arg uuid "$uuid" \
       --arg timestamp "$(date -Iseconds)" \
       '.mappings[$ip] = {
         "account_id": $account_id,
         "account_type": $account_type,
         "uuid": $uuid,
         "created_at": $timestamp,
         "last_used": $timestamp,
         "status": "active"
       } |
       .accounts[$account_id] = {
         "uuid": $uuid,
         "account_type": $account_type,
         "ips": [.accounts[$account_id].ips[]?, $ip] | unique,
         "created_at": (.accounts[$account_id].created_at // $timestamp),
         "updated_at": $timestamp
       } |
       .last_updated = $timestamp |
       .statistics.total_mappings = (.mappings | length) |
       .statistics.active_accounts = (.accounts | length)' \
       "$MAPPING_DB" > "$temp_file"
    
    mv "$temp_file" "$MAPPING_DB"
    
    log "添加 IP 映射: $ip -> $account_id ($account_type) [UUID: $uuid]"
    
    # 重新生成 Nginx 配置
    generate_nginx_config
}

# 删除 IP 映射
remove_mapping() {
    local ip="$1"
    
    # 检查映射是否存在
    if ! jq -e ".mappings[\"$ip\"]" "$MAPPING_DB" > /dev/null 2>&1; then
        error "IP $ip 的映射不存在"
        return 1
    fi
    
    # 获取账号信息
    local account_id=$(jq -r ".mappings[\"$ip\"].account_id" "$MAPPING_DB")
    
    # 更新数据库
    local temp_file=$(mktemp)
    jq --arg ip "$ip" \
       --arg account_id "$account_id" \
       --arg timestamp "$(date -Iseconds)" \
       'del(.mappings[$ip]) |
       .accounts[$account_id].ips = (.accounts[$account_id].ips - [$ip]) |
       if (.accounts[$account_id].ips | length) == 0 then
         del(.accounts[$account_id])
       else
         .accounts[$account_id].updated_at = $timestamp
       end |
       .last_updated = $timestamp |
       .statistics.total_mappings = (.mappings | length) |
       .statistics.active_accounts = (.accounts | length)' \
       "$MAPPING_DB" > "$temp_file"
    
    mv "$temp_file" "$MAPPING_DB"
    
    log "删除 IP 映射: $ip (账号: $account_id)"
    
    # 重新生成 Nginx 配置
    generate_nginx_config
}

# 查询 IP 映射
query_mapping() {
    local ip="$1"
    
    if jq -e ".mappings[\"$ip\"]" "$MAPPING_DB" > /dev/null 2>&1; then
        jq -r ".mappings[\"$ip\"] | 
               \"IP: $ip\n\" +
               \"账号ID: \" + .account_id + \"\n\" +
               \"账号类型: \" + .account_type + \"\n\" +
               \"UUID: \" + .uuid + \"\n\" +
               \"创建时间: \" + .created_at + \"\n\" +
               \"最后使用: \" + .last_used + \"\n\" +
               \"状态: \" + .status" "$MAPPING_DB"
    else
        error "IP $ip 的映射不存在"
        return 1
    fi
}

# 列出所有映射
list_mappings() {
    local filter="${1:-all}"
    
    case "$filter" in
        "active")
            jq -r '.mappings | to_entries[] | select(.value.status == "active") | 
                   .key + " -> " + .value.account_id + " (" + .value.account_type + ")"' "$MAPPING_DB"
            ;;
        "inactive")
            jq -r '.mappings | to_entries[] | select(.value.status == "inactive") | 
                   .key + " -> " + .value.account_id + " (" + .value.account_type + ")"' "$MAPPING_DB"
            ;;
        "all"|*)
            jq -r '.mappings | to_entries[] | 
                   .key + " -> " + .value.account_id + " (" + .value.account_type + ") [" + .value.status + "]"' "$MAPPING_DB"
            ;;
    esac
}

# 生成 Nginx 配置
generate_nginx_config() {
    local temp_conf=$(mktemp)
    
    # 备份现有配置
    if [[ -f "$IP_MAPPING_CONF" ]]; then
        cp "$IP_MAPPING_CONF" "${BACKUP_DIR}/ip-mapping-$(date +%Y%m%d-%H%M%S).conf.bak"
    fi
    
    # 生成新配置
    cat > "$temp_conf" << 'EOF'
# YoungsCoolPlay UI IP 与 vless 账号 1:1 映射配置
# 自动生成，请勿手动编辑

# IP 地址到 vless 账号的精确映射
map $remote_addr $vless_account_id {
    default "default";
EOF
    
    # 添加映射规则
    jq -r '.mappings | to_entries[] | select(.value.status == "active") | 
           "    \"" + .key + "\"    \"" + .value.account_id + "\";"' "$MAPPING_DB" >> "$temp_conf"
    
    cat >> "$temp_conf" << 'EOF'
}

# 根据账号 ID 映射到具体的 vless 配置
map $vless_account_id $vless_uuid {
    default "550e8400-e29b-41d4-a716-446655440000";
EOF
    
    # 添加 UUID 映射
    jq -r '.accounts | to_entries[] | 
           "    \"" + .key + "\" \"" + .value.uuid + "\";"' "$MAPPING_DB" >> "$temp_conf"
    
    cat >> "$temp_conf" << 'EOF'
}

# 账号类型映射
map $vless_account_id $account_type {
    default "standard";
EOF
    
    # 添加账号类型映射
    jq -r '.accounts | to_entries[] | 
           "    \"" + .key + "\" \"" + .value.account_type + "\";"' "$MAPPING_DB" >> "$temp_conf"
    
    cat >> "$temp_conf" << 'EOF'
}

# 包含其他配置
include /etc/nginx/conf.d/ip-mapping-base.conf;
EOF
    
    # 验证配置
    if nginx -t -c <(cat /etc/nginx/nginx.conf; echo "include $temp_conf;") 2>/dev/null; then
        mv "$temp_conf" "$IP_MAPPING_CONF"
        log "生成新的 Nginx 配置: $IP_MAPPING_CONF"
        
        # 重载 Nginx
        if systemctl reload nginx; then
            log "Nginx 配置重载成功"
        else
            error "Nginx 配置重载失败"
            return 1
        fi
    else
        error "生成的 Nginx 配置无效"
        rm -f "$temp_conf"
        return 1
    fi
}

# 导入映射（从 CSV 文件）
import_mappings() {
    local csv_file="$1"
    
    if [[ ! -f "$csv_file" ]]; then
        error "CSV 文件不存在: $csv_file"
        return 1
    fi
    
    local count=0
    while IFS=',' read -r ip account_id account_type uuid; do
        # 跳过标题行
        if [[ "$ip" == "ip" ]]; then
            continue
        fi
        
        # 清理数据
        ip=$(echo "$ip" | tr -d ' "')
        account_id=$(echo "$account_id" | tr -d ' "')
        account_type=$(echo "$account_type" | tr -d ' "')
        uuid=$(echo "$uuid" | tr -d ' "')
        
        if [[ -n "$ip" && -n "$account_id" ]]; then
            add_mapping "$ip" "$account_id" "${account_type:-standard}" "${uuid:-$(generate_uuid)}"
            ((count++))
        fi
    done < "$csv_file"
    
    log "导入完成，共处理 $count 条映射"
}

# 导出映射（到 CSV 文件）
export_mappings() {
    local csv_file="$1"
    
    echo "ip,account_id,account_type,uuid,created_at,last_used,status" > "$csv_file"
    
    jq -r '.mappings | to_entries[] | 
           .key + "," + 
           .value.account_id + "," + 
           .value.account_type + "," + 
           .value.uuid + "," + 
           .value.created_at + "," + 
           .value.last_used + "," + 
           .value.status' "$MAPPING_DB" >> "$csv_file"
    
    log "映射导出到: $csv_file"
}

# 统计信息
show_statistics() {
    echo "=== YoungsCoolPlay UI IP 映射统计 ==="
    echo
    
    # 基本统计
    local total_mappings=$(jq -r '.statistics.total_mappings' "$MAPPING_DB")
    local active_accounts=$(jq -r '.statistics.active_accounts' "$MAPPING_DB")
    local last_updated=$(jq -r '.last_updated' "$MAPPING_DB")
    
    echo "总映射数: $total_mappings"
    echo "活跃账号数: $active_accounts"
    echo "最后更新: $last_updated"
    echo
    
    # 按账号类型统计
    echo "按账号类型统计:"
    jq -r '.accounts | group_by(.account_type) | 
           .[] | .[0].account_type + ": " + (length | tostring)' "$MAPPING_DB"
    echo
    
    # 按状态统计
    echo "按状态统计:"
    jq -r '.mappings | group_by(.status) | 
           .[] | .[0].status + ": " + (length | tostring)' "$MAPPING_DB"
}

# 清理过期映射
cleanup_mappings() {
    local days="${1:-30}"
    local cutoff_date=$(date -d "$days days ago" -Iseconds)
    
    local temp_file=$(mktemp)
    jq --arg cutoff "$cutoff_date" \
       --arg timestamp "$(date -Iseconds)" \
       '.mappings = (.mappings | with_entries(select(.value.last_used >= $cutoff))) |
       .last_updated = $timestamp |
       .statistics.last_cleanup = $timestamp |
       .statistics.total_mappings = (.mappings | length)' \
       "$MAPPING_DB" > "$temp_file"
    
    mv "$temp_file" "$MAPPING_DB"
    
    log "清理 $days 天前的映射完成"
    generate_nginx_config
}

# 健康检查
health_check() {
    local issues=0
    
    echo "=== YoungsCoolPlay UI IP 映射健康检查 ==="
    echo
    
    # 检查配置文件
    if [[ ! -f "$IP_MAPPING_CONF" ]]; then
        error "Nginx 配置文件不存在: $IP_MAPPING_CONF"
        ((issues++))
    fi
    
    # 检查数据库文件
    if [[ ! -f "$MAPPING_DB" ]]; then
        error "映射数据库不存在: $MAPPING_DB"
        ((issues++))
    else
        # 验证 JSON 格式
        if ! jq empty "$MAPPING_DB" 2>/dev/null; then
            error "映射数据库 JSON 格式无效"
            ((issues++))
        fi
    fi
    
    # 检查 Nginx 配置
    if ! nginx -t 2>/dev/null; then
        error "Nginx 配置验证失败"
        ((issues++))
    fi
    
    # 检查服务状态
    if ! systemctl is-active nginx >/dev/null 2>&1; then
        error "Nginx 服务未运行"
        ((issues++))
    fi
    
    if [[ $issues -eq 0 ]]; then
        log "健康检查通过，所有组件正常"
        return 0
    else
        error "健康检查发现 $issues 个问题"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
YoungsCoolPlay UI IP 映射管理脚本

用法: $0 <命令> [参数...]

命令:
  add <IP> <账号ID> [账号类型] [UUID]     添加 IP 映射
  remove <IP>                           删除 IP 映射
  query <IP>                            查询 IP 映射
  list [all|active|inactive]            列出映射
  import <CSV文件>                      从 CSV 导入映射
  export <CSV文件>                      导出映射到 CSV
  generate                              重新生成 Nginx 配置
  stats                                 显示统计信息
  cleanup [天数]                        清理过期映射（默认30天）
  health                                健康检查
  help                                  显示此帮助信息

示例:
  $0 add 192.168.1.100 user001 premium
  $0 remove 192.168.1.100
  $0 query 192.168.1.100
  $0 list active
  $0 import mappings.csv
  $0 export backup.csv
  $0 cleanup 7
  $0 health

账号类型:
  - standard: 标准用户
  - premium: 高级用户
  - business: 企业用户
  - office: 办公用户
  - home: 家庭用户
  - education: 教育用户
  - mobile: 移动用户
  - international: 国际用户

EOF
}

# 主函数
main() {
    # 检查是否以 root 运行
    if [[ $EUID -ne 0 ]]; then
        error "此脚本需要 root 权限运行"
        exit 1
    fi
    
    # 检查依赖
    check_dependencies
    
    # 创建目录
    create_directories
    
    # 初始化数据库
    init_mapping_db
    
    # 解析命令
    case "${1:-help}" in
        "add")
            if [[ $# -lt 3 ]]; then
                error "add 命令需要至少 2 个参数: IP 和账号ID"
                show_help
                exit 1
            fi
            add_mapping "$2" "$3" "${4:-standard}" "${5:-}"
            ;;
        "remove")
            if [[ $# -lt 2 ]]; then
                error "remove 命令需要 IP 参数"
                exit 1
            fi
            remove_mapping "$2"
            ;;
        "query")
            if [[ $# -lt 2 ]]; then
                error "query 命令需要 IP 参数"
                exit 1
            fi
            query_mapping "$2"
            ;;
        "list")
            list_mappings "${2:-all}"
            ;;
        "import")
            if [[ $# -lt 2 ]]; then
                error "import 命令需要 CSV 文件路径"
                exit 1
            fi
            import_mappings "$2"
            ;;
        "export")
            if [[ $# -lt 2 ]]; then
                error "export 命令需要 CSV 文件路径"
                exit 1
            fi
            export_mappings "$2"
            ;;
        "generate")
            generate_nginx_config
            ;;
        "stats")
            show_statistics
            ;;
        "cleanup")
            cleanup_mappings "${2:-30}"
            ;;
        "health")
            health_check
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# 执行主函数
main "$@"