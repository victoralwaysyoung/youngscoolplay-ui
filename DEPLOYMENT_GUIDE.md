# YoungsCoolPlay UI - 完整部署指南

[![Go Version](https://img.shields.io/badge/Go-1.21+-blue.svg)](https://golang.org)
[![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-green.svg)]()

一个基于 Go 语言开发的现代化 Web UI 应用，支持自动化部署、负载均衡和智能流量管理。

## 📋 目录

- [项目概述](#项目概述)
- [功能特性](#功能特性)
- [系统要求](#系统要求)
- [快速开始](#快速开始)
- [项目打包与GitHub上传](#项目打包与github上传)
- [Ubuntu 24服务器部署](#ubuntu-24服务器部署)
- [负载均衡与反向代理](#负载均衡与反向代理)
- [IP与vless账号映射](#ip与vless账号映射)
- [监控与日志管理](#监控与日志管理)
- [常见问题解决方案](#常见问题解决方案)
- [API文档](#api文档)
- [贡献指南](#贡献指南)

## 🚀 项目概述

YoungsCoolPlay UI 是一个高性能的 Web 应用程序，提供：

- **现代化 Web 界面**: 基于最新的前端技术栈
- **高可用架构**: 支持负载均衡和故障转移
- **智能流量管理**: IP 地址与 vless 账号 1:1 映射
- **自动化部署**: 从 GitHub 到生产环境的完整 CI/CD 流程
- **实时监控**: 全面的性能监控和日志管理

## ✨ 功能特性

### 核心功能
- 🎯 **智能路由**: 基于 IP 地址的智能流量分发
- 🔒 **安全认证**: 多层安全防护机制
- 📊 **实时监控**: 性能指标和健康状态监控
- 🔄 **自动部署**: GitHub Actions 集成的 CI/CD 流程
- 🌐 **负载均衡**: Nginx 反向代理和负载均衡
- 📱 **响应式设计**: 支持多设备访问

### 技术特性
- **高性能**: Go 语言原生性能优势
- **可扩展**: 微服务架构设计
- **容错性**: 自动故障检测和恢复
- **可观测性**: 完整的日志和监控体系

## 🛠 系统要求

### 开发环境
- **Go**: 1.21+ 
- **Git**: 2.30+
- **操作系统**: Windows 10+, macOS 10.15+, Linux (Ubuntu 20.04+)

### 生产环境
- **操作系统**: Ubuntu 24.04 LTS (推荐)
- **内存**: 最小 2GB，推荐 4GB+
- **存储**: 最小 20GB，推荐 50GB+
- **网络**: 公网 IP 地址
- **域名**: 可选，用于 SSL 证书

## 🚀 快速开始

### 本地开发

1. **克隆项目**
```bash
git clone https://github.com/victoralwaysyoung/youngscoolplay-ui.git
cd youngscoolplay-ui
```

2. **安装依赖**
```bash
go mod tidy
```

3. **运行应用**
```bash
go run .
```

4. **访问应用**
```
http://localhost:2053
```

### Docker 快速部署

```bash
# 构建镜像
docker build -t youngscoolplay-ui .

# 运行容器
docker run -d -p 2053:2053 --name youngscoolplay youngscoolplay-ui
```

## 📦 项目打包与GitHub上传

### 1. 项目打包

#### Windows 环境
```batch
# 执行打包脚本
scripts\build.bat

# 生成的文件位于 dist/ 目录
dir dist\
```

#### Linux/macOS 环境
```bash
# 添加执行权限
chmod +x scripts/build.sh

# 执行打包脚本
./scripts/build.sh

# 查看生成的文件
ls -la dist/
```

#### 打包输出说明
```
dist/
├── youngscoolplay-linux-amd64/
│   ├── youngscoolplay          # Linux 可执行文件
│   ├── config.yaml.example     # 配置文件模板
│   ├── static/                 # 静态资源
│   └── install.sh              # 安装脚本
├── youngscoolplay-windows-amd64/
│   ├── youngscoolplay.exe      # Windows 可执行文件
│   ├── config.yaml.example
│   ├── static/
│   └── install.bat
└── youngscoolplay-darwin-amd64/
    ├── youngscoolplay          # macOS 可执行文件
    ├── config.yaml.example
    ├── static/
    └── install.sh
```

### 2. GitHub 仓库设置

#### 创建 GitHub 仓库

**方法一：通过 Web 界面**
1. 访问 [GitHub](https://github.com)
2. 点击右上角 "+" → "New repository"
3. 填写仓库信息：
   - Repository name: `youngscoolplay-ui`
   - Description: `YoungsCoolPlay UI - 现代化 Web 应用`
   - 选择 Public 或 Private
   - 不要初始化 README（本地已有）

**方法二：使用 GitHub CLI**
```bash
# 安装 GitHub CLI
# Windows: winget install GitHub.cli
# macOS: brew install gh
# Ubuntu: sudo apt install gh

# 登录 GitHub
gh auth login

# 创建仓库
gh repo create youngscoolplay-ui --public --description "YoungsCoolPlay UI - 现代化 Web 应用"
```

#### 配置 Git 和 SSH

1. **配置 Git 用户信息**
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

2. **生成 SSH 密钥**
```bash
# 生成新的 SSH 密钥
ssh-keygen -t ed25519 -C "your.email@example.com"

# 启动 ssh-agent
eval "$(ssh-agent -s)"

# 添加 SSH 密钥到 ssh-agent
ssh-add ~/.ssh/id_ed25519

# 复制公钥到剪贴板
# Linux: cat ~/.ssh/id_ed25519.pub | xclip -selection clipboard
# macOS: pbcopy < ~/.ssh/id_ed25519.pub
# Windows: type %USERPROFILE%\.ssh\id_ed25519.pub | clip
```

3. **添加 SSH 密钥到 GitHub**
   - 访问 GitHub Settings → SSH and GPG keys
   - 点击 "New SSH key"
   - 粘贴公钥内容并保存

### 3. 代码上传流程

#### 初始化本地仓库
```bash
# 初始化 Git 仓库（如果还没有）
git init

# 添加远程仓库
git remote add origin git@github.com:victoralwaysyoung/youngscoolplay-ui.git

# 检查 .gitignore 文件
cat .gitignore

# 添加所有文件
git add .

# 提交代码
git commit -m "Initial commit: YoungsCoolPlay UI project"

# 推送到 GitHub
git push -u origin main
```

#### 分支管理策略

**Git Flow 工作流**
```bash
# 创建开发分支
git checkout -b develop

# 创建功能分支
git checkout -b feature/new-feature develop

# 完成功能开发后合并
git checkout develop
git merge --no-ff feature/new-feature
git branch -d feature/new-feature

# 创建发布分支
git checkout -b release/v1.0.0 develop

# 发布完成后合并到主分支
git checkout main
git merge --no-ff release/v1.0.0
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin main --tags
```

### 4. GitHub Actions CI/CD

创建 `.github/workflows/ci-cd.yml`：

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  release:
    types: [ published ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.21'
    
    - name: Run tests
      run: |
        go mod tidy
        go test -v ./...
    
    - name: Run security scan
      uses: securecodewarrior/github-action-add-sarif@v1
      with:
        sarif-file: 'gosec-report.sarif'

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'release'
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.21'
    
    - name: Build application
      run: |
        chmod +x scripts/build.sh
        ./scripts/build.sh
    
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: youngscoolplay-binaries
        path: dist/

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - name: Deploy to production
      uses: appleboy/ssh-action@v0.1.7
      with:
        host: ${{ secrets.HOST }}
        username: ${{ secrets.USERNAME }}
        key: ${{ secrets.SSH_KEY }}
        script: |
          cd /opt/youngscoolplay
          ./scripts/deploy.sh --branch main --no-backup
```

## 🖥 Ubuntu 24服务器部署

### 1. 服务器环境准备

#### 自动化环境设置
```bash
# 下载并执行服务器设置脚本
wget https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay-ui/main/scripts/server-setup.sh
chmod +x server-setup.sh
sudo ./server-setup.sh
```

#### 手动环境设置

**更新系统**
```bash
sudo apt update && sudo apt upgrade -y
```

**安装基础依赖**
```bash
sudo apt install -y curl wget git unzip tar build-essential \
    software-properties-common apt-transport-https ca-certificates \
    gnupg lsb-release htop vim nano ufw fail2ban logrotate \
    supervisor nginx
```

**安装 Go 语言**
```bash
# 下载 Go 1.21.5
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz

# 安装 Go
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz

# 配置环境变量
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
echo 'export GOBIN=$GOPATH/bin' >> ~/.bashrc
source ~/.bashrc

# 验证安装
go version
```

**配置防火墙**
```bash
# 启用 UFW
sudo ufw enable

# 允许 SSH
sudo ufw allow ssh

# 允许 HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 允许应用端口
sudo ufw allow 2053/tcp

# 查看状态
sudo ufw status
```

### 2. 应用部署

#### 创建应用目录
```bash
sudo mkdir -p /opt/youngscoolplay
sudo chown $USER:$USER /opt/youngscoolplay
cd /opt/youngscoolplay
```

#### 克隆代码
```bash
git clone https://github.com/victoralwaysyoung/youngscoolplay-ui.git .
```

#### 自动化部署
```bash
# 使用部署脚本
chmod +x scripts/deploy.sh
./scripts/deploy.sh --help

# 执行部署
./scripts/deploy.sh --branch main --repo https://github.com/victoralwaysyoung/youngscoolplay-ui.git
```

#### 手动部署步骤

**构建应用**
```bash
# 下载依赖
go mod tidy

# 构建应用
go build -o youngscoolplay -ldflags "-X main.Version=$(git describe --tags --always)" .

# 设置执行权限
chmod +x youngscoolplay
```

**创建配置文件**
```bash
# 复制配置模板
cp config.yaml.example config.yaml

# 编辑配置
nano config.yaml
```

**配置示例**
```yaml
server:
  host: "0.0.0.0"
  port: 2053
  read_timeout: 30s
  write_timeout: 30s
  idle_timeout: 60s

database:
  driver: "sqlite"
  dsn: "/opt/youngscoolplay/data/app.db"

logging:
  level: "info"
  file: "/var/log/youngscoolplay/app.log"
  max_size: 100
  max_backups: 10
  max_age: 30

security:
  jwt_secret: "your-jwt-secret-key"
  cors_origins: ["*"]
  rate_limit: 100

features:
  enable_metrics: true
  enable_pprof: false
  enable_swagger: true
```

### 3. 系统服务配置

#### 自动安装服务
```bash
# 使用服务安装脚本
chmod +x scripts/service-install.sh
sudo ./scripts/service-install.sh --help

# 安装服务
sudo ./scripts/service-install.sh --user youngscoolplay --group youngscoolplay
```

#### 手动配置服务

**创建系统用户**
```bash
sudo useradd --system --shell /bin/false --home /opt/youngscoolplay youngscoolplay
sudo chown -R youngscoolplay:youngscoolplay /opt/youngscoolplay
```

**创建 systemd 服务文件**
```bash
sudo tee /etc/systemd/system/youngscoolplay.service > /dev/null << 'EOF'
[Unit]
Description=YoungsCoolPlay UI Service
Documentation=https://github.com/victoralwaysyoung/youngscoolplay-ui
After=network.target
Wants=network.target

[Service]
Type=simple
User=youngscoolplay
Group=youngscoolplay
WorkingDirectory=/opt/youngscoolplay
ExecStart=/opt/youngscoolplay/youngscoolplay
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30
Restart=always
RestartSec=5
StartLimitInterval=60
StartLimitBurst=3

# 安全设置
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/youngscoolplay /var/log/youngscoolplay

# 资源限制
LimitNOFILE=65536
LimitNPROC=4096

# 环境变量
Environment=GIN_MODE=release
Environment=GOMAXPROCS=2

[Install]
WantedBy=multi-user.target
EOF
```

**启动服务**
```bash
# 重载 systemd
sudo systemctl daemon-reload

# 启用服务
sudo systemctl enable youngscoolplay

# 启动服务
sudo systemctl start youngscoolplay

# 查看状态
sudo systemctl status youngscoolplay

# 查看日志
sudo journalctl -u youngscoolplay -f
```

### 4. 日志管理配置

**创建日志目录**
```bash
sudo mkdir -p /var/log/youngscoolplay
sudo chown youngscoolplay:youngscoolplay /var/log/youngscoolplay
```

**配置 logrotate**
```bash
sudo tee /etc/logrotate.d/youngscoolplay > /dev/null << 'EOF'
/var/log/youngscoolplay/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 youngscoolplay youngscoolplay
    postrotate
        systemctl reload youngscoolplay
    endscript
}
EOF
```

## ⚖️ 负载均衡与反向代理

### 1. Nginx 配置

#### 基础负载均衡配置

**主配置文件** `/etc/nginx/sites-available/youngscoolplay`
```nginx
# 上游服务器组
upstream youngscoolplay_backend {
    least_conn;
    server 127.0.0.1:2053 max_fails=3 fail_timeout=30s weight=1;
    server 127.0.0.1:2054 max_fails=3 fail_timeout=30s weight=1;
    server 127.0.0.1:2055 max_fails=3 fail_timeout=30s weight=1;
    
    # 保持连接
    keepalive 32;
    keepalive_requests 100;
    keepalive_timeout 60s;
}

# 限制配置
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
limit_conn_zone $binary_remote_addr zone=conn:10m;

# HTTP 服务器（重定向到 HTTPS）
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    
    # 强制 HTTPS
    return 301 https://$server_name$request_uri;
}

# HTTPS 服务器
server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;
    
    # SSL 配置
    ssl_certificate /etc/ssl/certs/your-domain.crt;
    ssl_certificate_key /etc/ssl/private/your-domain.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # 安全头
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # 日志配置
    access_log /var/log/nginx/youngscoolplay-access.log combined;
    error_log /var/log/nginx/youngscoolplay-error.log;
    
    # 连接限制
    limit_conn conn 20;
    
    # 主应用代理
    location / {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://youngscoolplay_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # 超时设置
        proxy_connect_timeout 30s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # 缓冲设置
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    # API 路由（更严格的限制）
    location /api/ {
        limit_req zone=api burst=10 nodelay;
        
        proxy_pass http://youngscoolplay_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # 登录接口（最严格限制）
    location /api/auth/login {
        limit_req zone=login burst=3 nodelay;
        
        proxy_pass http://youngscoolplay_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket 支持
    location /ws {
        proxy_pass http://youngscoolplay_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket 特殊设置
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }
    
    # 静态文件
    location /static/ {
        alias /opt/youngscoolplay/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        
        # 压缩
        gzip on;
        gzip_types text/css application/javascript image/svg+xml;
    }
    
    # 健康检查
    location /health {
        access_log off;
        proxy_pass http://youngscoolplay_backend;
        proxy_set_header Host $host;
    }
    
    # 监控端点（仅内网）
    location /metrics {
        allow 127.0.0.1;
        allow 10.0.0.0/8;
        allow 172.16.0.0/12;
        allow 192.168.0.0/16;
        deny all;
        
        proxy_pass http://youngscoolplay_backend;
        proxy_set_header Host $host;
    }
}
```

#### 启用配置
```bash
# 创建软链接
sudo ln -s /etc/nginx/sites-available/youngscoolplay /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重载配置
sudo systemctl reload nginx
```

### 2. 高级负载均衡策略

#### 基于地理位置的负载均衡

**安装 GeoIP 模块**
```bash
sudo apt install nginx-module-geoip
```

**配置地理位置映射**
```nginx
# 在 http 块中添加
geoip_country /usr/share/GeoIP/GeoIP.dat;
geoip_city /usr/share/GeoIP/GeoLiteCity.dat;

# 基于国家的上游选择
map $geoip_country_code $backend_pool {
    default youngscoolplay_global;
    CN youngscoolplay_china;
    US youngscoolplay_america;
    EU youngscoolplay_europe;
}

upstream youngscoolplay_china {
    server 127.0.0.1:2053;
    server 127.0.0.1:2054;
}

upstream youngscoolplay_america {
    server 127.0.0.1:2055;
    server 127.0.0.1:2056;
}

upstream youngscoolplay_europe {
    server 127.0.0.1:2057;
    server 127.0.0.1:2058;
}

upstream youngscoolplay_global {
    server 127.0.0.1:2059;
    server 127.0.0.1:2060;
}
```

#### 基于用户类型的负载均衡

```nginx
# 基于 Cookie 或 Header 的用户类型识别
map $http_user_type $user_backend {
    default youngscoolplay_standard;
    "premium" youngscoolplay_premium;
    "enterprise" youngscoolplay_enterprise;
}

upstream youngscoolplay_premium {
    server 127.0.0.1:2053 weight=3;
    server 127.0.0.1:2054 weight=2;
}

upstream youngscoolplay_enterprise {
    server 127.0.0.1:2055 weight=5;
    server 127.0.0.1:2056 weight=3;
}

upstream youngscoolplay_standard {
    server 127.0.0.1:2057;
    server 127.0.0.1:2058;
}
```

### 3. 健康检查配置

#### Nginx Plus 健康检查（商业版）
```nginx
upstream youngscoolplay_backend {
    zone youngscoolplay 64k;
    server 127.0.0.1:2053 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:2054 max_fails=3 fail_timeout=30s;
}

server {
    location /health {
        health_check interval=10s fails=3 passes=2 uri=/health;
        proxy_pass http://youngscoolplay_backend;
    }
}
```

#### 自定义健康检查脚本
```bash
#!/bin/bash
# /opt/youngscoolplay/scripts/health-check.sh

SERVERS=("127.0.0.1:2053" "127.0.0.1:2054" "127.0.0.1:2055")
NGINX_CONF="/etc/nginx/conf.d/upstream.conf"

for server in "${SERVERS[@]}"; do
    if curl -f -s "http://$server/health" > /dev/null; then
        echo "Server $server is healthy"
    else
        echo "Server $server is down, removing from upstream"
        # 从 Nginx 配置中移除故障服务器
        sed -i "s/server $server/#server $server/" "$NGINX_CONF"
        nginx -s reload
    fi
done
```

## 🗺 IP与vless账号映射

### 1. 映射系统架构

IP 与 vless 账号 1:1 映射系统提供：

- **精确映射**: 每个 IP 地址对应唯一的 vless 账号
- **动态管理**: 支持实时添加、删除、修改映射关系
- **智能分配**: 基于地理位置、用户类型的智能账号分配
- **性能优化**: 高效的查找和匹配算法
- **监控统计**: 完整的使用统计和监控

### 2. 配置文件说明

#### 主配置文件
详细配置请参考 `configs/nginx/ip-mapping.conf`，包含：

- **IP 映射规则**: 支持精确 IP 和 CIDR 网段
- **账号类型分类**: VIP、企业、办公、家庭、教育等
- **服务质量控制**: 带宽限制、连接数限制、请求频率限制
- **负载均衡**: 不同类型账号使用不同的服务器组

#### 映射规则示例

**精确 IP 映射**
```nginx
map $remote_addr $vless_account_id {
    "203.0.113.10"    "vip_001";
    "203.0.113.11"    "vip_002";
    "192.168.1.100"   "home_user_001";
}
```

**网段映射**
```nginx
map $remote_addr $vless_account_id {
    ~^10\.100\.1\.     "enterprise_team_a";
    ~^192\.168\.10\.   "office_beijing";
    ~^172\.16\.1\.     "edu_university_a";
}
```

**运营商网络映射**
```nginx
map $remote_addr $vless_account_id {
    ~^117\.136\.       "mobile_china_unicom";
    ~^223\.5\.         "mobile_china_telecom";
    ~^120\.196\.       "mobile_china_mobile";
}
```

### 3. 映射管理工具

#### 使用映射管理脚本

**安装管理工具**
```bash
# 复制管理脚本
sudo cp scripts/ip-mapping-manager.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/ip-mapping-manager.sh

# 创建软链接
sudo ln -s /usr/local/bin/ip-mapping-manager.sh /usr/local/bin/ipmgr
```

**基本操作**
```bash
# 添加 IP 映射
sudo ipmgr add 192.168.1.100 user001 premium

# 查询 IP 映射
sudo ipmgr query 192.168.1.100

# 列出所有映射
sudo ipmgr list

# 删除 IP 映射
sudo ipmgr remove 192.168.1.100

# 显示统计信息
sudo ipmgr stats

# 健康检查
sudo ipmgr health
```

**批量导入**
```bash
# 从 CSV 文件导入
sudo ipmgr import mappings.csv

# CSV 格式示例
cat > mappings.csv << 'EOF'
ip,account_id,account_type,uuid
192.168.1.100,user001,premium,550e8400-e29b-41d4-a716-446655440001
192.168.1.101,user002,standard,550e8400-e29b-41d4-a716-446655440002
10.0.1.100,enterprise001,business,660e8400-e29b-41d4-a716-446655440001
EOF
```

**导出映射**
```bash
# 导出到 CSV 文件
sudo ipmgr export backup.csv

# 查看导出的文件
cat backup.csv
```

### 4. 账号类型和服务质量

#### 账号类型定义

| 类型 | 说明 | 带宽限制 | 连接数限制 | 请求频率 |
|------|------|----------|------------|----------|
| premium | VIP 用户 | 100Mbps | 100 | 100r/s |
| business | 企业用户 | 50Mbps | 50 | 50r/s |
| office | 办公用户 | 30Mbps | 30 | 30r/s |
| home | 家庭用户 | 20Mbps | 20 | 20r/s |
| education | 教育用户 | 15Mbps | 15 | 15r/s |
| mobile | 移动用户 | 5Mbps | 5 | 5r/s |
| international | 国际用户 | 25Mbps | 25 | 25r/s |
| standard | 标准用户 | 10Mbps | 10 | 10r/s |

#### 动态服务质量调整

**基于时间的 QoS**
```nginx
# 根据时间调整带宽限制
map $time_iso8601 $time_based_limit {
    ~T0[0-8] "5m";    # 夜间降低带宽
    ~T(09|1[0-7]) "20m"; # 工作时间正常带宽
    ~T1[8-9] "15m";   # 晚间适中带宽
    ~T2[0-3] "5m";    # 深夜降低带宽
    default "10m";
}
```

**基于负载的动态调整**
```nginx
# 根据服务器负载调整限制
map $upstream_response_time $load_based_limit {
    ~^0\.[0-2] "20m";  # 低延迟，高带宽
    ~^0\.[3-5] "15m";  # 中等延迟，中等带宽
    ~^0\.[6-9] "10m";  # 高延迟，低带宽
    default "5m";      # 超高延迟，最低带宽
}
```

### 5. 监控和统计

#### 实时监控接口

**账号信息查询**
```bash
# 查询特定 IP 的账号信息
curl -H "Authorization: Bearer $TOKEN" \
     "https://your-domain.com/account/info"

# 响应示例
{
  "ip": "192.168.1.100",
  "account_id": "user001",
  "uuid": "550e8400-e29b-41d4-a716-446655440001",
  "account_type": "premium",
  "bandwidth_limit": "100m",
  "connection_limit": "100",
  "request_rate": "100r/s",
  "target_server": "youngscoolplay_premium",
  "timestamp": 1640995200
}
```

**流量统计查询**
```bash
# 查询流量统计
curl -H "Authorization: Bearer $TOKEN" \
     "https://your-domain.com/stats/traffic"

# 响应示例
{
  "account_id": "user001",
  "bytes_sent": 1048576000,
  "bytes_received": 524288000,
  "connections": 25,
  "last_activity": 1640995200
}
```

#### 管理界面

**访问管理界面**
```bash
# 仅内网可访问
curl "http://localhost/admin/ip-mapping"
```

**统计信息**
```bash
# 查看映射统计
curl "http://localhost:8081/stats/mappings"

# 实时连接统计
curl "http://localhost:8081/stats/realtime"
```

### 6. 安全和认证

#### API 认证

**JWT Token 认证**
```nginx
location /api/ {
    auth_request /auth;
    
    proxy_pass http://youngscoolplay_backend;
    proxy_set_header X-Account-ID $vless_account_id;
    proxy_set_header X-Account-Type $account_type;
}

location = /auth {
    internal;
    proxy_pass http://youngscoolplay_backend/api/auth/verify;
    proxy_pass_request_body off;
    proxy_set_header Content-Length "";
    proxy_set_header X-Original-URI $request_uri;
    proxy_set_header X-Account-ID $vless_account_id;
}
```

#### 访问控制

**IP 白名单**
```nginx
# 管理接口仅允许特定 IP 访问
location /admin/ {
    allow 127.0.0.1;
    allow 10.0.0.0/8;
    allow 172.16.0.0/12;
    allow 192.168.0.0/16;
    deny all;
    
    proxy_pass http://youngscoolplay_backend;
}
```

**基于账号类型的访问控制**
```nginx
# 高级功能仅 VIP 用户可访问
location /api/premium/ {
    if ($account_type != "premium") {
        return 403;
    }
    
    proxy_pass http://youngscoolplay_backend;
}
```

## 📊 监控与日志管理

### 1. 应用监控

#### Prometheus 监控配置

**安装 Prometheus**
```bash
# 下载 Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.40.0/prometheus-2.40.0.linux-amd64.tar.gz
tar xzf prometheus-2.40.0.linux-amd64.tar.gz
sudo mv prometheus-2.40.0.linux-amd64 /opt/prometheus

# 创建配置文件
sudo tee /opt/prometheus/prometheus.yml > /dev/null << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

scrape_configs:
  - job_name: 'youngscoolplay'
    static_configs:
      - targets: ['localhost:2053']
    metrics_path: /metrics
    scrape_interval: 10s

  - job_name: 'nginx'
    static_configs:
      - targets: ['localhost:9113']

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - localhost:9093
EOF

# 创建 systemd 服务
sudo tee /etc/systemd/system/prometheus.service > /dev/null << 'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/opt/prometheus/prometheus \
    --config.file=/opt/prometheus/prometheus.yml \
    --storage.tsdb.path=/opt/prometheus/data \
    --web.console.templates=/opt/prometheus/consoles \
    --web.console.libraries=/opt/prometheus/console_libraries \
    --web.listen-address=0.0.0.0:9090 \
    --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
sudo systemctl enable prometheus
sudo systemctl start prometheus
```

#### Grafana 仪表板

**安装 Grafana**
```bash
# 添加 Grafana 仓库
sudo apt-get install -y software-properties-common
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

# 安装 Grafana
sudo apt-get update
sudo apt-get install grafana

# 启动服务
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

**配置数据源**
```bash
# 添加 Prometheus 数据源
curl -X POST \
  http://admin:admin@localhost:3000/api/datasources \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://localhost:9090",
    "access": "proxy",
    "isDefault": true
  }'
```

#### 关键监控指标

**应用性能指标**
```go
// 在应用中添加 Prometheus 指标
var (
    httpRequestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )
    
    httpRequestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "http_request_duration_seconds",
            Help: "HTTP request duration in seconds",
        },
        []string{"method", "endpoint"},
    )
    
    activeConnections = prometheus.NewGauge(
        prometheus.GaugeOpts{
            Name: "active_connections",
            Help: "Number of active connections",
        },
    )
)
```

**系统资源监控**
```bash
# 安装 Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
tar xzf node_exporter-1.5.0.linux-amd64.tar.gz
sudo mv node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin/

# 创建 systemd 服务
sudo tee /etc/systemd/system/node_exporter.service > /dev/null << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable node_exporter
sudo systemctl start node_exporter
```

### 2. 日志管理系统

#### ELK Stack 部署

**安装 Elasticsearch**
```bash
# 添加 Elastic 仓库
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# 安装 Elasticsearch
sudo apt-get update
sudo apt-get install elasticsearch

# 配置 Elasticsearch
sudo tee /etc/elasticsearch/elasticsearch.yml > /dev/null << 'EOF'
cluster.name: youngscoolplay-logs
node.name: node-1
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: localhost
http.port: 9200
discovery.type: single-node
xpack.security.enabled: false
EOF

sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
```

**安装 Logstash**
```bash
sudo apt-get install logstash

# 配置 Logstash
sudo tee /etc/logstash/conf.d/youngscoolplay.conf > /dev/null << 'EOF'
input {
  file {
    path => "/var/log/youngscoolplay/*.log"
    start_position => "beginning"
    codec => "json"
  }
  
  file {
    path => "/var/log/nginx/youngscoolplay-*.log"
    start_position => "beginning"
  }
}

filter {
  if [path] =~ "nginx" {
    grok {
      match => { "message" => "%{NGINXACCESS}" }
    }
    date {
      match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
    }
  }
  
  if [path] =~ "youngscoolplay" {
    json {
      source => "message"
    }
    date {
      match => [ "timestamp", "ISO8601" ]
    }
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "youngscoolplay-%{+YYYY.MM.dd}"
  }
}
EOF

sudo systemctl enable logstash
sudo systemctl start logstash
```

**安装 Kibana**
```bash
sudo apt-get install kibana

# 配置 Kibana
sudo tee /etc/kibana/kibana.yml > /dev/null << 'EOF'
server.port: 5601
server.host: "localhost"
elasticsearch.hosts: ["http://localhost:9200"]
EOF

sudo systemctl enable kibana
sudo systemctl start kibana
```

#### 日志轮转配置

**应用日志轮转**
```bash
sudo tee /etc/logrotate.d/youngscoolplay > /dev/null << 'EOF'
/var/log/youngscoolplay/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 youngscoolplay youngscoolplay
    postrotate
        systemctl reload youngscoolplay
    endscript
}
EOF
```

**Nginx 日志轮转**
```bash
sudo tee /etc/logrotate.d/nginx-youngscoolplay > /dev/null << 'EOF'
/var/log/nginx/youngscoolplay-*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 0644 www-data www-data
    prerotate
        if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
            run-parts /etc/logrotate.d/httpd-prerotate; \
        fi \
    endscript
    postrotate
        invoke-rc.d nginx rotate >/dev/null 2>&1
    endscript
}
EOF
```

### 3. 告警配置

#### Prometheus 告警规则

**创建告警规则**
```bash
sudo mkdir -p /opt/prometheus/rules
sudo tee /opt/prometheus/rules/youngscoolplay.yml > /dev/null << 'EOF'
groups:
- name: youngscoolplay
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High error rate detected"
      description: "Error rate is {{ $value }} errors per second"

  - alert: HighResponseTime
    expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High response time detected"
      description: "95th percentile response time is {{ $value }} seconds"

  - alert: ServiceDown
    expr: up{job="youngscoolplay"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "YoungsCoolPlay service is down"
      description: "YoungsCoolPlay service has been down for more than 1 minute"

  - alert: HighMemoryUsage
    expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage"
      description: "Memory usage is {{ $value | humanizePercentage }}"

  - alert: HighCPUUsage
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage"
      description: "CPU usage is {{ $value }}%"
EOF
```

#### Alertmanager 配置

**安装 Alertmanager**
```bash
wget https://github.com/prometheus/alertmanager/releases/download/v0.25.0/alertmanager-0.25.0.linux-amd64.tar.gz
tar xzf alertmanager-0.25.0.linux-amd64.tar.gz
sudo mv alertmanager-0.25.0.linux-amd64 /opt/alertmanager

# 配置 Alertmanager
sudo tee /opt/alertmanager/alertmanager.yml > /dev/null << 'EOF'
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@your-domain.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
- name: 'web.hook'
  email_configs:
  - to: 'admin@your-domain.com'
    subject: 'YoungsCoolPlay Alert: {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      {{ end }}
  
  webhook_configs:
  - url: 'http://localhost:3000/api/alerts'
    send_resolved: true

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOF
```

## 🔧 常见问题解决方案

### 1. 部署相关问题

#### 问题：Go 版本不兼容
**症状**: 编译失败，提示 Go 版本过低
```
go: module requires Go 1.21 or later
```

**解决方案**:
```bash
# 检查当前 Go 版本
go version

# 卸载旧版本
sudo rm -rf /usr/local/go

# 下载并安装新版本
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz

# 更新环境变量
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# 验证安装
go version
```

#### 问题：端口被占用
**症状**: 应用启动失败
```
bind: address already in use
```

**解决方案**:
```bash
# 查找占用端口的进程
sudo netstat -tlnp | grep :2053
sudo lsof -i :2053

# 终止占用进程
sudo kill -9 <PID>

# 或者修改应用端口
nano config.yaml
# 修改 server.port 为其他端口
```

#### 问题：权限不足
**症状**: 无法创建文件或目录
```
permission denied
```

**解决方案**:
```bash
# 检查文件权限
ls -la /opt/youngscoolplay

# 修改所有者
sudo chown -R youngscoolplay:youngscoolplay /opt/youngscoolplay

# 修改权限
sudo chmod -R 755 /opt/youngscoolplay
sudo chmod +x /opt/youngscoolplay/youngscoolplay

# 检查 SELinux 状态（如果适用）
sestatus
sudo setsebool -P httpd_can_network_connect 1
```

### 2. 服务相关问题

#### 问题：服务启动失败
**症状**: systemctl 启动失败
```
Job for youngscoolplay.service failed
```

**解决方案**:
```bash
# 查看详细错误信息
sudo journalctl -u youngscoolplay -f

# 检查服务配置
sudo systemctl cat youngscoolplay

# 验证可执行文件
/opt/youngscoolplay/youngscoolplay --version

# 检查配置文件
/opt/youngscoolplay/youngscoolplay --config-check

# 重新加载 systemd
sudo systemctl daemon-reload
sudo systemctl restart youngscoolplay
```

#### 问题：服务频繁重启
**症状**: 服务不稳定，频繁重启
```
Service entered failed state
```

**解决方案**:
```bash
# 检查系统资源
free -h
df -h
top

# 检查应用日志
tail -f /var/log/youngscoolplay/app.log

# 调整服务配置
sudo systemctl edit youngscoolplay
# 添加以下内容：
[Service]
Restart=on-failure
RestartSec=10
StartLimitInterval=60
StartLimitBurst=3

# 检查内存泄漏
pmap -x $(pgrep youngscoolplay)
```

### 3. 网络相关问题

#### 问题：无法访问应用
**症状**: 浏览器无法连接
```
This site can't be reached
```

**解决方案**:
```bash
# 检查应用是否运行
sudo systemctl status youngscoolplay
curl http://localhost:2053/health

# 检查防火墙
sudo ufw status
sudo ufw allow 2053/tcp

# 检查 Nginx 配置
sudo nginx -t
sudo systemctl status nginx

# 检查端口监听
sudo netstat -tlnp | grep :2053
sudo netstat -tlnp | grep :80

# 检查 DNS 解析
nslookup your-domain.com
dig your-domain.com
```

#### 问题：SSL 证书问题
**症状**: HTTPS 访问失败
```
SSL_ERROR_BAD_CERT_DOMAIN
```

**解决方案**:
```bash
# 检查证书有效性
openssl x509 -in /etc/ssl/certs/your-domain.crt -text -noout

# 验证证书链
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/your-domain.crt

# 使用 Let's Encrypt 自动续期
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com

# 设置自动续期
sudo crontab -e
# 添加：0 12 * * * /usr/bin/certbot renew --quiet
```

### 4. 性能相关问题

#### 问题：响应时间过长
**症状**: 页面加载缓慢
```
Request timeout
```

**解决方案**:
```bash
# 检查系统负载
uptime
iostat -x 1 5

# 分析慢查询
tail -f /var/log/youngscoolplay/app.log | grep "slow"

# 优化 Nginx 配置
sudo nano /etc/nginx/sites-available/youngscoolplay
# 调整以下参数：
worker_processes auto;
worker_connections 1024;
keepalive_timeout 65;
client_max_body_size 10M;

# 启用 Gzip 压缩
gzip on;
gzip_types text/plain text/css application/json application/javascript;

# 重载配置
sudo nginx -s reload
```

#### 问题：内存使用过高
**症状**: 系统内存不足
```
Out of memory
```

**解决方案**:
```bash
# 检查内存使用
free -h
ps aux --sort=-%mem | head

# 分析内存泄漏
valgrind --tool=memcheck --leak-check=full ./youngscoolplay

# 调整 Go 垃圾回收
export GOGC=100
export GOMEMLIMIT=1GiB

# 添加 swap 空间
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 5. 数据库相关问题

#### 问题：数据库连接失败
**症状**: 应用无法连接数据库
```
database connection failed
```

**解决方案**:
```bash
# 检查数据库文件权限
ls -la /opt/youngscoolplay/data/

# 修复 SQLite 数据库
sqlite3 /opt/youngscoolplay/data/app.db ".schema"
sqlite3 /opt/youngscoolplay/data/app.db "PRAGMA integrity_check;"

# 备份和恢复数据库
cp /opt/youngscoolplay/data/app.db /opt/youngscoolplay/data/app.db.backup
sqlite3 /opt/youngscoolplay/data/app.db ".dump" | sqlite3 /opt/youngscoolplay/data/app_new.db

# 检查磁盘空间
df -h /opt/youngscoolplay/data/
```

### 6. 监控相关问题

#### 问题：监控数据缺失
**症状**: Grafana 显示无数据
```
No data points
```

**解决方案**:
```bash
# 检查 Prometheus 状态
curl http://localhost:9090/api/v1/targets

# 检查应用 metrics 端点
curl http://localhost:2053/metrics

# 验证 Prometheus 配置
promtool check config /opt/prometheus/prometheus.yml

# 重启 Prometheus
sudo systemctl restart prometheus

# 检查防火墙规则
sudo ufw allow 9090/tcp
sudo ufw allow 3000/tcp
```

### 7. 日志相关问题

#### 问题：日志文件过大
**症状**: 磁盘空间不足
```
No space left on device
```

**解决方案**:
```bash
# 检查日志文件大小
du -sh /var/log/youngscoolplay/
du -sh /var/log/nginx/

# 手动轮转日志
sudo logrotate -f /etc/logrotate.d/youngscoolplay

# 清理旧日志
find /var/log/youngscoolplay/ -name "*.log.*" -mtime +30 -delete

# 调整日志级别
nano /opt/youngscoolplay/config.yaml
# 修改 logging.level 为 "warn" 或 "error"
```

### 8. 安全相关问题

#### 问题：频繁的恶意请求
**症状**: 大量 4xx 错误
```
Too many requests
```

**解决方案**:
```bash
# 分析访问日志
tail -f /var/log/nginx/youngscoolplay-access.log | grep " 4[0-9][0-9] "

# 配置 fail2ban
sudo tee /etc/fail2ban/jail.d/youngscoolplay.conf > /dev/null << 'EOF'
[youngscoolplay]
enabled = true
port = http,https
filter = youngscoolplay
logpath = /var/log/nginx/youngscoolplay-access.log
maxretry = 5
bantime = 3600
findtime = 600
EOF

# 创建过滤规则
sudo tee /etc/fail2ban/filter.d/youngscoolplay.conf > /dev/null << 'EOF'
[Definition]
oreregex = ^<HOST> .* "(GET|POST|HEAD).*" (4[0-9][0-9]|5[0-9][0-9]) .*$
ignoreregex =
EOF

# 重启 fail2ban
sudo systemctl restart fail2ban

# 配置更严格的速率限制
sudo nano /etc/nginx/sites-available/youngscoolplay
# 添加：
limit_req_zone $binary_remote_addr zone=strict:10m rate=1r/s;
limit_req zone=strict burst=5 nodelay;
```

#### 问题：SSL/TLS 配置不安全
**症状**: SSL 测试评级较低
```
SSL Rating: B or lower
```

**解决方案**:
```bash
# 更新 SSL 配置
sudo nano /etc/nginx/sites-available/youngscoolplay

# 使用现代 SSL 配置
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_stapling on;
ssl_stapling_verify on;

# 添加安全头
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
add_header X-Frame-Options DENY always;
add_header X-Content-Type-Options nosniff always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;

# 测试配置
sudo nginx -t
sudo systemctl reload nginx

# 在线测试 SSL 配置
# 访问：https://www.ssllabs.com/ssltest/
```

## 📚 API文档

### 1. 认证接口

#### 登录
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "password"
}
```

**响应**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600,
  "user": {
    "id": 1,
    "username": "admin",
    "role": "admin"
  }
}
```

#### 验证令牌
```http
GET /api/auth/verify
Authorization: Bearer <token>
```

### 2. 系统信息接口

#### 健康检查
```http
GET /health
```

**响应**:
```json
{
  "status": "healthy",
  "timestamp": 1640995200,
  "version": "v1.0.0",
  "uptime": 3600
}
```

#### 系统指标
```http
GET /metrics
```

**响应**: Prometheus 格式的指标数据

### 3. 账号管理接口

#### 获取账号信息
```http
GET /api/account/info
Authorization: Bearer <token>
```

#### 更新账号映射
```http
POST /api/account/mapping
Authorization: Bearer <token>
Content-Type: application/json

{
  "ip": "192.168.1.100",
  "account_id": "user001",
  "account_type": "premium"
}
```

### 4. 统计接口

#### 流量统计
```http
GET /api/stats/traffic
Authorization: Bearer <token>
```

#### 连接统计
```http
GET /api/stats/connections
Authorization: Bearer <token>
```

## 🤝 贡献指南

### 1. 开发环境设置

```bash
# Fork 项目到你的 GitHub 账号
# 克隆你的 fork
git clone https://github.com/victoralwaysyoung/youngscoolplay-ui.git
cd youngscoolplay-ui

# 添加上游仓库
git remote add upstream https://github.com/original-owner/youngscoolplay-ui.git

# 创建开发分支
git checkout -b feature/your-feature-name
```

### 2. 代码规范

#### Go 代码规范
- 使用 `gofmt` 格式化代码
- 使用 `golint` 检查代码质量
- 遵循 Go 官方编码规范
- 添加适当的注释和文档

#### 提交规范
```bash
# 提交格式
git commit -m "type(scope): description"

# 类型说明：
# feat: 新功能
# fix: 修复 bug
# docs: 文档更新
# style: 代码格式调整
# refactor: 代码重构
# test: 测试相关
# chore: 构建过程或辅助工具的变动
```

### 3. 测试要求

```bash
# 运行所有测试
go test ./...

# 运行测试并生成覆盖率报告
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# 运行基准测试
go test -bench=. ./...
```

### 4. 提交 Pull Request

1. 确保所有测试通过
2. 更新相关文档
3. 提交 Pull Request
4. 等待代码审查
5. 根据反馈修改代码

## 📄 许可证

本项目采用 [GNU General Public License v3.0](LICENSE) 许可证。

## 🆘 支持

如果你在使用过程中遇到问题，可以通过以下方式获取帮助：

- **GitHub Issues**: [提交问题](https://github.com/victoralwaysyoung/youngscoolplay-ui/issues)
- **讨论区**: [GitHub Discussions](https://github.com/victoralwaysyoung/youngscoolplay-ui/discussions)
- **邮件支持**: support@your-domain.com

## 🔄 更新日志

### v1.0.0 (2024-01-01)
- 初始版本发布
- 基础 Web UI 功能
- 负载均衡和反向代理
- IP 与 vless 账号映射
- 自动化部署脚本

### v1.1.0 (计划中)
- 增强监控功能
- 性能优化
- 更多账号类型支持
- 改进的管理界面

---

**注意**: 本文档会持续更新，请定期查看最新版本。如有任何疑问或建议，欢迎提交 Issue 或 Pull Request。