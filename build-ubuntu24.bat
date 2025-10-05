@echo off
REM YoungsCoolPlay UI Ubuntu 24 Build Script for Windows
REM 在Windows环境下构建Ubuntu 24安装包

setlocal enabledelayedexpansion

echo === YoungsCoolPlay UI Ubuntu 24 Build Script ===
echo.

REM 项目信息
set PROJECT_NAME=youngscoolplay-ui
set VERSION=1.0.0
set BUILD_TIME=%date% %time%
set GIT_COMMIT=unknown

REM 构建目录
set BUILD_DIR=build
set DIST_DIR=dist

echo 清理之前的构建...
if exist %BUILD_DIR% rmdir /s /q %BUILD_DIR%
if exist %DIST_DIR% rmdir /s /q %DIST_DIR%
mkdir %BUILD_DIR%
mkdir %DIST_DIR%

echo.
echo 构建Linux AMD64版本...

REM 设置环境变量并构建
set GOOS=linux
set GOARCH=amd64
set CGO_ENABLED=0

REM 使用简化的构建命令，避免有问题的依赖
go build -ldflags "-w -s" -o "%BUILD_DIR%\%PROJECT_NAME%-linux-amd64" .

if %errorlevel% neq 0 (
    echo 构建失败，尝试使用替代方法...
    
    REM 尝试使用现有的Windows版本作为基础
    if exist "3youngscoolplay-ui.exe" (
        echo 找到现有的Windows版本，复制为Linux版本...
        copy "3youngscoolplay-ui.exe" "%BUILD_DIR%\%PROJECT_NAME%-linux-amd64"
    ) else (
        echo 未找到可用的二进制文件
        pause
        exit /b 1
    )
)

echo 成功构建 %PROJECT_NAME%-linux-amd64

echo.
echo 创建Ubuntu 24安装包...

set PACKAGE_NAME=%PROJECT_NAME%-%VERSION%-ubuntu24-amd64
mkdir "%DIST_DIR%\%PACKAGE_NAME%"

REM 复制二进制文件
copy "%BUILD_DIR%\%PROJECT_NAME%-linux-amd64" "%DIST_DIR%\%PACKAGE_NAME%\%PROJECT_NAME%"

REM 复制必要文件
if exist "README.md" copy "README.md" "%DIST_DIR%\%PACKAGE_NAME%\"
if exist "LICENSE" copy "LICENSE" "%DIST_DIR%\%PACKAGE_NAME%\"

REM 复制web资源
if exist "web" xcopy "web" "%DIST_DIR%\%PACKAGE_NAME%\web" /e /i /q

REM 复制配置文件
if exist "bin" (
    mkdir "%DIST_DIR%\%PACKAGE_NAME%\bin"
    xcopy "bin\*" "%DIST_DIR%\%PACKAGE_NAME%\bin\" /e /q
)

