# GitHub 仓库创建与代码上传教程

本文档详细介绍如何将 YoungsCoolPlay UI 项目上传到 GitHub，并设置完整的版本控制流程。

## 目录

1. [前置准备](#前置准备)
2. [创建 GitHub 仓库](#创建-github-仓库)
3. [本地 Git 配置](#本地-git-配置)
4. [代码上传流程](#代码上传流程)
5. [分支管理策略](#分支管理策略)
6. [自动化工作流](#自动化工作流)
7. [常见问题解决](#常见问题解决)

## 前置准备

### 1. 安装 Git

**Windows:**
```bash
# 下载并安装 Git for Windows
# https://git-scm.com/download/win

# 验证安装
git --version
```

**Ubuntu/Linux:**
```bash
sudo apt update
sudo apt install git

# 验证安装
git --version
```

**macOS:**
```bash
# 使用 Homebrew
brew install git

# 或使用 Xcode Command Line Tools
xcode-select --install
```

### 2. 配置 Git 用户信息

```bash
# 设置全局用户名和邮箱
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 验证配置
git config --global --list
```

### 3. 生成 SSH 密钥（推荐）

```bash
# 生成 SSH 密钥
ssh-keygen -t ed25519 -C "your.email@example.com"

# 启动 ssh-agent
eval "$(ssh-agent -s)"

# 添加私钥到 ssh-agent
ssh-add ~/.ssh/id_ed25519

# 复制公钥到剪贴板
cat ~/.ssh/id_ed25519.pub
```

将公钥添加到 GitHub：
1. 登录 GitHub
2. 点击头像 → Settings
3. 左侧菜单选择 "SSH and GPG keys"
4. 点击 "New SSH key"
5. 粘贴公钥内容并保存

## 创建 GitHub 仓库

### 方法一：通过 GitHub 网页界面

1. **登录 GitHub**
   - 访问 [github.com](https://github.com)
   - 登录您的账户

2. **创建新仓库**
   - 点击右上角的 "+" 按钮
   - 选择 "New repository"

3. **配置仓库信息**
   ```
   Repository name: youngscoolplay-ui
   Description: A modern web UI for Xray management with load balancing support
   Visibility: Public (或 Private，根据需要选择)
   
   ✅ Add a README file
   ✅ Add .gitignore (选择 Go)
   ✅ Choose a license (选择 MIT License)
   ```

4. **创建仓库**
   - 点击 "Create repository"

### 方法二：通过 GitHub CLI

```bash
# 安装 GitHub CLI
# Windows: winget install GitHub.cli
# macOS: brew install gh
# Ubuntu: sudo apt install gh

# 登录 GitHub
gh auth login

# 创建仓库
gh repo create youngscoolplay-ui --public --description "A modern web UI for Xray management with load balancing support"
```

## 本地 Git 配置

### 1. 初始化本地仓库

```bash
# 进入项目目录
cd /path/to/youngscoolplay

# 初始化 Git 仓库
git init

# 添加远程仓库
git remote add origin git@github.com:yourusername/youngscoolplay-ui.git

# 验证远程仓库
git remote -v
```

### 2. 配置 .gitignore

确保项目根目录有正确的 `.gitignore` 文件（已在前面步骤创建）。

### 3. 创建初始提交

```bash
# 添加所有文件到暂存区
git add .

# 查看暂存状态
git status

# 创建初始提交
git commit -m "Initial commit: YoungsCoolPlay UI project

- Add complete web UI for Xray management
- Include Chinese localization
- Add build scripts for multiple platforms
- Configure project structure and dependencies"

# 设置主分支名称
git branch -M main
```

## 代码上传流程

### 1. 首次推送

```bash
# 推送到远程仓库
git push -u origin main
```

### 2. 日常开发流程

```bash
# 1. 拉取最新代码
git pull origin main

# 2. 创建功能分支（可选）
git checkout -b feature/new-feature

# 3. 进行开发工作
# ... 编辑文件 ...

# 4. 查看更改
git status
git diff

# 5. 添加更改到暂存区
git add .
# 或选择性添加
git add path/to/specific/file

# 6. 提交更改
git commit -m "Add new feature: description of changes"

# 7. 推送到远程仓库
git push origin feature/new-feature

# 8. 创建 Pull Request（通过 GitHub 网页界面）
```

### 3. 提交信息规范

使用语义化提交信息：

```bash
# 功能添加
git commit -m "feat: add user authentication system"

# 错误修复
git commit -m "fix: resolve login redirect issue"

# 文档更新
git commit -m "docs: update installation guide"

# 样式更改
git commit -m "style: improve UI responsiveness"

# 重构代码
git commit -m "refactor: optimize database queries"

# 性能优化
git commit -m "perf: improve page load speed"

# 测试相关
git commit -m "test: add unit tests for auth module"

# 构建相关
git commit -m "build: update build scripts for cross-platform"

# CI/CD 相关
git commit -m "ci: add GitHub Actions workflow"
```

## 分支管理策略

### Git Flow 模型

```bash
# 主要分支
main        # 生产环境代码
develop     # 开发环境代码

# 辅助分支
feature/*   # 功能开发分支
release/*   # 发布准备分支
hotfix/*    # 紧急修复分支
```

### 分支操作示例

```bash
# 创建并切换到开发分支
git checkout -b develop

# 创建功能分支
git checkout -b feature/load-balancer develop

# 完成功能开发后合并到 develop
git checkout develop
git merge --no-ff feature/load-balancer
git branch -d feature/load-balancer

# 创建发布分支
git checkout -b release/v1.0.0 develop

# 发布完成后合并到 main 和 develop
git checkout main
git merge --no-ff release/v1.0.0
git tag -a v1.0.0 -m "Release version 1.0.0"

git checkout develop
git merge --no-ff release/v1.0.0
git branch -d release/v1.0.0
```

## 自动化工作流

### GitHub Actions 配置

创建 `.github/workflows/ci.yml`：

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Go
      uses: actions/setup-go@v3
      with:
        go-version: 1.21
    
    - name: Run tests
      run: go test -v ./...
    
    - name: Build
      run: go build -v ./...

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Go
      uses: actions/setup-go@v3
      with:
        go-version: 1.21
    
    - name: Build for multiple platforms
      run: |
        chmod +x scripts/build.sh
        ./scripts/build.sh
    
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: build-artifacts
        path: dist/

  release:
    needs: build
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/')
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Create Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        draft: false
        prerelease: false
```

### 自动化部署脚本

创建 `.github/workflows/deploy.yml`：

```yaml
name: Deploy to Server

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to server
      uses: appleboy/ssh-action@v0.1.5
      with:
        host: ${{ secrets.HOST }}
        username: ${{ secrets.USERNAME }}
        key: ${{ secrets.SSH_KEY }}
        script: |
          cd /opt/youngscoolplay-ui
          git pull origin main
          ./scripts/deploy.sh
          sudo systemctl restart youngscoolplay-ui
```

## 常见问题解决

### 1. 推送被拒绝

```bash
# 错误：Updates were rejected because the remote contains work
# 解决方案：先拉取远程更改
git pull origin main --rebase
git push origin main
```

### 2. 合并冲突

```bash
# 查看冲突文件
git status

# 手动解决冲突后
git add .
git commit -m "Resolve merge conflicts"
```

### 3. 撤销提交

```bash
# 撤销最后一次提交（保留更改）
git reset --soft HEAD~1

# 撤销最后一次提交（丢弃更改）
git reset --hard HEAD~1

# 撤销已推送的提交
git revert HEAD
git push origin main
```

### 4. 更改远程仓库地址

```bash
# 查看当前远程地址
git remote -v

# 更改远程地址
git remote set-url origin git@github.com:newusername/youngscoolplay-ui.git
```

### 5. 大文件处理

如果项目包含大文件，使用 Git LFS：

```bash
# 安装 Git LFS
git lfs install

# 跟踪大文件类型
git lfs track "*.exe"
git lfs track "*.zip"
git lfs track "*.tar.gz"

# 添加 .gitattributes
git add .gitattributes
git commit -m "Add Git LFS configuration"
```

## 最佳实践

### 1. 提交频率
- 小而频繁的提交优于大而稀少的提交
- 每个提交应该是一个逻辑单元
- 提交前确保代码可以编译和运行

### 2. 分支命名
```bash
feature/user-authentication
bugfix/login-redirect-issue
hotfix/security-vulnerability
release/v1.2.0
```

### 3. 代码审查
- 所有功能分支都应通过 Pull Request 合并
- 至少需要一个人审查代码
- 确保 CI/CD 检查通过

### 4. 标签管理
```bash
# 创建带注释的标签
git tag -a v1.0.0 -m "Release version 1.0.0"

# 推送标签
git push origin v1.0.0

# 推送所有标签
git push origin --tags
```

### 5. 安全考虑
- 永远不要提交敏感信息（密码、密钥等）
- 使用环境变量存储配置
- 定期更新依赖项
- 启用分支保护规则

---

通过遵循本教程，您可以建立一个完整的 Git 工作流程，确保代码的版本控制和协作开发的顺利进行。