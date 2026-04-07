# batch_edit - 协同多文件编辑

> 一次对话中修改多个相关文件时，保持原子性和一致性。

## 何时使用

- 批量重命名/迁移 API 路径
- 修改同一配置在多个文件中的值
- 一次性更新多个相关的 import/export 语句
- 任何需要"全有或全无"的多文件修改

## Manifest 格式

在对话中提供以下格式的 manifest，工具会自动解析并执行：

````markdown
## batch-edit manifest

### 1. edit: src/config.ts
old: export const API_VERSION = "v1"
new: export const API_VERSION = "v2"

### 2. edit: src/client.ts
old: /api/v1/
new: /api/v2/

### 3. edit: src/types.ts
old: API_VERSION: string = "v1"
new: API_VERSION: string = "v2"

### 4. verify
grep "v1" src/
````

## 执行流程

1. **解析** — 提取所有 edit + verify 步骤
2. **Dry-run** — 先验证所有 oldText 在目标文件中的确存在
3. **执行** — 全部匹配成功才执行，顺序写入
4. **Verify** — 执行 verify 命令（如 grep），失败则回滚
5. **报告** — 返回成功/失败/回滚结果

## 字段说明

| 字段 | 必填 | 说明 |
|------|------|------|
| `edit` | ✅ | 文件路径（绝对或相对于 workspace） |
| `old` | ✅ | 要替换的原文（精确匹配） |
| `new` | ✅ | 替换后的内容 |
| `create` | ❌ | 创建新文件（值为文件内容） |
| `delete` | ❌ | 删除文件（不需要 old/new） |
| `verify` | ❌ | 验证命令（如 `grep "v1" src/`） |
| `dry-run` | ❌ | 设置为 `false` 跳过 dry-run（谨慎使用） |

## 使用示例

**示例 1：API 版本升级**

````markdown
## batch-edit manifest

### 1. edit: config/settings.py
old: VERSION = "2.0"
new: VERSION = "3.0"

### 2. edit: src/main.py
old: from config import settings
     VERSION = settings.VERSION
new: from config import settings
     API_VER = settings.VERSION

### 3. edit: tests/test_api.py
old: assert response["version"] == "2.0"
new: assert response["version"] == "3.0"

### 4. verify
grep -r "\"2.0\"" src/ tests/
````

**示例 2：创建多个相关文件**

````markdown
## batch-edit manifest

### 1. create: src/utils/format.ts
export function formatDate(date: Date): string {
  return date.toISOString().split('T')[0];
}

### 2. create: src/utils/format.test.ts
import { formatDate } from './format';

test('formats date correctly', () => {
  expect(formatDate(new Date('2026-01-01'))).toBe('2026-01-01');
});
````

## 安全规则

1. **不修改 workspace 外部路径** — 路径必须在 `D:\OpenClaw\.openclaw\workspace\` 内
2. **不执行有破坏性的 verify** — 禁止 rm -rf 等危险命令
3. **oldText 必须精确匹配** — 模糊匹配会被拒绝
4. **回滚机制** — verify 失败后自动恢复原文件

## 工具实现

工具内部调用 `scripts/batch_edit_executor.py`，返回结构化结果。

## 限制

- 不支持二进制文件
- 单文件最多 10,000 行
- 单次 batch 最多 20 个 edit 操作
