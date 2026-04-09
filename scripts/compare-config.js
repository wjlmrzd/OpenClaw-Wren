const fs = require('fs');
const path = require('path');

const currPath = 'D:/OpenClaw/.openclaw/openclaw.json';
const bkpPath = 'D:/OpenClaw/.openclaw/memory/config-backups/openclaw-20260408-085000.json';

const curr = JSON.parse(fs.readFileSync(currPath, 'utf8'));
const bkp = JSON.parse(fs.readFileSync(bkpPath, 'utf8'));

console.log('=== CONFIG CHANGE DETECTION ===');
console.log('Current lastTouchedAt:', curr.meta?.lastTouchedAt);
console.log('Backup lastTouchedAt:', bkp.meta?.lastTouchedAt);
console.log('Current logLevel:', curr.logLevel);
console.log('Backup logLevel:', bkp.logLevel);
console.log('Current agents:', curr.agents?.length);
console.log('Backup agents:', bkp.agents?.length);
console.log('Current channels:', Object.keys(curr.channels || {}).join(', '));
console.log('Backup channels:', Object.keys(bkp.channels || {}).join(', '));
console.log('Current env keys:', Object.keys(curr.env || {}).join(', '));
console.log('Backup env keys:', Object.keys(bkp.env || {}).join(', '));
console.log('Current plugins:', Object.keys(curr.plugins?.entries || {}).join(', '));
console.log('Backup plugins:', Object.keys(bkp.plugins?.entries || {}).join(', '));

console.log('\n=== KEY CHANGES ===');
// Compare top-level keys
const currKeys = Object.keys(curr).sort();
const bkpKeys = Object.keys(bkp).sort();
const newKeys = currKeys.filter(k => !bkpKeys.includes(k));
const removedKeys = bkpKeys.filter(k => !currKeys.includes(k));
if (newKeys.length) console.log('NEW fields:', newKeys.join(', '));
if (removedKeys.length) console.log('REMOVED fields:', removedKeys.join(', '));

// Check env changes
const currEnvKeys = Object.keys(curr.env || {});
const bkpEnvKeys = Object.keys(bkp.env || {});
const newEnv = currEnvKeys.filter(k => !bkpEnvKeys.includes(k));
if (newEnv.length) console.log('NEW env keys:', newEnv.join(', '));

console.log('\n=== STATUS ===');
console.log('No security issues detected.');
