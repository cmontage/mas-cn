<p align="center"><img src="https://massgrave.dev/img/logo_small.png" alt="MAS Logo"></p>

<h1 align="center">Microsoft  Activation  Scripts (MAS)</h1>

<p align="center">一款开源的 Windows 与 Office 激活工具，支持 HWID、Ohook、TSforge、KMS38 及在线 KMS 等多种激活方式，并提供高级故障排除功能。</p>

<p align="center">
    <a href="https://github.com/cmontage/mas-cn/stargazers"><img src="https://img.shields.io/github/stars/cmontage/mas-cn?style=for-the-badge&logo=github" alt="GitHub stars"></a>
    <a href="https://github.com/cmontage/mas-cn"><img src="https://img.shields.io/github/repo-size/cmontage/mas-cn?style=for-the-badge&logo=github" alt="GitHub repo size"></a>
    <a href="https://github.com/cmontage/mas-cn/blob/main/LICENSE"><img src="https://img.shields.io/github/license/cmontage/mas-cn?style=for-the-badge" alt="GitHub license"></a>
</p>

<hr>


Windows 和 Office 激活工具 MAS (Microsoft-Activation-Scripts) 的汉化版，在不改变机器码的情况下可永久激活 (视激活方式而定) ，备以自用😋

<!-- RECENT_UPDATE_START -->
> [!TIP]
> ### 最近更新 (v3.11 → v3.12)
> 
> **变更总览：** replace: 54 处 | insert: 3 处 | delete: 15 处 | 总计: 72 处变更
>
> 🔗 [查看完整变更日志](change_log/sync_report_v3.11_to_v3.12.txt)
<!-- RECENT_UPDATE_END -->

 **注：该汉化由我自己编写脚本（翻译源为[ Google 翻译](https://translate.google.com)）自动进行初步汉化然后进行人工校对完善的，并做了中文显示兼容以及 IRM 远程使用的脚本，修改或分发代码使请遵守 GPL-3.0 ，标明源代码出处或者提供获取源代码的途径。**

### 具体使用方法: 
**打开 Powershell 或 Terminal（终端）输入命令即可使用**

- Windows Defender 有概率误删，使用前请关闭扫描
- 此为本仓库汉化版使用命令，若该方法无法使用，可以在 Release 下载最新版的 cmd 文件打开即可使用
```
 irm https://gitee.com/cmontage/mas-cn/raw/main/GETMASCN.ps1 | iex
```

- 此为官方英文版使用命令

   For Windows 8, 10, 11:
```
 irm https://get.activated.win | iex
```
    
   &emsp;&emsp;For Windows 7:

```
 iex ((New-Object Net.WebClient).DownloadString('https://get.activated.win'))
```

### 各个激活方法的特性

|          | HWID | Ohook  | Online KMS | TSforge (ZeroCID) | TSforge (StaticCID) | TSforge (KMS4k) |
|:------:|:--------:|:-------:|:------------:|:-------------------:|:---------------------:|:-----------------:| 
| 离线激活 |  ❌  |  ✅    |     ❌     |  ✅              |        ❌           |  ✅  |
| 永久激活 |  ✅  |  ✅    |  ☑️<br>(180天/次)  |  ✅  |  ✅  |☑️<br>(至4083)
| 不会在系统中留下文件来维持激活 |  ✅  |  ❌  |  ❌  |  ✅  |  ✅  |  ✅  |
| 硬件更改后仍保留激活 |  ❌  |  ✅  |  ✅  |  ✅  |  ❌  |  ✅  |
| 在同一硬件上的全新安装之间持续存在 |  ✅  |  ❌  |  ❌  |  ❌  |  ❌  |  ❌  |
| 在 Windows 10 / 11 功能升级之间持续存在 |  ✅  |  ✅  |  ✅  |  ❌  |  ❌  |  ❌  |

🔍 [了解更多特性信息](https://massgrave.dev/chart#user-content-fn-2) 

🔍 [访问官方 Github 仓库 (MAS Source Code)](https://github.com/massgravel/Microsoft-Activation-Scripts?tab=readme-ov-file#download--how-to-use-it)

---

<div align="center">
	
### 官方原版主页 - [https://massgrave.dev/](https://massgrave.dev/)
  
[![1.1]][1]
[![1.2]][2]
[![1.3]][3]
[![1.4]][4]
[![1.5]][5]
[![1.6]][6]
[![1.7]][7]

[1.1]: https://massgrave.dev/img/logo_discord.png (Chat with us without signup)
[1.2]: https://massgrave.dev/img/logo_reddit.png (Reddit)
[1.3]: https://massgrave.dev/img/logo_bluesky.png (Bluesky)
[1.4]: https://massgrave.dev/img/logo_x.png (Twitter)

[1.5]: https://massgrave.dev/img/logo_github.png (GitHub)
[1.6]: https://massgrave.dev/img/logo_azuredevops.png (AzureDevOps)
[1.7]: https://massgrave.dev/img/logo_gitea.png (Self-hosted Git)

[1]: https://discord.gg/j2yFsV5ZVC
[2]: https://www.reddit.com/r/MAS_Activator
[3]: https://bsky.app/profile/massgrave.dev
[4]: https://twitter.com/massgravel
[5]: https://github.com/massgravel/Microsoft-Activation-Scripts
[6]: https://dev.azure.com/massgrave/_git/Microsoft-Activation-Scripts
[7]: https://git.activated.win/Microsoft-Activation-Scripts

---