<#
.SYNOPSIS
  安装「拘灵遣将」skill 与两个只读子代理定义到 Codex 用户目录。

.DESCRIPTION
  只复制文件，**不修改你的 config.toml**（[agents] 那段需要你自己加，脚本会打印出来）。
  已存在的文件默认跳过并提示；加 -Force 会先按时间戳备份再覆盖。

.EXAMPLE
  .\install.ps1
  .\install.ps1 -Force
  .\install.ps1 -CodexHome 'D:\my-codex'
#>
[CmdletBinding()]
param(
    [string]$CodexHome,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

if (-not $CodexHome) { $CodexHome = Join-Path $env:USERPROFILE '.codex' }

$srcAgents = Join-Path $PSScriptRoot 'agents'
$srcSkill  = Join-Path $PSScriptRoot 'skills\juling-qianjiang'

foreach ($p in @($srcAgents, $srcSkill)) {
    if (-not (Test-Path -LiteralPath $p)) {
        throw "缺少资源：$p —— 请在仓库根目录运行本脚本。"
    }
}

$dstAgents = Join-Path $CodexHome 'agents'
$dstSkill  = Join-Path $CodexHome 'skills\juling-qianjiang'
$stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'

New-Item -ItemType Directory -Force -Path $dstAgents | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dstSkill) | Out-Null

Write-Host ''
Write-Host "Codex 用户目录: $CodexHome"
Write-Host ''

# ---- 子代理定义 ----
foreach ($name in @('scout.toml', 'inspector.toml')) {
    $from = Join-Path $srcAgents $name
    $to   = Join-Path $dstAgents $name

    if (Test-Path -LiteralPath $to) {
        if (-not $Force) {
            Write-Host "  跳过   agents\$name（已存在，加 -Force 覆盖）"
            continue
        }
        Copy-Item -LiteralPath $to -Destination "$to.bak-$stamp" -Force
    }
    Copy-Item -LiteralPath $from -Destination $to -Force
    Write-Host "  安装   agents\$name"
}

# ---- skill 目录 ----
if (Test-Path -LiteralPath $dstSkill) {
    if (-not $Force) {
        Write-Host '  跳过   skills\juling-qianjiang\（已存在，加 -Force 覆盖）'
    } else {
        Copy-Item -LiteralPath $dstSkill -Destination "$dstSkill.bak-$stamp" -Recurse -Force
        Remove-Item -LiteralPath $dstSkill -Recurse -Force
        Copy-Item -LiteralPath $srcSkill -Destination $dstSkill -Recurse -Force
        Write-Host '  安装   skills\juling-qianjiang\（旧版已备份）'
    }
} else {
    Copy-Item -LiteralPath $srcSkill -Destination $dstSkill -Recurse -Force
    Write-Host '  安装   skills\juling-qianjiang\'
}

Write-Host ''
Write-Host '------------------------------------------------------------'
Write-Host '还差一步：把下面这段加进 config.toml'
Write-Host "  $(Join-Path $CodexHome 'config.toml')"
Write-Host '------------------------------------------------------------'
Write-Host ''
Write-Host '  [agents]'
Write-Host '  max_concurrent_threads_per_session = 4'
Write-Host '  default_subagent_reasoning_effort = "high"'
Write-Host ''
Write-Host '（脚本刻意不替你改 config.toml：有些第三方管理器会重写这个文件，'
Write-Host '  由你自己加更容易在它被覆盖时发现。）'
Write-Host ''
Write-Host '然后开一个新会话（skill 列表是在会话开始时装进上下文的），发：'
Write-Host ''
Write-Host '  用 $juling-qianjiang 走一遍。先派 scout 探路，回报后立规格再动手，交付前派 inspector 审一遍。'
Write-Host ''
Write-Host '要确认派发是真的：app 里应该出现 scout 的 agent thread。'
Write-Host '如果它开始自己写「子代理 A 认为……」，那就是在扮演子代理 —— 见 README。'
Write-Host ''
