# lossless-claw Checkpoint Rollback Enhancement
# Applied: 2026-04-09
# Purpose: Add automatic rollback to CompactionEngine for failed/no-progress compaction

## Changes

### 1. `src/store/summary-store.ts`

**INSERT OR IGNORE → INSERT OR REPLACE in `insertContextItem`**
- Reason: `INSERT OR IGNORE` skips existing rows; `INSERT OR REPLACE` overwrites them.
  Rollback needs to restore original context items that may have been modified
  during a failed compaction.

**New method: `deleteContextItemsForConversation`**
- Reason: Before restoring checkpoint, clear all context_items so re-inserting
  checkpoint items gets exact original ordinals without conflicts.

```diff
- `INSERT OR IGNORE INTO context_items ...`
+ `INSERT OR REPLACE INTO context_items ...`

+ async deleteContextItemsForConversation(conversationId: number): Promise<void> {
+   this.db.prepare(`DELETE FROM context_items WHERE conversation_id = ?`).run(conversationId);
+ }
```

### 2. `src/compaction.ts`

#### 2a. `CompactionCheckpoint` interface — add `summaryMessageLinks`

```diff
  summaryParentLinks: Record<string, string[]>;
+ summaryMessageLinks: Record<string, number[]>;
```

#### 2b. `_writeCheckpoint` — collect `summaryMessageLinks`

Save leaf summary → message associations so rollback can re-link them.

```diff
    checkpoint: CompactionCheckpoint = {
      ...
      summaryParentLinks: {},
+     summaryMessageLinks: {},
    };

-   // Collect parent links for condensed summaries
-   await Promise.all(
-     summaries
-       .filter((s) => s.kind === "condensed")
-       .map(async (s) => {
-         const parentIds = await this.summaryStore.getSummaryParentIds(s.summaryId);
-         if (parentIds.length > 0) {
-           checkpoint.summaryParentLinks[s.summaryId] = parentIds;
-         }
-       }),
-   );
+   // Collect parent links for condensed summaries and message links for leaf summaries
+   await Promise.all(
+     summaries.map(async (s) => {
+       if (s.kind === "condensed") {
+         const parentIds = await this.summaryStore.getSummaryParentIds(s.summaryId);
+         if (parentIds.length > 0) {
+           checkpoint.summaryParentLinks![s.summaryId] = parentIds;
+         }
+       }
+       const messageIds = await this.summaryStore.getSummaryMessages(s.summaryId);
+       if (messageIds.length > 0) {
+         checkpoint.summaryMessageLinks![s.summaryId] = messageIds;
+       }
+     }),
+   );
```

#### 2c. `rollbackCheckpoint` — clear before restore + restore message links

```diff
    const { conversationId, contextItems, summaries } = checkpoint;
    let restoredItems = 0;
    let restoredSummaries = 0;

+   // Clear dirty state before restoring checkpoint
+   await this.summaryStore.deleteContextItemsForConversation(conversationId);
```

```diff
    // Re-link summaries to their parent summaries using stored links
-   for (const [childId, parentIds] of Object.entries(checkpoint.summaryParentLinks)) {
+   for (const [childId, parentIds] of Object.entries(checkpoint.summaryParentLinks ?? {})) {
      ...
    }

+   // Re-link leaf summaries to their source messages
+   for (const [summaryId, messageIds] of Object.entries(checkpoint.summaryMessageLinks ?? {})) {
+     if (messageIds.length > 0) {
+       try {
+         await this.summaryStore.linkSummaryToMessages(summaryId, messageIds);
+       } catch {
+         // Best-effort
+       }
+     }
+   }
```

## Architecture Summary

The `_runPassWithRollback` method already existed and wraps `leafPass`/`condensedPass`
in try/catch with rollback on error. This patch adds:

1. **Clean rollback state**: Clear all context_items before restoring (fixes OR IGNORE skip issue)
2. **Full DAG restoration**: Also save and restore summary → message links (leaf summaries)
3. **`INSERT OR REPLACE`**: Rollback can now overwrite modified context_items

## Checkpoint Location

Checkpoints are written to:
`~/.openclaw/agent-<agentId>/memory/lcm-checkpoints/<compactId>.json`

## Manual Rollback (if needed)

If compaction corrupts agent state:
```typescript
// In a cron job or manual script:
const engine = /* get CompactionEngine instance */;
const checkpointDir = join(homedir(), '.openclaw', 'memory', 'lcm-checkpoints');
const files = readdirSync(checkpointDir).filter(f => f.endsWith('.json'));
const latest = files.sort().at(-1);
const compactId = latest?.replace('.json', '');
if (compactId) {
  const result = await engine.rollbackCheckpoint(compactId);
  console.log(`Restored ${result.restoredItems} items, ${result.restoredSummaries} summaries`);
}
```

## Rollback Trigger Conditions

| Condition | Trigger | Current |
|-----------|---------|---------|
| Compaction throws exception | `_runPassWithRollback` catches → rollback | ✅ |
| No progress (tokens >= before) | Loop breaks but checkpoint cleaned | ⚠️ No rollback (future enhancement) |
| Crash mid-compaction | Checkpoint file remains on disk | ✅ (manual recovery) |
