#!/bin/bash

# YoungsCoolPlay UI 系统服务安装配置脚本
# 用于配置 systemd 服务、开机自启、日志管理等

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置变量
APP_NAME="youngscoolplay-ui"
APP_DIR="/opt/${APP_NAME}"
LOG_DIR="/var/log/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
SERVICE_NAME="${APP_NAME}"
SERVICE_USER="${USER}"
SERVICE_GROUP="${USER}"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查权限
check_permissions() {
    log_info "检查权限..."
    
    if [[ $EUID -eq 0 ]]; then
        log_error "请不要使用 root 用户运行此脚本"
        exit 1
    fi
    
    if ! sudo -n true 2>/dev/null; then
        log_error "需要 sudo 权限来安装系统服务"
        exit 1
    fi
    
    log_success "权限检查通过"
}

# 创建服务用户和组
create_service_user() {
    log_info "配置服务用户和组..."
    
    # 检查用户是否存在
    if ! id "$SERVICE_USER" &>/dev/null; then
        log_info "创建服务用户: $SERVICE_USER"
        sudo useradd -r -s /bin/false -d "$APP_DIR" "$SERVICE_USER"
    else
        log_info "服务用户已存在: $SERVICE_USER"
    fi
    
    # 检查组是否存在
    if ! getent group "$SERVICE_GROUP" &>/dev/null; then
        log_info "创建服务组: $SERVICE_GROUP"
        sudo groupadd -r "$SERVICE_GROUP"
    else
        log_info "服务组已存在: $SERVICE_GROUP"
    fi
    
    # 将当前用户添加到服务组
    sudo usermod -a -G "$SERVICE_GROUP" "$USER"
    
    log_success "服务用户和组配置完成"
}

