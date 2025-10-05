# YoungsCoolPlay UI

一个功能强大、易于使用的 Xray 面板管理工具，基于 3x-ui 优化改进。

## ✨ 特性

- 🚀 **一键安装部署** - 支持 `bash <(curl -Ls ...)` 快速部署
- 🎨 **现代化界面** - 简洁美观的 Web 管理界面
- 🔧 **完整功能** - 支持所有 Xray 协议和配置
- 🛡️ **安全可靠** - 内置安全防护和访问控制
- 📱 **响应式设计** - 支持桌面和移动设备
- 🌍 **多语言支持** - 支持中文、英文等多种语言

## 🚀 快速部署

### 一键安装（推荐）

```bash
bash <(curl -Ls https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay-ui/main/scripts/one-click-install.sh)
```

### 其他部署方式

#### 手动安装

1. 下载部署包：
```bash
wget https://github.com/victoralwaysyoung/youngscoolplay-ui/releases/download/latest/youngscoolplay-ui-production.zip
```

2. 解压并安装：
```bash
unzip youngscoolplay-ui-production.zip
cd youngscoolplay-ui-production
sudo chmod +x install.sh
sudo ./install.sh
```

#### 自动化部署脚本

```bash
# 下载部署包
wget https://github.com/victoralwaysyoung/youngscoolplay-ui/releases/download/latest/youngscoolplay-ui-production.zip
unzip youngscoolplay-ui-production.zip
cd youngscoolplay-ui-production

# 使用自动化部署脚本
chmod +x deploy-to-server.sh
./deploy-to-server.sh your-server-ip username
```

## 📋 系统要求

- **操作系统**: Linux (Ubuntu 18.04+, CentOS 7+, Debian 9+)
- **架构**: x86_64 (amd64)
- **内存**: 最少 512MB RAM
- **存储**: 最少 1GB 可用空间
- **网络**: 互联网连接

## 🔧 管理命令

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

## 🌐 访问面板

安装完成后，通过浏览器访问：

```
http://your-server-ip:54321
```

默认登录信息将在安装完成后显示。

## 📚 详细文档

- [部署方法详解](DEPLOYMENT_METHODS.md)
- [生产环境部署指南](PRODUCTION_DEPLOYMENT_GUIDE.md)
- [部署检查清单](youngscoolplay-ui-production/DEPLOYMENT_CHECKLIST.md)

## 🔒 安全建议

1. **修改默认密码** - 安装后立即修改默认登录密码
2. **配置防火墙** - 只开放必要的端口
3. **启用 HTTPS** - 配置 SSL 证书
4. **定期更新** - 保持系统和应用最新版本

## 🆚 与 3x-ui 的改进

- ✅ 更好的错误处理和日志记录
- ✅ 增强的安全配置
- ✅ 多防火墙支持 (UFW, firewalld, iptables)
- ✅ 自动配置备份
- ✅ 完整的服务配置
- ✅ 详细的部署文档

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来帮助改进项目。

## 📄 许可证

本项目基于 [GPL-3.0](LICENSE) 许可证开源。

## 🙏 致谢

感谢 [3x-ui](https://github.com/MHSanaei/3x-ui) 项目提供的基础框架。