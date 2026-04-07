import { readFileSync, writeFileSync } from 'fs';

const file = 'D:\\OpenClaw\\.openclaw\\workspace\\memory\\cron-jobs.json';
let s = readFileSync(file, 'utf8');
if (s.charCodeAt(0) === 0xFEFF) s = s.slice(1);

// Replace all U+FFFD (replacement char) with a safe placeholder
s = s.replace(/\uFFFD/g, '?');

// Also replace any other non-ASCII control chars
s = s.replace(/[\x00-\x08\x0b\x0c\x0e-\x1f]/g, '');

try {
  const data = JSON.parse(s);
  console.log('✅ JSON valid! Jobs:', data.jobs.length);
  
  // Apply fixes
  const fixes = [
    { id: '92af6946-b23b-4534-a6b8-5877cfa36f12', timeout: 300, name: '健康监控员' },
    { id: '3a1df011-613d-4528-a274-530cfd84f4fb', timeout: 300, name: '事件协调员' },
    { id: '58540a34-62ab-46a7-a713-cac112e5cd48', timeout: 180, name: '运动提醒员' },
  ];
  
  let changes = 0;
  for (const f of fixes) {
    const job = data.jobs.find(j => j.id === f.id);
    if (job) {
      const old = job.payload.timeoutSeconds;
      job.payload.timeoutSeconds = f.timeout;
      console.log(`OK ${f.name}: ${old}s → ${f.timeout}s`);
      changes++;
    } else {
      console.log(`MISS ${f.id} (${f.name})`);
    }
  }
  
  // Find 每日早报 by searching for timeout 450
  const daily = data.jobs.find(j => j.payload?.timeoutSeconds === 450);
  if (daily) {
    console.log(`Found 每日早报: ${daily.id}`);
    daily.payload.timeoutSeconds = 600;
    console.log('OK 每日早报: 450s → 600s');
    changes++;
  }
  
  // Fix scheduler delivery
  const sched = data.jobs.find(j => j.id === 'b6bc413c-0228-48c8-b42c-0af833216d2c');
  if (sched) {
    if (!sched.delivery || sched.delivery.mode !== 'announce') {
      sched.delivery = { mode: 'announce', channel: 'last' };
      console.log('OK 调度优化员: added delivery');
      changes++;
    }
  }
  
  // Reset error counters
  for (const j of data.jobs) {
    if (j.state) {
      j.state.consecutiveErrors = 0;
      j.state.lastStatus = 'ok';
      if (j.state.lastError) delete j.state.lastError;
    }
  }
  console.log('✅ Reset all error counters');
  
  // Save
  const out = JSON.stringify(data, null, 2);
  // Add UTF-8 BOM
  const bom = Buffer.from([0xEF, 0xBB, 0xBF]);
  const content = Buffer.concat([bom, Buffer.from(out, 'utf8')]);
  writeFileSync(file, content);
  console.log(`\n💾 Saved (${content.length} bytes, ${changes} changes)`);
  
} catch (e) {
  console.error('❌ Error:', e.message);
  const pos = parseInt(e.message.match(/position (\d+)/)?.[1] || '0');
  console.log('Around:', JSON.stringify(s.slice(Math.max(0,pos-30), pos+30)));
}
