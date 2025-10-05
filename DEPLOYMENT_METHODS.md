# YoungsCoolPlay UI 部署方法详解

## 概述

本文档详细说明了 YoungsCoolPlay UI 的各种部署方法，重点介绍了类似 3x-ui 的一键安装部署方式。

## 一键安装部署（推荐）

### 使用方法

```bash
bash <(curl -Ls https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay-ui/main/scripts/one-click-install.sh)
```

### 工作原理

这个一键安装命令的工作原理如下：

1. **curl 下载脚本**：
   - `curl -Ls` 从 GitHub 下载安装脚本
   - `-L` 参数跟随重定向
   - `-s` 参数静默模式，不显示进度

2. **bash 执行脚本**：
   - `bash <(...)` 将下载的内容作为 bash 脚本执行
   - `<(...)` 是进程替换，将命令输出作为文件输入

3. **脚本执行流程**：
   ```
   检查 root 权限 → 检测系统环境 → 安装依赖 → 下载应用 → 配置服务 → 启动应用
   ```

### 详细执行步骤

#### 1. 环境检查
- 检查是否具有 root 权限
- 检测操作系统类型（Ubuntu、CentOS、Debian 等）
- 检测 CPU 架构（amd64、arm64 等）

#### 2. 依赖安装
根据不同系统安装必要依赖：
```bash
# Ubuntu/Debian
apt-get install -y curl wget unzip tar systemd

# CentOS/RHEL
yum install -y curl wget unzip tar systemd

# Alpine
apk add curl wget unzip tar openrc
```

#### 3. 版本获取
通过 GitHub API 获取最新版本：
```bash
curl -s "https://api.github.com/repos/victoralwaysyoung/youngscoolplay-ui/releases/latest"
```

#### 4. 下载安装包
从 GitHub Releases 下载对应版本的安装包：
```bash
wget "https://github.com/victoralwaysyoung/youngscoolplay-ui/releases/download/v1.0.0/youngscoolplay-ui-production.zip"
```

#### 5. 应用安装
- 解压安装包到 `/usr/local/youngscoolplay-ui/`
- 设置执行权限
- 创建配置目录 `/etc/youngscoolplay-ui/`
- 创建日志目录 `/var/log/youngscoolplay-ui/`

#### 6. 服务配置
创建 systemd 服务文件：
```ini
[Unit]
Description=YoungsCoolPlay UI - Advanced Xray Panel
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/youngscoolplay-ui/youngscoolplay-ui
Restart=always

[Install]
WantedBy=multi-user.target
```

#### 7. 启动服务
```bash
systemctl daemon-reload
systemctl enable youngscoolplay-ui
systemctl start youngscoolplay-ui
```

## 与 3x-ui 安装方式的对比

### 3x-ui 安装方式分析

3x-ui 的安装脚本 `bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh)` 采用了以下策略：

1. **统一入口**：一个脚本处理所有系统
2. **自动检测**：自动识别系统类型和架构
3. **依赖管理**：自动安装所需依赖
4. **服务集成**：自动配置 systemd 服务
5. **用户友好**：提供彩色输出和进度提示

### YoungsCoolPlay UI 的改进

我们的安装脚本在 3x-ui 基础上进行了以下改进：

1. **更好的错误处理**：
   ```bash
   set -e  # 遇到错误立即退出
   trap 'cleanup; exit 1' ERR  # 错误时自动清理
   ```

2. **更详细的日志**：
   ```bash
   log_info() { echo -e "${BLUE}[INFO]${PLAIN} $1"; }
   log_success() { echo -e "${GREEN}[SUCCESS]${PLAIN} $1"; }
   log_error() { echo -e "${RED}[ERROR]${PLAIN} $1"; }
   ```

3. **配置备份**：
   ```bash
   backup_existing_config() {
       local backup_dir="/tmp/youngscoolplay-ui-backup-$(date +%Y%m%d-%H%M%S)"
       cp -r "$CONFIG_DIR" "$backup_dir"
   }
   ```

4. **安全增强**：
   ```bash
   # 生成随机凭据
   username=$(generate_random_string 10)
   password=$(generate_random_string 12)
   ```

