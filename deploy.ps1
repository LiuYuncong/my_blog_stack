# ==========================================
# 脚本 2：一键编译与自动上传（跨平台 Tar 完美版）
# ==========================================
$serverIP = "117.72.195.134"
$sshPort = "4180"
$sshUser = "cong"
$remoteDir = "/DATA/AppData/xiaocong-site"

Write-Host "==== 1. 开始清理并生成静态文件 ====" -ForegroundColor Cyan
hugo --gc --cleanDestinationDir --minify
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Hugo 生成失败！请检查 Markdown 格式或配置。" -ForegroundColor Red; exit 1 }

Write-Host "==== 2. 打包为 Linux 原生格式 (tar.gz) ====" -ForegroundColor Cyan
if (Test-Path public.tar.gz) { Remove-Item public.tar.gz -Force }
# 使用 Windows 内置的 tar 命令打包，完美解决反斜杠问题
tar -czf public.tar.gz -C public .
if ($LASTEXITCODE -ne 0) { Write-Host "❌ 压缩打包失败！" -ForegroundColor Red; exit 1 }

Write-Host "==== 3. 上传 public.tar.gz 到服务器... ====" -ForegroundColor Cyan
scp -P $sshPort public.tar.gz ${sshUser}@${serverIP}:~/public.tar.gz
if ($LASTEXITCODE -ne 0) { Write-Host "❌ 上传失败！请检查网络或 SSH 密钥/密码。" -ForegroundColor Red; exit 1 }

Write-Host "==== 4. 服务器端清空旧文件并解压部署 ====" -ForegroundColor Cyan
# 确保目标文件夹存在 -> 清空旧文件 -> 解压 -> 赋权 -> 删掉压缩包
$remoteCmd = "sudo mkdir -p $remoteDir && sudo rm -rf $remoteDir/* && sudo tar -xzf ~/public.tar.gz -C $remoteDir && sudo chmod -R 755 $remoteDir && rm -f ~/public.tar.gz"

ssh -t -p $sshPort ${sshUser}@${serverIP} $remoteCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "🎉 部署完美完成！" -ForegroundColor Green
    Write-Host "👉 提示：请去浏览器按 Ctrl + F5 强制刷新查看最新效果！" -ForegroundColor Yellow
    # 部署完顺手把本地的压缩包也清了，保持桌面干净
    if (Test-Path public.tar.gz) { Remove-Item public.tar.gz -Force }
} else {
    Write-Host "❌ 服务器端部署命令执行失败！请检查服务器目录权限或 sudo 密码。" -ForegroundColor Red
}