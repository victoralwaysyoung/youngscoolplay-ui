#!/bin/bash

# Ubuntu 24 服务器环境准备脚本
# 用于自动化配置 YoungsCoolPlay UI 部署环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "请不要使用 root 用户运行此脚本"
        log_info "建议创建普通用户: sudo adduser youngscool"
        exit 1
    fi
}

# 检查系统版本
check_system() {
    log_info "检查系统版本..."
    
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法检测系统版本"
        exit 1
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        log_error "此脚本仅支持 Ubuntu 系统"
        exit 1
    fi
    
    if [[ "$VERSION_ID" != "24.04" && "$VERSION_ID" != "24.10" ]]; then
        log_warning "检测到 Ubuntu $VERSION_ID，建议使用 Ubuntu 24.04 LTS"
    fi
    
    log_success "系统检查通过: $PRETTY_NAME"
}

# 更新系统包
update_system() {
    log_info "更新系统包..."
    
    sudo apt update
    sudo apt upgrade -y
    
    log_success "系统包更新完成"
}

# 安装基础依赖
install_dependencies() {
    log_info "安装基础依赖..."
    
    sudo apt install -y \
        curl \
        wget \
        git \
        unzip \
        tar \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        htop \
        vim \
        nano \
        ufw \
        fail2ban \
        logrotate \
        supervisor \
        nginx
    
    log_success "基础依赖安装完成"
}

# 安装 Go 语言环境
install_go() {
    log_info "安装 Go 语言环境..."
    
    # 检查是否已安装 Go
    if command -v go &> /dev/null; then
        local go_version=$(go version | awk '{print $3}' | sed 's/go//')
        log_info "检测到已安装的 Go 版本: $go_version"
        
        # 检查版本是否满足要求 (>= 1.21)
        if [[ $(echo -e "1.21\n$go_version" | sort -V | head -n1) == "1.21" ]]; then
            log_success "Go 版本满足要求"
            return 0
        else
            log_warning "Go 版本过低，将升级到最新版本"
        fi
    fi
    
    # 下载并安装最新版本的 Go
    local go_version="1.21.5"
    local go_archive="go${go_version}.linux-amd64.tar.gz"
    
    cd /tmp
    wget -q "https://golang.org/dl/${go_archive}"
    
    # 移除旧版本
    sudo rm -rf /usr/local/go
    
    # 安装新版本
    sudo tar -C /usr/local -xzf "${go_archive}"
    
    # 配置环境变量
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        echo 'export GOPATH=$HOME/go' >> ~/.bashrc
        echo 'export GOBIN=$GOPATH/bin' >> ~/.bashrc
    fi
    
    # 立即生效
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export GOBIN=$GOPATH/bin
    
    # 创建 Go 工作目录
    mkdir -p $HOME/go/{bin,src,pkg}
    
    log_success "Go ${go_version} 安装完成"
    go version
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    
    # 启用 UFW
    sudo ufw --force enable
    
    # 默认策略
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # 允许 SSH
    sudo ufw allow ssh
    sudo ufw allow 22/tcp
    
    # 允许 HTTP/HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # 允许应用端口
    sudo ufw allow 2053/tcp  # YoungsCoolPlay UI
    sudo ufw allow 2096/tcp  # Sub service
    
    # 显示状态
    sudo ufw status verbose
    
    log_success "防火墙配置完成"
}

# 配置 Fail2Ban
configure_fail2ban() {
    log_info "配置 Fail2Ban..."
    
    # 创建自定义配置
    sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
EOF
    
    # 启动服务
    sudo systemctl enable fail2ban
    sudo systemctl restart fail2ban
    
    log_success "Fail2Ban 配置完成"
}

# 创建应用用户和目录
create_app_structure() {
    log_info "创建应用目录结构..."
    
    # 创建应用目录
    sudo mkdir -p /opt/youngscoolplay-ui
    sudo mkdir -p /var/log/youngscoolplay-ui
    sudo mkdir -p /etc/youngscoolplay-ui
    
    # 设置权限
    sudo chown -R $USER:$USER /opt/youngscoolplay-ui
    sudo chown -R $USER:$USER /var/log/youngscoolplay-ui
    sudo chown -R $USER:$USER /etc/youngscoolplay-ui
    
    # 创建配置目录
    mkdir -p ~/.config/youngscoolplay-ui
    
    log_success "应用目录结构创建完成"
}