5. **多防火墙支持**：
   ```bash
   # 支持 UFW、firewalld、iptables
   configure_firewall()
   ```

## 其他部署方法

### 1. Docker 部署

```bash
# 使用 Docker Compose
docker-compose up -d

# 使用 Docker 命令
docker run -d --name youngscoolplay-ui \
  -p 54321:54321 \
  -v /etc/youngscoolplay-ui:/etc/youngscoolplay-ui \
  youngscoolplay-ui:latest
```

### 2. 手动部署

```bash
# 1. 下载安装包
wget https://github.com/victoralwaysyoung/youngscoolplay-ui/releases/download/v1.0.0/youngscoolplay-ui-production.zip

# 2. 解压
unzip youngscoolplay-ui-production.zip

# 3. 运行安装脚本
cd youngscoolplay-ui-production
sudo ./install.sh
```

### 3. 源码编译部署

```bash
# 1. 克隆仓库
git clone https://github.com/victoralwaysyoung/youngscoolplay-ui.git

# 2. 编译
cd youngscoolplay-ui
go build -o youngscoolplay-ui

# 3. 安装
sudo cp youngscoolplay-ui /usr/local/bin/
sudo systemctl enable youngscoolplay-ui
sudo systemctl start youngscoolplay-ui
```

## 部署后管理

### 服务管理命令

```bash
# 查看服务状态
systemctl status youngscoolplay-ui

# 启动服务
systemctl start youngscoolplay-ui

# 停止服务
systemctl stop youngscoolplay-ui

# 重启服务
systemctl restart youngscoolplay-ui

# 查看日志
journalctl -u youngscoolplay-ui -f
```

### 配置文件位置

- **应用目录**：`/usr/local/youngscoolplay-ui/`
- **配置目录**：`/etc/youngscoolplay-ui/`
- **日志目录**：`/var/log/youngscoolplay-ui/`
- **Web 资源**：`/var/lib/youngscoolplay-ui/web/`

### 更新升级

```bash
# 使用一键脚本更新（推荐）
bash <(curl -Ls https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay-ui/main/scripts/one-click-install.sh)

# 手动更新
systemctl stop youngscoolplay-ui
wget https://github.com/victoralwaysyoung/youngscoolplay-ui/releases/download/latest/youngscoolplay-ui-production.zip
# ... 解压和替换文件
systemctl start youngscoolplay-ui
```

## 安全建议

1. **修改默认密码**：安装后立即登录并修改默认密码
2. **启用 HTTPS**：配置 SSL 证书启用 HTTPS 访问
3. **防火墙配置**：只开放必要的端口
4. **定期备份**：定期备份配置文件和数据
5. **监控日志**：定期检查应用日志

## 故障排除

### 常见问题

1. **权限不足**：
   ```bash
   sudo bash <(curl -Ls https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay-ui/main/scripts/one-click-install.sh)
   ```

2. **网络问题**：
   ```bash
   # 检查网络连接
   curl -I https://github.com
   
   # 使用代理
   export https_proxy=http://proxy:port
   ```

3. **服务启动失败**：
   ```bash
   # 查看详细错误
   journalctl -u youngscoolplay-ui -n 50
   
   # 检查端口占用
   netstat -tlnp | grep 54321
   ```

4. **依赖问题**：
   ```bash
   # 手动安装依赖
   apt-get update
   apt-get install -y curl wget unzip tar
   ```

### 日志分析

```bash
# 实时查看日志
tail -f /var/log/youngscoolplay-ui/app.log

# 查看错误日志
tail -f /var/log/youngscoolplay-ui/error.log

# 查看系统日志
journalctl -u youngscoolplay-ui --since "1 hour ago"
```

## 总结

YoungsCoolPlay UI 的一键安装部署方式借鉴了 3x-ui 的成功经验，同时在安全性、稳定性和用户体验方面进行了改进。通过 `bash <(curl -Ls ...)` 的方式，用户可以在几分钟内完成从下载到配置的整个部署过程，大大降低了部署门槛。