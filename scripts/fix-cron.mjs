import { readFileSync, writeFileSync } from 'fs';

const file = 'D:\\OpenClaw\\.openclaw\\workspace\\memory\\cron-list.json';

// Read as UTF-16LE (Windows default for BOM 0xFF 0xFE)
const content = readFileSync(file, 'utf16le');

const data = JSON.parse(content);

const fixes = [
    { id: '92af6946-b23b-4534-a6b8-5877cfa36f12', timeout: 300 },  // 健康监控员 120->300
    { id: '3a1df011-613d-4528-a274-530cfd84f4fb', timeout: 300 },  // 事件协调员 180->300
    { id: '58540a34-62ab-46a7-a713-cac112e5cd48', timeout: 180 },  // 运动提醒员 120->180
    { id: '0e63f087-5446-4033-b826-19dafe65673b', timeout: 600 },  // 每日早报 450->600
];

let changed = 0;
for (const fix of fixes) {
    const job = data.jobs.find(j => j.id === fix.id);
    if (job) {
        const oldTimeout = job.payload.timeoutSeconds;
        job.payload.timeoutSeconds = fix.timeout;
        job.updatedAtMs = Date.now();
        console.log(`✓ ${job.name}: ${oldTimeout}s → ${fix.timeout}s`);
        changed++;
    } else {
        console.log(`✗ Job ${fix.id} not found`);
    }
}

// Fix scheduler optimizer - add delivery
const scheduler = data.jobs.find(j => j.id === 'b6bc413c-0228-48c8-b42c-0af833216d2c');
if (scheduler) {
    scheduler.delivery = { mode: "announce", channel: "last" };
    scheduler.updatedAtMs = Date.now();
    console.log(`✓ ${scheduler.name}: added delivery {mode:announce, channel:last}`);
    changed++;
    if (scheduler.payload.timeoutSeconds < 600) {
        const old = scheduler.payload.timeoutSeconds;
        scheduler.payload.timeoutSeconds = 600;
        console.log(`✓ ${scheduler.name}: timeout ${old}s → 600s`);
    }
}

console.log(`\nTotal: ${changed} changes`);

// Save as UTF-8 (with BOM for PowerShell compatibility)
writeFileSync(file, '\uFEFF' + JSON.stringify(data, null, 2), 'utf8');
console.log('Saved to ' + file);
