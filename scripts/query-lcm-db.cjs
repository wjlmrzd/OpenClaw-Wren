// Query LCM database using require with full path
const { DatabaseSync } = require('D:/OpenClaw/.openclaw/workspace/plugins-graph-memory/node_modules/@photostructure/sqlite');

const dbPath = 'C:/Users/Administrator/.openclaw/lcm.db';
console.log('Querying LCM database:', dbPath);

try {
  const db = new DatabaseSync(dbPath);
  
  // List tables
  const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table'").all();
  console.log('\n=== Tables ===');
  console.log(JSON.stringify(tables, null, 2));
  
  // Check conversations table
  try {
    const convs = db.prepare("SELECT * FROM conversations ORDER BY updated_at DESC LIMIT 5").all();
    console.log('\n=== Recent conversations ===');
    console.log(JSON.stringify(convs, null, 2));
  } catch (e) {
    console.log('No conversations table or error:', e.message);
  }
  
  // Check messages table
  try {
    const msgCount = db.prepare("SELECT COUNT(*) as cnt FROM message_parts").all();
    console.log('\n=== Message parts count ===');
    console.log(JSON.stringify(msgCount, null, 2));
  } catch (e) {
    console.log('No message_parts table or error:', e.message);
  }
  
  // Check summaries table
  try {
    const sumCount = db.prepare("SELECT COUNT(*) as cnt FROM summaries").all();
    console.log('\n=== Summaries count ===');
    console.log(JSON.stringify(sumCount, null, 2));
  } catch (e) {
    console.log('No summaries table or error:', e.message);
  }
  
} catch (e) {
  console.log('Error:', e.message);
}