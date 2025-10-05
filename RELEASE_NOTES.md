# YoungsCoolPlay UI - Ubuntu 24 Release

## 版本信息
- **版本**: v1.0.0-ubuntu24
- **发布日期**: 2025年10月5日
- **目标系统**: Ubuntu 24.04 LTS (AMD64)

## 新功能和改进

### 🎯 Ubuntu 24 专门优化
- 专门为 Ubuntu 24.04 LTS 系统编译和优化
- 包含完整的安装脚本和系统服务配置
- 支持 systemd 服务管理

### 🔧 项目重构
- 更新模块路径为 `github.com/victoralwaysyoung/youngscoolplay-ui`
- 统一项目命名规范，从 `YOUNGSCOOLPLAY-UI` 改为 `youngscoolplay-ui`
- 修复所有类型引用错误（`TgBot` → `Tgbot`）

### 📦 部署包内容
- **二进制文件**: `youngscoolplay-ui` (Linux AMD64)
- **Web资源**: 完整的前端界面文件
- **配置文件**: 默认配置和示例文件
- **安装脚本**: `install.sh` 一键安装脚本
- **服务文件**: `youngscoolplay-ui.service` systemd 服务配置
- **文档**: 详细的安装和使用说明

## 安装方法

### 快速安装
```bash
# 下载部署包
wget https://github.com/victoralwaysyoung/youngscoolplay-ui/releases/download/v1.0.0/youngscoolplay-ui-production.zip

# 解压
cd /opt
unzip youngscoolplay-ui-production.zip

# 运行安装脚本
sudo chmod +x install.sh
sudo ./install.sh
```

### 从源码部署
```bash
# 克隆仓库
git clone https://github.com/victoralwaysyoung/youngscoolplay-ui.git
cd youngscoolplay-ui

# 使用部署脚本
chmod +x scripts/deploy.sh
sudo ./scripts/deploy.sh
```

## 系统要求
- Ubuntu 24.04 LTS
- 64位 AMD64 架构
- 至少 512MB 内存
- 至少 100MB 磁盘空间
- systemd 支持

## 服务管理
```bash
# 查看服务状态
sudo systemctl status youngscoolplay-ui

# 启动服务
sudo systemctl start youngscoolplay-ui

# 停止服务
sudo systemctl stop youngscoolplay-ui

# 重启服务
sudo systemctl restart youngscoolplay-ui

# 查看日志
sudo journalctl -u youngscoolplay-ui -f
```

## 配置文件位置
- **主配置**: `/etc/youngscoolplay-ui/`
- **Web资源**: `/var/www/youngscoolplay-ui/`
- **日志文件**: `/var/log/youngscoolplay-ui/`
- **二进制文件**: `/usr/local/bin/youngscoolplay-ui`

## 更新内容

### 修复的问题
- ✅ 修复模块路径引用错误
- ✅ 统一项目命名规范
- ✅ 修复 Telegram Bot 类型引用错误
- ✅ 更新所有文档中的 GitHub 仓库地址
- ✅ 优化 systemd 服务配置

### 技术改进
- 🔄 重构 Go 模块依赖管理
- 🔄 优化编译参数，减小二进制文件大小
- 🔄 改进部署脚本的错误处理
- 🔄 增强日志记录和监控功能

## 已知问题
- 无已知严重问题

## 下一版本计划
- 支持更多 Linux 发行版
- 增加 Docker 容器化部署
- 改进 Web 界面用户体验
- 增加更多监控和统计功能

## 支持和反馈
- **GitHub Issues**: [提交问题](https://github.com/victoralwaysyoung/youngscoolplay-ui/issues)
- **讨论区**: [GitHub Discussions](https://github.com/victoralwaysyoung/youngscoolplay-ui/discussions)

---

**注意**: 这是专门为 Ubuntu 24 优化的版本，如果您使用其他系统，请查看相应的发布版本。