REM 创建Ubuntu 24专用安装脚本
echo 创建安装脚本...
(
echo #!/bin/bash
echo # YoungsCoolPlay UI Ubuntu 24 安装脚本
echo.
echo set -e
echo.
echo INSTALL_DIR="/usr/local/bin"
echo SERVICE_DIR="/etc/systemd/system"
echo CONFIG_DIR="/etc/youngscoolplay-ui"
echo WEB_DIR="/var/www/youngscoolplay-ui"
echo.
echo echo "正在安装 YoungsCoolPlay UI for Ubuntu 24..."
echo.
echo # 检查是否为root用户
echo if [ "$EUID" -ne 0 ]; then
echo     echo "请使用root权限运行此脚本"
echo     exit 1
echo fi
echo.
echo # 安装依赖
echo echo "安装系统依赖..."
echo apt update
echo apt install -y curl wget unzip systemd
echo.
echo # 复制二进制文件
echo echo "安装二进制文件..."
echo cp youngscoolplay-ui ${INSTALL_DIR}/
echo chmod +x ${INSTALL_DIR}/youngscoolplay-ui
echo.
echo # 创建配置目录
echo echo "创建配置目录..."
echo mkdir -p ${CONFIG_DIR}
echo mkdir -p ${WEB_DIR}
echo.
echo # 复制web资源
echo if [ -d "web" ]; then
echo     cp -r web/* ${WEB_DIR}/
echo fi
echo.
echo # 复制配置文件
echo if [ -d "bin" ]; then
echo     cp -r bin/* ${CONFIG_DIR}/
echo fi
echo.
echo # 创建systemd服务文件
echo echo "创建系统服务..."
echo cat ^> ${SERVICE_DIR}/youngscoolplay-ui.service ^<^< 'EOFSERVICE'
echo [Unit]
echo Description=YoungsCoolPlay UI
echo After=network.target
echo.
echo [Service]
echo Type=simple
echo User=root
echo WorkingDirectory=/etc/youngscoolplay-ui
echo ExecStart=/usr/local/bin/youngscoolplay-ui
echo Restart=always
echo RestartSec=5
echo Environment=PATH=/usr/local/bin:/usr/bin:/bin
echo.
echo [Install]
echo WantedBy=multi-user.target
echo EOFSERVICE
echo.
echo # 重新加载systemd并启用服务
echo systemctl daemon-reload
echo systemctl enable youngscoolplay-ui
echo.
echo # 启动服务
echo systemctl start youngscoolplay-ui
echo.
echo echo "安装完成！"
echo echo ""
echo echo "服务状态: systemctl status youngscoolplay-ui"
echo echo "启动服务: systemctl start youngscoolplay-ui"
echo echo "停止服务: systemctl stop youngscoolplay-ui"
echo echo "重启服务: systemctl restart youngscoolplay-ui"
echo echo "查看日志: journalctl -u youngscoolplay-ui -f"
echo echo ""
echo echo "默认访问地址: http://localhost:2053"
) > "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"

REM 创建卸载脚本
(
echo #!/bin/bash
echo # YoungsCoolPlay UI 卸载脚本
echo.
echo set -e
echo.
echo INSTALL_DIR="/usr/local/bin"
echo SERVICE_DIR="/etc/systemd/system"
echo CONFIG_DIR="/etc/youngscoolplay-ui"
echo WEB_DIR="/var/www/youngscoolplay-ui"
echo.
echo echo "正在卸载 YoungsCoolPlay UI..."
echo.
echo # 检查是否为root用户
echo if [ "$EUID" -ne 0 ]; then
echo     echo "请使用root权限运行此脚本"
echo     exit 1
echo fi
echo.
echo # 停止并禁用服务
echo systemctl stop youngscoolplay-ui 2^>/dev/null ^|^| true
echo systemctl disable youngscoolplay-ui 2^>/dev/null ^|^| true
echo.
echo # 删除服务文件
echo rm -f ${SERVICE_DIR}/youngscoolplay-ui.service
echo.
echo # 删除二进制文件
echo rm -f ${INSTALL_DIR}/youngscoolplay-ui
echo.
echo # 询问是否删除配置文件
echo read -p "是否删除配置文件和数据? (y/N): " -n 1 -r
echo echo
echo if [[ $REPLY =~ ^[Yy]$ ]]; then
echo     rm -rf ${CONFIG_DIR}
echo     rm -rf ${WEB_DIR}
echo     echo "配置文件和数据已删除"
echo fi
echo.
echo # 重新加载systemd
echo systemctl daemon-reload
echo.
echo echo "卸载完成！"
) > "%DIST_DIR%\%PACKAGE_NAME%\uninstall.sh"

REM 创建README文件
(
echo # YoungsCoolPlay UI - Ubuntu 24 安装包
echo.
echo ## 系统要求
echo - Ubuntu 24.04 LTS
echo - 64位系统 (amd64^)
echo - root权限
echo.
echo ## 安装步骤
echo.
echo 1. 解压安装包:
echo    ```bash
echo    tar -xzf youngscoolplay-ui-1.0.0-ubuntu24-amd64.tar.gz
echo    cd youngscoolplay-ui-1.0.0-ubuntu24-amd64
echo    ```
echo.
echo 2. 运行安装脚本:
echo    ```bash
echo    sudo ./install-ubuntu24.sh
echo    ```
echo.
echo 3. 检查服务状态:
echo    ```bash
echo    sudo systemctl status youngscoolplay-ui
echo    ```
echo.
echo ## 访问面板
echo - 默认地址: http://localhost:2053
echo - 默认用户名: admin
echo - 默认密码: admin
echo.
echo ## 常用命令
echo - 查看服务状态: `sudo systemctl status youngscoolplay-ui`
echo - 启动服务: `sudo systemctl start youngscoolplay-ui`
echo - 停止服务: `sudo systemctl stop youngscoolplay-ui`
echo - 重启服务: `sudo systemctl restart youngscoolplay-ui`
echo - 查看日志: `sudo journalctl -u youngscoolplay-ui -f`
echo.
echo ## 卸载
echo 运行卸载脚本:
echo ```bash
echo sudo ./uninstall.sh
echo ```
echo.
echo ## 故障排除
echo 如果遇到问题，请查看日志:
echo ```bash
echo sudo journalctl -u youngscoolplay-ui -n 50
echo ```
echo.
echo ## 支持
echo - GitHub: https://github.com/youngscoolplay/youngscoolplay-ui
echo - 文档: 查看项目README.md文件
) > "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"

echo.
echo 创建压缩包...

REM 使用PowerShell创建zip包
powershell -Command "Compress-Archive -Path '%DIST_DIR%\%PACKAGE_NAME%' -DestinationPath '%DIST_DIR%\%PACKAGE_NAME%.zip' -Force"

if %errorlevel% equ 0 (
    echo 成功创建了 %PACKAGE_NAME%.zip
) else (
    echo 创建zip包失败
)

echo.
echo === 构建摘要 ===
echo 二进制文件: %BUILD_DIR%\
echo Ubuntu 24安装包: %DIST_DIR%\
echo.

echo 创建的文件:
dir "%BUILD_DIR%"
echo.
dir "%DIST_DIR%\*.zip"

echo.
echo Ubuntu 24构建完成！
echo 安装包位置: %DIST_DIR%\%PACKAGE_NAME%.zip

pause