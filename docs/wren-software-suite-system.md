# Wren 软件套装管理系统

> 目标：新电脑 / 重装 / 多设备 → 一键还原，始终最新，多端同步

---

## 一、系统架构

```
┌─────────────────────────────────────────────────────────┐
│                    📦 配置层 (JSON/YAML)                 │
│  • software清单.json    • extensions清单.json           │
│  • dotfiles/            • scripts/                      │
├─────────────────────────────────────────────────────────┤
│                    🔧 核心引擎                           │
│  • Winget/Pyget/OneGet  • 浏览器扩展管理器              │
│  • Scoop/Choco          • 自动更新检测                   │
│  • Config同步           • 安装脚本生成                   │
├─────────────────────────────────────────────────────────┤
│                    ☁️ 同步层                            │
│  • GitHub/Gitea私有库   • icloud/Dropbox/坚果云          │
│  • 自建文件服务器       • Obsidian vault (天然同步)     │
└─────────────────────────────────────────────────────────┘
```

---

## 二、软件管理方案

### 方案 A：Scoop + 私有 Bucket（推荐 Windows）

**原理**：Scoop 用 JSON 声明依赖，Git 同步清单文件即可

```powershell
# 安装清单示例 (scoop-bucket.json)
{
  "apps": [
    { "name": "git", "bucket": "main" },
    { "name": "nodejs-lts", "bucket": "main" },
    { "name": "python", "bucket": "main" },
    { "name": "vscode", "bucket": "extras" },
    { "name": "obsidian", "bucket": "extras" },
    { "name": "docker", "bucket": "main" }
  ]
}
```

**核心脚本**：
```powershell
# install-scoop-apps.ps1
$json = Get-Content "$PSScriptRoot\apps.json" | ConvertFrom-Json
foreach ($app in $json.apps) {
    if (!(scoop list $app.name)) {
        scoop install $app.name
    }
}
```

**优势**：
- 安装路径干净（用户目录）
- 一条命令装完全部
- 版本锁定或始终最新可选

---

### 方案 B：winget + 厂商包（系统级软件）

```powershell
# winget-import.json (winget export 输出格式)
{
  "winget": [
    { "PackageIdentifier": "Git.Git" },
    { "PackageIdentifier": "Microsoft.VisualStudioCode" },
    { "PackageIdentifier": "OpenJS.NodeJS.LTS" }
  ]
}
```

```powershell
# 批量安装
winget import -i winget-import.json --accept-source-agreements
```

---

## 三、浏览器扩展管理

### Chrome/Edge 扩展（扩展名同步）

**工具：Chrome Extension Sources Backup + 扩展ID列表**

```powershell
# extensions.json - 扩展清单
{
  "extensions": [
    { "id": "crxId或URL", "name": "名称" },
    { "id": "nangchenjbjgdg石化gadbgadbg", "name": "uBlock Origin" },
    { "id": "oh Ahlcjajcpmbhpkibnlpecbpjjjj", "name": "ChatGPT Writer" }
  ]
}
```

**自动安装脚本**：
```powershell
# install-extensions.ps1
$extensions = @(
    "https://chrome.google.com/webstore/detail/..."
)
foreach ($ext in $extensions) {
    Start-Process "msedge.exe" "$ext"
    # 或用 crxmake 自动打包安装
}
```

**推荐方案：Browser GAP / Extension Manager**

---

## 四、Dotfiles 同步方案

### 基础结构

```
dotfiles/
├── .gitconfig
├── .gitignore_global
├── .ssh/
│   └── config
├── .vscode/
│   ├── settings.json
│   └── extensions.json
├── .obsidian/          # Obsidian 配置
├── .openclaw/          # OpenClaw 配置
├── .oh-my-zsh/         # Shell 主题
├── scripts/
│   ├── bootstrap.ps1    # 一键安装脚本
│   ├── link-configs.ps1 # 建立符号链接
│   └── install-apps.ps1 # 安装软件
└── README.md
```

### 符号链接方案

```powershell
# link-configs.ps1
$dotfiles = @{
    "$env:USERPROFILE\.gitconfig" = "$PSScriptRoot\.gitconfig"
    "$env:APPDATA\Code\User\settings.json" = "$PSScriptRoot\.vscode\settings.json"
    "$env:USERPROFILE\.obsidian" = "$PSScriptRoot\.obsidian"
}

foreach ($source in $dotfiles.Keys) {
    $target = $dotfiles[$source]
    if (Test-Path $target) {
        New-Item -ItemType SymbolicLink -Path $source -Target $target -Force
    }
}
```

