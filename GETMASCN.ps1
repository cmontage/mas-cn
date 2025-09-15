# 编码设置
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
try { chcp 65001 | Out-Null } catch {}

# 设置TLS 1.2，确保与GitHub API通信安全
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 定义仓库信息
$repoOwner = "cmontage"
$repoName = "mas-cn"
$giteeApiUrl = "https://gitee.com/api/v5/repos/$repoOwner/$repoName/releases/latest"
$githubApiUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"

# 使用UTF-8专用的Write-Output函数
function Write-UTF8Output {
    param([string]$Message, [string]$ForegroundColor = "White")
    
    if ($null -ne $Host.UI.RawUI) {
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
    $latestRelease = $null
    $source = "unknown"
    
    # 优先尝试从Gitee获取
    Write-UTF8Output "尝试从Gitee获取最新版本..." "Yellow"
    try {
        $latestRelease = Invoke-RestMethod -Uri $giteeApiUrl -Method Get -Headers @{
            "User-Agent" = "PowerShell Script"
        } -TimeoutSec 10
        
        if ($latestRelease -and $latestRelease.tag_name) {
            $source = "Gitee"
            Write-UTF8Output "成功从Gitee获取版本信息" "Green"
        } else {
            throw "Gitee响应无效"
        }
    } catch {
        Write-UTF8Output "从Gitee获取失败: $($_.Exception.Message)" "Yellow"
        
        # 回退到GitHub
        Write-UTF8Output "回退到GitHub获取最新版本..." "Yellow"
        try {
            $latestRelease = Invoke-RestMethod -Uri $githubApiUrl -Method Get -Headers @{
                "User-Agent" = "PowerShell Script"
            } -TimeoutSec 15
            $source = "GitHub"
            Write-UTF8Output "成功从GitHub获取版本信息" "Green"
        } catch {
            throw "无法从GitHub和Gitee获取版本信息: $($_.Exception.Message)"
        }
    }
    
    # 获取版本号
    $version = $latestRelease.tag_name
    Write-UTF8Output "找到最新版本: $version (来源: $source)" "Green"
    
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
    
    Write-UTF8Output "正在从 $source 下载 $fileName 到 $tempDir..." "Cyan"
    Write-UTF8Output "下载链接: $downloadUrl" "Gray"
    
    # 下载文件
    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -TimeoutSec 30
    
    # 验证文件是否下载成功
    if (Test-Path $downloadPath) {
        $fileSize = (Get-Item $downloadPath).Length
        Write-UTF8Output "下载完成: $downloadPath (大小: $([math]::Round($fileSize/1KB, 2)) KB)" "Green"
        
        # 启动cmd文件
        Write-UTF8Output "正在启动 $fileName..." "Cyan"
        try {
            Start-Process -FilePath $downloadPath
            Write-UTF8Output "MAS 激活脚本已启动！" "Green"
        } catch {
            Write-UTF8Output "启动失败: $($_.Exception.Message)" "Red"
            Write-UTF8Output "您可以手动运行: $downloadPath" "Yellow"
        }
    } else {
        Write-UTF8Output "文件下载失败！" "Red"
    }
} catch {
    Write-UTF8Output "发生错误: $_" "Red"
}
