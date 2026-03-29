const fs = require('fs');
const c = fs.readFileSync('D:/OpenClaw/.openclaw/workspace/cron/jobs.json');
const str = c.toString('utf8').replace(/^\uFEFF/, '');
const lines = str.split('\n');

const problemLine = lines[356]; // Line 357 (0-indexed)
console.log('Problem line (raw):');
console.log(problemLine);
console.log('\nProblem line (char codes):');
for (let i = 0; i < problemLine.length; i++) {
    const code = problemLine.charCodeAt(i);
    if (code > 127 || code < 32) {
        console.log(`  pos ${i}: code=${code} (0x${code.toString(16)}) char='${problemLine[i]}'`);
    }
}

// Check the next few lines too
console.log('\nLines 357-360:');
for (let i = 356; i <= 359; i++) {
    console.log(`${i+1}: ${JSON.stringify(lines[i])}`);
}
