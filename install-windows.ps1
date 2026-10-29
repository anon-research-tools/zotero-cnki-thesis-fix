# Zotero CNKI thesis metadata fix - Windows installer
$ErrorActionPreference = "Stop"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$prefsRoot = Join-Path $env:APPDATA "Zotero\Zotero\Profiles"
$prefs = Get-ChildItem (Join-Path $prefsRoot "*\prefs.js") -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

$data = $null
if ($prefs) {
    $text = Get-Content $prefs.FullName -Raw
    $use = [regex]::Match($text, 'extensions\.zotero\.useDataDir",\s*(\w+)').Groups[1].Value
    $dir = [regex]::Match($text, 'extensions\.zotero\.dataDir",\s*"([^"]+)"').Groups[1].Value
    if ($use -eq "true" -and $dir) {
        $data = $dir.Replace('\\', '\').Replace('/', '\')
    }
}

if (-not $data) {
    $data = Join-Path $env:USERPROFILE "Zotero"
}

$targetDir = Join-Path $data "translators"
$target = Join-Path $targetDir "CNKI.js"

if (-not (Test-Path $targetDir)) {
    Write-Host "找不到 Zotero 译者目录：$targetDir"
    Write-Host "请先在 Zotero 设置 -> 高级 -> 文件和文件夹 确认数据目录。"
    exit 1
}

$stamp = Get-Date -Format "yyyyMMddHHmmss"
if (Test-Path $target) {
    $backup = "$target.bak-$stamp"
    Copy-Item $target $backup -Force
    Write-Host "已备份：$backup"
}

Copy-Item (Join-Path $here "CNKI.js") $target -Force

$content = Get-Content $target -Raw
$content = $content -replace '"lastUpdated": "[^"]*"', ('"lastUpdated": "' + (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + '"')
Set-Content -Path $target -Value $content -NoNewline -Encoding UTF8

Write-Host ""
Write-Host "已安装到：$target"
Write-Host ""
Write-Host "接下来："
Write-Host "  1. 完全退出并重新启动 Zotero"
Write-Host "  2. 浏览器 -> Zotero 连接器 -> 设置 -> 高级 -> Reset Translators"
Write-Host "  3. 刷新知网检索页，批量保存 2 篇学位论文验证「大学」「日期」"
Write-Host ""
Write-Host "回滚：把 $target.bak-$stamp 改名回 CNKI.js，重启 Zotero 后再 Reset Translators。"
