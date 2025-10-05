@echo off
REM YoungsCoolPlay UI Build Script for Windows
REM This script builds the application for multiple platforms

setlocal enabledelayedexpansion

echo === YoungsCoolPlay UI Build Script ===

REM Project information
set PROJECT_NAME=youngscoolplay-ui
set /p VERSION=<config\version 2>nul || set VERSION=dev
for /f "tokens=*" %%i in ('git rev-parse --short HEAD 2^>nul') do set GIT_COMMIT=%%i
if not defined GIT_COMMIT set GIT_COMMIT=unknown

REM Build directories
set BUILD_DIR=build
set DIST_DIR=dist

echo Version: %VERSION%
echo Git Commit: %GIT_COMMIT%
echo.

REM Clean previous builds
echo Cleaning previous builds...
if exist %BUILD_DIR% rmdir /s /q %BUILD_DIR%
if exist %DIST_DIR% rmdir /s /q %DIST_DIR%
mkdir %BUILD_DIR%
mkdir %DIST_DIR%

REM Build flags
set LDFLAGS=-w -s -X 'main.version=%VERSION%' -X 'main.gitCommit=%GIT_COMMIT%'

echo Building for multiple platforms...

REM Build for Linux AMD64
echo Building for linux/amd64...
set GOOS=linux
set GOARCH=amd64
set CGO_ENABLED=0
go build -ldflags="%LDFLAGS%" -o "%BUILD_DIR%\%PROJECT_NAME%-linux-amd64" .
if errorlevel 1 (
    echo Failed to build for linux/amd64
    exit /b 1
)
echo Successfully built %PROJECT_NAME%-linux-amd64

REM Build for Linux ARM64
echo Building for linux/arm64...
set GOOS=linux
set GOARCH=arm64
set CGO_ENABLED=0
go build -ldflags="%LDFLAGS%" -o "%BUILD_DIR%\%PROJECT_NAME%-linux-arm64" .
if errorlevel 1 (
    echo Failed to build for linux/arm64
    exit /b 1
)
echo Successfully built %PROJECT_NAME%-linux-arm64

REM Build for Windows AMD64
echo Building for windows/amd64...
set GOOS=windows
set GOARCH=amd64
set CGO_ENABLED=0
go build -ldflags="%LDFLAGS%" -o "%BUILD_DIR%\%PROJECT_NAME%-windows-amd64.exe" .
if errorlevel 1 (
    echo Failed to build for windows/amd64
    exit /b 1
)
echo Successfully built %PROJECT_NAME%-windows-amd64.exe

REM Build for macOS AMD64
echo Building for darwin/amd64...
set GOOS=darwin
set GOARCH=amd64
set CGO_ENABLED=0
go build -ldflags="%LDFLAGS%" -o "%BUILD_DIR%\%PROJECT_NAME%-darwin-amd64" .
if errorlevel 1 (
    echo Failed to build for darwin/amd64
    exit /b 1
)
echo Successfully built %PROJECT_NAME%-darwin-amd64

REM Build for macOS ARM64
echo Building for darwin/arm64...
set GOOS=darwin
set GOARCH=arm64
set CGO_ENABLED=0
go build -ldflags="%LDFLAGS%" -o "%BUILD_DIR%\%PROJECT_NAME%-darwin-arm64" .
if errorlevel 1 (
    echo Failed to build for darwin/arm64
    exit /b 1
)
echo Successfully built %PROJECT_NAME%-darwin-arm64

echo.
echo Creating distribution packages...

REM Create Windows package
set PACKAGE_NAME=%PROJECT_NAME%-%VERSION%-windows-amd64
mkdir "%DIST_DIR%\%PACKAGE_NAME%"
copy "%BUILD_DIR%\%PROJECT_NAME%-windows-amd64.exe" "%DIST_DIR%\%PACKAGE_NAME%\"
if exist README.md copy README.md "%DIST_DIR%\%PACKAGE_NAME%\"
if exist LICENSE copy LICENSE "%DIST_DIR%\%PACKAGE_NAME%\"
if exist web xcopy web "%DIST_DIR%\%PACKAGE_NAME%\web\" /e /i /q
if exist bin xcopy bin "%DIST_DIR%\%PACKAGE_NAME%\bin\" /e /i /q

REM Create install.bat for Windows
echo @echo off > "%DIST_DIR%\%PACKAGE_NAME%\install.bat"
echo echo Installing YoungsCoolPlay UI... >> "%DIST_DIR%\%PACKAGE_NAME%\install.bat"
echo copy %PROJECT_NAME%-windows-amd64.exe C:\Windows\System32\%PROJECT_NAME%.exe >> "%DIST_DIR%\%PACKAGE_NAME%\install.bat"
echo echo Installation completed! >> "%DIST_DIR%\%PACKAGE_NAME%\install.bat"
echo echo Run '%PROJECT_NAME%' to start the application. >> "%DIST_DIR%\%PACKAGE_NAME%\install.bat"

REM Create Linux package
set PACKAGE_NAME=%PROJECT_NAME%-%VERSION%-linux-amd64
mkdir "%DIST_DIR%\%PACKAGE_NAME%"
copy "%BUILD_DIR%\%PROJECT_NAME%-linux-amd64" "%DIST_DIR%\%PACKAGE_NAME%\"
if exist README.md copy README.md "%DIST_DIR%\%PACKAGE_NAME%\"
if exist LICENSE copy LICENSE "%DIST_DIR%\%PACKAGE_NAME%\"
if exist web xcopy web "%DIST_DIR%\%PACKAGE_NAME%\web\" /e /i /q
if exist bin xcopy bin "%DIST_DIR%\%PACKAGE_NAME%\bin\" /e /i /q

echo.
echo Build Summary:
echo Binaries built in: %BUILD_DIR%\
echo Packages created in: %DIST_DIR%\
echo.

echo Created files:
dir /b %BUILD_DIR%
echo.
dir /b %DIST_DIR%

echo.
echo Build completed successfully!

endlocal