# 配置 Git
configure_git() {
    log_info "配置 Git..."
    
    # 检查 Git 配置
    if ! git config --global user.name &> /dev/null; then
        read -p "请输入 Git 用户名: " git_username
        git config --global user.name "$git_username"
    fi
    
    if ! git config --global user.email &> /dev/null; then
        read -p "请输入 Git 邮箱: " git_email
        git config --global user.email "$git_email"
    fi
    
    # 配置 Git 默认分支
    git config --global init.defaultBranch main
    
    # 配置 Git 编辑器
    git config --global core.editor vim
    
    log_success "Git 配置完成"
    log_info "用户名: $(git config --global user.name)"
    log_info "邮箱: $(git config --global user.email)"
}

# 生成 SSH 密钥
generate_ssh_key() {
    log_info "检查 SSH 密钥..."
    
    if [[ ! -f ~/.ssh/id_ed25519 ]]; then
        log_info "生成 SSH 密钥..."
        
        read -p "请输入邮箱地址用于 SSH 密钥: " ssh_email
        ssh-keygen -t ed25519 -C "$ssh_email" -f ~/.ssh/id_ed25519 -N ""
        
        # 启动 ssh-agent 并添加密钥
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519
        
        log_success "SSH 密钥生成完成"
        log_info "公钥内容:"
        cat ~/.ssh/id_ed25519.pub
        log_warning "请将上述公钥添加到 GitHub SSH Keys 中"
    else
        log_success "SSH 密钥已存在"
    fi
}

# 配置 Nginx
configure_nginx() {
    log_info "配置 Nginx..."
    
    # 备份默认配置
    sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
    
    # 创建基础配置
    sudo tee /etc/nginx/sites-available/youngscoolplay-ui > /dev/null <<EOF
# YoungsCoolPlay UI Nginx 配置
upstream youngscoolplay_backend {
    least_conn;
    server 127.0.0.1:2053 max_fails=3 fail_timeout=30s;
    # 可以添加更多后端服务器实现负载均衡
    # server 127.0.0.1:2054 max_fails=3 fail_timeout=30s;
    # server 127.0.0.1:2055 max_fails=3 fail_timeout=30s;
}

# HTTP 服务器配置
server {
    listen 80;
    server_name _;
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # 日志配置
    access_log /var/log/nginx/youngscoolplay-ui.access.log;
    error_log /var/log/nginx/youngscoolplay-ui.error.log;
    
    # 限制请求大小
    client_max_body_size 10M;
    
    # 限制连接数
    limit_conn_zone \$binary_remote_addr zone=conn_limit_per_ip:10m;
    limit_req_zone \$binary_remote_addr zone=req_limit_per_ip:10m rate=10r/s;
    
    location / {
        limit_conn conn_limit_per_ip 10;
        limit_req zone=req_limit_per_ip burst=20 nodelay;
        
        proxy_pass http://youngscoolplay_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # 超时设置
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # 健康检查端点
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # 静态文件缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options nosniff;
    }
}
EOF
    
    # 启用站点
    sudo ln -sf /etc/nginx/sites-available/youngscoolplay-ui /etc/nginx/sites-enabled/
    
    # 移除默认站点
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # 测试配置
    sudo nginx -t
    
    # 启动服务
    sudo systemctl enable nginx
    sudo systemctl restart nginx
    
    log_success "Nginx 配置完成"
}

# 配置日志轮转
configure_logrotate() {
    log_info "配置日志轮转..."
    
    sudo tee /etc/logrotate.d/youngscoolplay-ui > /dev/null <<EOF
/var/log/youngscoolplay-ui/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 $USER $USER
    postrotate
        systemctl reload youngscoolplay-ui || true
    endscript
}
EOF
    
    log_success "日志轮转配置完成"
}

