[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-Location "D:\OpenClaw\.openclaw\workspace"
git add -A
git commit -m "refactor: 第1次自我完善 - 脚本清理 + 文档完善

- 归档 32 个重复/旧版脚本到 scripts/_archive/
- 保留 41 个最新版本脚本
- 新增 scripts/README.md 脚本目录索引
- 新增 Memory/Atlas/自我进化.md 自检记录
- 脚本从 73 个减少到 41 个 (-44%)"
