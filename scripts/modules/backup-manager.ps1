# 备份管理模块 - 备份配置、历史记录
# 由 unified-maintenance-console.ps1 调用

$ErrorActionPreference = "Continue"

$ConfigDir = Join-Path $env:USERPROFILE ".openclaw"
$BackupDir = Join-Path $env:USERPROFILE ".openclaw\backups"

function Show-BackupMenu {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗"
    Write-Host "║                    备份管理 v1.0                                ║"
    Write-Host "╠══════════════════════════════════════════════════════════════╣"
    Write-Host "║  1. 立即备份           - 备份当前配置                           ║"
    Write-Host "║  2. 列出备份           - 查看所有备份                          ║"
    Write-Host "║  3. 恢复备份           - 从备份恢复配置                        ║"
    Write-Host "║  4. 删除备份           - 删除指定备份                         ║"
    Write-Host "║  5. 导出备份           - 导出备份到其他位置                     ║"
    Write-Host "║  6. 备份设置           - 配置自动备份                         ║"
    Write-Host "║  0. 返回                                                    ║"
    Write-Host "╚══════════════════════════════════════════════════════════════╝"
    Write-Host ""
}

function New-Backup {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  创建备份" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # 创建备份目录
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupName = Read-Host "请输入备份名称 (留空使用时间戳)"
    if ([string]::IsNullOrWhiteSpace($backupName)) {
        $backupName = "backup_$timestamp"
    }
    
    $backupPath = Join-Path $BackupDir $backupName
    Write-Host ""
    Write-Host "  正在创建备份: $backupName" -ForegroundColor Yellow
    Write-Host ""
    
    # 备份配置文件
    $configFiles = @(
        "config.yaml",
        "secrets.yaml", 
        "agents.yaml",
        "memory\*",
        "skills\*",
        "plugins\*"
    )
    
    $totalSize = 0
    $fileCount = 0
    
    foreach ($pattern in $configFiles) {
        $sourcePath = Join-Path $ConfigDir $pattern
        if (Test-Path $sourcePath) {
            $destPath = $sourcePath -replace [regex]::Escape($ConfigDir), $backupPath
            $destFolder = Split-Path $destPath -Parent
            
            if (-not (Test-Path $destFolder)) {
                New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
            }
            
            Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force -ErrorAction SilentlyContinue
            
            $files = Get-ChildItem $sourcePath -Recurse -File -ErrorAction SilentlyContinue
            foreach ($f in $files) {
                $totalSize += $f.Length
                $fileCount++
            }
        }
    }
    
    # 创建备份信息文件
    $infoPath = Join-Path $backupPath "backup_info.txt"
    @"
Backup Name: $backupName
Created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Files: $fileCount
Size: $([math]::Round($totalSize/1KB, 2)) KB
OpenClaw Version: v0.1.9
"@ | Out-File -FilePath $infoPath -Encoding UTF8
    
    # 压缩备份
    $zipPath = "$backupPath.zip"
    if (Test-Path $backupPath) {
        Compress-Archive -Path $backupPath -DestinationPath $zipPath -Force
        Remove-Item -path $backupPath -Recurse -Force
        Write-Host "  ✅ 备份创建成功!" -ForegroundColor Green
        Write-Host "  位置: $zipPath" -ForegroundColor Cyan
        Write-Host ("  大小: {0:N2} KB" -f ($totalSize/1KB)) -ForegroundColor Gray
    } else {
        Write-Host "  ❌ 备份创建失败" -ForegroundColor Red
    }
    
    Read-Host "按 Enter 继续"
}

function Get-BackupList {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  备份列表" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Path $BackupDir)) {
        Write-Host "  暂无备份" -ForegroundColor Gray
        return
    }
    
    $backups = Get-ChildItem $BackupDir -Filter "*.zip" | Sort-Object LastWriteTime -Descending
    
    if ($backups.Count -eq 0) {
        Write-Host "  暂无备份" -ForegroundColor Gray
        return
    }
    
    $backups | ForEach-Object -Begin { $i = 1 } -Process {
        $sizeStr = "$([math]::Round($_.Length/1KB, 1)) KB"
        $dateStr = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
        Write-Host ("  {0,2}. {1,-35} {2,10}  {3}" -f $i, $_.Name, $sizeStr, $dateStr)
        $i++
    }
    
    Write-Host ""
    Write-Host ("  总计: {0} 个备份" -f $backups.Count) -ForegroundColor Yellow
}

