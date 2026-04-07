import { readFileSync } from 'fs';
const raw = readFileSync('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'utf8');
// Remove UTF-8 BOM if present
const content = raw.replace(/^\uFEFF/, '');
const data = JSON.parse(content);
const jobs = data.jobs;
const now = Date.now();
const active = jobs.filter(j => j.enabled !== false);

console.log(`Total: ${jobs.length} | Active: ${active.length}`);

const statusGroups = {};
active.forEach(j => {
  const s = j.state?.lastStatus || 'unknown';
  statusGroups[s] = (statusGroups[s] || 0) + 1;
});
console.log('By status:', JSON.stringify(statusGroups));

const errors = active.filter(j => j.state?.lastStatus === 'error');
console.log(`\nERROR jobs (${errors.length}):`);
errors.forEach(j => {
  const ageMs = now - (j.state?.lastRunAtMs || 0);
  const ageH = Math.round(ageMs / 3600000 * 10) / 10;
  const lastRun = j.state?.lastRunAtMs ? new Date(j.state.lastRunAtMs).toISOString() : 'never';
  console.log(`  ${j.name} | ${lastRun} | age=${ageH}h | id=${j.id}`);
});

const timeouts = active.filter(j => j.state?.lastStatus === 'timeout');
console.log(`\nTIMEOUT jobs (${timeouts.length}):`);
timeouts.forEach(j => {
  const ageMs = now - (j.state?.lastRunAtMs || 0);
  const ageH = Math.round(ageMs / 3600000 * 10) / 10;
  const lastRun = j.state?.lastRunAtMs ? new Date(j.state.lastRunAtMs).toISOString() : 'never';
  console.log(`  ${j.name} | ${lastRun} | age=${ageH}h | id=${j.id}`);
});

const stale = active.filter(j => {
  if (!j.state?.lastRunAtMs) return false;
  return (now - j.state.lastRunAtMs) > 12 * 3600000;
});
console.log(`\nSTALE jobs >12h (${stale.length}):`);
stale.forEach(j => {
  const ageMs = now - (j.state?.lastRunAtMs || 0);
  const ageH = Math.round(ageMs / 3600000 * 10) / 10;
  const lastRun = j.state?.lastRunAtMs ? new Date(j.state.lastRunAtMs).toISOString() : 'never';
  console.log(`  ${j.name} | ${lastRun} | age=${ageH}h | status=${j.state?.lastStatus}`);
});

console.log('\nAll active jobs by schedule:');
active.forEach(j => {
  const expr = j.schedule?.expr || (j.schedule?.everyMs ? j.schedule.everyMs + 'ms' : '?');
  const timeout = j.payload?.timeoutSeconds || '?';
  const status = j.state?.lastStatus || 'unknown';
  const consecutiveErrors = j.state?.consecutiveErrors || 0;
  const duration = j.state?.lastDurationMs || 0;
  console.log(`  [${status}] ${expr} | ${j.name} | t=${timeout}s | dur=${duration}ms | err=${consecutiveErrors} | id=${j.id}`);
});
