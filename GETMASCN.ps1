# MAS 中文版获取脚本 - 优化版，解决Gitee下载乱码与兼容问题

if (-not $args) {
    Write-Host ''
    Write-Host '需要帮助？查看项目主页: ' -NoNewline
    Write-Host 'https://github.com/cmontage/mas-cn' -ForegroundColor Green
    Write-Host ''
}

& {
    $psv = (Get-Host).Version.Major
    $troubleshoot = 'https://github.com/cmontage/mas-cn/issues'

    # 检查 PowerShell 执行模式
    if ($ExecutionContext.SessionState.LanguageMode.value__ -ne 0) {
        Write-Host "PowerShell 未在完整语言模式下运行。"
        Write-Host "帮助 - https://massgrave.dev/troubleshoot" -ForegroundColor White -BackgroundColor Blue
        return
    }

    # 检查 .NET 环境
    try {
        [void][System.AppDomain]::CurrentDomain.GetAssemblies(); [void][System.Math]::Sqrt(144)
    }
    catch {
        Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "PowerShell 无法加载 .NET 命令。"
        Write-Host "帮助 - https://massgrave.dev/troubleshoot" -ForegroundColor White -BackgroundColor Blue
        return
    }

    # 检查第三方杀毒软件
    function Check3rdAV {
        $cmd = if ($psv -ge 3) { 'Get-CimInstance' } else { 'Get-WmiObject' }
        try {
            $avList = & $cmd -Namespace root\SecurityCenter2 -Class AntiVirusProduct -ErrorAction SilentlyContinue | 
                      Where-Object { $_.displayName -notlike '*windows*' } | 
                      Select-Object -ExpandProperty displayName

            if ($avList) {
                Write-Host '第三方杀毒软件可能会阻止脚本运行 - ' -ForegroundColor White -BackgroundColor Blue -NoNewline
                Write-Host " $($avList -join ', ')" -ForegroundColor DarkRed -BackgroundColor White
            }
        } catch {}
    }

    # 检查文件是否创建成功
    function CheckFile {
        param ([string]$FilePath)
        if (-not (Test-Path $FilePath)) {
            Check3rdAV
            Write-Host "无法在临时文件夹中创建 MAS 文件，操作中止！"
            Write-Host "帮助 - $troubleshoot" -ForegroundColor White -BackgroundColor Blue
            throw
        }
    }

    # 设置安全协议
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

    # 定义仓库信息
    $repoOwner = "cmontage"
    $repoName = "mas-cn"

    # 定义多个下载源（优先 Gitee）
    $URLs = @(
        "https://gitee.com/api/v5/repos/$repoOwner/$repoName/releases/latest",
        "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"
    )

    Write-Progress -Activity "获取版本信息..." -Status "请稍等"

    $latestRelease = $null
    $source = "unknown"
    $errors = @()

    foreach ($URL in $URLs) {
        try {
            $headers = @{ "User-Agent" = "PowerShell MAS-CN Script" }
            if ($psv -ge 3) {
                $response = Invoke-RestMethod -Uri $URL -Headers $headers -TimeoutSec 15
            } else {
                $w = New-Object Net.WebClient
                $w.Headers.Add("User-Agent", "PowerShell MAS-CN Script")
                $responseText = $w.DownloadString($URL)
                $response = $responseText | ConvertFrom-Json
            }
            if ($response -and $response.tag_name) {
                $latestRelease = $response
                $source = if ($URL -like "*gitee*") { "Gitee" } else { "GitHub" }
                break
            }
        }
        catch {
            $errors += $_
        }
    }

    Write-Progress -Activity "获取版本信息..." -Status "完成" -Completed

    if (-not $latestRelease) {
        Check3rdAV
        foreach ($err in $errors) {
            Write-Host "错误: $($err.Exception.Message)" -ForegroundColor Red
        }
        Write-Host "无法从任何可用的仓库获取 MAS 版本信息，操作中止！"
        Write-Host "检查杀毒软件或防火墙是否阻止了连接。"
        Write-Host "帮助 - $troubleshoot" -ForegroundColor White -BackgroundColor Blue
        return
    }

    # 显示版本信息
    $version = $latestRelease.tag_name
    Write-Host "找到最新版本: " -NoNewline
    Write-Host "$version" -ForegroundColor Green -NoNewline
    Write-Host " (来源: $source)"

    # 查找 CMD 文件
    $cmdAsset = $latestRelease.assets | Where-Object { $_.name -like "*.cmd" -or $_.name -like "*.bat" } | Select-Object -First 1

    if (-not $cmdAsset) {
        Write-Host "未在版本 $version 中找到 CMD 文件！" -ForegroundColor Red
        Write-Host "帮助 - $troubleshoot" -ForegroundColor White -BackgroundColor Blue
        return
    }

    $downloadUrl = $cmdAsset.browser_download_url
    $fileName = $cmdAsset.name

    Write-Progress -Activity "下载 MAS 文件..." -Status "请稍等"

    $tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName() + ".cmd")
    $downloadSuccess = $false

    try {
        Write-Host "下载链接: $downloadUrl" -ForegroundColor Gray
        # Gitee 需要用WebClient二进制下载，GitHub可直接Invoke-RestMethod
        if ($source -eq "Gitee") {
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "PowerShell MAS-CN Script")
            $wc.DownloadFile($downloadUrl, $tempFile)
        } else {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -Headers @{ "User-Agent" = "PowerShell MAS-CN Script" }
        }
        $downloadSuccess = $true
    } catch {
        Write-Host "下载失败: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Progress -Activity "下载 MAS 文件..." -Status "完成" -Completed

    if (-not $downloadSuccess -or -not (Test-Path $tempFile)) {
        Write-Host "无法下载 MAS 文件，操作中止！" -ForegroundColor Red
        Write-Host "帮助 - $troubleshoot" -ForegroundColor White -BackgroundColor Blue
        return
    }

    # 检查文件是否创建成功
    CheckFile $tempFile

    # 启动前设置代码页为936（简体中文GBK），防止乱码
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c chcp 936 && `"$tempFile`"" -Wait

    # 删除临时文件
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
}