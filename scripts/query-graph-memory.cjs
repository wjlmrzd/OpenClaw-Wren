// Query graph-memory database
const { DatabaseSync } = require('D:/OpenClaw/.openclaw/workspace/plugins-graph-memory/node_modules/@photostructure/sqlite');

const dbPath = 'D:/OpenClaw/.openclaw/memory/main.sqlite';
console.log('Querying graph-memory database:', dbPath);

try {
  const db = new DatabaseSync(dbPath);
  
  // List tables
  const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table'").all();
  console.log('\n=== Tables ===');
  tables.forEach(t => console.log(' -', t.name));
  
  // Check nodes count
  try {
    const nodes = db.prepare("SELECT COUNT(*) as cnt FROM nodes").all();
    console.log('\n=== Nodes count ===', nodes[0].cnt);
  } catch (e) {
    console.log('No nodes table');
  }
  
  // Check edges count  
  try {
    const edges = db.prepare("SELECT COUNT(*) as cnt FROM edges").all();
    console.log('=== Edges count ===', edges[0].cnt);
  } catch (e) {
    console.log('No edges table');
  }
  
  // Recent nodes
  try {
    const recent = db.prepare("SELECT name, type, created_at FROM nodes ORDER BY created_at DESC LIMIT 10").all();
    console.log('\n=== Recent nodes ===');
    recent.forEach(n => console.log(` - [${n.type}] ${n.name} (${n.created_at})`));
  } catch (e) {
    console.log('Error querying nodes:', e.message);
  }
  
} catch (e) {
  console.log('Error:', e.message);
}