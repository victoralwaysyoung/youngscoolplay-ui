#!/bin/bash
# YoungsCoolPlay UI Ubuntu 24 安装脚本

set -e

INSTALL_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"
CONFIG_DIR="/etc/youngscoolplay-ui"
WEB_DIR="/var/www/youngscoolplay-ui"

echo "正在安装 YoungsCoolPlay UI for Ubuntu 24..."

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "请使用root权限运行此脚本"
    exit 1
fi

# 安装依赖
echo "安装系统依赖..."
apt update
apt install -y curl wget unzip systemd

# 复制二进制文件
echo "安装二进制文件..."
cp youngscoolplay-ui ${INSTALL_DIR}/
chmod +x ${INSTALL_DIR}/youngscoolplay-ui

# 创建配置目录
echo "创建配置目录..."
mkdir -p ${CONFIG_DIR}
mkdir -p ${WEB_DIR}

# 复制web资源
if [ -d "web" ]; then
    cp -r web/* ${WEB_DIR}/
fi

# 复制配置文件
if [ -d "bin" ]; then
    cp -r bin/* ${CONFIG_DIR}/
fi

# 创建systemd服务文件
echo "创建系统服务..."
cat > ${SERVICE_DIR}/youngscoolplay-ui.service << 'EOFSERVICE'
[Unit]
Description=YoungsCoolPlay UI
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/youngscoolplay-ui
ExecStart=/usr/local/bin/youngscoolplay-ui
Restart=always
RestartSec=5
Environment=PATH=/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=multi-user.target
EOFSERVICE

# 重新加载systemd并启用服务
systemctl daemon-reload
systemctl enable youngscoolplay-ui

# 启动服务
systemctl start youngscoolplay-ui

echo "安装完成！"
echo "服务状态: systemctl status youngscoolplay-ui"
echo "查看日志: journalctl -u youngscoolplay-ui -f"
echo "停止服务: systemctl stop youngscoolplay-ui"
echo "启动服务: systemctl start youngscoolplay-ui"