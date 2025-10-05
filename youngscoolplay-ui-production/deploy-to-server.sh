#!/bin/bash

# YoungsCoolPlay UI 服务器部署脚本
# 使用方法: ./deploy-to-server.sh [server_ip] [username]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

# 配置变量
DEPLOYMENT_PACKAGE="youngscoolplay-ui-production.tar.gz"
REMOTE_DIR="/tmp/youngscoolplay-ui-deploy"
SERVICE_NAME="youngscoolplay-ui"

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

# 显示使用说明
show_usage() {
    echo "YoungsCoolPlay UI 服务器部署脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 <server_ip> <username>"
    echo ""
    echo "参数说明:"
    echo "  server_ip  - 目标服务器IP地址"
    echo "  username   - SSH登录用户名"
    echo ""
    echo "示例:"
    echo "  $0 192.168.1.100 root"
    echo "  $0 example.com ubuntu"
    echo ""
}

# 检查参数
check_parameters() {
    if [[ $# -lt 2 ]]; then
        log_error "参数不足"
        show_usage
        exit 1
    fi
    
    SERVER_IP="$1"
    USERNAME="$2"
    
    log_info "目标服务器: $SERVER_IP"
    log_info "登录用户: $USERNAME"
}

# 检查本地环境
check_local_environment() {
    log_info "检查本地环境..."
    
    # 检查必要命令
    local commands=("ssh" "scp" "tar")
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "未找到命令: $cmd"
            exit 1
        fi
    done
    
    # 检查部署包
    if [[ ! -f "$DEPLOYMENT_PACKAGE" ]]; then
        log_warning "未找到部署包，正在创建..."
        create_deployment_package
    fi
    
    log_success "本地环境检查完成"
}

# 创建部署包
create_deployment_package() {
    log_info "创建部署包..."
    
    if [[ ! -d "youngscoolplay-ui-production" ]]; then
        log_error "未找到部署目录: youngscoolplay-ui-production"
        exit 1
    fi
    
    tar -czf "$DEPLOYMENT_PACKAGE" -C . youngscoolplay-ui-production
    log_success "部署包创建完成: $DEPLOYMENT_PACKAGE"
}

# 测试SSH连接
test_ssh_connection() {
    log_info "测试SSH连接..."
    
    if ssh -o ConnectTimeout=10 -o BatchMode=yes "$USERNAME@$SERVER_IP" "echo 'SSH连接测试成功'" >/dev/null 2>&1; then
        log_success "SSH连接正常"
    else
        log_error "SSH连接失败，请检查："
        echo "  1. 服务器IP地址是否正确"
        echo "  2. 用户名是否正确"
        echo "  3. SSH密钥是否已配置"
        echo "  4. 服务器SSH服务是否正常"
        exit 1
    fi
}

# 检查服务器环境
check_server_environment() {
    log_info "检查服务器环境..."
    
    # 检查操作系统
    local os_info
    os_info=$(ssh "$USERNAME@$SERVER_IP" "cat /etc/os-release | grep '^ID=' | cut -d'=' -f2 | tr -d '\"'")
    log_info "服务器操作系统: $os_info"
    
    # 检查架构
    local arch
    arch=$(ssh "$USERNAME@$SERVER_IP" "uname -m")
    log_info "服务器架构: $arch"
    
    # 检查权限
    if ssh "$USERNAME@$SERVER_IP" "sudo -n true" >/dev/null 2>&1; then
        log_success "具有sudo权限"
    else
        log_warning "可能需要输入sudo密码"
    fi
    
    # 检查端口占用
    local port_check
    port_check=$(ssh "$USERNAME@$SERVER_IP" "netstat -tlnp 2>/dev/null | grep ':54321 ' || echo 'free'")
    if [[ "$port_check" == "free" ]]; then
        log_success "端口54321可用"
    else
        log_warning "端口54321可能被占用: $port_check"
    fi
}

# 上传部署包
upload_deployment_package() {
    log_info "上传部署包到服务器..."
    
    # 创建远程目录
    ssh "$USERNAME@$SERVER_IP" "mkdir -p $REMOTE_DIR"
    
    # 上传文件
    if scp "$DEPLOYMENT_PACKAGE" "$USERNAME@$SERVER_IP:$REMOTE_DIR/"; then
        log_success "部署包上传完成"
    else
        log_error "部署包上传失败"
        exit 1
    fi
}

# 在服务器上解压和安装
install_on_server() {
    log_info "在服务器上安装应用..."
    
    ssh "$USERNAME@$SERVER_IP" << 'EOF'
set -e

# 进入部署目录
cd /tmp/youngscoolplay-ui-deploy

# 解压部署包
echo "解压部署包..."
tar -xzf youngscoolplay-ui-production.tar.gz
cd youngscoolplay-ui-production

# 检查安装脚本
if [[ -f "install.sh" ]]; then
    echo "运行安装脚本..."
    chmod +x install.sh
    sudo ./install.sh
elif [[ -f "one-click-install.sh" ]]; then
    echo "运行一键安装脚本..."
    chmod +x one-click-install.sh
    sudo ./one-click-install.sh
else
    echo "未找到安装脚本，进行手动安装..."
    
    # 手动安装步骤
    sudo mkdir -p /usr/local/youngscoolplay-ui
    sudo mkdir -p /etc/youngscoolplay-ui
    sudo mkdir -p /var/log/youngscoolplay-ui
    sudo mkdir -p /var/lib/youngscoolplay-ui/web
    
    # 复制文件
    sudo cp youngscoolplay-ui /usr/local/youngscoolplay-ui/
    sudo chmod +x /usr/local/youngscoolplay-ui/youngscoolplay-ui
    
    if [[ -d "web" ]]; then
        sudo cp -r web/* /var/lib/youngscoolplay-ui/web/
    fi
    
    if [[ -d "bin" ]]; then
        sudo cp -r bin/* /etc/youngscoolplay-ui/
        sudo chmod +x /etc/youngscoolplay-ui/* 2>/dev/null || true
    fi
    
    # 安装服务
    if [[ -f "youngscoolplay-ui.service" ]]; then
        sudo cp youngscoolplay-ui.service /etc/systemd/system/
        sudo systemctl daemon-reload
    fi
fi

echo "安装完成"
EOF
    
    log_success "服务器安装完成"
}

# 启动服务
start_service() {
    log_info "启动服务..."
    
    ssh "$USERNAME@$SERVER_IP" << 'EOF'
# 启用并启动服务
sudo systemctl enable youngscoolplay-ui 2>/dev/null || true
sudo systemctl start youngscoolplay-ui

# 等待服务启动
sleep 3

# 检查服务状态
if sudo systemctl is-active --quiet youngscoolplay-ui; then
    echo "服务启动成功"
    sudo systemctl status youngscoolplay-ui --no-pager -l
else
    echo "服务启动失败，查看错误信息："
    sudo journalctl -u youngscoolplay-ui -n 20 --no-pager
    exit 1
fi
EOF
    
    log_success "服务启动成功"
}

# 显示部署结果
show_deployment_result() {
    log_success "部署完成！"
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${PLAIN}"
    echo -e "${GREEN}║                        部署信息                              ║${PLAIN}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${PLAIN}"
    echo -e "${GREEN}║${PLAIN} 服务器地址: ${BLUE}$SERVER_IP${PLAIN}${GREEN}                                    ║${PLAIN}"
    echo -e "${GREEN}║${PLAIN} 访问地址:   ${BLUE}http://$SERVER_IP:54321${PLAIN}${GREEN}                        ║${PLAIN}"
    echo -e "${GREEN}║${PLAIN} 服务状态:   ${BLUE}systemctl status youngscoolplay-ui${PLAIN}${GREEN}            ║${PLAIN}"
    echo -e "${GREEN}║${PLAIN} 查看日志:   ${BLUE}journalctl -u youngscoolplay-ui -f${PLAIN}${GREEN}            ║${PLAIN}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${PLAIN}"
    echo ""
    
    log_info "管理命令："
    echo "  ssh $USERNAME@$SERVER_IP 'sudo systemctl status youngscoolplay-ui'"
    echo "  ssh $USERNAME@$SERVER_IP 'sudo systemctl restart youngscoolplay-ui'"
    echo "  ssh $USERNAME@$SERVER_IP 'sudo journalctl -u youngscoolplay-ui -f'"
    echo ""
    
    log_warning "安全提醒："
    echo "  1. 请立即登录Web界面并修改默认密码"
    echo "  2. 配置防火墙规则限制访问"
    echo "  3. 定期备份配置文件"
    echo ""
}

# 清理临时文件
cleanup() {
    log_info "清理临时文件..."
    
    ssh "$USERNAME@$SERVER_IP" "rm -rf $REMOTE_DIR" 2>/dev/null || true
    
    log_success "清理完成"
}

# 主函数
main() {
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                YoungsCoolPlay UI 服务器部署                  ║
║                     自动化部署脚本                           ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${PLAIN}"
    
    check_parameters "$@"
    check_local_environment
    test_ssh_connection
    check_server_environment
    upload_deployment_package
    install_on_server
    start_service
    show_deployment_result
    cleanup
}

# 错误处理
trap 'log_error "部署过程中发生错误"; cleanup; exit 1' ERR

# 执行主函数
main "$@"