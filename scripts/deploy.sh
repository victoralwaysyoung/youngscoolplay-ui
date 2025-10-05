#!/bin/bash

# YoungsCoolPlay UI 自动化部署脚本
# 支持从 GitHub 自动拉取代码并部署到生产环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置变量
APP_NAME="youngscoolplay-ui"
APP_DIR="/opt/${APP_NAME}"
LOG_DIR="/var/log/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
SERVICE_NAME="${APP_NAME}"
BACKUP_DIR="/opt/${APP_NAME}/backups"
GITHUB_REPO="https://github.com/yourusername/youngscoolplay-ui.git"
BRANCH="main"
BUILD_TIMEOUT=300
HEALTH_CHECK_TIMEOUT=60

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
    fi
}

# 错误处理
error_exit() {
    log_error "$1"
    cleanup_on_error
    exit 1
}

# 错误清理
cleanup_on_error() {
    log_warning "部署失败，开始清理..."
    
    # 如果有备份，尝试回滚
    if [[ -f "${BACKUP_DIR}/latest/youngscoolplay-ui" ]]; then
        log_info "尝试回滚到上一个版本..."
        rollback_deployment
    fi
}

# 检查权限
check_permissions() {
    log_info "检查部署权限..."
    
    if [[ ! -w "$APP_DIR" ]]; then
        error_exit "没有应用目录写权限: $APP_DIR"
    fi
    
    if ! sudo -n systemctl status >/dev/null 2>&1; then
        error_exit "需要 sudo 权限来管理系统服务"
    fi
    
    log_success "权限检查通过"
}

# 检查依赖
check_dependencies() {
    log_info "检查部署依赖..."
    
    local deps=("git" "go" "systemctl" "nginx")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error_exit "缺少依赖: ${missing_deps[*]}"
    fi
    
    # 检查 Go 版本
    local go_version=$(go version | awk '{print $3}' | sed 's/go//')
    if [[ $(echo -e "1.21\n$go_version" | sort -V | head -n1) != "1.21" ]]; then
        error_exit "Go 版本过低，需要 >= 1.21，当前版本: $go_version"
    fi
    
    log_success "依赖检查通过"
}

# 创建必要目录
create_directories() {
    log_info "创建必要目录..."
    
    sudo mkdir -p "$APP_DIR" "$LOG_DIR" "$CONFIG_DIR" "$BACKUP_DIR"
    sudo chown -R $USER:$USER "$APP_DIR" "$LOG_DIR" "$BACKUP_DIR"
    
    log_success "目录创建完成"
}

# 备份当前版本
backup_current_version() {
    log_info "备份当前版本..."
    
    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/${backup_timestamp}"
    
    mkdir -p "$backup_path"
    
    # 备份可执行文件
    if [[ -f "${APP_DIR}/youngscoolplay-ui" ]]; then
        cp "${APP_DIR}/youngscoolplay-ui" "${backup_path}/"
        log_debug "备份可执行文件到: ${backup_path}/youngscoolplay-ui"
    fi
    
    # 备份配置文件
    if [[ -d "${APP_DIR}/web" ]]; then
        cp -r "${APP_DIR}/web" "${backup_path}/"
        log_debug "备份 web 目录到: ${backup_path}/web"
    fi
    
    # 创建最新备份链接
    ln -sfn "$backup_path" "${BACKUP_DIR}/latest"
    
    # 清理旧备份（保留最近10个）
    cd "$BACKUP_DIR"
    ls -t | grep -E '^[0-9]{8}_[0-9]{6}$' | tail -n +11 | xargs -r rm -rf
    
    log_success "备份完成: $backup_path"
}

# 拉取最新代码
pull_latest_code() {
    log_info "拉取最新代码..."
    
    cd "$APP_DIR"
    
    # 检查是否为 Git 仓库
    if [[ ! -d ".git" ]]; then
        log_info "初始化 Git 仓库..."
        git clone "$GITHUB_REPO" .
    else
        # 检查远程仓库
        local current_remote=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$current_remote" != "$GITHUB_REPO" ]]; then
            log_warning "更新远程仓库地址: $GITHUB_REPO"
            git remote set-url origin "$GITHUB_REPO"
        fi
        
        # 拉取最新代码
        git fetch origin
        
        # 检查是否有本地更改
        if ! git diff --quiet HEAD; then
            log_warning "检测到本地更改，将被重置"
            git reset --hard HEAD
        fi
        
        # 切换到指定分支并拉取
        git checkout "$BRANCH"
        git pull origin "$BRANCH"
    fi
    
    # 获取当前提交信息
    local commit_hash=$(git rev-parse --short HEAD)
    local commit_message=$(git log -1 --pretty=format:"%s")
    
    log_success "代码拉取完成"
    log_info "当前提交: $commit_hash - $commit_message"
}

