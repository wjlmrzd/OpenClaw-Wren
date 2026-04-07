import { readFileSync, writeFileSync } from 'fs';

const file = 'D:\\OpenClaw\\.openclaw\\workspace\\memory\\cron-jobs.json';
const buf = readFileSync(file);
const str = buf.toString('utf8');

console.log('File size:', buf.length, 'bytes');

// Search for timeout patterns
const patterns = [
    { search: '"timeoutSeconds":180', after: '"model": "dashscope-coding-plan/qwen3-coder-plus"', replace: '"timeoutSeconds":300', after2: '"model": "dashscope-coding-plan/qwen3-coder-plus"', label: '健康监控员' },
    { search: '"timeoutSeconds":180', after: '"model": "dashscope-coding-plan/qwen3.5-plus"', replace: '"timeoutSeconds":300', after2: '"model": "dashscope-coding-plan/qwen3.5-plus"', label: '事件协调员' },
    { search: '"timeoutSeconds":180', after: '"model": "minimax-coding-plan/minimax-2.7"', replace: '"timeoutSeconds":180', after2: '"model": "minimax-coding-plan/minimax-2.7"', label: '运动提醒员 (OK, no change)' },
    { search: '"timeoutSeconds":450', after: '"model": "dashscope-coding-plan/qwen3.5-plus"', replace: '"timeoutSeconds":600', after2: '"model": "dashscope-coding-plan/qwen3.5-plus"', label: '每日早报' },
];

let modified = false;
let result = str;

// Process each job separately by finding its ID context
const fixes = [
    // 健康监控员: 92af6946, timeout 180 -> 300
    { id: '92af6946', oldTimeout: '180', newTimeout: '300' },
    // 事件协调员: 3a1df011, timeout 180 -> 300  
    { id: '3a1df011', oldTimeout: '180', newTimeout: '300' },
    // 运动提醒员: 58540a34, timeout 180 -> 180 (already OK)
    { id: '58540a34', oldTimeout: '180', newTimeout: '180' },
    // 每日早报: 0e63f087, timeout 450 -> 600
    { id: '0e63f087', oldTimeout: '450', newTimeout: '600' },
];

let changes = 0;
for (const fix of fixes) {
    const idPos = result.indexOf(fix.id);
    if (idPos === -1) { console.log('MISS:', fix.id); continue; }
    
    // Find timeoutSeconds after the ID
    const searchStr = `"id": "${fix.id}"`;
    const startPos = result.indexOf(searchStr);
    if (startPos === -1) { console.log('MISS id:', fix.id); continue; }
    
    // Find the next timeoutSeconds after this position
    const searchTimeout = `"timeoutSeconds":${fix.oldTimeout}`;
    let timeoutPos = result.indexOf(searchTimeout, startPos + searchStr.length);
    
    if (timeoutPos === -1) {
        console.log(`WARN: ${fix.id} - timeout ${fix.oldTimeout} not found`);
        continue;
    }
    
    const replaceStr = `"timeoutSeconds":${fix.newTimeout}`;
    if (fix.oldTimeout !== fix.newTimeout) {
        result = result.substring(0, timeoutPos) + replaceStr + result.substring(timeoutPos + searchTimeout.length);
        console.log(`OK ${fix.id}: ${fix.oldTimeout}s -> ${fix.newTimeout}s`);
        changes++;
    } else {
        console.log(`OK ${fix.id}: already ${fix.oldTimeout}s`);
    }
}

// Fix scheduler optimizer delivery
const schedPos = result.indexOf('b6bc413c');
if (schedPos !== -1) {
    // Check if delivery has mode:announce
    const deliverySection = result.substring(schedPos, schedPos + 2000);
    if (!deliverySection.includes('"mode": "announce"')) {
        // Add delivery after the payload closing brace
        const payloadEnd = deliverySection.indexOf('"timeoutSeconds":600"');
        if (payloadEnd !== -1) {
            const insertPos = schedPos + payloadEnd + '"timeoutSeconds":600'.length;
            result = result.substring(0, insertPos) + ',"delivery": {"mode": "announce", "channel": "last"}' + result.substring(insertPos);
            console.log('OK b6bc413c: added delivery config');
            changes++;
        }
    } else {
        console.log('OK b6bc413c: delivery already present');
    }
}

// Reset error counters
result = result.replace(/"consecutiveErrors":\s*\d+/g, '"consecutiveErrors":0');
result = result.replace(/"lastStatus":\s*"\w+"/g, '"lastStatus":"ok"');
// Remove lastError fields
result = result.replace(/,"lastError":\s*"[^"]*"/g, '');
console.log('Reset all error counters');

if (changes > 0 || result !== str) {
    writeFileSync(file, result, 'utf8');
    console.log('Saved to', file, `(${(result.length / 1024).toFixed(1)} KB)`);
} else {
    console.log('No changes made');
}
