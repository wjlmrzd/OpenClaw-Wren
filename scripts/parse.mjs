import { readFileSync, writeFileSync } from 'fs';

const file = 'D:\\OpenClaw\\.openclaw\\workspace\\memory\\cron-jobs.json';
let s = readFileSync(file, 'utf8');

// Remove BOM if present
if (s.charCodeAt(0) === 0xFEFF) s = s.slice(1);

console.log('File length:', s.length, 'chars');
console.log('First 100:', s.slice(0, 100));

try {
  const data = JSON.parse(s);
  console.log('\nJobs count:', data.jobs?.length || 0);
  
  if (!data.jobs) {
    console.error('No jobs array');
    process.exit(1);
  }
  
  // List all jobs with timeouts
  data.jobs.forEach(j => {
    const timeout = j.payload?.timeoutSeconds || 'N/A';
    console.log(`${j.id.slice(0,8)}: ${timeout}s - ${j.name}`);
  });
  
} catch (e) {
  console.error('JSON parse error:', e.message);
  
  // Try to find where the error is
  const pos = e.message.match(/position (\d+)/);
  if (pos) {
    const p = parseInt(pos[1]);
    console.log('Error context:', s.slice(Math.max(0, p-50), p+50));
  }
}