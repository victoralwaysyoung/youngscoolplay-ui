# YoungsCoolPlay UI 生产环境部署指南

## 部署包信息

### 生产环境部署包已创建完成 ✅

- **部署包名称**: `youngscoolplay-ui-production.zip`
- **压缩包大小**: 49.2 MB (51,622,468 字节)
- **创建时间**: 2025年10月5日 23:31:32
- **包含文件**: 155个文件，总大小 146.1 MB

### 部署包内容

```
youngscoolplay-ui-production/
├── youngscoolplay-ui              # 主程序二进制文件
├── web/                          # Web界面资源
├── bin/                          # 二进制工具（Xray等）
├── install.sh                    # 安装脚本
├── one-click-install.sh          # 一键安装脚本
├── deploy-to-server.sh           # 服务器部署脚本
├── youngscoolplay-ui.service     # systemd服务配置
├── youngscoolplay-ui.sh          # 管理脚本
├── LICENSE                       # 许可证文件
├── README.md                     # 部署说明
├── DEPLOYMENT_CHECKLIST.md      # 部署检查清单
└── ...                          # 其他必要文件
```

## 部署方式

### 方式一：一键安装（最简单）

直接在目标服务器上执行：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay-ui/main/scripts/one-click-install.sh)
```

**优点**：
- 无需手动上传文件
- 自动处理所有依赖
- 自动配置服务
- 适合快速部署

### 方式二：自动化部署脚本（推荐）

使用提供的自动化部署脚本：

```bash
# 1. 确保有SSH密钥访问权限
ssh-copy-id user@your-server-ip

# 2. 运行部署脚本
chmod +x youngscoolplay-ui-production/deploy-to-server.sh
./youngscoolplay-ui-production/deploy-to-server.sh your-server-ip username
```

**优点**：
- 全自动化部署流程
- 包含环境检查
- 自动错误处理
- 部署状态反馈

### 方式三：手动部署

```bash
# 1. 上传部署包到服务器
scp youngscoolplay-ui-production.zip user@server:/tmp/

# 2. 登录服务器
ssh user@server

# 3. 解压并安装
cd /tmp
unzip youngscoolplay-ui-production.zip
cd youngscoolplay-ui-production
sudo chmod +x install.sh
sudo ./install.sh

# 4. 启动服务
sudo systemctl enable youngscoolplay-ui
sudo systemctl start youngscoolplay-ui
```

## 服务器要求

### 最低系统要求

- **操作系统**: Linux (Ubuntu 18.04+, CentOS 7+, Debian 9+)
- **架构**: x86_64 (amd64)
- **内存**: 最少 512MB RAM
- **存储**: 最少 1GB 可用空间
- **网络**: 互联网连接

### 推荐配置

- **内存**: 1GB+ RAM
- **存储**: 2GB+ 可用空间
- **CPU**: 1核心+
- **网络**: 稳定的互联网连接

### 网络端口

- **默认端口**: 54321 (可配置)
- **防火墙**: 需要开放相应端口

## 部署前准备

### 1. 服务器准备

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
sudo yum update -y                       # CentOS/RHEL

# 安装基础依赖
sudo apt install -y curl wget unzip tar systemd  # Ubuntu/Debian
sudo yum install -y curl wget unzip tar systemd   # CentOS/RHEL
```

### 2. 防火墙配置

```bash
# UFW (Ubuntu)
sudo ufw allow 54321/tcp
sudo ufw enable

# firewalld (CentOS)
sudo firewall-cmd --permanent --add-port=54321/tcp
sudo firewall-cmd --reload

# iptables
sudo iptables -I INPUT -p tcp --dport 54321 -j ACCEPT
```

### 3. SSH密钥配置（推荐）

```bash
# 生成SSH密钥（如果没有）
ssh-keygen -t rsa -b 4096

# 复制公钥到服务器
ssh-copy-id user@your-server-ip
```

## 部署步骤详解

### 使用自动化部署脚本

1. **准备部署环境**
   ```bash
   # 确保部署包存在
   ls -la youngscoolplay-ui-production.zip
   
   # 解压部署包（如果需要）
   unzip youngscoolplay-ui-production.zip
   ```

2. **执行部署脚本**
   ```bash
   cd youngscoolplay-ui-production
   chmod +x deploy-to-server.sh
   ./deploy-to-server.sh 192.168.1.100 root
   ```

3. **脚本执行流程**
   - 检查本地环境和参数
   - 测试SSH连接
   - 检查服务器环境
   - 上传部署包
   - 在服务器上安装应用
   - 启动服务
   - 显示部署结果

### 部署验证

部署完成后，脚本会显示：

```
╔══════════════════════════════════════════════════════════════╗
║                        部署信息                              ║
╠══════════════════════════════════════════════════════════════╣
║ 服务器地址: 192.168.1.100                                   ║
║ 访问地址:   http://192.168.1.100:54321                      ║
║ 服务状态:   systemctl status youngscoolplay-ui              ║
║ 查看日志:   journalctl -u youngscoolplay-ui -f              ║
╚══════════════════════════════════════════════════════════════╝
```

## 部署后配置

### 1. 首次登录

1. 打开浏览器访问 `http://your-server-ip:54321`
2. 使用安装时生成的用户名和密码登录
3. **立即修改默认密码**

### 2. 基础安全配置