# 创建目录结构
create_directories() {
    log_info "创建目录结构..."
    
    # 创建主要目录
    sudo mkdir -p "$APP_DIR" "$LOG_DIR" "$CONFIG_DIR"
    sudo mkdir -p "$APP_DIR/backups" "$APP_DIR/tmp"
    
    # 设置目录权限
    sudo chown -R "$SERVICE_USER:$SERVICE_GROUP" "$APP_DIR" "$LOG_DIR" "$CONFIG_DIR"
    sudo chmod 755 "$APP_DIR" "$CONFIG_DIR"
    sudo chmod 750 "$LOG_DIR"
    sudo chmod 700 "$APP_DIR/backups"
    
    # 创建日志文件
    sudo touch "$LOG_DIR/app.log" "$LOG_DIR/error.log" "$LOG_DIR/access.log"
    sudo chown "$SERVICE_USER:$SERVICE_GROUP" "$LOG_DIR"/*.log
    sudo chmod 640 "$LOG_DIR"/*.log
    
    log_success "目录结构创建完成"
}

# 创建配置文件
create_config_files() {
    log_info "创建配置文件..."
    
    # 创建主配置文件
    sudo tee "$CONFIG_DIR/config.yaml" > /dev/null <<EOF
# YoungsCoolPlay UI 配置文件
server:
  host: "0.0.0.0"
  port: 2053
  sub_port: 2096
  
logging:
  level: "info"
  file: "$LOG_DIR/app.log"
  max_size: 100  # MB
  max_backups: 10
  max_age: 30    # days
  
security:
  session_timeout: 3600
  max_login_attempts: 5
  rate_limit: 100  # requests per minute
  
database:
  path: "$APP_DIR/data/database.db"
  backup_interval: 24  # hours
  
xray:
  config_path: "$APP_DIR/config/xray.json"
  log_path: "$LOG_DIR/xray.log"
  
performance:
  max_connections: 1000
  read_timeout: 30
  write_timeout: 30
  idle_timeout: 120
EOF
    
    # 创建环境变量文件
    sudo tee "$CONFIG_DIR/environment" > /dev/null <<EOF
# YoungsCoolPlay UI 环境变量
GIN_MODE=release
LOG_LEVEL=info
CONFIG_FILE=$CONFIG_DIR/config.yaml
DATA_DIR=$APP_DIR/data
TMP_DIR=$APP_DIR/tmp
EOF
    
    # 设置配置文件权限
    sudo chown "$SERVICE_USER:$SERVICE_GROUP" "$CONFIG_DIR"/*
    sudo chmod 640 "$CONFIG_DIR"/*
    
    log_success "配置文件创建完成"
}

# 创建 systemd 服务文件
create_systemd_service() {
    log_info "创建 systemd 服务文件..."
    
    sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" > /dev/null <<EOF
[Unit]
Description=YoungsCoolPlay UI - Modern Web UI for Xray Management
Documentation=https://github.com/yourusername/youngscoolplay-ui
After=network-online.target
Wants=network-online.target
RequiresMountsFor=$APP_DIR

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/$APP_NAME
ExecReload=/bin/kill -HUP \$MAINPID
ExecStop=/bin/kill -TERM \$MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStartSec=60
TimeoutStopSec=30
RestartSec=10
Restart=always
StartLimitInterval=300
StartLimitBurst=5

# 安全设置
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectHome=true
ProtectSystem=strict
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictSUIDSGID=true
RemoveIPC=true
RestrictNamespaces=true

# 文件系统访问
ReadWritePaths=$APP_DIR $LOG_DIR $CONFIG_DIR
ReadOnlyPaths=/etc/ssl/certs

# 网络安全
IPAddressDeny=any
IPAddressAllow=localhost
IPAddressAllow=10.0.0.0/8
IPAddressAllow=172.16.0.0/12
IPAddressAllow=192.168.0.0/16

# 资源限制
LimitNOFILE=65536
LimitNPROC=32768
LimitMEMLOCK=64M
TasksMax=4096

# 环境变量
EnvironmentFile=$CONFIG_DIR/environment
Environment=HOME=$APP_DIR
Environment=USER=$SERVICE_USER

# 日志设置
StandardOutput=append:$LOG_DIR/app.log
StandardError=append:$LOG_DIR/error.log
SyslogIdentifier=$SERVICE_NAME
SyslogFacility=daemon

# 看门狗
WatchdogSec=30

[Install]
WantedBy=multi-user.target
EOF
    
    log_success "systemd 服务文件创建完成"
}

# 创建服务管理脚本
create_service_scripts() {
    log_info "创建服务管理脚本..."
    
    # 创建启动脚本
    sudo tee "$APP_DIR/start.sh" > /dev/null <<'EOF'
#!/bin/bash
# YoungsCoolPlay UI 启动脚本

SERVICE_NAME="youngscoolplay-ui"

echo "启动 $SERVICE_NAME 服务..."
sudo systemctl start "$SERVICE_NAME"

if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "服务启动成功"
    sudo systemctl status "$SERVICE_NAME" --no-pager
else
    echo "服务启动失败"
    sudo systemctl status "$SERVICE_NAME" --no-pager
    exit 1
fi
EOF
    
    # 创建停止脚本
    sudo tee "$APP_DIR/stop.sh" > /dev/null <<'EOF'
#!/bin/bash
# YoungsCoolPlay UI 停止脚本

SERVICE_NAME="youngscoolplay-ui"

echo "停止 $SERVICE_NAME 服务..."
sudo systemctl stop "$SERVICE_NAME"

if ! sudo systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "服务停止成功"
else
    echo "服务停止失败"
    exit 1
fi
EOF
    
    # 创建重启脚本
    sudo tee "$APP_DIR/restart.sh" > /dev/null <<'EOF'
#!/bin/bash
# YoungsCoolPlay UI 重启脚本

SERVICE_NAME="youngscoolplay-ui"

echo "重启 $SERVICE_NAME 服务..."
sudo systemctl restart "$SERVICE_NAME"

sleep 3

if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "服务重启成功"
    sudo systemctl status "$SERVICE_NAME" --no-pager
else
    echo "服务重启失败"
    sudo systemctl status "$SERVICE_NAME" --no-pager
    exit 1
fi
EOF
    
    # 创建状态检查脚本
    sudo tee "$APP_DIR/status.sh" > /dev/null <<'EOF'
#!/bin/bash
# YoungsCoolPlay UI 状态检查脚本

SERVICE_NAME="youngscoolplay-ui"
LOG_DIR="/var/log/youngscoolplay-ui"

echo "=== 服务状态 ==="
sudo systemctl status "$SERVICE_NAME" --no-pager

echo -e "\n=== 服务是否运行 ==="
if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "✅ 服务正在运行"
else
    echo "❌ 服务未运行"
fi

echo -e "\n=== 服务是否启用 ==="
if sudo systemctl is-enabled --quiet "$SERVICE_NAME"; then
    echo "✅ 服务已启用（开机自启）"
else
    echo "❌ 服务未启用"
fi

echo -e "\n=== 端口监听状态 ==="
netstat -tlnp 2>/dev/null | grep -E ":(2053|2096)" || echo "未检测到监听端口"

echo -e "\n=== 最近日志 ==="
if [[ -f "$LOG_DIR/app.log" ]]; then
    echo "应用日志（最近10行）:"
    tail -10 "$LOG_DIR/app.log"
else
    echo "应用日志文件不存在"
fi

if [[ -f "$LOG_DIR/error.log" ]]; then
    echo -e "\n错误日志（最近5行）:"
    tail -5 "$LOG_DIR/error.log"
fi

echo -e "\n=== 系统资源使用 ==="
if pgrep -f "youngscoolplay-ui" > /dev/null; then
    echo "进程信息:"
    ps aux | grep -v grep | grep youngscoolplay-ui
    
    echo -e "\n内存使用:"
    pmap $(pgrep -f "youngscoolplay-ui") 2>/dev/null | tail -1 || echo "无法获取内存信息"
fi
EOF
    
    # 设置脚本权限
    sudo chmod +x "$APP_DIR"/*.sh
    sudo chown "$SERVICE_USER:$SERVICE_GROUP" "$APP_DIR"/*.sh
    
    log_success "服务管理脚本创建完成"
}

# 配置日志轮转
configure_log_rotation() {
    log_info "配置日志轮转..."
    
    sudo tee "/etc/logrotate.d/${SERVICE_NAME}" > /dev/null <<EOF
$LOG_DIR/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 $SERVICE_USER $SERVICE_GROUP
    sharedscripts
    postrotate
        if systemctl is-active --quiet $SERVICE_NAME; then
            systemctl reload $SERVICE_NAME || true
        fi
    endscript
}

# Xray 日志轮转
$LOG_DIR/xray.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 $SERVICE_USER $SERVICE_GROUP
    copytruncate
}
EOF
    
    # 测试日志轮转配置
    sudo logrotate -d "/etc/logrotate.d/${SERVICE_NAME}" > /dev/null
    
    log_success "日志轮转配置完成"
}

# 配置监控和告警
configure_monitoring() {
    log_info "配置监控和告警..."
    
    # 创建健康检查脚本
    sudo tee "$APP_DIR/health-check.sh" > /dev/null <<'EOF'
#!/bin/bash
# YoungsCoolPlay UI 健康检查脚本

SERVICE_NAME="youngscoolplay-ui"
HEALTH_URL="http://localhost:2053/health"
LOG_FILE="/var/log/youngscoolplay-ui/health-check.log"

# 检查服务状态
if ! systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "$(date): 服务未运行" >> "$LOG_FILE"
    exit 1
fi

# 检查端口连通性
if ! curl -f -s --max-time 10 "$HEALTH_URL" > /dev/null; then
    echo "$(date): 健康检查失败 - $HEALTH_URL" >> "$LOG_FILE"
    exit 1
fi

# 检查内存使用
MEMORY_USAGE=$(ps -o pid,ppid,cmd,%mem,%cpu --sort=-%mem -C youngscoolplay-ui | awk 'NR==2{print $4}')
if [[ -n "$MEMORY_USAGE" ]] && (( $(echo "$MEMORY_USAGE > 80" | bc -l) )); then
    echo "$(date): 内存使用过高: ${MEMORY_USAGE}%" >> "$LOG_FILE"
fi

echo "$(date): 健康检查通过" >> "$LOG_FILE"
exit 0
EOF
    
    # 创建 cron 任务进行定期健康检查
    (crontab -l 2>/dev/null; echo "*/5 * * * * $APP_DIR/health-check.sh") | crontab -
    
    # 创建系统资源监控脚本
    sudo tee "$APP_DIR/monitor.sh" > /dev/null <<'EOF'
#!/bin/bash
# YoungsCoolPlay UI 系统监控脚本

SERVICE_NAME="youngscoolplay-ui"
LOG_FILE="/var/log/youngscoolplay-ui/monitor.log"

# 获取系统信息
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.2f", $3/$2 * 100.0)}')
DISK_USAGE=$(df -h /opt | awk 'NR==2{print $5}' | sed 's/%//')
LOAD_AVERAGE=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')

# 获取服务信息
if systemctl is-active --quiet "$SERVICE_NAME"; then
    SERVICE_STATUS="运行中"
    PID=$(systemctl show -p MainPID "$SERVICE_NAME" | cut -d= -f2)
    if [[ "$PID" != "0" ]]; then
        SERVICE_MEMORY=$(ps -p "$PID" -o %mem --no-headers | tr -d ' ')
        SERVICE_CPU=$(ps -p "$PID" -o %cpu --no-headers | tr -d ' ')
    else
        SERVICE_MEMORY="0"
        SERVICE_CPU="0"
    fi
else
    SERVICE_STATUS="未运行"
    SERVICE_MEMORY="0"
    SERVICE_CPU="0"
fi

# 记录监控数据
echo "$(date '+%Y-%m-%d %H:%M:%S'),${CPU_USAGE},${MEMORY_USAGE},${DISK_USAGE},${LOAD_AVERAGE},${SERVICE_STATUS},${SERVICE_MEMORY},${SERVICE_CPU}" >> "$LOG_FILE"

# 检查告警条件
if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    echo "$(date): 告警 - CPU使用率过高: ${CPU_USAGE}%" >> "$LOG_FILE"
fi

if (( $(echo "$MEMORY_USAGE > 85" | bc -l) )); then
    echo "$(date): 告警 - 内存使用率过高: ${MEMORY_USAGE}%" >> "$LOG_FILE"
fi

if (( DISK_USAGE > 90 )); then
    echo "$(date): 告警 - 磁盘使用率过高: ${DISK_USAGE}%" >> "$LOG_FILE"
fi
EOF
    
    # 添加监控 cron 任务
    (crontab -l 2>/dev/null; echo "*/10 * * * * $APP_DIR/monitor.sh") | crontab -
    
    # 设置脚本权限
    sudo chmod +x "$APP_DIR/health-check.sh" "$APP_DIR/monitor.sh"
    sudo chown "$SERVICE_USER:$SERVICE_GROUP" "$APP_DIR/health-check.sh" "$APP_DIR/monitor.sh"
    
    log_success "监控和告警配置完成"
}

