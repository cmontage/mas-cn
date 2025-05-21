[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 定义仓库信息
$repoOwner = "cmontage"
$repoName = "mas-cn"
$apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"

Write-Host "正在获取 $repoName 的最新版本信息..." -ForegroundColor Cyan

try {
    # 获取最新版本信息
    $latestRelease = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{
        "User-Agent" = "PowerShell Script"
    }
    
    # 获取版本号
    $version = $latestRelease.tag_name
    Write-Host "找到最新版本: $version" -ForegroundColor Green
    
    # 查找cmd文件
    $cmdAsset = $latestRelease.assets | Where-Object { $_.name -like "*.cmd" -or $_.name -like "*.bat" } | Select-Object -First 1
    
    if ($null -eq $cmdAsset) {
        Write-Host "未在最新版本中找到cmd文件！" -ForegroundColor Red
        exit 1
    }
    
    $downloadUrl = $cmdAsset.browser_download_url
    $fileName = $cmdAsset.name
    
    # 使用临时目录而不是相对路径
    $tempDir = [System.IO.Path]::GetTempPath()
    $downloadPath = Join-Path -Path $tempDir -ChildPath $fileName
    
    Write-Host "正在下载 $fileName 到 $tempDir..." -ForegroundColor Cyan
    
    # 下载文件
    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath
    
    # 验证文件是否下载成功
    if (Test-Path $downloadPath) {
        Write-Host "下载完成: $downloadPath" -ForegroundColor Green
        
        # 启动cmd文件
        Write-Host "正在启动 $fileName..." -ForegroundColor Cyan
        Start-Process -FilePath $downloadPath
    } else {
        Write-Host "文件下载失败！" -ForegroundColor Red
    }
} catch {
    Write-Host "发生错误: $_" -ForegroundColor Red
}
