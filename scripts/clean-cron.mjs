import { readFileSync, writeFileSync } from 'fs';

// Read the restored file
const file = 'D:\\OpenClaw\\.openclaw\\workspace\\memory\\cron-jobs.json';
let s = readFileSync(file, 'utf8');
console.log('Original length:', s.length);

// The file has garbled Chinese + control characters.
// Fix: remove invalid control chars (but keep \r\n\t)
const cleaned = s.replace(/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/g, '');
console.log('Cleaned length:', cleaned.length);

// Validate JSON
try {
  const data = JSON.parse(cleaned);
  console.log('JSON valid! Jobs:', data.jobs.length);
  
  // List all jobs
  data.jobs.forEach(j => {
    console.log(`  ${j.id.slice(0,8)}: timeout=${j.payload?.timeoutSeconds} - ${j.name}`);
  });
  
} catch (e) {
  console.error('Still invalid:', e.message);
  const pos = parseInt(e.message.match(/position (\d+)/)?.[1] || 0);
  console.log('Around error:', JSON.stringify(cleaned.slice(Math.max(0,pos-30), pos+30)));
}