# 启用和启动服务
enable_and_start_service() {
    log_info "启用和启动服务..."
    
    # 重新加载 systemd
    sudo systemctl daemon-reload
    
    # 启用服务（开机自启）
    sudo systemctl enable "$SERVICE_NAME"
    
    # 如果应用程序存在，启动服务
    if [[ -f "$APP_DIR/$APP_NAME" ]]; then
        sudo systemctl start "$SERVICE_NAME"
        
        # 等待服务启动
        sleep 5
        
        # 检查服务状态
        if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
            log_success "服务启动成功"
        else
            log_warning "服务启动失败，请检查日志"
            sudo systemctl status "$SERVICE_NAME" --no-pager
        fi
    else
        log_warning "应用程序不存在，服务已配置但未启动"
        log_info "请先部署应用程序，然后运行: sudo systemctl start $SERVICE_NAME"
    fi
    
    log_success "服务配置完成"
}

# 显示服务信息
show_service_info() {
    log_success "系统服务配置完成！"
    echo
    log_info "服务信息:"
    echo "  - 服务名称: $SERVICE_NAME"
    echo "  - 服务用户: $SERVICE_USER"
    echo "  - 服务组: $SERVICE_GROUP"
    echo "  - 应用目录: $APP_DIR"
    echo "  - 日志目录: $LOG_DIR"
    echo "  - 配置目录: $CONFIG_DIR"
    echo
    
    log_info "服务状态:"
    if sudo systemctl is-enabled --quiet "$SERVICE_NAME"; then
        echo "  - 开机自启: ✅ 已启用"
    else
        echo "  - 开机自启: ❌ 未启用"
    fi
    
    if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "  - 运行状态: ✅ 正在运行"
    else
        echo "  - 运行状态: ❌ 未运行"
    fi
    echo
    
    log_info "管理命令:"
    echo "  - 启动服务: sudo systemctl start $SERVICE_NAME"
    echo "  - 停止服务: sudo systemctl stop $SERVICE_NAME"
    echo "  - 重启服务: sudo systemctl restart $SERVICE_NAME"
    echo "  - 查看状态: sudo systemctl status $SERVICE_NAME"
    echo "  - 查看日志: sudo journalctl -u $SERVICE_NAME -f"
    echo "  - 启用自启: sudo systemctl enable $SERVICE_NAME"
    echo "  - 禁用自启: sudo systemctl disable $SERVICE_NAME"
    echo
    
    log_info "快捷脚本:"
    echo "  - 启动: $APP_DIR/start.sh"
    echo "  - 停止: $APP_DIR/stop.sh"
    echo "  - 重启: $APP_DIR/restart.sh"
    echo "  - 状态: $APP_DIR/status.sh"
    echo "  - 健康检查: $APP_DIR/health-check.sh"
    echo "  - 监控: $APP_DIR/monitor.sh"
    echo
    
    log_info "日志文件:"
    echo "  - 应用日志: $LOG_DIR/app.log"
    echo "  - 错误日志: $LOG_DIR/error.log"
    echo "  - 访问日志: $LOG_DIR/access.log"
    echo "  - 健康检查日志: $LOG_DIR/health-check.log"
    echo "  - 监控日志: $LOG_DIR/monitor.log"
    echo
    
    log_info "配置文件:"
    echo "  - 主配置: $CONFIG_DIR/config.yaml"
    echo "  - 环境变量: $CONFIG_DIR/environment"
    echo "  - 服务文件: /etc/systemd/system/$SERVICE_NAME.service"
    echo "  - 日志轮转: /etc/logrotate.d/$SERVICE_NAME"
}