# 配置系统限制
configure_system_limits() {
    log_info "配置系统限制..."
    
    # 增加文件描述符限制
    sudo tee -a /etc/security/limits.conf > /dev/null <<EOF

# YoungsCoolPlay UI 系统限制
$USER soft nofile 65536
$USER hard nofile 65536
$USER soft nproc 32768
$USER hard nproc 32768
EOF
    
    # 配置内核参数
    sudo tee -a /etc/sysctl.conf > /dev/null <<EOF

# YoungsCoolPlay UI 网络优化
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_tw_buckets = 5000
EOF
    
    # 应用内核参数
    sudo sysctl -p
    
    log_success "系统限制配置完成"
}

# 创建部署脚本
create_deploy_script() {
    log_info "创建部署脚本..."
    
    tee /opt/youngscoolplay-ui/deploy.sh > /dev/null <<'EOF'
#!/bin/bash

# YoungsCoolPlay UI 部署脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 配置变量
APP_DIR="/opt/youngscoolplay-ui"
LOG_DIR="/var/log/youngscoolplay-ui"
SERVICE_NAME="youngscoolplay-ui"

# 进入应用目录
cd $APP_DIR

# 拉取最新代码
log_info "拉取最新代码..."
git pull origin main

# 构建应用
log_info "构建应用..."
go mod tidy
go build -o youngscoolplay-ui .

# 停止服务
log_info "停止服务..."
sudo systemctl stop $SERVICE_NAME || true

# 备份旧版本
if [[ -f youngscoolplay-ui.old ]]; then
    rm -f youngscoolplay-ui.old
fi
if [[ -f youngscoolplay-ui ]]; then
    mv youngscoolplay-ui youngscoolplay-ui.old
fi

# 移动新版本
mv youngscoolplay-ui $APP_DIR/

# 设置权限
chmod +x $APP_DIR/youngscoolplay-ui

# 启动服务
log_info "启动服务..."
sudo systemctl start $SERVICE_NAME
sudo systemctl enable $SERVICE_NAME

# 检查服务状态
sleep 5
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    log_success "部署完成，服务运行正常"
else
    log_error "服务启动失败"
    sudo systemctl status $SERVICE_NAME
    exit 1
fi

log_success "部署完成！"
EOF
    
    chmod +x /opt/youngscoolplay-ui/deploy.sh
    
    log_success "部署脚本创建完成"
}

# 显示完成信息
show_completion_info() {
    log_success "服务器环境准备完成！"
    echo
    log_info "环境信息:"
    echo "  - 系统版本: $(lsb_release -d | cut -f2)"
    echo "  - Go 版本: $(go version | awk '{print $3}')"
    echo "  - Git 版本: $(git --version | awk '{print $3}')"
    echo "  - Nginx 版本: $(nginx -v 2>&1 | awk '{print $3}')"
    echo
    log_info "目录结构:"
    echo "  - 应用目录: /opt/youngscoolplay-ui"
    echo "  - 日志目录: /var/log/youngscoolplay-ui"
    echo "  - 配置目录: /etc/youngscoolplay-ui"
    echo
    log_info "下一步操作:"
    echo "  1. 将 SSH 公钥添加到 GitHub"
    echo "  2. 克隆项目代码到 /opt/youngscoolplay-ui"
    echo "  3. 运行部署脚本进行首次部署"
    echo "  4. 配置 SSL 证书（可选）"
    echo
    log_warning "重要提醒:"
    echo "  - 请记录好服务器的 IP 地址和 SSH 端口"
    echo "  - 建议定期更新系统和依赖包"
    echo "  - 监控服务器资源使用情况"
}

# 主函数
main() {
    log_info "开始 Ubuntu 24 服务器环境准备..."
    
    check_root
    check_system
    update_system
    install_dependencies
    install_go
    configure_firewall
    configure_fail2ban
    create_app_structure
    configure_git
    generate_ssh_key
    configure_nginx
    configure_logrotate
    configure_system_limits
    create_deploy_script
    
    show_completion_info
}

# 执行主函数
main "$@"