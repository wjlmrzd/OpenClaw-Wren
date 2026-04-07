// Query LCM database to understand what's stored
import sqlite from '@photostructure/sqlite';

const dbPath = 'C:/Users/Administrator/.openclaw/lcm.db';
console.log('Querying LCM database:', dbPath);

try {
  const db = sqlite(dbPath);
  
  // List tables
  const tables = db.exec("SELECT name FROM sqlite_master WHERE type='table'");
  console.log('\n=== Tables ===');
  console.log(JSON.stringify(tables, null, 2));
  
  // Check conversations table
  try {
    const convs = db.exec("SELECT * FROM conversations ORDER BY updated_at DESC LIMIT 5");
    console.log('\n=== Recent conversations ===');
    console.log(JSON.stringify(convs, null, 2));
  } catch (e) {
    console.log('No conversations table or error:', e.message);
  }
  
  // Check messages table
  try {
    const msgCount = db.exec("SELECT COUNT(*) as cnt FROM message_parts");
    console.log('\n=== Message count ===');
    console.log(JSON.stringify(msgCount, null, 2));
  } catch (e) {
    console.log('No message_parts table or error:', e.message);
  }
  
  // Check summaries table
  try {
    const sumCount = db.exec("SELECT COUNT(*) as cnt FROM summaries");
    console.log('\n=== Summaries count ===');
    console.log(JSON.stringify(sumCount, null, 2));
  } catch (e) {
    console.log('No summaries table or error:', e.message);
  }
  
} catch (e) {
  console.log('Error:', e.message);
}