function Restore-Backup {
    Get-BackupList
    Write-Host ""
    $backupName = Read-Host "请输入要恢复的备份名称"
    if ([string]::IsNullOrWhiteSpace($backupName)) {
        Write-Host "  备份名称不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    $zipPath = Join-Path $BackupDir "$backupName.zip"
    if (-not (Test-Path $zipPath)) {
        Write-Host "  备份不存在: $backupName" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    Write-Host ""
    Write-Host "  ⚠️ 警告: 此操作将覆盖当前配置!" -ForegroundColor Red
    $confirm = Read-Host "确定要恢复吗? (输入 YES 确认)"
    
    if ($confirm -ne "YES") {
        Write-Host "  已取消" -ForegroundColor Gray
        Read-Host "按 Enter 继续"
        return
    }
    
    Write-Host ""
    Write-Host "  正在恢复备份..." -ForegroundColor Yellow
    
    # 解压到临时目录
    $tempDir = Join-Path $BackupDir "temp_restore"
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
    
    # 恢复文件
    $tempBackupPath = Join-Path $tempDir $backupName
    if (Test-Path $tempBackupPath) {
        Copy-Item -Path "$tempBackupPath\*" -Destination $ConfigDir -Recurse -Force
        Remove-Item -Path $tempDir -Recurse -Force
        Write-Host "  ✅ 恢复成功!" -ForegroundColor Green
        Write-Host "  请重启 Gateway 使更改生效" -ForegroundColor Cyan
    } else {
        Write-Host "  ❌ 恢复失败" -ForegroundColor Red
    }
    
    Read-Host "按 Enter 继续"
}

function Remove-Backup {
    Get-BackupList
    Write-Host ""
    $backupName = Read-Host "请输入要删除的备份名称"
    if ([string]::IsNullOrWhiteSpace($backupName)) {
        Write-Host "  备份名称不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    $zipPath = Join-Path $BackupDir "$backupName.zip"
    if (-not (Test-Path $zipPath)) {
        Write-Host "  备份不存在: $backupName" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    Remove-Item -Path $zipPath -Force
    Write-Host "  ✅ 已删除: $backupName" -ForegroundColor Green
    
    Read-Host "按 Enter 继续"
}

function Export-Backup {
    Get-BackupList
    Write-Host ""
    $backupName = Read-Host "请输入要导出的备份名称"
    if ([string]::IsNullOrWhiteSpace($backupName)) {
        Write-Host "  备份名称不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    $targetPath = Read-Host "请输入导出目标路径"
    if ([string]::IsNullOrWhiteSpace($targetPath)) {
        Write-Host "  路径不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    $zipPath = Join-Path $BackupDir "$backupName.zip"
    if (-not (Test-Path $zipPath)) {
        Write-Host "  备份不存在: $backupName" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    $destPath = Join-Path $targetPath "$backupName.zip"
    Copy-Item -Path $zipPath -Destination $destPath -Force
    Write-Host "  ✅ 已导出到: $destPath" -ForegroundColor Green
    
    Read-Host "按 Enter 继续"
}

function Set-BackupSettings {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  备份设置" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. 设置自动备份周期 (每日/每周)"
    Write-Host "  2. 设置备份保留数量"
    Write-Host "  3. 启用/禁用自动备份"
    Write-Host ""
    Write-Host "  注: 自动备份功能需要在 crontab 中配置" -ForegroundColor Gray
    Write-Host ""
    Read-Host "按 Enter 继续"
}

function Main {
    do {
        Show-BackupMenu
        $choice = Read-Host "请选择操作 (0-6)"
        
        switch ($choice) {
            "1" { New-Backup }
            "2" { Get-BackupList; Read-Host "按 Enter 继续" }
            "3" { Restore-Backup }
            "4" { Remove-Backup }
            "5" { Export-Backup }
            "6" { Set-BackupSettings }
            "0" { return }
            default { 
                Write-Host "  无效选择" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($choice -ne "0")
}

Main