# 构建应用
build_application() {
    log_info "构建应用..."
    
    cd "$APP_DIR"
    
    # 清理模块缓存
    go clean -modcache || true
    
    # 下载依赖
    log_info "下载 Go 模块依赖..."
    timeout $BUILD_TIMEOUT go mod download
    
    # 整理依赖
    go mod tidy
    
    # 验证模块
    go mod verify
    
    # 构建应用
    log_info "编译应用程序..."
    local build_flags="-ldflags='-w -s -X main.version=$(git describe --tags --always) -X main.buildTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
    
    timeout $BUILD_TIMEOUT go build $build_flags -o "${APP_NAME}.new" .
    
    # 验证构建结果
    if [[ ! -f "${APP_NAME}.new" ]]; then
        error_exit "构建失败：可执行文件不存在"
    fi
    
    # 检查可执行文件
    if ! ./"${APP_NAME}.new" --version &>/dev/null; then
        log_warning "无法验证可执行文件版本，但构建成功"
    fi
    
    log_success "应用构建完成"
}

# 停止服务
stop_service() {
    log_info "停止服务..."
    
    if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        sudo systemctl stop "$SERVICE_NAME"
        
        # 等待服务完全停止
        local timeout=30
        while sudo systemctl is-active --quiet "$SERVICE_NAME" && [[ $timeout -gt 0 ]]; do
            sleep 1
            ((timeout--))
        done
        
        if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
            log_warning "服务未能正常停止，强制终止"
            sudo systemctl kill "$SERVICE_NAME"
            sleep 2
        fi
    fi
    
    log_success "服务已停止"
}

# 部署新版本
deploy_new_version() {
    log_info "部署新版本..."
    
    cd "$APP_DIR"
    
    # 移动新版本到位
    if [[ -f "$APP_NAME" ]]; then
        mv "$APP_NAME" "${APP_NAME}.old"
    fi
    
    mv "${APP_NAME}.new" "$APP_NAME"
    chmod +x "$APP_NAME"
    
    # 更新配置文件权限
    find web -type f -name "*.html" -exec chmod 644 {} \;
    find web -type f -name "*.js" -exec chmod 644 {} \;
    find web -type f -name "*.css" -exec chmod 644 {} \;
    
    log_success "新版本部署完成"
}

# 创建系统服务
create_systemd_service() {
    log_info "创建系统服务..."
    
    sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" > /dev/null <<EOF
[Unit]
Description=YoungsCoolPlay UI Service
Documentation=https://github.com/yourusername/youngscoolplay-ui
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/$APP_NAME
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30
Restart=always
RestartSec=10
StartLimitInterval=60
StartLimitBurst=3

# 安全设置
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR $LOG_DIR $CONFIG_DIR

# 资源限制
LimitNOFILE=65536
LimitNPROC=32768

# 环境变量
Environment=GIN_MODE=release
Environment=LOG_LEVEL=info

# 日志设置
StandardOutput=append:$LOG_DIR/app.log
StandardError=append:$LOG_DIR/error.log
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载 systemd
    sudo systemctl daemon-reload
    
    log_success "系统服务创建完成"
}

# 启动服务
start_service() {
    log_info "启动服务..."
    
    # 启用服务
    sudo systemctl enable "$SERVICE_NAME"
    
    # 启动服务
    sudo systemctl start "$SERVICE_NAME"
    
    log_success "服务启动完成"
}

# 健康检查
health_check() {
    log_info "执行健康检查..."
    
    local timeout=$HEALTH_CHECK_TIMEOUT
    local check_interval=2
    local port=2053
    
    while [[ $timeout -gt 0 ]]; do
        if curl -f -s "http://localhost:$port/health" >/dev/null 2>&1; then
            log_success "健康检查通过"
            return 0
        fi
        
        sleep $check_interval
        ((timeout -= check_interval))
        log_debug "等待服务启动... 剩余时间: ${timeout}s"
    done
    
    log_error "健康检查失败"
    
    # 显示服务状态和日志
    sudo systemctl status "$SERVICE_NAME" --no-pager
    echo
    log_info "最近的错误日志:"
    tail -20 "$LOG_DIR/error.log" 2>/dev/null || echo "无错误日志"
    
    return 1
}

# 回滚部署
rollback_deployment() {
    log_warning "开始回滚部署..."
    
    if [[ ! -f "${BACKUP_DIR}/latest/youngscoolplay-ui" ]]; then
        error_exit "没有可用的备份版本进行回滚"
    fi
    
    # 停止服务
    stop_service
    
    # 恢复备份版本
    cp "${BACKUP_DIR}/latest/youngscoolplay-ui" "${APP_DIR}/youngscoolplay-ui"
    chmod +x "${APP_DIR}/youngscoolplay-ui"
    
    # 恢复 web 目录
    if [[ -d "${BACKUP_DIR}/latest/web" ]]; then
        rm -rf "${APP_DIR}/web"
        cp -r "${BACKUP_DIR}/latest/web" "${APP_DIR}/"
    fi
    
    # 启动服务
    start_service
    
    # 健康检查
    if health_check; then
        log_success "回滚完成，服务运行正常"
    else
        error_exit "回滚后服务仍然异常"
    fi
}

