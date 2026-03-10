---
title: "Github自动部署"
description: "告别手动上传 public 文件夹，记录如何使用 GitHub Actions 实现 Hugo 博客到云服务器的自动化部署工作流。"
date: 2026-03-10T19:16:44+08:00
image: 
math: 
license: 
comments: true
draft: true
build:
  list: always    # Change to "never" to hide the page from the list
---

在搭建博客的初期，我们通常会经历这样一个痛苦的循环：本地写文章 -> 运行 `hugo` 命令生成静态网页 -> 压缩 `public` 文件夹 -> 通过 FTP 或 SSH 传到云服务器 -> 解压覆盖原文件。

这种“手动搬砖”的模式不仅繁琐，而且极易出错。今天，我们来彻底改变这种工作流，利用 **GitHub Actions** 实现：**只要在本地敲下 `git push`，云服务器上的博客就会在几十秒内自动更新。**



## 

我们的目标是搭建一条流水线，这条流水线由 GitHub 提供免费的算力支持。它的工作原理如下：
1. 监听我们 GitHub 仓库的 `main` 分支。
2. 一旦有代码推送，启动一台云端 Ubuntu 容器。
3. 自动安装 Hugo 环境并拉取我们的代码与主题（如 Hugo Stack）。
4. 执行 `hugo --minify` 生成静态网页。
5. 通过 SSH 协议，利用 `rsync` 增量同步到我们自己云服务器的 Nginx 网站根目录。

## 核心难点：打通服务器的“免密通道”

想要让 GitHub 的机器人有权限把文件塞进我们的云服务器，就必须配置 SSH 密钥对。这是新手最容易“昏头”的地方：**到底该把谁给谁？**

我们在本地终端执行 `ssh-keygen -t ed25519 -f ~/.ssh/github_deploy_key -N ""` 生成密钥对后，会得到两个文件：

* 🔑 **私钥 (`github_deploy_key`)：这是“钥匙”。**
    * **归宿：** 需要交给 GitHub。
    * **操作：** 在 GitHub 仓库的 `Settings` -> `Secrets and variables` -> `Actions` 中，新建名为 `SSH_PRIVATE_KEY` 的变量，将私钥的**全部内容**粘贴进去。
* 🔒 **公钥 (`github_deploy_key.pub`)：这是“锁”。**
    * **归宿：** 需要安装在你的云服务器上。
    * **操作：** 登录云服务器，将公钥内容追加到 `~/.ssh/authorized_keys` 文件中，并确保该文件权限为 `600`，`.ssh` 目录权限为 `700`。

> **踩坑预警：** 如果你的云服务器修改了默认的 22 端口，请务必在测试免密登录以及后续的配置文件中显式指定该端口！

## GitHub Actions 配置实战

在本地博客仓库的根目录下，创建 `.github/workflows/deploy.yml` 文件。这是指挥 GitHub 机器人干活的“剧本”：

```yaml
name: Deploy My Blog to Cloud Server

on:
  push:
    branches:
      - main  # 触发条件：推送到 main 分支

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          submodules: recursive # 【重要】自动拉取子模块（如 Stack 主题）
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v3
        with:
          hugo-version: 'latest'
          extended: true        # 【重要】Stack 等包含 SCSS 的主题必须开启 extended 版

      - name: Build Static Site
        run: hugo --minify

      - name: Deploy to Server via SSH
        uses: easingthemes/ssh-deploy@main
        env:
          SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
          REMOTE_HOST: ${{ secrets.REMOTE_HOST }} # 在 Secrets 中配置：云服务器 IP
          REMOTE_USER: ${{ secrets.REMOTE_USER }} # 在 Secrets 中配置：登录用户名
          REMOTE_PORT: ${{ secrets.REMOTE_PORT }} # 在 Secrets 中配置：SSH 端口
          REMOTE_PORT: ${{ secrets.REMOTE_PORT }}
          TARGET: "/var/www/html"                 # 你的 Nginx 网站根目录
          SOURCE: "public/"
          ARGS: "-avzr --delete"                  # 增量同步，并删除服务器上多余的文件
```

## 最后的拼图：目录权限

如果你是以普通用户（如 `cong`）而不是 `root` 的身份配置的 GitHub 部署，请务必确保该用户对 Nginx 的网页目录拥有写入权限，否则 GitHub Actions 传输文件时会报 `Permission denied` 错误：

```bash
# 将网站目录的所有权赋给你的部署用户
sudo chown -R cong:cong /var/www/html
```

## 结语

配置完成后，执行经典的 Git 三连（`git add .`, `git commit -m "..."`, `git push`）。打开 GitHub 的 Actions 面板，看着那个黄色的圆圈转动，最终变成绿色的对勾，你会发现，之前折腾的这一切都是值得的。

从此以后，只需专注写作。