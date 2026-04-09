const fs = require('fs');

const curr = fs.readFileSync('D:/OpenClaw/.openclaw/openclaw.json', 'utf8').replace(/^\uFEFF/, '');
const bkp = fs.readFileSync('D:/OpenClaw/.openclaw/memory/config-backups/openclaw-20260408-085000.json', 'utf8').replace(/^\uFEFF/, '');

const cJ = JSON.parse(curr);
const bJ = JSON.parse(bkp);

const currKeys = Object.keys(cJ).sort();
const bkpKeys = Object.keys(bJ).sort();

console.log('New top-level keys:', currKeys.filter(k => !bkpKeys.includes(k)));
console.log('Removed keys:', bkpKeys.filter(k => !currKeys.includes(k)));
console.log('curr meta.lastTouchedAt:', cJ.meta?.lastTouchedAt);
console.log('bkp meta.lastTouchedAt:', bJ.meta?.lastTouchedAt);
console.log('curr size:', curr.length);
console.log('bkp size:', bkp.length);
console.log('Size diff:', curr.length - bkp.length);

// Check env field values
const envDiff = [];
for (const key of Object.keys({...cJ.env, ...bJ.env})) {
    if (cJ.env[key] !== bJ.env[key]) {
        envDiff.push(key);
    }
}
if (envDiff.length) console.log('Env changed:', envDiff.join(', '));

// Check hooks
const currHooks = Object.keys(cJ.hooks?.entries || {});
const bkpHooks = Object.keys(bJ.hooks?.entries || {});
const newHooks = currHooks.filter(k => !bkpHooks.includes(k));
if (newHooks.length) console.log('New hooks:', newHooks.join(', '));
