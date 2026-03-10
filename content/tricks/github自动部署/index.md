---
title: "Github自动部署"
description: "告别手动上传 public 文件夹，记录如何使用 GitHub Actions 实现 Hugo 博客到云服务器的自动化部署工作流。"
date: 2026-03-10
categories: ["tricks"]
image: 
math: 
license: 
comments: true
draft: false
build:
  list: always    # Change to "never" to hide the page from the list
---

你是否也曾经历过这样的循环：在本地写完一篇精彩的博客，然后手动运行 `hugo` 生成静态文件，接着打开 FTP 客户端或敲下一串 `scp` 命令，把 `public` 文件夹传到服务器，最后还要解压、覆盖……一次两次还能忍受，但每次都要重复这套“搬砖”流程，不仅消磨写作热情，还容易出错。

今天，我们来彻底终结这种低效的手动部署。借助 **GitHub Actions**，我们可以打造一条完全自动化的部署流水线：**只需在本地执行 `git push`，几十秒后，你的云服务器上的博客就会自动更新到最新版本。** 全程无需手动连接服务器，一切都由 GitHub 免费提供的云虚拟机完成。

## 自动化部署的核心原理

整个流水线的逻辑非常清晰，像一个高效的工厂流水线：

1. **触发**：当你将代码推送到 GitHub 仓库的 `main` 分支（或其他指定分支）时，流水线自动启动。
2. **构建环境**：GitHub 分配一台临时的 Ubuntu 容器，里面预装了最新的软件包。
3. **准备代码**：自动拉取你的博客源码，包括所有子模块（比如 Hugo 主题 Stack）。
4. **生成静态网站**：安装指定版本的 Hugo（extended 版），运行 `hugo --minify` 命令，生成压缩后的静态网页文件。
5. **同步到服务器**：通过 SSH 协议，利用 `rsync` 工具将生成的 `public` 目录内容增量同步到你云服务器的 Nginx 网站根目录。

整个过程自动化、可重复、可追溯，而且完全免费。

## 打通服务器的“免密通道”

要让 GitHub 的机器人能够登录你的云服务器并写入文件，必须配置 SSH 密钥认证。这是整个配置中最容易让人混淆的一步，核心原则是：**私钥留给 GitHub，公钥锁在服务器上。**

打开本地终端，执行以下命令生成一对专用的部署密钥（这里使用 `ed25519` 算法，安全性更高，且不需要输入密码）：

bash

```
ssh-keygen -t ed25519 -f ~/.ssh/github_deploy_key -N ""
```



执行后会生成两个文件：

- `~/.ssh/github_deploy_key` —— **私钥（钥匙）**：**绝对不能泄露**，需要交给 GitHub。
- `~/.ssh/github_deploy_key.pub` —— **公钥（锁）**：需要安装在云服务器上。

### 将私钥交给 GitHub

1. 在浏览器中打开你的 GitHub 仓库，依次进入 **Settings** -> **Secrets and variables** -> **Actions**。
2. 点击 **New repository secret**。
3. **Name** 填写 `SSH_PRIVATE_KEY`（注意大小写，后面会用到）。
4. **Secret** 中粘贴 **私钥文件 `github_deploy_key` 的完整内容**，包括 `-----BEGIN OPENSSH PRIVATE KEY-----` 和 `-----END OPENSSH PRIVATE KEY-----` 这两行。
5. 点击 **Add secret** 保存。

### 将公钥锁到服务器上

登录你的云服务器（假设你使用普通用户 `cong` 进行部署），执行以下命令：

bash

```
# 确保 ~/.ssh 目录存在且权限正确
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 将公钥内容追加到 authorized_keys 文件中
cat >> ~/.ssh/authorized_keys << 'EOF'
（这里粘贴 github_deploy_key.pub 的完整内容）
EOF

# 设置正确的权限
chmod 600 ~/.ssh/authorized_keys
```



> **⚠️ 注意**：如果你的云服务器 SSH 端口不是默认的 22（例如改成了 2222），请在后续的 GitHub Secrets 中正确配置端口，并在本地先测试免密登录是否成功：
>
> bash
>
> ```
> ssh -i ~/.ssh/github_deploy_key -p <你的端口> <用户名>@<服务器IP>
> ```
>
> 
>
> 如果能够直接登录而不需要密码，说明密钥配置成功。

## 编写 GitHub Actions 工作流

在本地博客仓库的根目录下，创建文件夹 `.github/workflows/`，并在其中新建一个文件，例如 `deploy.yml`。这个 YAML 文件就是告诉 GitHub Actions 如何执行部署的“剧本”。

以下是一个完整且经过测试的配置示例，关键部分已添加注释：

yaml

```
name: Deploy Hugo Blog to Cloud Server

on:
  push:
    branches:
      - main  # 当推送到 main 分支时触发

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          submodules: recursive  # 如果使用了 git submodule（如主题），拉取完整代码
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v3
        with:
          hugo-version: 'latest'
          extended: true  # 如果主题使用 SCSS 等特性，必须启用 extended 版本

      - name: Build site
        run: hugo --minify  # 生成静态文件，输出到 public 目录

      - name: Deploy to server via rsync
        uses: easingthemes/ssh-deploy@main
        env:
          SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
          REMOTE_HOST: ${{ secrets.REMOTE_HOST }}      # 你的服务器 IP
          REMOTE_USER: ${{ secrets.REMOTE_USER }}      # 登录用户名，如 cong
          REMOTE_PORT: ${{ secrets.REMOTE_PORT }}      # SSH 端口，默认为 22
          TARGET: /var/www/html                         # 服务器上的网站根目录
          SOURCE: public/                                # 本地要同步的目录（注意末尾的斜杠）
          ARGS: -avzr --delete                           # rsync 参数：归档、压缩、递归、删除多余文件
```



> **注意**：`REMOTE_HOST`、`REMOTE_USER`、`REMOTE_PORT` 这些敏感信息也建议保存在 GitHub Secrets 中，避免直接写在文件里。你可以在仓库 Secrets 中分别添加 `REMOTE_HOST`、`REMOTE_USER`、`REMOTE_PORT`，然后在上述文件中通过 `${{ secrets.REMOTE_HOST }}` 引用。

## 最后一步：确保服务器目录权限正确

GitHub Actions 将使用你在 `REMOTE_USER` 中指定的用户身份登录服务器。如果该用户对目标目录（如 `/var/www/html`）没有写入权限，rsync 会失败并报 `Permission denied` 错误。

假设你的部署用户是 `cong`，网站目录为 `/var/www/html`，请登录服务器执行：

bash

```
sudo chown -R cong:cong /var/www/html
```



这条命令将目录的所有者改为 `cong` 用户，确保部署用户有完全的读写权限。

## 享受一键部署的畅快

所有配置完成后，将你的 Hugo 博客源码推送到 GitHub 仓库的 `main` 分支：

bash

```
git add .
git commit -m "Add GitHub Actions auto deploy"
git push origin main
```



然后打开 GitHub 仓库的 **Actions** 标签页，你会看到一个新的工作流正在运行，黄色的圆圈表示进行中。等待几十秒，当它变成绿色的 ✓ 时，访问你的博客网址，内容已经是最新的了！

从此以后，你可以心无旁骛地专注于写作，每次写完文章，只需执行常规的 `git add`、`git commit`、`git push`，剩下的就交给 GitHub Actions 和 rsync 去完成。技术，本该如此优雅。

------

**延伸思考**：如果你有多个分支需要部署，或者想要在部署前运行测试，都可以通过修改 `on.push.branches` 或增加新的 job 来实现。GitHub Actions 的灵活性远不止于此，等待你去发掘。