---

## 五、自动更新检测

### 软件更新检测

```powershell
# check-updates.ps1 - 每周定时执行
Write-Host "=== Scoop Updates ===" -ForegroundColor Cyan
scoop status | ConvertFrom-Json | ForEach-Object {
    if ($_.status -eq "update") {
        Write-Host "[UPDATE] $($_.name) $($_.version) → $($_.latest)"
    }
}

Write-Host "`n=== Winget Updates ===" -ForegroundColor Cyan
winget upgrade --accept-source-agreements | Out-String -Stream |
    Select-String "Upgradable" -Context 0,1
```

### 浏览器扩展更新检测

```powershell
# 检查 Chrome 扩展更新
$extPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions"
Get-ChildItem $extPath -Directory |
    ForEach-Object {
        $ver = (Get-ChildItem $_.FullName -Directory | Sort-Object Name -Descending | Select-Object -First 1).Name
        Write-Host "$($_.Name): v$ver"
    }
```

---

## 六、GitHub 私有库同步

### 推送更新

```powershell
# sync-to-git.ps1
$env:GIT_SSH_COMMAND = "ssh -i ~/.ssh/id_github"
Set-Location "$PSScriptRoot\..\dotfiles"

git add -A
git commit -m "Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git push origin main
```

### 新设备拉取

```powershell
# bootstrap.ps1
git clone git@github.com:wren/dotfiles.git $env:USERPROFILE\dotfiles
Set-Location "$env:USERPROFILE\dotfiles"
.\install-apps.ps1
.\link-configs.ps1
scoop import apps.json
```

---

## 七、多端同步矩阵

| 内容 | 同步工具 | 说明 |
|------|----------|------|
| **软件清单** | Git 私有库 | 版本化，历史可查 |
| **浏览器扩展** | Git 私有库 + 浏览器内置同步 | Chrome账号同步扩展列表 |
| **配置文件** | Git 私有库 + 符号链接 | dotfiles 方案 |
| **Obsidian笔记** | Obsidian Sync / iCloud / Git | 原生支持，天然同步 |
| **OpenClaw配置** | Git 私有库 | openclaw.json + skills |
| **SSH/密码** | 1Password / Bitwarden | 不放 Git，单独同步 |
| **开发环境** | Docker / Dev Containers | 环境即代码 |

---

## 八、实施路线图

### Phase 1：建立清单（1天）
- [ ] 导出当前 Scoop/Winget 软件列表
- [ ] 导出浏览器扩展 ID 列表
- [ ] 收集所有配置文件路径
- [ ] 创建 GitHub 私有仓库

### Phase 2：脚本化（1-2天）
- [ ] `bootstrap.ps1` — 新电脑一键安装
- [ ] `link-configs.ps1` — 符号链接配置
- [ ] `check-updates.ps1` — 更新检测脚本
- [ ] `sync.ps1` — 自动同步脚本

### Phase 3：自动化（持续）
- [ ] Cron 每周运行更新检测
- [ ] Cron 每日自动同步 Git
- [ ] 重大更新自动推送通知

---

## 九、GitHub Actions 自动构建

```yaml
# .github/workflows/check-updates.yml
name: Weekly Update Check
on:
  schedule:
    - cron: '0 2 * * 1'  # 每周一 10:00
  workflow_dispatch:

jobs:
  check:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check Scoop updates
        run: |
          scoop update
          scoop status --json | ConvertFrom-Json |
          Where-Object { $_.status -eq 'update' } |
          ConvertTo-Json | Out-File updates.json
      - name: Notify
        if: always()
        run: |
          $content = Get-Content updates.json -Raw
          if ($content -and $content -ne 'null') {
            Write-Host "::notice::有软件可更新"
          }
```

---

## 十、一句话总结

| 层次 | 工具 |
|------|------|
| **软件** | Scoop + winget，双 JSON 清单 |
| **扩展** | 扩展ID列表 + Chrome账号同步 |
| **配置** | dotfiles + Git + 符号链接 |
| **同步** | Git 私有库 + Obsidian Sync |
| **自动化** | Cron 驱动脚本 + GitHub Actions |

---

*关键原则：所有清单进 Git → 新设备 clone + run → 始终最新版本*
