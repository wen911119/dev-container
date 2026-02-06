# 1. 进入脚本所在目录
Set-Location $PSScriptRoot

# --- 环境检查开始 ---
Write-Host "🔍 正在检查构建环境..."

# 检查 Docker 是否安装
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ 错误: 未找到 docker 命令。" -ForegroundColor Red
    Write-Host "👉 请先安装 Docker Desktop。"
    Write-Host "🔗 参考指引: https://github.com/wen911119/dev-container?tab=readme-ov-file#2-%E5%85%88%E5%86%B3%E6%9D%A1%E4%BB%B6"
    exit 1
}

# 检查 buildx 是否可用
try {
    docker buildx version | Out-Null
} catch {
    Write-Host "❌ 错误: 您的 Docker 版本不支持 buildx。" -ForegroundColor Red
    Write-Host "👉 请升级 Docker Desktop 到最新版本。"
    exit 1
}

# 检查当前构建器驱动是否为 docker-container
# 获取 docker buildx inspect 的输出
$InspectOutput = docker buildx inspect 2>&1
# 查找 Driver: 行
$DriverLine = $InspectOutput | Select-String "Driver:\s+(\S+)"
if ($DriverLine) {
    $CurrentDriver = $DriverLine.Matches.Groups[1].Value
} else {
    $CurrentDriver = "unknown"
}

if ($CurrentDriver -ne "docker-container") {
    Write-Host "❌ 错误: 当前构建器驱动为 '$CurrentDriver'，不支持多架构构建 (linux/amd64,linux/arm64)。" -ForegroundColor Red
    Write-Host "⚠️  必须使用 'docker-container' 驱动。" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "👉 请按照文档完成一次性环境设置："
    Write-Host "   https://github.com/wen911119/dev-container?tab=readme-ov-file#3-%E4%B8%80%E6%AC%A1%E6%80%A7%E7%8E%AF%E5%A2%83%E8%AE%BE%E7%BD%AE"
    Write-Host ""
    Write-Host "   或者运行以下命令快速修复："
    Write-Host "   docker buildx create --name mybuilder --driver docker-container --use"
    Write-Host "   docker buildx inspect --bootstrap"
    exit 1
}

Write-Host "✅ 环境检查通过 (Driver: $CurrentDriver)" -ForegroundColor Green
# --- 环境检查结束 ---

# 2. 从 project.json 读取 project_name
if (-not (Test-Path "project.json")) {
    Write-Host "❌ 错误: 找不到 project.json 文件" -ForegroundColor Red
    exit 1
}

# 简单解析 JSON (假设格式标准)
$ProjectContent = Get-Content "project.json" -Raw

# 使用正则提取 project_name
if ($ProjectContent -match '"project_name"\s*:\s*"([^"]+)"') {
    $ProjectName = $matches[1]
} else {
    Write-Host "❌ 错误: 无法从 project.json 中解析 project_name" -ForegroundColor Red
    exit 1
}

# 使用正则提取 repo_url 并校验 HTTPS
if ($ProjectContent -match '"repo_url"\s*:\s*"([^"]+)"') {
    $RepoUrl = $matches[1]
    if (-not $RepoUrl.StartsWith("https://")) {
        Write-Host "❌ 错误: repo_url 必须是 HTTPS 格式 (以 https:// 开头)。" -ForegroundColor Red
        Write-Host "   当前值: $RepoUrl"
        Write-Host "   原因: Docker 构建过程中无法处理 SSH 密钥认证，只能 Clone 公开仓库。"
        exit 1
    }
} else {
    Write-Host "❌ 错误: 无法从 project.json 中解析 repo_url" -ForegroundColor Red
    exit 1
}

# 3. 定义镜像名称和时间戳
$ImageBase = "wen911119/${ProjectName}"
$Timestamp = Get-Date -Format "yyyyMMddHHmmss"

Write-Host "🚀 开始构建镜像: ${ImageBase}" -ForegroundColor Cyan
Write-Host "🏷️  Tags: latest, ${Timestamp}"
Write-Host "📂 上下文: $(Get-Location)"

# 4. 执行多架构构建并推送
# 注意: PowerShell 中换行符是 `
docker buildx build `
  --platform linux/amd64,linux/arm64 `
  --progress=tty `
  -t "${ImageBase}:latest" `
  -t "${ImageBase}:${Timestamp}" `
  --push .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 构建并推送成功!" -ForegroundColor Green
} else {
    Write-Host "❌ 构建失败" -ForegroundColor Red
    exit 1
}
