# ==========================================
# 脚本 1：新建文章与板块管理 (根据当前 tree 更新)
# ==========================================
# 更新为与 content 目录下一致的三个主要板块
$sections = @(
    "posts (文艺随笔)", 
    "projects (科研课题)", 
    "tricks (经验总结)"
)

Write-Host "请选择你要把文章发到哪个板块：" -ForegroundColor Cyan
for ($i=0; $i -lt $sections.Length; $i++) {
    Write-Host "[$($i+1)] $($sections[$i])"
}

$choice = Read-Host "输入对应数字 (回车默认1)"
if ([string]::IsNullOrWhiteSpace($choice)) { $choice = 1 }

# 提取英文路径名称
$sectionName = ($sections[[int]$choice-1] -split " ")[0]

$title = Read-Host "请输入文章/项目名称 (建议用英文或拼音，如 my-new-paper)"
if ([string]::IsNullOrWhiteSpace($title)) { 
    Write-Host "❌ 名称不能为空！" -ForegroundColor Red
    exit 1 
}

# 使用 Page Bundle 模式创建，生成 文件夹 + index.md，方便存图片
# 注意：新版 Hugo 更推荐写全 content 路径，这里帮你补全以防报错
$path = "content/$sectionName/$title/index.md"
hugo new $path

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 创建成功！请用 Typora 打开 $path 进行编辑。" -ForegroundColor Green
    Write-Host "👉 提示：你可以直接把图片粘贴到 content/$sectionName/$title/ 文件夹内。" -ForegroundColor Yellow
} else {
    Write-Host "❌ 创建失败，请检查 Hugo 是否正确安装或路径是否合法。" -ForegroundColor Red
}