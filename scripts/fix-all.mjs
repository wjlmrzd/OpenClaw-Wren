import { readFileSync, writeFileSync, readFileSync as read } from 'fs';

const file = 'D:\\OpenClaw\\.openclaw\\workspace\\memory\\cron-jobs.json';

// Try reading as UTF-8 first
let buf = readFileSync(file);
let str = buf.toString('utf8');

console.log('Length as UTF-8:', str.length);
console.log('First 50 chars:', JSON.stringify(str.substring(0, 50)));

// If it looks like replacement chars, try UTF-16 LE
if (str.indexOf('\uFFFD') > 0 && str.indexOf('"jobs"') === -1) {
    console.log('Looks like UTF-16LE - converting...');
    buf = readFileSync(file);
    str = buf.toString('utf16le');
    console.log('Length as UTF16LE:', str.length);
    console.log('First 50 chars:', JSON.stringify(str.substring(0, 50)));
}

if (str.indexOf('"jobs"') === -1) {
    console.error('ERROR: Cannot parse JSON structure');
    process.exit(1);
}

const fixes = [
    // { jobId, oldTimeout, newTimeout }
    { jobId: '92af6946-b23b-4534-a6b8-5877cfa36f12', oldTimeout: 180, newTimeout: 300 },
    { jobId: '3a1df011-613d-4528-a274-530cfd84f4fb', oldTimeout: 180, newTimeout: 300 },
    { jobId: '58540a34-62ab-46a7-a713-cac112e5cd48', oldTimeout: 180, newTimeout: 180 },
    { jobId: '0e63f087-5446-4033-b826-19dafe65673b', oldTimeout: 450, newTimeout: 600 },
];

let changes = 0;
for (const f of fixes) {
    const idIdx = str.indexOf(`"id": "${f.jobId}"`);
    if (idIdx === -1) {
        console.log(`MISS: ${f.jobId}`);
        continue;
    }
    
    // Find the timeoutSeconds after this id
    const from = idIdx + `"id": "${f.jobId}"`.length;
    const searchFor = `"timeoutSeconds":${f.oldTimeout}`;
    const tsIdx = str.indexOf(searchFor, from);
    
    if (tsIdx === -1) {
        // Try alternate format
        const altSearch = `"timeoutSeconds": ${f.oldTimeout}`;
        const tsIdx2 = str.indexOf(altSearch, from);
        if (tsIdx2 === -1) {
            console.log(`WARN: timeout ${f.oldTimeout} for ${f.jobId} not found`);
            continue;
        }
        const replaceWith = `"timeoutSeconds": ${f.newTimeout}`;
        str = str.substring(0, tsIdx2) + replaceWith + str.substring(tsIdx2 + altSearch.length);
    } else {
        const replaceWith = `"timeoutSeconds":${f.newTimeout}`;
        str = str.substring(0, tsIdx) + replaceWith + str.substring(tsIdx + searchFor.length);
    }
    
    console.log(`OK ${f.jobId}: ${f.oldTimeout}s -> ${f.newTimeout}s`);
    changes++;
}

// Fix scheduler optimizer delivery
const schedIdx = str.indexOf('"id": "b6bc413c-0228-48c8-b42c-0af833216d2c"');
if (schedIdx !== -1) {
    const afterSched = str.substring(schedIdx, schedIdx + 3000);
    if (!afterSched.match(/"delivery":\s*\{[^}]*"mode":\s*"announce"/)) {
        // Find the closing } of the payload section
        // After timeoutSeconds":600
        const ts600Idx = str.indexOf('"timeoutSeconds":600', schedIdx);
        if (ts600Idx !== -1) {
            const after = ts600Idx + '"timeoutSeconds":600'.length;
            // Insert delivery before the next "state" or end of payload
            str = str.substring(0, after) + ',"delivery": {"mode": "announce", "channel": "last"}' + str.substring(after);
            console.log('OK scheduler: added delivery');
            changes++;
        }
    }
}

// Reset all error counters
let oldStr = str;
str = str.replace(/"consecutiveErrors":\s*\d+/g, '"consecutiveErrors": 0');
str = str.replace(/"lastStatus":\s*"\w+"/g, '"lastStatus": "ok"');
str = str.replace(/,"lastError":\s*"[^"]*"/g, '');
str = str.replace(/"lastError":\s*"[^"]*",/g, '');
if (str !== oldStr) {
    console.log('OK: Reset all error counters');
    changes++;
}

// Validate it's still valid JSON by trying to parse
try {
    JSON.parse(str);
    console.log('JSON is valid');
} catch (e) {
    console.error('JSON INVALID:', e.message);
    process.exit(1);
}

// Save as UTF-8 (no BOM)
writeFileSync(file, str, 'utf8');
console.log(`\nSaved (UTF-8, ${(str.length/1024).toFixed(1)} KB, $changes changes)`);
