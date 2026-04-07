const os = require('os');
const fs = require('fs');
const path = require('path');
const execSync = require('child_process').execSync;

// Memory
const freeMem = os.freemem();
const totalMem = os.totalmem();
const memUsage = (1 - freeMem / totalMem) * 100;

// Disk - use fs.statSync to check disk (approximation)
// Better: use wmic via exec
try {
  const out = execSync('wmic logicaldisk get DeviceID,FreeSpace,Size /format:csv', { encoding: 'utf8' });
  const lines = out.trim().split('\n').filter(l => l.trim() && !l.includes('Node'));
  const disks = {};
  lines.forEach(line => {
    const parts = line.split(',');
    if (parts.length >= 4) {
      const id = parts[1];
      const free = parseInt(parts[2]) || 0;
      const size = parseInt(parts[3]) || 0;
      if (id && size > 0) {
        disks[id] = {
          freeGB: Math.round(free / 1024 / 1024 / 1024 * 100) / 100,
          totalGB: Math.round(size / 1024 / 1024 / 1024 * 100) / 100,
          usagePercent: Math.round((1 - free / size) * 1000) / 10
        };
      }
    }
  });
  
  const result = {
    memory: {
      freeMB: Math.round(freeMem / 1024 / 1024),
      totalMB: Math.round(totalMem / 1024 / 1024),
      usagePercent: Math.round(memUsage * 10) / 10
    },
    disks
  };
  
  console.log(JSON.stringify(result, null, 2));
} catch (e) {
  console.log(JSON.stringify({ error: e.message }));
}