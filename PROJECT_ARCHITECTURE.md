# 3YOUNGSCOOLPLAY-UI 项目架构文档

## 项目概述

**3YOUNGSCOOLPLAY-UI** 是一个基于 Go 语言开发的高级开源 Web 控制面板，专门用于管理 Xray-core 服务器。它提供了用户友好的界面来配置和监控各种 VPN 和代理协议。

- **项目名称**: 3YOUNGSCOOLPLAY-UI
- **版本**: v2
- **Go 版本要求**: 1.25.1
- **主要功能**: Xray-core 管理、用户管理、流量监控、多协议支持

## 核心架构组件

### 1. 入口模块 (main.go)
- **职责**: 应用程序入口点，初始化数据库、Web 服务器和命令行操作
- **关键功能**:
  - 数据库初始化
  - Web 服务器启动
  - 日志级别配置
  - 环境变量加载

### 2. 配置管理模块 (config/)
- **文件**: `config.go`, `version`, `name`
- **职责**: 提供配置管理工具，包括版本信息、日志级别、数据库路径等
- **关键功能**:
  - 版本和应用名称管理
  - 日志级别控制
  - 数据库和二进制文件路径配置
  - 环境变量处理

### 3. 数据库模块 (database/)
- **文件**: `db.go`, `model/model.go`
- **职责**: 数据库初始化、迁移和管理，使用 GORM 和 SQLite
- **关键功能**:
  - 数据库连接管理
  - 模型自动迁移
  - 默认用户创建
  - 数据库检查点操作

### 4. Web 服务模块 (web/)
- **核心文件**: `web.go`
- **职责**: 主要 Web 服务器实现，包括 HTTP/HTTPS 服务、路由、模板和后台任务调度

#### 4.1 控制器层 (web/controller/)
- **api.go**: API 控制器，处理 RESTful API 请求
- **base.go**: 基础控制器，提供通用功能
- **inbound.go**: 入站连接管理
- **index.go**: 首页和登录控制
- **server.go**: 服务器状态管理
- **setting.go**: 系统设置管理
- **xray_setting.go**: Xray 配置管理
- **xui.go**: 主面板控制器

#### 4.2 服务层 (web/service/)
- **config.json**: 服务配置文件
- **inbound.go**: 入站服务逻辑
- **outbound.go**: 出站服务逻辑
- **panel.go**: 面板管理服务
- **server.go**: 服务器管理
- **setting.go**: 设置服务
- **tgbot.go**: Telegram 机器人服务
- **user.go**: 用户管理服务
- **warp.go**: WARP 服务
- **xray.go**: Xray 核心服务
- **xray_setting.go**: Xray 设置服务

#### 4.3 后台任务模块 (web/job/)
- **check_client_ip_job.go**: 客户端 IP 监控
- **check_cpu_usage.go**: CPU 使用率检查
- **check_hash_storage.go**: 哈希存储检查
- **check_xray_running_job.go**: Xray 运行状态检查
- **clear_logs_job.go**: 日志清理
- **periodic_traffic_reset_job.go**: 定期流量重置
- **stats_notify_job.go**: 统计通知
- **xray_traffic_job.go**: Xray 流量统计

#### 4.4 其他 Web 组件
- **entity/**: 实体定义
- **global/**: 全局变量和哈希存储
- **html/**: HTML 模板文件
- **locale/**: 本地化支持
- **middleware/**: 中间件（域名验证、重定向）
- **network/**: 网络组件（自动 HTTPS）
- **session/**: 会话管理
- **translation/**: 多语言翻译文件

### 5. Xray 核心模块 (xray/)
- **职责**: Xray-core 的直接管理和配置
- **关键文件**:
  - **api.go**: Xray API 接口
  - **client_traffic.go**: 客户端流量管理
  - **config.go**: Xray 配置管理
  - **inbound.go**: 入站配置
  - **log_writer.go**: 日志写入器
  - **process.go**: 进程管理
  - **traffic.go**: 流量统计

### 6. 订阅模块 (sub/)
- **职责**: 处理订阅链接生成和管理
- **关键文件**:
  - **sub.go**: 订阅核心逻辑
  - **subController.go**: 订阅控制器
  - **subJsonService.go**: JSON 订阅服务
  - **subService.go**: 订阅服务逻辑
  - **default.json**: 默认配置

### 7. 工具模块 (util/)
- **common/**: 通用工具（错误处理、格式化、多错误处理）
- **crypto/**: 加密工具
- **json_util/**: JSON 处理工具
- **random/**: 随机数生成
- **reflect_util/**: 反射工具
- **sys/**: 系统工具（跨平台系统信息获取）

### 8. 日志模块 (logger/)
- **职责**: 统一的日志管理
- **功能**: 提供不同级别的日志记录

## 数据模型

### 核心数据模型 (database/model/)
- **User**: 用户模型
- **Inbound**: 入站连接配置
- **OutboundTraffics**: 出站流量统计
- **Setting**: 系统设置
- **InboundClientIps**: 客户端 IP 记录
- **ClientTraffic**: 客户端流量统计
- **HistoryOfSeeders**: 数据库迁移历史

## 部署和配置

### 支持的部署方式
1. **直接部署**: 使用 `install.sh` 脚本
2. **Docker 部署**: 使用 `Dockerfile` 和 `docker-compose.yml`
3. **系统服务**: 支持 systemd (`youngscoolplay-ui.service`) 和 OpenRC (`youngscoolplay-ui.rc`)

### 配置文件
- **数据库**: SQLite，默认路径 `/etc/youngscoolplay-ui/youngscoolplay-ui.db`
- **日志**: 可配置级别（debug, info, notice, warning, error）
- **Web 界面**: 支持多语言和主题

## 技术栈

### 后端技术
- **Go 1.25.1**: 主要编程语言
- **Gin**: Web 框架
- **GORM**: ORM 框架
- **SQLite**: 数据库
- **Xray-core**: 代理核心

### 前端技术
- **Vue.js**: 前端框架
- **Ant Design Vue**: UI 组件库
- **CodeMirror**: 代码编辑器
- **Axios**: HTTP 客户端

### 其他依赖
- **Telegram Bot API**: 机器人通知
- **Cron**: 定时任务
- **QR Code**: 二维码生成
- **TOTP**: 两步验证

## 安全特性

1. **用户认证**: 支持用户名/密码和两步验证
2. **IP 限制**: 客户端 IP 监控和限制
3. **Fail2Ban**: 集成 Fail2Ban 防护
4. **TLS/SSL**: 支持自动 HTTPS
5. **密码加密**: 使用 bcrypt 加密存储

## 监控和统计

1. **实时流量监控**: 上传/下载统计
2. **系统资源监控**: CPU、内存、网络使用情况
3. **客户端管理**: 在线状态、流量配额
4. **日志管理**: 访问日志和错误日志
5. **Telegram 通知**: 系统状态和告警通知

## 扩展性

1. **多语言支持**: 支持 12+ 种语言
2. **主题系统**: 支持明暗主题切换
3. **插件架构**: 模块化设计便于扩展
4. **API 接口**: 完整的 RESTful API
5. **Docker 支持**: 容器化部署

这个架构设计确保了 3YOUNGSCOOLPLAY-UI 的高可用性、可扩展性和易维护性，为用户提供了强大而灵活的 Xray 管理解决方案。