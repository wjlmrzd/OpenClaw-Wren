import { readFileSync } from 'fs';
const file = 'D:\\OpenClaw\\.openclaw\\workspace\\memory\\cron-jobs.json';
let s = readFileSync(file, 'utf8');
if (s.charCodeAt(0) === 0xFEFF) s = s.slice(1);
console.log('Length:', s.length);

// Check if it has replacement chars
const hasRepl = s.includes('\uFFFD');
console.log('Has replacement chars:', hasRepl);

// Count lines and check around garbled area
const lines = s.split('\n');
console.log('Lines:', lines.length);

// Find name fields with non-ASCII
for (let i = 0; i < lines.length; i++) {
  const l = lines[i];
  if (l.includes('"name"') && /[^\x00-\x7F]/.test(l)) {
    console.log(`Line ${i+1}:`, l.slice(0, 80));
  }
}

// Try parse
try {
  const data = JSON.parse(s);
  console.log('\n✅ JSON valid! Jobs:', data.jobs.length);
  
  // Show first few jobs
  data.jobs.slice(0,3).forEach(j => {
    console.log(`  ${j.id.slice(0,8)}: timeout=${j.payload?.timeoutSeconds} - ${j.name}`);
  });
  
  // Show timeouts distribution
  const timeouts = {};
  data.jobs.forEach(j => {
    const t = j.payload?.timeoutSeconds || 0;
    timeouts[t] = (timeouts[t] || 0) + 1;
  });
  console.log('\nTimeout distribution:', timeouts);
  
} catch (e) {
  console.error('❌ Parse error:', e.message);
  const pos = parseInt(e.message.match(/position (\d+)/)?.[1] || '0');
  // Find line/col
  let line = 1, col = pos;
  for (let i = 0; i < pos && i < s.length; i++) {
    if (s[i] === '\n') { line++; col = 0; }
    else col++;
  }
  console.log(`Error at line ${line}, col ${col}`);
  console.log('Around:', JSON.stringify(s.slice(Math.max(0,pos-40), pos+40)));
}
