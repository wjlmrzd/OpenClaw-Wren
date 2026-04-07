import { readFileSync } from 'fs';
const s = readFileSync('D:\\OpenClaw\\.openclaw\\workspace\\memory\\cron-jobs.json', 'utf8');

// Check exact format around timeoutSeconds
const formats = s.match(/"timeoutSeconds"[^\d]+\d+/g);
console.log('Formats found:', [...new Set(formats || [])]);

// Find all timeout values with their job IDs
const jobs = [];
const re = /"id":\s*"([^"]+)"[^}]*"timeoutSeconds"[^\d]+(\d+)/g;
let m;
while ((m = re.exec(s)) !== null) {
  jobs.push({ id: m[1], timeout: parseInt(m[2]) });
}
console.log('\nAll jobs with timeouts:', jobs.length);
jobs.forEach(j => console.log(`  ${j.id}: ${j.timeout}s`));

// Find specific problematic ones
const targetIds = [
  '92af6946-b23b-4534-a6b8-5877cfa36f12', // 健康监控员
  '3a1df011-613d-4528-a274-530cfd84f4fb', // 事件协调员
  '58540a34-62ab-46a7-a713-cac112e5cd48', // 运动提醒员
];
console.log('\nTarget jobs:');
targetIds.forEach(id => {
  const j = jobs.find(j => j.id.startsWith(id.slice(0,8)));
  console.log(`  ${id.slice(0,8)}: ${j ? j.timeout + 's' : 'NOT FOUND'}`);
});