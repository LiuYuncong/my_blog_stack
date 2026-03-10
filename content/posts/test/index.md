---
title: "Markdown 语法与主题渲染测试"
description: "这是一篇用于测试 Hugo 排版和渲染效果的占位文章，包含常用语法、代码高亮和数学公式。"
date: 2026-03-09T05:22:46+08:00
categories:
    - posts
tags:
    - markdown
    - 测试
image: "cover.jpg" # 如果有封面图，请将图片命名为 cover.jpg 放在与本文档同级的文件夹内
math: true
license: "CC BY-NC-SA 4.0"
comments: true
draft: false      # 已改为 false，方便直接运行 hugo server 预览
build:
    list: always
---

为了确保博客的各个视觉元素都能正常工作，这里准备了一份包含常见排版格式的测试内容。你可以用它来检查字体、颜色、代码高亮以及插件的渲染情况。

## 1. 文本排版

这是一段普通的文本。你可以使用 **粗体**、*斜体*，或者 ~~删除线~~ 来强调内容。你还可以使用行内代码，比如 `hugo server -D`。如果你的主题支持，也可以测试一下标记 `<mark>高亮文本</mark>`。

## 2. 列表测试

### 无序列表与嵌套
* 一级列表项 A
* 一级列表项 B
  * 二级列表项 B1
  * 二级列表项 B2
* 一级列表项 C

### 有序列表
1. 第一步：打开 Typora 编写内容
2. 第二步：保存到 Page Bundle 文件夹
3. 第三步：运行部署脚本

### 任务列表
- [x] 完成博客基础目录搭建
- [x] 编写并测试 PowerShell 部署脚本
- [ ] 发布第一篇正式博文

## 3. 引用块

> 这是一个引用块的测试。
> 用于展示名言、重要提示或引用他人的文章片段。
>
>> 这是嵌套的引用块，用来检查主题是否支持多层级引用样式的区分。

## 4. 代码高亮测试

下面是一段用于测试语法高亮的代码块：

```powershell
# 测试 PowerShell 代码高亮
$siteName = "Hugo Stack Blog"
Write-Host "Welcome to $siteName!" -ForegroundColor Cyan

function Build-Site {
    hugo --gc --cleanDestinationDir --minify
}