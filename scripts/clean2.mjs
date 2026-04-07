import { readFileSync, writeFileSync } from 'fs';

const file = 'D:\\OpenClaw\\.openclaw\\workspace\\memory\\cron-jobs.json';
let s = readFileSync(file, 'utf8');
console.log('Original length:', s.length);

// Remove UTF-8 BOM
if (s.charCodeAt(0) === 0xFEFF) {
  s = s.slice(1);
  console.log('Removed BOM');
}

// Remove any zero-width characters
s = s.replace(/[\u200B-\u200F\uFEFF]/g, '');

// Check first 50 chars
console.log('Starts with:', JSON.stringify(s.slice(0,50)));

// Try to find any remaining control characters
const badChars = [];
for (let i = 0; i < Math.min(1000, s.length); i++) {
  const c = s.charCodeAt(i);
  if (c < 0x20 && c !== 0x0D && c !== 0x0A && c !== 0x09) {
    badChars.push({ pos: i, char: c, repr: JSON.stringify(s[i]) });
  }
}
console.log('Bad control chars in first 1000:', badChars.slice(0,5));

// Try JSON.parse
try {
  const data = JSON.parse(s);
  console.log('JSON valid! Jobs:', data.jobs.length);
} catch (e) {
  console.error('Parse error:', e.message);
  const pos = parseInt(e.message.match(/position (\d+)/)?.[1] || '0');
  console.log('Around error pos', pos, ':', JSON.stringify(s.slice(Math.max(0,pos-20), pos+20)));
}
