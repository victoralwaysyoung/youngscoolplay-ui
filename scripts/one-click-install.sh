#!/bin/bash

# YoungsCoolPlay UI 一键安装脚本
# 使用方法: bash <(curl -Ls https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay-ui/main/scripts/one-click-install.sh)

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

# 项目配置
REPO_OWNER="victoralwaysyoung"
REPO_NAME="youngscoolplay-ui"
APP_NAME="youngscoolplay-ui"
SERVICE_NAME="youngscoolplay-ui"
INSTALL_DIR="/usr/local/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
LOG_DIR="/var/log/${APP_NAME}"
WEB_DIR="/var/lib/${APP_NAME}/web"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${PLAIN} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${PLAIN} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${PLAIN} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${PLAIN} $1"
}

# 显示横幅
show_banner() {
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    YoungsCoolPlay UI                         ║
║                   一键安装部署脚本                            ║
║                                                              ║
║  GitHub: https://github.com/victoralwaysyoung/youngscoolplay-ui  ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${PLAIN}"
}

# 检查 root 权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限运行"
        log_info "请使用: sudo bash <(curl -Ls https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay-ui/main/scripts/one-click-install.sh)"
        exit 1
    fi
}

# 检测系统
detect_system() {
    log_info "检测系统环境..."
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    elif [[ -f /usr/lib/os-release ]]; then
        source /usr/lib/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        log_error "无法检测系统类型"
        exit 1
    fi
    
    log_success "检测到系统: $OS $VER"
}

# 检测架构
detect_arch() {
    case "$(uname -m)" in
        x86_64|x64|amd64) ARCH='amd64' ;;
        i*86|x86) ARCH='386' ;;
        armv8*|armv8|arm64|aarch64) ARCH='arm64' ;;
        armv7*|armv7|arm) ARCH='armv7' ;;
        armv6*|armv6) ARCH='armv6' ;;
        armv5*|armv5) ARCH='armv5' ;;
        s390x) ARCH='s390x' ;;
        *) 
            log_error "不支持的 CPU 架构: $(uname -m)"
            exit 1
            ;;
    esac
    
    log_success "检测到架构: $ARCH"
}

# 安装依赖
install_dependencies() {
    log_info "安装系统依赖..."
    
    case "${OS}" in
        ubuntu|debian|armbian)
            apt-get update -qq
            apt-get install -y -qq curl wget unzip tar systemd
            ;;
        centos|rhel|almalinux|rocky|ol)
            yum update -y -q
            yum install -y -q curl wget unzip tar systemd
            ;;
        fedora|amzn)
            dnf update -y -q
            dnf install -y -q curl wget unzip tar systemd
            ;;
        arch|manjaro)
            pacman -Syu --noconfirm
            pacman -S --noconfirm curl wget unzip tar systemd
            ;;
        alpine)
            apk update
            apk add curl wget unzip tar openrc
            ;;
        *)
            log_warning "未知系统类型，尝试使用 apt 安装依赖"
            apt-get update -qq
            apt-get install -y -qq curl wget unzip tar systemd
            ;;
    esac
    
    log_success "依赖安装完成"
}

