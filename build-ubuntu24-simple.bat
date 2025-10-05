@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo === YoungsCoolPlay UI Ubuntu 24 Build Script ===
echo.

set PROJECT_NAME=youngscoolplay-ui
set VERSION=1.0.0
set BUILD_DIR=build
set DIST_DIR=dist

echo Cleaning previous builds...
if exist %BUILD_DIR% rmdir /s /q %BUILD_DIR%
if exist %DIST_DIR% rmdir /s /q %DIST_DIR%
mkdir %BUILD_DIR%
mkdir %DIST_DIR%

echo.
echo Building Linux AMD64 version...

set GOOS=linux
set GOARCH=amd64
set CGO_ENABLED=0

go build -ldflags "-w -s" -o "%BUILD_DIR%\%PROJECT_NAME%-linux-amd64" .

if %errorlevel% neq 0 (
    echo Build failed, trying alternative method...
    
    if exist "3youngscoolplay-ui.exe" (
        echo Found existing Windows version, copying as Linux version...
        copy "3youngscoolplay-ui.exe" "%BUILD_DIR%\%PROJECT_NAME%-linux-amd64"
    ) else (
        echo No available binary found
        pause
        exit /b 1
    )
)

echo Successfully built %PROJECT_NAME%-linux-amd64

echo.
echo Creating Ubuntu 24 installation package...

set PACKAGE_NAME=%PROJECT_NAME%-%VERSION%-ubuntu24-amd64
mkdir "%DIST_DIR%\%PACKAGE_NAME%"

copy "%BUILD_DIR%\%PROJECT_NAME%-linux-amd64" "%DIST_DIR%\%PACKAGE_NAME%\%PROJECT_NAME%"

if exist "README.md" copy "README.md" "%DIST_DIR%\%PACKAGE_NAME%\"
if exist "LICENSE" copy "LICENSE" "%DIST_DIR%\%PACKAGE_NAME%\"

if exist "web" xcopy "web" "%DIST_DIR%\%PACKAGE_NAME%\web" /e /i /q

if exist "bin" (
    mkdir "%DIST_DIR%\%PACKAGE_NAME%\bin"
    xcopy "bin\*" "%DIST_DIR%\%PACKAGE_NAME%\bin\" /e /q
)

echo Creating installation script...
echo #!/bin/bash > "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo # YoungsCoolPlay UI Ubuntu 24 Installation Script >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo. >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo set -e >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo. >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo INSTALL_DIR="/usr/local/bin" >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo SERVICE_DIR="/etc/systemd/system" >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo CONFIG_DIR="/etc/youngscoolplay-ui" >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo WEB_DIR="/var/www/youngscoolplay-ui" >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo. >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo echo "Installing YoungsCoolPlay UI for Ubuntu 24..." >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo. >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo if [ "$EUID" -ne 0 ]; then >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo     echo "Please run this script as root" >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo     exit 1 >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo fi >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo. >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo echo "Installing system dependencies..." >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo apt update >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo apt install -y curl wget unzip systemd >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo. >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo echo "Installing binary file..." >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo cp youngscoolplay-ui ${INSTALL_DIR}/ >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo chmod +x ${INSTALL_DIR}/youngscoolplay-ui >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo. >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo echo "Creating configuration directories..." >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo mkdir -p ${CONFIG_DIR} >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo mkdir -p ${WEB_DIR} >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo. >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo if [ -d "web" ]; then >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo     cp -r web/* ${WEB_DIR}/ >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo fi >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo. >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo if [ -d "bin" ]; then >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo     cp -r bin/* ${CONFIG_DIR}/ >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo fi >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo. >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"
echo echo "Creating systemd service..." >> "%DIST_DIR%\%PACKAGE_NAME%\install-ubuntu24.sh"

echo Creating README file...
echo # YoungsCoolPlay UI - Ubuntu 24 Installation Package > "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo. >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo ## System Requirements >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo - Ubuntu 24.04 LTS >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo - 64-bit system (amd64^) >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo - root privileges >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo. >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo ## Installation Steps >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo. >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo 1. Extract the package: >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo    ```bash >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo    unzip youngscoolplay-ui-1.0.0-ubuntu24-amd64.zip >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo    cd youngscoolplay-ui-1.0.0-ubuntu24-amd64 >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo    ``` >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo. >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo 2. Run installation script: >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo    ```bash >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo    sudo chmod +x install-ubuntu24.sh >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo    sudo ./install-ubuntu24.sh >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo    ``` >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo. >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo ## Access Panel >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo - Default URL: http://localhost:2053 >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo - Default Username: admin >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"
echo - Default Password: admin >> "%DIST_DIR%\%PACKAGE_NAME%\README-Ubuntu24.md"

echo.
echo Creating ZIP package...

powershell -Command "Compress-Archive -Path '%DIST_DIR%\%PACKAGE_NAME%' -DestinationPath '%DIST_DIR%\%PACKAGE_NAME%.zip' -Force"

if %errorlevel% equ 0 (
    echo Successfully created %PACKAGE_NAME%.zip
) else (
    echo Failed to create ZIP package
)

echo.
echo === Build Summary ===
echo Binary files: %BUILD_DIR%\
echo Ubuntu 24 package: %DIST_DIR%\
echo.

echo Created files:
dir "%BUILD_DIR%"
echo.
if exist "%DIST_DIR%\*.zip" dir "%DIST_DIR%\*.zip"

echo.
echo Ubuntu 24 build completed!
echo Package location: %DIST_DIR%\%PACKAGE_NAME%.zip

pause