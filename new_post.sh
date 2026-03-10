#!/bin/bash

# ==========================================
# 博客创作辅助脚本 (Linux/macOS 版)
# ==========================================

# 定义板块颜色
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

echo -e "${CYAN}请选择你要发表的板块：${NC}"
echo "1) posts    (文艺随笔)"
echo "2) projects (科研课题)"
echo "3) tricks   (经验总结)"

read -p "输入对应数字 (默认1): " choice
choice=${choice:-1}

# 根据选择确定目录和默认分类
case $choice in
    1) section="posts"; default_category="posts" ;;
    2) section="projects"; default_category="projects" ;;
    3) section="tricks"; default_category="tricks" ;;
    *) echo -e "${RED}❌ 无效选择${NC}"; exit 1 ;;
esac

echo -e "${YELLOW}--- 请输入文章信息 ---${NC}"

# 1. 文件夹名称 (用于 URL)
read -p "请输入文章目录名 (用作URL链接，如 my-new-paper): " slug
if [ -z "$slug" ]; then
    echo -e "${RED}❌ 目录名不能为空！${NC}"
    exit 1
fi

# 2. 文章标题
read -p "请输入文章显示标题 (如 Github自动部署，默认与目录名相同): " title
title=${title:-$slug}

# 3. 文章描述
read -p "请输入文章描述 (Description, 可为空): " description

# 4. 文章分类
read -p "请输入文章分类 (Category, 默认: $default_category): " category
category=${category:-$default_category}

# 5. 文章标签
read -p "请输入标签 (Tags, 多个标签请用空格隔开, 可为空): " tags_input

# 处理标签逻辑
if [ -z "$tags_input" ]; then
    # 如果为空，保留 tags 字段但不填内容
    tags_line="tags: "
else
    # 如果有输入，将空格分隔的字符串转换为 ["tag1", "tag2"] 格式
    IFS=' ' read -r -a tag_array <<< "$tags_input"
    tags_format=""
    for tag in "${tag_array[@]}"; do
        tags_format="$tags_format\"$tag\", "
    done
    # 去除末尾多余的逗号和空格
    tags_format=${tags_format%, }
    tags_line="tags: [$tags_format]"
fi

# 获取当前日期
current_date=$(date +"%Y-%m-%d")

# 定义路径
target_dir="content/$section/$slug"
target_path="$target_dir/index.md"

echo -e "${YELLOW}正在生成文章...${NC}"

# 创建 Page Bundle 目录
mkdir -p "$target_dir"

# 直接写入你要求的 Front Matter 模板
cat > "$target_path" << EOF
---
title: "$title"
description: "$description"
date: $current_date
categories: ["$category"]
$tags_line
image: 
math: 
license: 
comments: true
draft: false
build:
  list: always    # Change to "never" to hide the page from the list
---

EOF

if [ -f "$target_path" ]; then
    echo -e "${GREEN}✅ 创建成功！${NC}"
    echo -e "文件位置: ${CYAN}$target_path${NC}"
    
    # 自动尝试用 VS Code 打开
    if command -v code >/dev/null 2>&1; then
        code "$target_path"
        echo -e "${GREEN}🚀 已为你自动打开 VS Code 编辑器${NC}"
    else
        echo -e "${YELLOW}👉 请使用 Typora 或其他编辑器打开该文件进行编辑${NC}"
    fi
else
    echo -e "${RED}❌ 创建失败，请确认是否在博客根目录运行或检查权限${NC}"
fi