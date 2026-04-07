// Query actual graph-memory database (correct table names)
const { DatabaseSync } = require('D:/OpenClaw/.openclaw/workspace/plugins-graph-memory/node_modules/@photostructure/sqlite');

const dbPath = 'C:/Users/Administrator/.openclaw/graph-memory.db';
console.log('Querying graph-memory database:', dbPath);

try {
  const db = new DatabaseSync(dbPath);
  
  // Check nodes count
  const nodes = db.prepare("SELECT COUNT(*) as cnt FROM gm_nodes").all();
  console.log('\n=== Nodes count ===', nodes[0].cnt);
  
  // Check edges count  
  const edges = db.prepare("SELECT COUNT(*) as cnt FROM gm_edges").all();
  console.log('=== Edges count ===', edges[0].cnt);
  
  // Check messages count
  const msgs = db.prepare("SELECT COUNT(*) as cnt FROM gm_messages").all();
  console.log('=== Messages count ===', msgs[0].cnt);
  
  // Recent nodes
  const recent = db.prepare("SELECT name, type, created_at FROM gm_nodes ORDER BY created_at DESC LIMIT 10").all();
  console.log('\n=== Recent nodes ===');
  recent.forEach(n => console.log(` - [${n.type}] ${n.name} (${n.created_at})`));
  
  // Recent messages
  const recentMsgs = db.prepare("SELECT * FROM gm_messages ORDER BY created_at DESC LIMIT 5").all();
  console.log('\n=== Recent messages ===');
  recentMsgs.forEach(m => console.log(' -', m.content?.substring(0, 100), '(', m.created_at, ')'));
  
} catch (e) {
  console.log('Error:', e.message);
}