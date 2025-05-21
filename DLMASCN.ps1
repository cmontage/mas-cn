# 编码设置
try {
    $OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)
    chcp 65001 >$null 2>&1
} catch {}

# 设置TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 定义中文消息常量，避免运行时解析问题
$MSG_GETTING = [System.Text.Encoding]::UTF8.GetString([byte[]](0xE6, 0xAD, 0xA3, 0xE5, 0x9C, 0xA8, 0xE8, 0x8E, 0xB7, 0xE5, 0x8F, 0x96))
$MSG_LATEST = [System.Text.Encoding]::UTF8.GetString([byte[]](0xE6, 0x89, 0xBE, 0xE5, 0x88, 0xB0, 0xE6, 0x9C, 0x80, 0xE6, 0x96, 0xB0, 0xE7, 0x89, 0x88, 0xE6, 0x9C, 0xAC))
$MSG_NOTFOUND = [System.Text.Encoding]::UTF8.GetString([byte[]](0xE6, 0x9C, 0xAA, 0xE5, 0x9C, 0xA8, 0xE6, 0x9C, 0x80, 0xE6, 0x96, 0xB0, 0xE7, 0x89, 0x88, 0xE6, 0x9C, 0xAC, 0xE4, 0xB8, 0xAD, 0xE6, 0x89, 0xBE, 0xE5, 0x88, 0xB0, 0x63, 0x6D, 0x64, 0xE6, 0x96, 0x87, 0xE4, 0xBB, 0xB6))
$MSG_DOWNLOADING = [System.Text.Encoding]::UTF8.GetString([byte[]](0xE6, 0xAD, 0xA3, 0xE5, 0x9C, 0xA8, 0xE4, 0xB8, 0x8B, 0xE8, 0xBD, 0xBD))
$MSG_TO = [System.Text.Encoding]::UTF8.GetString([byte[]](0xE5, 0x88, 0xB0))
$MSG_COMPLETE = [System.Text.Encoding]::UTF8.GetString([byte[]](0xE4, 0xB8, 0x8B, 0xE8, 0xBD, 0xBD, 0xE5, 0xAE, 0x8C, 0xE6, 0x88, 0x90))
$MSG_STARTING = [System.Text.Encoding]::UTF8.GetString([byte[]](0xE6, 0xAD, 0xA3, 0xE5, 0x9C, 0xA8, 0xE5, 0x90, 0xAF, 0xE5, 0x8A, 0xA8))
$MSG_ERROR = [System.Text.Encoding]::UTF8.GetString([byte[]](0xE5, 0x8F, 0x91, 0xE7, 0x94, 0x9F, 0xE9, 0x94, 0x99, 0xE8, 0xAF, 0xAF))
$MSG_FAILED = [System.Text.Encoding]::UTF8.GetString([byte[]](0xE6, 0x96, 0x87, 0xE4, 0xBB, 0xB6, 0xE4, 0xB8, 0x8B, 0xE8, 0xBD, 0xBD, 0xE5, 0xA4, 0xB1, 0xE8, 0xB4, 0xA5))

# 定义仓库信息
$repoOwner = "cmontage"
$repoName = "mas-cn"
$apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"

# 增强版输出函数
function Write-CDNSafeOutput {
    param([string]$Message, [string]$ForegroundColor = "White")
    
    try {
        if ($Host.UI.RawUI -ne $null) {
            Write-Host $Message -ForegroundColor $ForegroundColor
        } else {
            [Console]::ForegroundColor = $ForegroundColor
            [Console]::WriteLine($Message)
            [Console]::ResetColor()
        }
    } catch {
        # 终极后备方案，使用命令行回显
        echo $Message
    }
}

# 显示版本信息
Write-CDNSafeOutput "$MSG_GETTING $repoName 的最新版本信息..." "Cyan"

try {
    # 获取最新版本信息
    $latestRelease = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{
        "User-Agent" = "PowerShell Script"
        "Accept-Charset" = "UTF-8"
    }
    
    # 获取版本号
    $version = $latestRelease.tag_name
    Write-CDNSafeOutput "$MSG_LATEST: $version" "Green"
    
    # 查找cmd文件
    $cmdAsset = $latestRelease.assets | Where-Object { $_.name -like "*.cmd" -or $_.name -like "*.bat" } | Select-Object -First 1
    
    if ($null -eq $cmdAsset) {
        Write-CDNSafeOutput "$MSG_NOTFOUND！" "Red"
        exit 1
    }
    
    $downloadUrl = $cmdAsset.browser_download_url
    $fileName = $cmdAsset.name
    
    # 使用临时目录
    $tempDir = [System.IO.Path]::GetTempPath()
    $downloadPath = Join-Path -Path $tempDir -ChildPath $fileName
    
    Write-CDNSafeOutput "$MSG_DOWNLOADING $fileName $MSG_TO $tempDir..." "Cyan"
    
    # 下载文件设置
    $webClient = New-Object System.Net.WebClient
    $webClient.Encoding = [System.Text.Encoding]::UTF8
    $webClient.DownloadFile($downloadUrl, $downloadPath)
    
    # 验证文件是否下载成功
    if (Test-Path $downloadPath) {
        Write-CDNSafeOutput "$MSG_COMPLETE: $downloadPath" "Green"
        
        # 启动cmd文件
        Write-CDNSafeOutput "$MSG_STARTING $fileName..." "Cyan"
        Start-Process -FilePath $downloadPath
    } else {
        Write-CDNSafeOutput "$MSG_FAILED！" "Red"
    }
} catch {
    Write-CDNSafeOutput "$MSG_ERROR: $_" "Red"
}
