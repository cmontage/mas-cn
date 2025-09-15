# MAS 中文版获取脚本 - 优化版本
# 基于官方 get.ps1 结构改进

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
        } catch {
            # 静默处理杀毒软件检测错误
        }
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
    
    # 随机尝试下载源
    foreach ($URL in $URLs | Sort-Object { Get-Random }) {
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

    # 下载文件内容（以二进制方式保持原始编码）
    $content = $null
    $downloadErrors = @()
    
    try {
        if ($psv -ge 3) {
            # 以字节方式下载以保持原始编码
            $response = Invoke-WebRequest -Uri $downloadUrl -TimeoutSec 30
            $contentBytes = $response.Content
            # 转换为字符串但保持原始编码
            $content = [System.Text.Encoding]::Default.GetString($contentBytes)
        } else {
            $w = New-Object Net.WebClient
            $w.Encoding = [System.Text.Encoding]::Default
            $content = $w.DownloadString($downloadUrl)
        }
    }
    catch {
        $downloadErrors += $_
    }

    Write-Progress -Activity "下载 MAS 文件..." -Status "完成" -Completed

    if (-not $content) {
        Check3rdAV
        foreach ($err in $downloadErrors) {
            Write-Host "下载错误: $($err.Exception.Message)" -ForegroundColor Red
        }
        Write-Host "无法下载 MAS 文件，操作中止！"
        Write-Host "帮助 - $troubleshoot" -ForegroundColor White -BackgroundColor Blue
        return
    }

    # 检查 AutoRun 注册表（可能导致 CMD 崩溃）
    $paths = "HKCU:\SOFTWARE\Microsoft\Command Processor", "HKLM:\SOFTWARE\Microsoft\Command Processor"
    foreach ($path in $paths) { 
        if (Get-ItemProperty -Path $path -Name "Autorun" -ErrorAction SilentlyContinue) { 
            Write-Warning "发现 AutoRun 注册表，CMD 可能会崩溃！`n手动复制粘贴以下命令来修复...`nRemove-ItemProperty -Path '$path' -Name 'Autorun'"
        } 
    }

    # 创建临时文件
    $rand = [Guid]::NewGuid().Guid
    $isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
    $FilePath = if ($isAdmin) { 
        "$env:SystemRoot\Temp\MAS_CN_$rand.cmd" 
    } else { 
        "$env:USERPROFILE\AppData\Local\Temp\MAS_CN_$rand.cmd" 
    }
    
    # 写入文件（保持原始编码）
    $fileHeader = "@::: MAS-CN $version $rand`r`n"
    Set-Content -Path $FilePath -Value "$fileHeader$content" -Encoding Default
    CheckFile $FilePath

    # 验证文件内容（调试用）
    $fileSize = (Get-Item $FilePath).Length
    Write-Host "临时文件创建成功:" -ForegroundColor Green
    Write-Host "  路径: $FilePath" -ForegroundColor Gray  
    Write-Host "  大小: $([math]::Round($fileSize/1KB, 2)) KB" -ForegroundColor Gray

    Write-Host "文件已下载: " -NoNewline
    Write-Host "$fileName" -ForegroundColor Green -NoNewline
    Write-Host " (大小: $([math]::Round($content.Length/1KB, 2)) KB)"

    # 验证 CMD 环境
    $env:ComSpec = "$env:SystemRoot\system32\cmd.exe"
    $chkcmd = & $env:ComSpec /c "echo CMD is working"
    if ($chkcmd -notcontains "CMD is working") {
        Write-Warning "cmd.exe 工作异常。`n报告问题: $troubleshoot"
    }

    # 检查架构兼容性
    if ($psv -lt 3) {
        if (Test-Path "$env:SystemRoot\Sysnative") {
            Write-Warning "当前使用 x86 PowerShell 运行，建议使用 x64 PowerShell..."
            return
        }
    }

    Write-Host "正在启动 MAS 中文版激活脚本..." -ForegroundColor Cyan

    # 以管理员权限运行
    try {
        # 简化启动参数，避免引号嵌套问题
        if ($psv -lt 3) {
            $p = Start-Process -FilePath $env:ComSpec -ArgumentList "/c `"$FilePath`" $args" -Verb RunAs -PassThru
            $p.WaitForExit()
        } else {
            Start-Process -FilePath $env:ComSpec -ArgumentList "/c `"$FilePath`" $args" -Wait -Verb RunAs
        }
        
        Write-Host "MAS 激活脚本已启动！" -ForegroundColor Green
    }
    catch {
        Write-Host "启动失败: $($_.Exception.Message)" -ForegroundColor Red
        
        # 提供诊断信息
        Write-Host "`n=== 诊断信息 ===" -ForegroundColor Yellow
        Write-Host "临时文件: $FilePath" -ForegroundColor Gray
        Write-Host "文件存在: $(Test-Path $FilePath)" -ForegroundColor Gray
        Write-Host "文件大小: $((Get-Item $FilePath -ErrorAction SilentlyContinue).Length) bytes" -ForegroundColor Gray
        
        # 显示文件前几行用于调试
        try {
            Write-Host "文件前5行内容:" -ForegroundColor Gray
            Get-Content $FilePath -TotalCount 5 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        } catch {
            Write-Host "无法读取文件内容" -ForegroundColor Red
        }
        
        # 检查杀毒软件拦截
        if ($_.Exception.Message -like "*病毒*" -or $_.Exception.Message -like "*垃圾软件*" -or 
            $_.Exception.Message -like "*virus*" -or $_.Exception.Message -like "*malware*" -or
            $_.Exception.Message -like "*blocked*" -or $_.Exception.Message -like "*阻止*") {
            
            Check3rdAV
            Write-Host "`n=== 杀毒软件误报处理指南 ===" -ForegroundColor Yellow
            Write-Host "MAS 被错误识别为恶意软件。这是激活工具的常见误报。" -ForegroundColor Yellow
            Write-Host "`n解决方案：" -ForegroundColor Green
            Write-Host "1. 临时关闭 Windows Defender 实时保护"
            Write-Host "2. 将临时文件夹添加到排除列表: $(Split-Path $FilePath)"
            Write-Host "3. 手动以管理员身份运行: $FilePath"
            Write-Host "`n项目地址: https://github.com/massgravel/Microsoft-Activation-Scripts" -ForegroundColor Blue
            
            # 打开文件所在目录
            try {
                Start-Process -FilePath "explorer.exe" -ArgumentList "/select,`"$FilePath`""
            } catch {
                Write-Host "文件位置: $FilePath"
            }
        }
    }

    CheckFile $FilePath

    # 清理临时文件
    $FilePaths = @("$env:SystemRoot\Temp\MAS_CN*.cmd", "$env:USERPROFILE\AppData\Local\Temp\MAS_CN*.cmd")
    foreach ($FilePattern in $FilePaths) { 
        Get-Item $FilePattern -ErrorAction SilentlyContinue | Remove-Item 
    }

} @args
