# 编码设置
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
try { chcp 65001 | Out-Null } catch {}

# 设置TLS 1.2，确保与GitHub API通信安全
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 定义仓库信息
$repoOwner = "cmontage"
$repoName = "mas-cn"
$apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"

# 使用UTF-8专用的Write-Output函数
function Write-UTF8Output {
    param([string]$Message, [string]$ForegroundColor = "White")
    
    if ($Host.UI.RawUI -ne $null) {
        Write-Host $Message -ForegroundColor $ForegroundColor
    } else {
        # 远程执行时尝试使用不同方式输出
        [Console]::ForegroundColor = $ForegroundColor
        [Console]::WriteLine($Message)
        [Console]::ResetColor()
    }
}

Write-UTF8Output "正在获取 $repoName 的最新版本信息..." "Cyan"

try {
    # 获取最新版本信息
    $latestRelease = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{
        "User-Agent" = "PowerShell Script"
    }
    
    # 获取版本号
    $version = $latestRelease.tag_name
    Write-UTF8Output "找到最新版本: $version" "Green"
    
    # 查找cmd文件
    $cmdAsset = $latestRelease.assets | Where-Object { $_.name -like "*.cmd" -or $_.name -like "*.bat" } | Select-Object -First 1
    
    if ($null -eq $cmdAsset) {
        Write-UTF8Output "未在最新版本中找到cmd文件！" "Red"
        exit 1
    }
    
    $downloadUrl = $cmdAsset.browser_download_url
    $fileName = $cmdAsset.name
    
    # 使用临时目录而不是相对路径
    $tempDir = [System.IO.Path]::GetTempPath()
    $downloadPath = Join-Path -Path $tempDir -ChildPath $fileName
    
    Write-UTF8Output "正在下载 $fileName 到 $tempDir..." "Cyan"
    
    # 下载文件
    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath
    
    # 验证文件是否下载成功
    if (Test-Path $downloadPath) {
        Write-UTF8Output "下载完成: $downloadPath" "Green"
        
        # 启动cmd文件
        Write-UTF8Output "正在启动 $fileName..." "Cyan"
        Start-Process -FilePath $downloadPath
    } else {
        Write-UTF8Output "文件下载失败！" "Red"
    }
} catch {
    Write-UTF8Output "发生错误: $_" "Red"
}
