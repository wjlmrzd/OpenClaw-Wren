# Obsidian 知识库优化脚本
# 根据用户使用手册标准化笔记结构

$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$vaultPath = "E:\software\Obsidian\vault"
$knowledgePath = "$vaultPath\knowledge"

# 定义笔记分类映射 (旧目录 -> PARA 目录)
$categoryMap = @{
    "知识"     = "02_Areas"  # 知识 -> Areas (长期知识源)
    "系统设计"  = "03_Resources"  # 系统设计 -> Resources (系统架构和规范)
    "项目"     = "01_Projects"  # 项目 -> Projects (实时性最高)
    "健康"     = "02_Areas/健康"  # 健康 -> Areas
    "运动"     = "02_Areas/运动"  # 运动 -> Areas
    "工具"     = "03_Resources/工具"  # 工具 -> Resources
    "问题"     = "03_Resources/问题"  # 问题 -> Resources
}

# 定义标签映射 (用于自动生成 YAML)
$tagMap = @{
    "知识"     = @("知识管理", "AI", "OpenClaw")
    "系统设计"  = @("系统设计", "架构", "OpenClaw")
    "项目"     = @("项目", "跑步")
    "健康"     = @("健康", "跑步")
    "运动"     = @("运动", "跑步", "训练")
    "工具"     = @("工具", "配置")
    "问题"     = @("问题", "故障排除")
}

# 创建子目录
$subDirs = @("02_Areas/健康", "02_Areas/运动", "03_Resources/工具", "03_Resources/问题")
foreach ($dir in $subDirs) {
    $fullPath = Join-Path $vaultPath $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "[创建] $dir"
    }
}

# 处理每篇笔记
$processed = 0
$skipped = 0

Get-ChildItem $knowledgePath -Recurse -Filter "*.md" | ForEach-Object {
    $notePath = $_.FullName
    $noteDir = Split-Path $_.DirectoryName -Leaf
    $noteName = $_.Name
    
    # 确定目标目录
    $targetSubDir = $categoryMap[$noteDir]
    if ($targetSubDir) {
        $targetDir = Join-Path $vaultPath $targetSubDir
        $targetPath = Join-Path $targetDir $noteName
        
        # 读取笔记内容
        $content = Get-Content $notePath -Raw -Encoding UTF8
        
        # 检查是否已有标准 YAML
        if ($content -match "^---\s*\ntype:") {
            Write-Host "[跳过] $noteName (已有标准 YAML)"
            $script:skipped++
        } else {
            # 生成 YAML Frontmatter
            $tags = $tagMap[$noteDir]
            if ($null -eq $tags) { $tags = @("笔记") }
            
            # 尝试从现有 YAML 中提取信息
            $created = "2026-03-25"
            $existingCreated = [regex]::Match($content, "创建时间[:：]\s*(\d{4}-\d{2}-\d{2})")
            if ($existingCreated.Success) {
                $created = $existingCreated.Groups[1].Value
            }
            
            $yaml = @"
---
type: concept
status: active
tags: [$($tags -join ', ')]
created: $created
source: ""
project: ""
latest_sync: $(Get-Date -Format "yyyy-MM-dd")
---
"@
            
            # 移除旧的简单 YAML (如果有)
            if ($content -match "^---\s*\n[\s\S]*?\n---\s*\n") {
                $content = $content -replace "^---\s*\n[\s\S]*?\n---\s*\n", ""
            }
            
            # 移除旧的创建时间标记
            $content = $content -replace "\*\*创建时间\*\*:\s*\d{4}-\d{2}-\d{2}\s*", ""
            $content = $content -replace "\*\*最后更新\*\*:\s*\d{4}-\d{2}-\d{2}\s*", ""
            $content = $content -replace "\*\*标签\*\*:\s*#[^\n]+\s*", ""
            
            # 合并新内容
            $newContent = $yaml + "`n" + $content.TrimStart()
            
            # 写入新位置
            $newContent | Set-Content -Path $targetPath -Encoding UTF8
            
            Write-Host "[处理] $noteName -> $targetSubDir"
            $script:processed++
        }
    }
}

Write-Host "`n完成: $processed 篇笔记已处理, $skipped 篇已跳过"
