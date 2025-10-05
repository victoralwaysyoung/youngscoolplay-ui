#!/bin/bash

# YoungsCoolPlay UI Ubuntu 24 Build Script
# 专门为Ubuntu 24系统编译的脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="youngscoolplay-ui"
VERSION="1.0.0"
BUILD_TIME=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# 构建目录
BUILD_DIR="build"
DIST_DIR="dist"

echo -e "${BLUE}=== YoungsCoolPlay UI Ubuntu 24 Build Script ===${NC}"
echo -e "${YELLOW}Version: ${VERSION}${NC}"
echo -e "${YELLOW}Build Time: ${BUILD_TIME}${NC}"
echo -e "${YELLOW}Git Commit: ${GIT_COMMIT}${NC}"
echo ""

# 清理之前的构建
echo -e "${YELLOW}清理之前的构建...${NC}"
rm -rf ${BUILD_DIR}
rm -rf ${DIST_DIR}
mkdir -p ${BUILD_DIR}
mkdir -p ${DIST_DIR}

# 构建标志
LDFLAGS="-w -s -X 'main.version=${VERSION}' -X 'main.buildTime=${BUILD_TIME}' -X 'main.gitCommit=${GIT_COMMIT}'"

# 构建Linux AMD64版本
echo -e "${GREEN}构建Linux AMD64版本...${NC}"
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build \
    -ldflags="${LDFLAGS}" \
    -o "${BUILD_DIR}/${PROJECT_NAME}-linux-amd64" \
    .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 成功构建 ${PROJECT_NAME}-linux-amd64${NC}"
else
    echo -e "${RED}✗ 构建失败${NC}"
    exit 1
fi

# 创建Ubuntu 24安装包
echo -e "${BLUE}创建Ubuntu 24安装包...${NC}"

PACKAGE_NAME="${PROJECT_NAME}-${VERSION}-ubuntu24-amd64"
mkdir -p "${DIST_DIR}/${PACKAGE_NAME}"

# 复制二进制文件
cp "${BUILD_DIR}/${PROJECT_NAME}-linux-amd64" "${DIST_DIR}/${PACKAGE_NAME}/${PROJECT_NAME}"

# 复制必要文件
cp README.md "${DIST_DIR}/${PACKAGE_NAME}/" 2>/dev/null || echo "README.md not found"
cp LICENSE "${DIST_DIR}/${PACKAGE_NAME}/" 2>/dev/null || echo "LICENSE not found"

# 复制web资源
if [ -d "web" ]; then
    cp -r web "${DIST_DIR}/${PACKAGE_NAME}/"
fi