# 更新 Nginx 配置
update_nginx_config() {
    log_info "更新 Nginx 配置..."
    
    # 测试 Nginx 配置
    if ! sudo nginx -t; then
        log_warning "Nginx 配置测试失败，跳过重载"
        return 1
    fi
    
    # 重载 Nginx
    sudo systemctl reload nginx
    
    log_success "Nginx 配置更新完成"
}

# 清理旧文件
cleanup_old_files() {
    log_info "清理旧文件..."
    
    cd "$APP_DIR"
    
    # 删除旧的可执行文件
    rm -f "${APP_NAME}.old"
    
    # 清理临时文件
    find . -name "*.tmp" -type f -delete 2>/dev/null || true
    find . -name "*.log.*" -type f -mtime +7 -delete 2>/dev/null || true
    
    log_success "文件清理完成"
}

# 显示部署信息
show_deployment_info() {
    log_success "部署完成！"
    echo
    log_info "部署信息:"
    echo "  - 应用名称: $APP_NAME"
    echo "  - 应用目录: $APP_DIR"
    echo "  - 服务状态: $(sudo systemctl is-active $SERVICE_NAME)"
    echo "  - 进程 PID: $(sudo systemctl show -p MainPID $SERVICE_NAME | cut -d= -f2)"
    echo "  - 监听端口: 2053 (主服务), 2096 (子服务)"
    echo
    
    # 显示版本信息
    if [[ -f "${APP_DIR}/${APP_NAME}" ]]; then
        local version_info=$(./"${APP_DIR}/${APP_NAME}" --version 2>/dev/null || echo "未知版本")
        echo "  - 应用版本: $version_info"
    fi
    
    # 显示 Git 信息
    cd "$APP_DIR"
    local commit_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "未知")
    local commit_date=$(git log -1 --format="%ci" 2>/dev/null || echo "未知")
    echo "  - Git 提交: $commit_hash"
    echo "  - 提交时间: $commit_date"
    echo
    
    log_info "访问地址:"
    echo "  - 本地访问: http://localhost:2053"
    echo "  - 外部访问: http://$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP"):80"
    echo
    
    log_info "日志文件:"
    echo "  - 应用日志: $LOG_DIR/app.log"
    echo "  - 错误日志: $LOG_DIR/error.log"
    echo "  - Nginx 日志: /var/log/nginx/youngscoolplay-ui.*.log"
    echo
    
    log_info "管理命令:"
    echo "  - 查看状态: sudo systemctl status $SERVICE_NAME"
    echo "  - 重启服务: sudo systemctl restart $SERVICE_NAME"
    echo "  - 查看日志: sudo journalctl -u $SERVICE_NAME -f"
    echo "  - 回滚版本: $0 --rollback"
}

# 显示帮助信息
show_help() {
    cat <<EOF
YoungsCoolPlay UI 自动化部署脚本

用法: $0 [选项]

选项:
  -h, --help              显示此帮助信息
  -r, --rollback          回滚到上一个版本
  -c, --check             仅执行健康检查
  -b, --branch BRANCH     指定部署分支 (默认: main)
  --repo URL              指定 Git 仓库地址
  --debug                 启用调试模式
  --skip-backup           跳过备份步骤
  --skip-health-check     跳过健康检查

示例:
  $0                      # 标准部署
  $0 --branch develop     # 部署 develop 分支
  $0 --rollback           # 回滚到上一个版本
  $0 --check              # 仅检查服务健康状态

EOF
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -r|--rollback)
                rollback_deployment
                exit 0
                ;;
            -c|--check)
                health_check
                exit $?
                ;;
            -b|--branch)
                BRANCH="$2"
                shift 2
                ;;
            --repo)
                GITHUB_REPO="$2"
                shift 2
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --skip-health-check)
                SKIP_HEALTH_CHECK=true
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 主部署流程
main_deployment() {
    log_info "开始 YoungsCoolPlay UI 自动化部署..."
    log_info "目标分支: $BRANCH"
    log_info "Git 仓库: $GITHUB_REPO"
    echo
    
    # 执行部署步骤
    check_permissions
    check_dependencies
    create_directories
    
    # 备份当前版本
    if [[ "${SKIP_BACKUP:-false}" != "true" ]]; then
        backup_current_version
    fi
    
    pull_latest_code
    build_application
    stop_service
    deploy_new_version
    create_systemd_service
    start_service
    
    # 健康检查
    if [[ "${SKIP_HEALTH_CHECK:-false}" != "true" ]]; then
        if ! health_check; then
            error_exit "健康检查失败，部署中止"
        fi
    fi
    
    update_nginx_config
    cleanup_old_files
    show_deployment_info
    
    log_success "部署流程完成！"
}

# 脚本入口点
main() {
    # 设置错误处理
    trap 'error_exit "脚本执行过程中发生错误"' ERR
    
    # 解析参数
    parse_arguments "$@"
    
    # 执行主流程
    main_deployment
}

# 执行主函数
main "$@"