# 显示帮助信息
show_help() {
    cat <<EOF
YoungsCoolPlay UI 系统服务安装配置脚本

用法: $0 [选项]

选项:
  -h, --help              显示此帮助信息
  -u, --user USER         指定服务用户 (默认: $USER)
  -g, --group GROUP       指定服务组 (默认: $USER)
  --app-dir DIR           指定应用目录 (默认: $APP_DIR)
  --log-dir DIR           指定日志目录 (默认: $LOG_DIR)
  --config-dir DIR        指定配置目录 (默认: $CONFIG_DIR)
  --no-start              不启动服务，仅配置
  --remove                移除服务配置

示例:
  $0                      # 标准安装
  $0 --user www-data      # 使用 www-data 用户
  $0 --no-start           # 仅配置，不启动
  $0 --remove             # 移除服务

EOF
}

# 移除服务配置
remove_service() {
    log_info "移除服务配置..."
    
    # 停止并禁用服务
    if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        sudo systemctl stop "$SERVICE_NAME"
    fi
    
    if sudo systemctl is-enabled --quiet "$SERVICE_NAME"; then
        sudo systemctl disable "$SERVICE_NAME"
    fi
    
    # 移除服务文件
    sudo rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
    sudo rm -f "/etc/logrotate.d/${SERVICE_NAME}"
    
    # 重新加载 systemd
    sudo systemctl daemon-reload
    
    # 移除 cron 任务
    crontab -l 2>/dev/null | grep -v "$APP_DIR" | crontab - || true
    
    log_success "服务配置已移除"
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -u|--user)
                SERVICE_USER="$2"
                shift 2
                ;;
            -g|--group)
                SERVICE_GROUP="$2"
                shift 2
                ;;
            --app-dir)
                APP_DIR="$2"
                shift 2
                ;;
            --log-dir)
                LOG_DIR="$2"
                shift 2
                ;;
            --config-dir)
                CONFIG_DIR="$2"
                shift 2
                ;;
            --no-start)
                NO_START=true
                shift
                ;;
            --remove)
                remove_service
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 主函数
main() {
    log_info "开始 YoungsCoolPlay UI 系统服务配置..."
    
    parse_arguments "$@"
    check_permissions
    create_service_user
    create_directories
    create_config_files
    create_systemd_service
    create_service_scripts
    configure_log_rotation
    configure_monitoring
    
    if [[ "${NO_START:-false}" != "true" ]]; then
        enable_and_start_service
    else
        log_info "跳过服务启动（--no-start 参数）"
        sudo systemctl daemon-reload
        sudo systemctl enable "$SERVICE_NAME"
    fi
    
    show_service_info
    
    log_success "系统服务配置完成！"
}

# 执行主函数
main "$@"