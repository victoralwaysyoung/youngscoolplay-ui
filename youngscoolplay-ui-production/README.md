# YoungsCoolPlay UI - 生产环境部署包

## 快速部署

### 一键安装（推荐）

```bash
bash <(curl -Ls https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay-ui/main/scripts/one-click-install.sh)
```

### 手动安装

1. **上传文件到服务器**
   ```bash
   # 解压部署包
   tar -xzf youngscoolplay-ui-production.tar.gz
   cd youngscoolplay-ui-production
   ```

2. **运行安装脚本**
   ```bash
   sudo chmod +x install.sh
   sudo ./install.sh
   ```

3. **启动服务**
   ```bash
   sudo systemctl enable youngscoolplay-ui
   sudo systemctl start youngscoolplay-ui
   ```

## 文件说明

- `youngscoolplay-ui` - 主程序二进制文件
- `web/` - Web界面资源文件
- `bin/` - Xray等二进制工具
- `install.sh` - 安装脚本
- `one-click-install.sh` - 一键安装脚本
- `youngscoolplay-ui.service` - systemd服务配置
- `youngscoolplay-ui.sh` - 管理脚本

## 系统要求

- Linux 系统（Ubuntu 18.04+, CentOS 7+, Debian 9+）
- 64位架构（amd64）
- Root权限
- 网络连接

## 管理命令

```bash
# 查看状态
systemctl status youngscoolplay-ui

# 启动/停止/重启
systemctl start youngscoolplay-ui
systemctl stop youngscoolplay-ui
systemctl restart youngscoolplay-ui

# 查看日志
journalctl -u youngscoolplay-ui -f
```

## 默认配置

- 端口：54321
- 配置目录：`/etc/youngscoolplay-ui/`
- 日志目录：`/var/log/youngscoolplay-ui/`
- Web目录：`/var/lib/youngscoolplay-ui/web/`

## 技术支持

- GitHub: https://github.com/victoralwaysyoung/youngscoolplay-ui
- Issues: https://github.com/victoralwaysyoung/youngscoolplay-ui/issues