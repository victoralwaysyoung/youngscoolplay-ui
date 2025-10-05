# YoungsCoolPlay UI 部署检查清单

## 文件完整性验证

### 核心文件检查 ✅

- [x] `youngscoolplay-ui` - 主程序二进制文件
- [x] `web/` - Web界面资源目录
- [x] `bin/` - 二进制工具目录
  - [x] `geoip.dat` - IP地理位置数据
  - [x] `geosite.dat` - 网站分类数据
  - [x] `xray-windows-amd64` - Xray核心程序
- [x] `install.sh` - 安装脚本
- [x] `one-click-install.sh` - 一键安装脚本
- [x] `youngscoolplay-ui.service` - systemd服务配置
- [x] `youngscoolplay-ui.sh` - 管理脚本
- [x] `LICENSE` - 许可证文件
- [x] `README.md` - 部署说明文档

### 部署包统计信息

- **文件总数**: 155个文件
- **总大小**: 146.1 MB
- **创建时间**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## 部署前准备

### 服务器要求

- [ ] Linux 操作系统（Ubuntu 18.04+, CentOS 7+, Debian 9+）
- [ ] 64位架构（amd64）
- [ ] Root权限或sudo权限
- [ ] 至少 512MB 可用内存
- [ ] 至少 1GB 可用磁盘空间
- [ ] 网络连接正常

### 端口要求

- [ ] 端口 54321 未被占用（默认Web端口）
- [ ] 防火墙已配置允许相应端口

### 依赖检查

- [ ] curl 已安装
- [ ] wget 已安装
- [ ] unzip 已安装
- [ ] tar 已安装
- [ ] systemd 服务管理器可用

## 部署步骤

### 方式一：一键安装（推荐）

```bash
# 1. 下载并执行一键安装脚本
bash <(curl -Ls https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay-ui/main/scripts/one-click-install.sh)

# 2. 等待安装完成
# 3. 记录生成的登录信息
```

### 方式二：手动部署

```bash
# 1. 上传部署包到服务器
scp youngscoolplay-ui-production.tar.gz user@server:/tmp/

# 2. 登录服务器并解压
ssh user@server
cd /tmp
tar -xzf youngscoolplay-ui-production.tar.gz
cd youngscoolplay-ui-production

# 3. 运行安装脚本
sudo chmod +x install.sh
sudo ./install.sh

# 4. 启动服务
sudo systemctl enable youngscoolplay-ui
sudo systemctl start youngscoolplay-ui
```

## 部署后验证

### 服务状态检查

```bash
# 检查服务状态
sudo systemctl status youngscoolplay-ui

# 检查端口监听
sudo netstat -tlnp | grep 54321

# 检查进程
ps aux | grep youngscoolplay-ui
```

### 功能验证

- [ ] Web界面可以正常访问
- [ ] 登录功能正常
- [ ] 基本配置功能可用
- [ ] Xray服务可以启动

### 日志检查

```bash
# 查看应用日志
sudo journalctl -u youngscoolplay-ui -f

# 查看错误日志
sudo tail -f /var/log/youngscoolplay-ui/error.log
```

## 安全配置

### 必要的安全措施

- [ ] 修改默认登录密码
- [ ] 配置防火墙规则
- [ ] 启用HTTPS（如果需要）
- [ ] 设置定期备份
- [ ] 配置日志轮转

### 推荐的安全设置

- [ ] 启用双因素认证
- [ ] 限制登录IP范围
- [ ] 设置会话超时
- [ ] 定期更新系统和应用

## 故障排除

### 常见问题

1. **服务启动失败**
   ```bash
   # 检查详细错误信息
   sudo journalctl -u youngscoolplay-ui -n 50
   
   # 检查端口占用
   sudo netstat -tlnp | grep 54321
   ```

2. **Web界面无法访问**
   ```bash
   # 检查防火墙设置
   sudo ufw status
   sudo firewall-cmd --list-ports
   
   # 检查服务监听
   sudo ss -tlnp | grep 54321
   ```

3. **权限问题**
   ```bash
   # 检查文件权限
   ls -la /usr/local/youngscoolplay-ui/
   
   # 修复权限
   sudo chown -R root:root /usr/local/youngscoolplay-ui/
   sudo chmod +x /usr/local/youngscoolplay-ui/youngscoolplay-ui
   ```

## 维护建议

### 定期维护任务

- [ ] 每周检查服务状态
- [ ] 每月备份配置文件
- [ ] 每季度更新应用版本
- [ ] 定期清理日志文件

### 监控建议

- [ ] 设置服务状态监控
- [ ] 配置资源使用监控
- [ ] 设置异常告警

## 联系支持

如果在部署过程中遇到问题，请：

1. 查看本检查清单
2. 检查GitHub Issues: https://github.com/victoralwaysyoung/youngscoolplay-ui/issues
3. 提交新的Issue并提供详细的错误信息

---

**部署完成确认**

- [ ] 所有检查项目已完成
- [ ] 服务正常运行
- [ ] 功能验证通过
- [ ] 安全配置已设置
- [ ] 备份和监控已配置

部署人员签名：_________________ 日期：_________________