# plugins-checkpoint-wrapper — 架构分析

> ⚠️ 已废弃：2026-04-09 方案 B 已直接在 lossless-claw 源码实现。

## 原方案回顾（已放弃）

### 方案 A：Plugin Wrapper 包装 lossless-claw
- **状态**：放弃
- **原因**：OpenClaw workspace plugins 先于 global npm packages 加载，wrapper 无法干净地拦截 lossless-claw 的 `compact()` 调用
- **已创建文件**：全部作废
  - `plugins-checkpoint-wrapper/src/checkpoint-store.ts`
  - `plugins-checkpoint-wrapper/src/checkpoint-engine.ts`
  - `plugins-checkpoint-wrapper/index.ts`
  - `scripts/lcm-snapshot.py`

### 方案 B：直接修改 lossless-claw 源码 ✅ 已实现
- **状态**：已完成，commit `7c68cc2` → 新 commit
- **路径**：`plugins-lossless-claw-enhanced/src/compaction.ts`

## 最终实现细节

### 关键发现
1. lossless-claw **已有** checkpoint 基础设施，但**没有自动 rollback**
2. `CompactionEngine` 在每次 `compactFullSweep`/`compactLeaf` 前调用 `_writeCheckpoint()`
3. `CompactionEngine._rollbackCheckpoint()` 方法存在且功能完整
4. 唯一的缺失：pass 调用失败时不会触发 rollback，而是直接抛出异常留下不完整的 DAG 状态

### 实现内容

**新增方法**（`CompactionEngine`）：
```typescript
async _runPassWithRollback<T>(
  compactId: string | null,
  passName: string,
  passFn: () => Promise<T | null>,
): Promise<T | null>
```
- 包装任意 `leafPass` / `condensedPass` 调用
- pass 成功 → 返回结果
- pass 抛出异常 → `rollbackCheckpoint(compactId)` → re-throw
- 4 处调用全部包装：`compactLeaf` × 2，`compactFullSweep` × 2

**工作流程**：
```
compactFullSweep/compactLeaf
  └─ _writeCheckpoint() → compactId
      └─ _runPassWithRollback("leafPass", () => leafPass(...))
          ├─ 成功 → 返回，continue
          └─ 异常 → rollbackCheckpoint(compactId) → re-throw
      └─ _runPassWithRollback("condensedPass", () => condensedPass(...))
          └─ (同上)
  └─ _cleanupCheckpoint(compactId)
```

**Checkpoint 存储**：
- 路径：`~/.openclaw/memory/lcm-checkpoints/{compactId}.json`
- 内容：`CompactionCheckpoint` — `{compactId, conversationId, timestamp, tokensBefore, contextItems[], summaries[]}`

**Rollback 恢复范围**：
- `context_items` 表：删除被 compact 的 range，重新插入旧的 ordinal
- `summaries` 表：重新 `INSERT` 旧 summary 记录
- `summary_parents` 表：重建父子关系
- ⚠️ **不恢复**：messages 表（原始消息不会被删除，只是不再被 context_items 引用）

### 已知限制
1. **LLM summarization 失败时**：会 rollback，但原消息仍在 DB 中，下次 compact 会再次尝试压缩
2. **DB 写入事务中间失败**：rollback 能恢复到上次的 context_items/summaries 状态，但事务边界外的变更（如 event message 写入失败）不会被恢复
3. **OpenClaw 更新后需重新应用**：修改的是 workspace plugin 内的 lossless-claw 副本，openclaw 更新不会覆盖

### 验证方式
```bash
# 查看 checkpoint 文件
Get-ChildItem "$env:USERPROFILE\.openclaw\memory\lcm-checkpoints"

# 测试 rollback（手动触发 compaction 并检查日志）
openclaw cron run <jobId>
# 观察日志中出现：[lcm-compact] leafPass failed with error, rolling back
```
