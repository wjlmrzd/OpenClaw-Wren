const fs = require('fs');
const c = fs.readFileSync('D:/OpenClaw/.openclaw/workspace/cron/jobs.json');
// Strip BOM
const str = c.toString('utf8').replace(/^\uFEFF/, '');
console.log('After BOM removal, first 300 chars:');
console.log(JSON.stringify(str.substring(0, 300)));
console.log('\nLast 300 chars:');
console.log(JSON.stringify(str.substring(str.length - 300)));
try {
    JSON.parse(str);
    console.log('\nJSON Valid!');
} catch(e) {
    console.log('\nError:', e.message);
    // Find position
    const lines = str.substring(0, 5000).split('\n');
    console.log('\nFirst 20 lines (to find issue):');
    lines.slice(0, 20).forEach((l, i) => console.log(i+1 + ': ' + JSON.stringify(l)));
}