# 复制配置文件
if [ -d "bin" ]; then
    mkdir -p "${DIST_DIR}/${PACKAGE_NAME}/bin"
    cp bin/* "${DIST_DIR}/${PACKAGE_NAME}/bin/" 2>/dev/null || true
fi

# 创建Ubuntu 24专用安装脚本
cat > "${DIST_DIR}/${PACKAGE_NAME}/install-ubuntu24.sh" << 'EOF'
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
echo ""
echo "服务状态: systemctl status youngscoolplay-ui"
echo "启动服务: systemctl start youngscoolplay-ui"
echo "停止服务: systemctl stop youngscoolplay-ui"
echo "重启服务: systemctl restart youngscoolplay-ui"
echo "查看日志: journalctl -u youngscoolplay-ui -f"
echo ""
echo "默认访问地址: http://localhost:2053"
EOF

chmod +x "${DIST_DIR}/${PACKAGE_NAME}/install-ubuntu24.sh"

# 创建卸载脚本
cat > "${DIST_DIR}/${PACKAGE_NAME}/uninstall.sh" << 'EOF'
#!/bin/bash
# YoungsCoolPlay UI 卸载脚本

set -e

INSTALL_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"
CONFIG_DIR="/etc/youngscoolplay-ui"
WEB_DIR="/var/www/youngscoolplay-ui"

echo "正在卸载 YoungsCoolPlay UI..."

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "请使用root权限运行此脚本"
    exit 1
fi

# 停止并禁用服务
systemctl stop youngscoolplay-ui 2>/dev/null || true
systemctl disable youngscoolplay-ui 2>/dev/null || true

# 删除服务文件
rm -f ${SERVICE_DIR}/youngscoolplay-ui.service

# 删除二进制文件
rm -f ${INSTALL_DIR}/youngscoolplay-ui

# 询问是否删除配置文件
read -p "是否删除配置文件和数据? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf ${CONFIG_DIR}
    rm -rf ${WEB_DIR}
    echo "配置文件和数据已删除"
fi

# 重新加载systemd
systemctl daemon-reload

echo "卸载完成！"
EOF

chmod +x "${DIST_DIR}/${PACKAGE_NAME}/uninstall.sh"

# 创建README文件
cat > "${DIST_DIR}/${PACKAGE_NAME}/README-Ubuntu24.md" << 'EOF'
# YoungsCoolPlay UI - Ubuntu 24 安装包

## 系统要求
- Ubuntu 24.04 LTS
- 64位系统 (amd64)
- root权限

## 安装步骤

1. 解压安装包:
   ```bash
   tar -xzf youngscoolplay-ui-1.0.0-ubuntu24-amd64.tar.gz
   cd youngscoolplay-ui-1.0.0-ubuntu24-amd64
   ```

2. 运行安装脚本:
   ```bash
   sudo ./install-ubuntu24.sh
   ```

3. 检查服务状态:
   ```bash
   sudo systemctl status youngscoolplay-ui
   ```

## 访问面板
- 默认地址: http://localhost:2053
- 默认用户名: admin
- 默认密码: admin

## 常用命令
- 查看服务状态: `sudo systemctl status youngscoolplay-ui`
- 启动服务: `sudo systemctl start youngscoolplay-ui`
- 停止服务: `sudo systemctl stop youngscoolplay-ui`
- 重启服务: `sudo systemctl restart youngscoolplay-ui`
- 查看日志: `sudo journalctl -u youngscoolplay-ui -f`

## 卸载
运行卸载脚本:
```bash
sudo ./uninstall.sh
```

## 故障排除
如果遇到问题，请查看日志:
```bash
sudo journalctl -u youngscoolplay-ui -n 50
```

## 支持
- GitHub: https://github.com/youngscoolplay/youngscoolplay-ui
- 文档: 查看项目README.md文件
EOF

# 创建压缩包
echo -e "${GREEN}创建压缩包...${NC}"
cd "${DIST_DIR}"
tar -czf "${PACKAGE_NAME}.tar.gz" "${PACKAGE_NAME}"
echo -e "${GREEN}✓ 创建了 ${PACKAGE_NAME}.tar.gz${NC}"

# 创建zip包
if command -v zip >/dev/null 2>&1; then
    zip -r "${PACKAGE_NAME}.zip" "${PACKAGE_NAME}" >/dev/null
    echo -e "${GREEN}✓ 创建了 ${PACKAGE_NAME}.zip${NC}"
fi

cd ..

echo ""
echo -e "${BLUE}构建摘要:${NC}"
echo -e "${GREEN}✓ 二进制文件: ${BUILD_DIR}/${NC}"
echo -e "${GREEN}✓ Ubuntu 24安装包: ${DIST_DIR}/${NC}"
echo ""

# 列出创建的文件
echo -e "${YELLOW}创建的文件:${NC}"
ls -la ${BUILD_DIR}/
echo ""
ls -la ${DIST_DIR}/*.tar.gz ${DIST_DIR}/*.zip 2>/dev/null || true

echo ""
echo -e "${GREEN}Ubuntu 24构建完成！${NC}"
echo -e "${YELLOW}安装包位置: ${DIST_DIR}/${PACKAGE_NAME}.tar.gz${NC}"