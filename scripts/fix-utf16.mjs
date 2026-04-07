import { readFileSync, writeFileSync } from 'fs';

const file = 'D:\\OpenClaw\\.openclaw\\workspace\\memory\\cron-jobs.json';

// Read as UTF-16LE
const buf = readFileSync(file);
console.log('File size:', buf.length, 'bytes');
console.log('First 4 bytes:', buf.slice(0,4).toString('hex'), buf[0] === 0xff && buf[1] === 0xfe ? '(UTF-16LE BOM confirmed)' : '(no BOM)');

// Convert UTF-16LE to UTF-8
const s16 = buf.toString('utf16le');
console.log('As UTF-16LE:', s16.slice(0,80));

try {
  const data = JSON.parse(s16);
  console.log('\n✅ JSON valid! Jobs:', data.jobs.length);
  
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
  
  // Find 每日早报 by timeout 450
  const daily = data.jobs.find(j => j.payload?.timeoutSeconds === 450);
  if (daily) {
    daily.payload.timeoutSeconds = 600;
    console.log('OK 每日早报: 450s → 600s');
    changes++;
  }
  
  // Fix scheduler delivery
  const sched = data.jobs.find(j => j.id === 'b6bc413c-0228-48c8-b42c-0af833216d2c');
  if (sched) {
    sched.delivery = { mode: 'announce', channel: 'last' };
    console.log('OK 调度优化员: added delivery');
    changes++;
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
  
  // Save as UTF-8 with BOM
  const out = JSON.stringify(data, null, 2);
  const utf8Bom = Buffer.concat([Buffer.from([0xEF, 0xBB, 0xBF]), Buffer.from(out, 'utf8')]);
  writeFileSync(file, utf8Bom);
  console.log(`\n💾 Saved (${utf8Bom.length} bytes, ${changes} changes)`);
  
} catch (e) {
  console.error('❌ Error:', e.message);
}
