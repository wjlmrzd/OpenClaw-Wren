const fs = require('fs');
const c = fs.readFileSync('D:/OpenClaw/.openclaw/workspace/cron/jobs.json');
const str = c.toString('utf8').replace(/^\uFEFF/, '');
const lines = str.split('\n');

// Find line 357
console.log('Line 357 (the error line):');
console.log(lines[356]);

// Check around line 357 for bad characters
for (let i = 354; i <= 358; i++) {
    const line = lines[i];
    console.log(`\nLine ${i+1}: ${JSON.stringify(line)}`);
    // Check for control characters
    for (let j = 0; j < line.length; j++) {
        const code = line.charCodeAt(j);
        if (code < 32 && code !== 9 && code !== 10 && code !== 13) {
            console.log(`  Bad char at pos ${j}: code=${code}, char=${JSON.stringify(line[j])}`);
        }
    }
}
