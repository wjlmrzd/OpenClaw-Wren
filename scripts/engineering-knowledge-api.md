# 工程知识检索接口

## 快速检索

主会话可以直接调用工程知识检索：

```
用户: "搜索工程知识中关于 CAD 属性块的内容"
   → 我会调用检索接口
   → 返回相关笔记列表
```

## 命令行检索

```powershell
# 基本搜索
.\search-engineering-knowledge.ps1 -Query "属性块"

# 限定分类
.\search-engineering-knowledge.ps1 -Query "AutoCAD" -Category cad

# 显示内容摘要
.\search-engineering-knowledge.ps1 -Query "脚本" -Category automation -ShowContent

# 查看待处理文档
.\search-engineering-knowledge.ps1 -Query "" -Category pending
```

## 分类选项

| 参数 | 分类 |
|------|------|
| all | 全部知识 |
| cad | CAD 与建模 |
| automation | 自动化工具 |
| architecture | 系统架构 |
| process | 工艺流程 |
| atomic | 原子笔记 |
| pending | 待解析文档 |

## OCR 处理

```powershell
# OCR 识别
.\ocr-processor.ps1 -ImagePath "E:\EngineeringDocs\scan.jpg"

# 指定输出
.\ocr-processor.ps1 -ImagePath "E:\EngineeringDocs\scan.jpg" -OutputPath "E:\software\Obsidian\vault\knowledge\工程知识\00-Inbox\ocr_result.md"
```

## 文档监控

```powershell
# 运行文档监控
.\doc-watcher.ps1

# 模拟运行（不实际处理）
.\doc-watcher.ps1 -DryRun

# 指定监控文件夹
.\doc-watcher.ps1 -WatchFolder "E:\CustomFolder"
```

## 自动解析 Cron

- **任务名**: 📄 工程文档解析员
- **频率**: 每天 02:30
- **功能**: 扫描 E:\EngineeringDocs，自动创建待解析任务

---

**版本**: 1.0
**更新**: 2026-03-31