# 获取最新版本
get_latest_version() {
    log_info "获取最新版本信息..."
    
    local api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
    VERSION=$(curl -s "$api_url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ -z "$VERSION" ]]; then
        log_error "无法获取最新版本信息，可能是网络问题或 GitHub API 限制"
        log_info "尝试使用默认版本: v1.0.0"
        VERSION="v1.0.0"
    fi
    
    log_success "获取到版本: $VERSION"
}

# 下载安装包
download_package() {
    log_info "下载安装包..."
    
    local download_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/${APP_NAME}-production.zip"
    local temp_dir="/tmp/${APP_NAME}-install"
    
    # 创建临时目录
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # 下载文件
    log_info "下载地址: $download_url"
    if ! wget -q --show-progress "$download_url" -O "${APP_NAME}.zip"; then
        log_error "下载失败，请检查网络连接或版本是否存在"
        exit 1
    fi
    
    # 解压文件
    log_info "解压安装包..."
    
    # 显示压缩包信息
    log_info "压缩包信息:"
    unzip -l "${APP_NAME}.zip" | head -20
    
    # 解压文件（显示详细信息）
    log_info "开始解压..."
    unzip -o "${APP_NAME}.zip"
    local unzip_exit_code=$?
    
    log_info "unzip 命令退出码: $unzip_exit_code"
    
    log_info "解压完成，检查目录结构:"
    ls -la
    
    # 检查目录是否存在（更宽松的检查）
    if [[ -d "${APP_NAME}-production" ]]; then
        log_success "找到安装目录: ${APP_NAME}-production"
        cd "${APP_NAME}-production"
    elif [[ $unzip_exit_code -eq 1 ]] && [[ -d "${APP_NAME}-production" ]]; then
        # unzip 退出码为 1 通常表示警告（如路径分隔符），但文件已成功解压
        log_warning "unzip 有警告但解压成功，继续安装..."
        cd "${APP_NAME}-production"
    else
        log_error "解压失败，找不到安装目录 ${APP_NAME}-production"
        log_info "当前目录内容:"
        ls -la
        log_info "尝试查找可能的目录:"
        find . -type d -name "*${APP_NAME}*" -o -name "*production*" 2>/dev/null || true
        
        # 如果 unzip 退出码不是 0，显示错误信息
        if [[ $unzip_exit_code -ne 0 ]]; then
            log_error "unzip 命令失败，退出码: $unzip_exit_code"
        fi
        exit 1
    fi
    
    log_success "安装包下载并解压完成"
}

# 停止现有服务
stop_existing_service() {
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        log_info "停止现有服务..."
        systemctl stop "$SERVICE_NAME"
        log_success "现有服务已停止"
    fi
}

# 备份现有配置
backup_existing_config() {
    if [[ -d "$CONFIG_DIR" ]]; then
        local backup_dir="/tmp/${APP_NAME}-backup-$(date +%Y%m%d-%H%M%S)"
        log_info "备份现有配置到: $backup_dir"
        cp -r "$CONFIG_DIR" "$backup_dir"
        log_success "配置备份完成"
    fi
}

# 安装应用
install_application() {
    log_info "安装应用文件..."
    
    # 创建目录
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$WEB_DIR"
    
    # 复制二进制文件
    if [[ -f "${APP_NAME}" ]]; then
        cp "${APP_NAME}" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/${APP_NAME}"
        log_success "二进制文件安装完成"
    else
        log_error "未找到二进制文件"
        exit 1
    fi
    
    # 复制 Web 资源
    if [[ -d "web" ]]; then
        cp -r web/* "$WEB_DIR/"
        log_success "Web 资源安装完成"
    fi
    
    # 复制 bin 目录（如果存在）
    if [[ -d "bin" ]]; then
        cp -r bin/* "$CONFIG_DIR/"
        chmod +x "$CONFIG_DIR"/* 2>/dev/null || true
        log_success "Bin 文件安装完成"
    fi
}

# 创建系统服务
create_systemd_service() {
    log_info "创建系统服务..."
    
    cat > "/etc/systemd/system/${SERVICE_NAME}.service" << EOF
[Unit]
Description=YoungsCoolPlay UI - Advanced Xray Panel
Documentation=https://github.com/${REPO_OWNER}/${REPO_NAME}
After=network.target nss-lookup.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/${APP_NAME}
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30
Restart=always
RestartSec=10
StartLimitInterval=60
StartLimitBurst=3

# 安全设置
NoNewPrivileges=false
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${INSTALL_DIR} ${CONFIG_DIR} ${LOG_DIR} ${WEB_DIR}

# 资源限制
LimitNOFILE=65536
LimitNPROC=32768

# 环境变量
Environment=GIN_MODE=release

# 日志设置
StandardOutput=append:${LOG_DIR}/app.log
StandardError=append:${LOG_DIR}/error.log
SyslogIdentifier=${SERVICE_NAME}

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载 systemd
    systemctl daemon-reload
    log_success "系统服务创建完成"
}

# 生成随机字符串
generate_random_string() {
    local length=${1:-10}
    LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1
}

# 配置应用
configure_application() {
    log_info "配置应用..."
    
    # 生成随机凭据
    local username=$(generate_random_string 10)
    local password=$(generate_random_string 12)
    local web_path=$(generate_random_string 15)
    local port=$(shuf -i 10000-65000 -n 1)
    
    # 获取服务器 IP
    local server_ip
    local ip_services=(
        "https://api4.ipify.org"
        "https://ipv4.icanhazip.com"
        "https://v4.api.ipinfo.io/ip"
        "https://ipv4.myexternalip.com/raw"
        "https://4.ident.me"
    )
    
    for service in "${ip_services[@]}"; do
        server_ip=$(curl -s --max-time 5 "$service" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "$server_ip" ]]; then
            break
        fi
    done
    
    [[ -z "$server_ip" ]] && server_ip="YOUR_SERVER_IP"
    
    # 显示配置信息
    echo
    log_success "应用配置完成！"
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${PLAIN}"
    echo -e "${GREEN}║                        登录信息                              ║${PLAIN}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${PLAIN}"
    echo -e "${GREEN}║${PLAIN} 访问地址: ${BLUE}http://${server_ip}:${port}/${web_path}${PLAIN}${GREEN}                    ║${PLAIN}"
    echo -e "${GREEN}║${PLAIN} 用户名:   ${YELLOW}${username}${PLAIN}${GREEN}                                        ║${PLAIN}"
    echo -e "${GREEN}║${PLAIN} 密码:     ${YELLOW}${password}${PLAIN}${GREEN}                                      ║${PLAIN}"
    echo -e "${GREEN}║${PLAIN} 端口:     ${YELLOW}${port}${PLAIN}${GREEN}                                           ║${PLAIN}"
    echo -e "${GREEN}║${PLAIN} Web路径:  ${YELLOW}${web_path}${PLAIN}${GREEN}                                   ║${PLAIN}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${PLAIN}"
    echo
    
    # 保存配置到文件
    cat > "${CONFIG_DIR}/install-info.txt" << EOF
YoungsCoolPlay UI 安装信息
安装时间: $(date)
版本: ${VERSION}

登录信息:
访问地址: http://${server_ip}:${port}/${web_path}
用户名: ${username}
密码: ${password}
端口: ${port}
Web路径: ${web_path}

管理命令:
查看状态: systemctl status ${SERVICE_NAME}
启动服务: systemctl start ${SERVICE_NAME}
停止服务: systemctl stop ${SERVICE_NAME}
重启服务: systemctl restart ${SERVICE_NAME}
查看日志: journalctl -u ${SERVICE_NAME} -f
EOF
    
    log_success "配置信息已保存到: ${CONFIG_DIR}/install-info.txt"
}

# 启动服务
start_service() {
    log_info "启动服务..."
    
    # 启用并启动服务
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"
    
    # 等待服务启动
    sleep 3
    
    # 检查服务状态
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_success "服务启动成功"
    else
        log_error "服务启动失败"
        log_info "查看详细错误信息: journalctl -u $SERVICE_NAME -n 20"
        exit 1
    fi
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    
    # 检查并配置 UFW
    if command -v ufw >/dev/null 2>&1; then
        ufw allow 54321/tcp comment "YoungsCoolPlay UI"
        log_success "UFW 防火墙规则已添加"
    fi
    
    # 检查并配置 firewalld
    if command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=54321/tcp
        firewall-cmd --reload
        log_success "firewalld 防火墙规则已添加"
    fi
    
    # 检查并配置 iptables
    if command -v iptables >/dev/null 2>&1 && ! command -v ufw >/dev/null 2>&1 && ! command -v firewall-cmd >/dev/null 2>&1; then
        iptables -I INPUT -p tcp --dport 54321 -j ACCEPT
        # 尝试保存 iptables 规则
        if command -v iptables-save >/dev/null 2>&1; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        fi
        log_success "iptables 防火墙规则已添加"
    fi
}

# 显示完成信息
show_completion_info() {
    echo
    log_success "YoungsCoolPlay UI 安装完成！"
    echo
    log_info "管理命令:"
    echo -e "  ${BLUE}systemctl status ${SERVICE_NAME}${PLAIN}     - 查看服务状态"
    echo -e "  ${BLUE}systemctl restart ${SERVICE_NAME}${PLAIN}    - 重启服务"
    echo -e "  ${BLUE}systemctl stop ${SERVICE_NAME}${PLAIN}       - 停止服务"
    echo -e "  ${BLUE}systemctl start ${SERVICE_NAME}${PLAIN}      - 启动服务"
    echo -e "  ${BLUE}journalctl -u ${SERVICE_NAME} -f${PLAIN}     - 查看实时日志"
    echo
    log_info "重要文件位置:"
    echo -e "  ${BLUE}应用目录:${PLAIN} ${INSTALL_DIR}"
    echo -e "  ${BLUE}配置目录:${PLAIN} ${CONFIG_DIR}"
    echo -e "  ${BLUE}日志目录:${PLAIN} ${LOG_DIR}"
    echo -e "  ${BLUE}Web目录:${PLAIN}  ${WEB_DIR}"
    echo -e "  ${BLUE}安装信息:${PLAIN} ${CONFIG_DIR}/install-info.txt"
    echo
    log_warning "安全提醒:"
    echo -e "  ${YELLOW}1. 请立即登录面板并修改默认密码${PLAIN}"
    echo -e "  ${YELLOW}2. 建议启用双因素认证${PLAIN}"
    echo -e "  ${YELLOW}3. 定期备份配置文件${PLAIN}"
    echo -e "  ${YELLOW}4. 监控服务器资源使用情况${PLAIN}"
    echo
}

# 清理临时文件
cleanup() {
    log_info "清理临时文件..."
    rm -rf "/tmp/${APP_NAME}-install" 2>/dev/null || true
    log_success "清理完成"
}

# 主函数
main() {
    show_banner
    check_root
    detect_system
    detect_arch
    install_dependencies
    get_latest_version
    download_package
    stop_existing_service
    backup_existing_config
    install_application
    create_systemd_service
    configure_application
    start_service
    configure_firewall
    show_completion_info
    cleanup
}

# 错误处理
trap 'log_error "安装过程中发生错误，正在清理..."; cleanup; exit 1' ERR

# 执行主函数
main "$@"