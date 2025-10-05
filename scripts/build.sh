#!/bin/bash

# YoungsCoolPlay UI Build Script
# This script builds the application for multiple platforms

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project information
PROJECT_NAME="youngscoolplay-ui"
VERSION=$(cat config/version 2>/dev/null || echo "dev")
BUILD_TIME=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Build directory
BUILD_DIR="build"
DIST_DIR="dist"

echo -e "${BLUE}=== YoungsCoolPlay UI Build Script ===${NC}"
echo -e "${YELLOW}Version: ${VERSION}${NC}"
echo -e "${YELLOW}Build Time: ${BUILD_TIME}${NC}"
echo -e "${YELLOW}Git Commit: ${GIT_COMMIT}${NC}"
echo ""

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf ${BUILD_DIR}
rm -rf ${DIST_DIR}
mkdir -p ${BUILD_DIR}
mkdir -p ${DIST_DIR}

# Build flags
LDFLAGS="-w -s -X 'main.version=${VERSION}' -X 'main.buildTime=${BUILD_TIME}' -X 'main.gitCommit=${GIT_COMMIT}'"

# Build for different platforms
build_platform() {
    local os=$1
    local arch=$2
    local ext=$3
    
    echo -e "${GREEN}Building for ${os}/${arch}...${NC}"
    
    local output_name="${PROJECT_NAME}"
    if [ "$os" = "windows" ]; then
        output_name="${PROJECT_NAME}.exe"
    fi
    
    GOOS=${os} GOARCH=${arch} CGO_ENABLED=0 go build \
        -ldflags="${LDFLAGS}" \
        -o "${BUILD_DIR}/${PROJECT_NAME}-${os}-${arch}${ext}" \
        .
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully built ${PROJECT_NAME}-${os}-${arch}${ext}${NC}"
    else
        echo -e "${RED}✗ Failed to build ${PROJECT_NAME}-${os}-${arch}${ext}${NC}"
        exit 1
    fi
}

# Build for multiple platforms
echo -e "${BLUE}Building for multiple platforms...${NC}"

# Linux builds
build_platform "linux" "amd64" ""
build_platform "linux" "arm64" ""
build_platform "linux" "386" ""

# Windows builds
build_platform "windows" "amd64" ".exe"
build_platform "windows" "386" ".exe"

# macOS builds
build_platform "darwin" "amd64" ""
build_platform "darwin" "arm64" ""

# FreeBSD builds
build_platform "freebsd" "amd64" ""

echo ""
echo -e "${BLUE}Creating distribution packages...${NC}"

# Create distribution packages
create_package() {
    local os=$1
    local arch=$2
    local ext=$3
    
    local binary_name="${PROJECT_NAME}-${os}-${arch}${ext}"
    local package_name="${PROJECT_NAME}-${VERSION}-${os}-${arch}"
    
    echo -e "${GREEN}Creating package for ${os}/${arch}...${NC}"
    
    # Create package directory
    mkdir -p "${DIST_DIR}/${package_name}"
    
    # Copy binary
    cp "${BUILD_DIR}/${binary_name}" "${DIST_DIR}/${package_name}/"
    
    # Copy essential files
    cp README.md "${DIST_DIR}/${package_name}/" 2>/dev/null || echo "README.md not found"
    cp LICENSE "${DIST_DIR}/${package_name}/" 2>/dev/null || echo "LICENSE not found"
    
    # Copy configuration files
    if [ -d "bin" ]; then
        mkdir -p "${DIST_DIR}/${package_name}/bin"
        cp bin/config.json "${DIST_DIR}/${package_name}/bin/" 2>/dev/null || echo "config.json not found"
    fi
    
    # Copy web assets
    if [ -d "web" ]; then
        cp -r web "${DIST_DIR}/${package_name}/"
    fi
    
    # Create install script for Linux/macOS
    if [ "$os" != "windows" ]; then
        cat > "${DIST_DIR}/${package_name}/install.sh" << 'EOF'
#!/bin/bash
# Installation script for YoungsCoolPlay UI

set -e

INSTALL_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"
CONFIG_DIR="/etc/youngscoolplay-ui"

echo "Installing YoungsCoolPlay UI..."

# Copy binary
sudo cp youngscoolplay-ui* ${INSTALL_DIR}/youngscoolplay-ui
sudo chmod +x ${INSTALL_DIR}/youngscoolplay-ui

# Create config directory
sudo mkdir -p ${CONFIG_DIR}
sudo cp -r web ${CONFIG_DIR}/
sudo cp -r bin ${CONFIG_DIR}/ 2>/dev/null || true

# Create systemd service
sudo tee ${SERVICE_DIR}/youngscoolplay-ui.service > /dev/null << 'EOFSERVICE'
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

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable youngscoolplay-ui
sudo systemctl start youngscoolplay-ui

echo "Installation completed!"
echo "Service status: sudo systemctl status youngscoolplay-ui"
echo "View logs: sudo journalctl -u youngscoolplay-ui -f"
EOF
        chmod +x "${DIST_DIR}/${package_name}/install.sh"
    fi
    
    # Create archive
    cd "${DIST_DIR}"
    if command -v tar >/dev/null 2>&1; then
        tar -czf "${package_name}.tar.gz" "${package_name}"
        echo -e "${GREEN}✓ Created ${package_name}.tar.gz${NC}"
    fi
    
    if command -v zip >/dev/null 2>&1; then
        zip -r "${package_name}.zip" "${package_name}" >/dev/null
        echo -e "${GREEN}✓ Created ${package_name}.zip${NC}"
    fi
    
    cd ..
}

# Create packages for all platforms
create_package "linux" "amd64" ""
create_package "linux" "arm64" ""
create_package "windows" "amd64" ".exe"
create_package "darwin" "amd64" ""
create_package "darwin" "arm64" ""

echo ""
echo -e "${BLUE}Build Summary:${NC}"
echo -e "${GREEN}✓ Binaries built in: ${BUILD_DIR}/${NC}"
echo -e "${GREEN}✓ Packages created in: ${DIST_DIR}/${NC}"
echo ""

# List all created files
echo -e "${YELLOW}Created files:${NC}"
ls -la ${BUILD_DIR}/
echo ""
ls -la ${DIST_DIR}/*.tar.gz ${DIST_DIR}/*.zip 2>/dev/null || true

echo ""
echo -e "${GREEN}Build completed successfully!${NC}"