```bash
# 检查服务状态
sudo systemctl status youngscoolplay-ui

# 查看日志
sudo journalctl -u youngscoolplay-ui -f

# 检查端口监听
sudo netstat -tlnp | grep 54321
```

### 3. 高级配置

- 配置HTTPS证书
- 设置反向代理（Nginx/Apache）
- 配置域名解析
- 设置定期备份

## 管理和维护

### 服务管理命令

```bash
# 查看服务状态
sudo systemctl status youngscoolplay-ui

# 启动服务
sudo systemctl start youngscoolplay-ui

# 停止服务
sudo systemctl stop youngscoolplay-ui

# 重启服务
sudo systemctl restart youngscoolplay-ui

# 查看实时日志
sudo journalctl -u youngscoolplay-ui -f

# 查看历史日志
sudo journalctl -u youngscoolplay-ui -n 100
```

### 配置文件位置

- **应用目录**: `/usr/local/youngscoolplay-ui/`
- **配置目录**: `/etc/youngscoolplay-ui/`
- **日志目录**: `/var/log/youngscoolplay-ui/`
- **Web资源**: `/var/lib/youngscoolplay-ui/web/`
- **服务配置**: `/etc/systemd/system/youngscoolplay-ui.service`

### 备份建议

```bash
# 备份配置
sudo tar -czf youngscoolplay-ui-backup-$(date +%Y%m%d).tar.gz \
  /etc/youngscoolplay-ui \
  /var/lib/youngscoolplay-ui

# 定期备份脚本
echo "0 2 * * * root tar -czf /backup/youngscoolplay-ui-\$(date +\%Y\%m\%d).tar.gz /etc/youngscoolplay-ui /var/lib/youngscoolplay-ui" | sudo tee -a /etc/crontab
```

## 故障排除

### 常见问题

1. **服务启动失败**
   ```bash
   # 查看详细错误
   sudo journalctl -u youngscoolplay-ui -n 50
   
   # 检查配置文件
   sudo /usr/local/youngscoolplay-ui/youngscoolplay-ui --help
   ```

2. **端口被占用**
   ```bash
   # 查看端口占用
   sudo netstat -tlnp | grep 54321
   
   # 杀死占用进程
   sudo kill -9 <PID>
   ```

3. **权限问题**
   ```bash
   # 修复文件权限
   sudo chown -R root:root /usr/local/youngscoolplay-ui/
   sudo chmod +x /usr/local/youngscoolplay-ui/youngscoolplay-ui
   ```

4. **Web界面无法访问**
   ```bash
   # 检查防火墙
   sudo ufw status
   sudo firewall-cmd --list-ports
   
   # 检查服务监听
   sudo ss -tlnp | grep 54321
   ```

### 日志分析

```bash
# 查看应用日志
sudo tail -f /var/log/youngscoolplay-ui/app.log

# 查看错误日志
sudo tail -f /var/log/youngscoolplay-ui/error.log

# 查看系统日志
sudo journalctl -u youngscoolplay-ui --since "1 hour ago"
```

## 更新升级

### 自动更新

```bash
# 重新运行一键安装脚本
bash <(curl -Ls https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay-ui/main/scripts/one-click-install.sh)
```

### 手动更新

```bash
# 1. 停止服务
sudo systemctl stop youngscoolplay-ui

# 2. 备份当前版本
sudo cp /usr/local/youngscoolplay-ui/youngscoolplay-ui /usr/local/youngscoolplay-ui/youngscoolplay-ui.backup

# 3. 下载新版本
wget https://github.com/victoralwaysyoung/youngscoolplay-ui/releases/download/latest/youngscoolplay-ui-production.zip

# 4. 解压并替换
unzip youngscoolplay-ui-production.zip
sudo cp youngscoolplay-ui-production/youngscoolplay-ui /usr/local/youngscoolplay-ui/

# 5. 重启服务
sudo systemctl start youngscoolplay-ui
```

## 安全建议

### 基础安全

1. **修改默认密码**：安装后立即修改
2. **启用HTTPS**：配置SSL证书
3. **防火墙配置**：只开放必要端口
4. **定期更新**：保持系统和应用最新

### 高级安全

1. **反向代理**：使用Nginx/Apache作为前端
2. **访问控制**：限制IP访问范围
3. **双因素认证**：启用2FA
4. **监控告警**：配置异常监控

## 性能优化

### 系统优化

```bash
# 调整文件描述符限制
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# 优化网络参数
echo "net.core.somaxconn = 65536" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 应用优化

- 配置适当的并发连接数
- 启用gzip压缩
- 配置缓存策略
- 监控资源使用情况

## 技术支持

如果在部署过程中遇到问题：

1. **查看文档**：<mcfile name="DEPLOYMENT_CHECKLIST.md" path="C:/Users/24814/Desktop/youngscoolplay/youngscoolplay-ui-production/DEPLOYMENT_CHECKLIST.md"></mcfile>
2. **GitHub Issues**：https://github.com/victoralwaysyoung/youngscoolplay-ui/issues
3. **提交问题**：提供详细的错误信息和系统环境

---

**部署成功确认清单**

- [ ] 部署包已创建并验证
- [ ] 服务器环境已准备
- [ ] 部署脚本执行成功
- [ ] 服务正常启动
- [ ] Web界面可以访问
- [ ] 基础功能正常
- [ ] 安全配置已完成
- [ ] 备份和监控已设置