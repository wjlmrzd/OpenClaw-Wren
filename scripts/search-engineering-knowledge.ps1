# 工程知识检索接口
# 功能:快速检索工程知识篇章,支持多维度查询

param(
    [Parameter(Mandatory=$true)]
    [string]$Query,
    
    [ValidateSet("all", "cad", "automation", "architecture", "process", "atomic", "pending")]
    [string]$Category = "all",
    
    [int]$MaxResults = 10,
    
    [switch]$ShowContent,
    
    [string]$VaultPath = "E:\software\Obsidian\vault"
)

$ErrorActionPreference = "Continue"

function Write-Log {
    param([string]$Message)
    Write-Host $Message
}

# 知识篇章根目录
$knowledgeRoot = Join-Path $VaultPath "knowledge\工程知识"

# 分类目录映射
$categoryMap = @{
    "cad" = "CAD与建模"
    "automation" = "自动化工具"
    "architecture" = "系统架构"
    "process" = "工艺流程"
    "atomic" = "原子笔记"
    "pending" = "00-Inbox"
}

function Search-Files {
    param(
        [string]$Path,
        [string]$Pattern
    )
    
    $results = @()
    if (-not (Test-Path $Path)) {
        return $results
    }
    
    $files = Get-ChildItem -Path $Path -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($content -match $Pattern) {
            $title = "Untitled"
            if ($content -match "(?s)^---\ntitle:\s*""?([^""\n]+)""?") {
                $title = $Matches[1]
            } elseif ($content -match "(?s)^#\s+(.+)$") {
                $title = $Matches[1]
            }
            
            $results += @{
                title = $title
                file = $file.FullName
                relativePath = $file.FullName.Replace($VaultPath, "")
                size = $file.Length
                modified = $file.LastWriteTime
            }
        }
    }
    
    return $results
}

Write-Log "=== 工程知识检索 ==="
Write-Log "关键词: $Query"
Write-Log "分类: $Category"
Write-Log ""

# 确定搜索路径
$searchPaths = @()
if ($Category -eq "all") {
    $searchPaths = @($knowledgeRoot)
} else {
    $categoryPath = $categoryMap[$Category]
    if ($categoryPath) {
        $searchPaths += Join-Path $knowledgeRoot $categoryPath
    }
}

# 执行搜索
$allResults = @()
$pattern = "(?i)$([regex]::Escape($Query))"

foreach ($path in $searchPaths) {
    $results = Search-Files -Path $path -Pattern $pattern
    $allResults += $results
}

# 排序
$allResults = $allResults | Sort-Object { $_.modified } -Descending | Select-Object -First $MaxResults

Write-Log "找到 $($allResults.Count) 个结果"
Write-Log ""

# 输出结果
if ($allResults.Count -eq 0) {
    Write-Log "未找到相关内容"
    Write-Log ""
    Write-Log "提示:"
    Write-Log "- 尝试不同的关键词"
    Write-Log "- 使用 -Category 指定分类"
    Write-Log "- 查看 00-Inbox 是否有待处理的文档"
} else {
    foreach ($i in 0..($allResults.Count - 1)) {
        $result = $allResults[$i]
        $num = $i + 1
        Write-Log "$num. $($result.title)"
        Write-Log "   $($result.relativePath)"
        Write-Log "   $($result.modified.ToString(""yyyy-MM-dd HH:mm""))"
        
        if ($ShowContent) {
            $content = Get-Content $result.file -Raw -ErrorAction SilentlyContinue
            $snippet = ($content -split "`n" | Select-Object -First 10) -join "`n"
            Write-Log "   ---"
            Write-Log "   $snippet"
            Write-Log "   ---"
        }
        
        Write-Log ""
    }
}

return $allResults
