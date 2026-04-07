# Wren 软件套装系统方案

## 核心思路

**用 Git 声明所有依赖，用脚本一键安装。**

```
清单文件 (Git)
    ↓ 同步到所有设备
执行脚本 → 安装软件 → 链接配置 → 完成
```

---

## 一、软件管理：Scoop + winget

**Scoop** — 用户级软件，安装路径干净
**Winget** — 系统级软件，厂商包

```
wren-software/
├── apps-scoop.json      # Scoop 清单
├── apps-winget.json     # Winget 清单
├── extensions.json     # 浏览器扩展ID列表
├── dotfiles/            # 配置文件
│   ├── .gitconfig
│   ├── .ssh/config
│   └── vscode-settings.json
└── scripts/
    ├── bootstrap.ps1    # 新设备：一键装完
    ├── sync.ps1         # 同步到Git
    └── check-updates.ps1 # 检查更新
```

---

## 二、安装脚本示例

```powershell
# bootstrap.ps1 - 新电脑跑这一条

# 1. 装 Scoop
iwr -useb get.scoop.sh | iex

# 2. 从 Git 拉清单
git clone git@github.com:wren/wren-software.git

# 3. 批量装 Scoop 软件
scoop install $(Get-Content apps-scoop.json | ConvertFrom-Json | ForEach-Object { $_.name })

# 4. 批量装 Winget 软件
winget import -i apps-winget.json

# 5. 建立符号链接
.\scripts\link-configs.ps1

echo "✅ 安装完成"
```

---

## 三、浏览器扩展管理

```json
// extensions.json
{
  "chrome": [
    "oh Ahlcjajcpmbhpkibnlpecbpjjjj",  // ChatGPT Writer
    "nangchenjbjgdgfadbgadbg",           // uBlock Origin
    "cklcfgcbmjnkgghgcjjjpccljppmlp"    // 某插件
  ]
}
```

> 扩展用 Chrome 账号自动同步，ID 列表放 Git 备份即可

---

## 四、配置同步：dotfiles + 符号链接

```
配置文件（Git仓库）
    ↓ 符号链接
~/.gitconfig, ~/.ssh/config, %APPDATA%/Code/User/settings.json
```

```powershell
# link-configs.ps1
mklink /D $env:USERPROFILE\.obsidian "$repo\.obsidian"
mklink /D $env:APPDATA\Code\User\settings.json "$repo\vscode-settings.json"
```

---

## 五、自动更新 + 同步

| 任务 | 频率 | 动作 |
|------|------|------|
| 检查软件更新 | 每周一 | 推送通知到 Telegram |
| 同步配置到 Git | 每日 | 自动 commit + push |
| 浏览器扩展检查 | 每月 | 更新 extensions.json |

---

## 六、关键优势

1. **新电脑**：clone + run = 5分钟还原全套环境
2. **始终最新**：脚本每次从源安装，不锁定版本
3. **多端同步**：Git 私有库 = 所有设备同步
4. **版本可控**：要锁定版本？清单里写死版本号即可

---

## 七、下一步行动

1. 创建 GitHub 私有仓库 `wren-software`
2. 导出当前 Scoop 列表：`scoop export > apps-scoop.json`
3. 导出浏览器扩展 ID（Chrome 地址栏 `chrome://extensions/`）
4. 写第一个 `bootstrap.ps1`
5. 设定每日 Cron 自动同步

---

*核心原则：Everything as Code，Git 是唯一真相来源*
