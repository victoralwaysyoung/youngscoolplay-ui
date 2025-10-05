# YoungsCoolPlay UI - Ubuntu 24 部署包

这是专门为 Ubuntu 24 系统编译的 YoungsCoolPlay UI 部署包。

## 系统要求

- Ubuntu 24.04 LTS
- 64位 AMD64 架构
- 至少 512MB 内存
- 至少 100MB 磁盘空间

## 快速安装

1. 下载并解压部署包
2. 进入解压后的目录
3. 运行安装脚本：

```bash
sudo chmod +x install-ubuntu24.sh
sudo ./install-ubuntu24.sh
```

## 手动安装

如果需要手动安装，请按以下步骤操作：

1. 复制二进制文件到系统路径：
```bash
sudo cp youngscoolplay-ui /usr/local/bin/
sudo chmod +x /usr/local/bin/youngscoolplay-ui
```

2. 创建配置目录：
```bash
sudo mkdir -p /etc/youngscoolplay-ui
sudo mkdir -p /var/www/youngscoolplay-ui
```

3. 复制配置文件和web资源：
```bash
sudo cp -r bin/* /etc/youngscoolplay-ui/
sudo cp -r web/* /var/www/youngscoolplay-ui/
```

4. 创建systemd服务文件：
```bash
sudo cp youngscoolplay-ui.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable youngscoolplay-ui
sudo systemctl start youngscoolplay-ui
```

## 服务管理

- 查看服务状态：`sudo systemctl status youngscoolplay-ui`
- 启动服务：`sudo systemctl start youngscoolplay-ui`
- 停止服务：`sudo systemctl stop youngscoolplay-ui`
- 重启服务：`sudo systemctl restart youngscoolplay-ui`
- 查看日志：`sudo journalctl -u youngscoolplay-ui -f`

## 配置文件

配置文件位于 `/etc/youngscoolplay-ui/` 目录下，请根据需要修改配置。

## 卸载

要卸载 YoungsCoolPlay UI，请运行：

```bash
sudo systemctl stop youngscoolplay-ui
sudo systemctl disable youngscoolplay-ui
sudo rm /etc/systemd/system/youngscoolplay-ui.service
sudo rm /usr/local/bin/youngscoolplay-ui
sudo rm -rf /etc/youngscoolplay-ui
sudo rm -rf /var/www/youngscoolplay-ui
sudo systemctl daemon-reload
```

## 支持

如有问题，请访问项目仓库：https://github.com/victoralwaysyoung/youngscoolplay-ui