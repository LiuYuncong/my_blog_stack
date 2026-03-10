#!/bin/bash

# ==========================================
# 博客创作辅助脚本 (Linux 版)
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

case $choice in
    1) section="posts" ;;
    2) section="projects" ;;
    3) section="tricks" ;;
    *) echo -e "${RED}❌ 无效选择${NC}"; exit 1 ;;
esac

read -p "请输入文章名称 (如 my-new-paper): " title

if [ -z "$title" ]; then
    echo -e "${RED}❌ 名称不能为空！${NC}"
    exit 1
fi

# 使用 Hugo Page Bundle 模式创建
# 路径结构: content/板块/文章名/index.md
target_path="content/$section/$title/index.md"

echo -e "${YELLOW}正在创建文章...${NC}"
hugo new "$target_path"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 创建成功！${NC}"
    echo -e "文件位置: ${CYAN}$target_path${NC}"
    
    # 自动尝试用 VS Code 打开（如果在本地或 SSH 转发环境下）
    if command -v code >/dev/null 2>&1; then
        code "$target_path"
        echo -e "${GREEN}🚀 已为你自动打开 VS Code 编辑器${NC}"
    else
        echo -e "${YELLOW}👉 请使用 Typora 或编辑器打开该文件进行编辑${NC}"
    fi
else
    echo -e "${RED}❌ 创建失败，请确认是否在博客根目录运行${NC}"
fi