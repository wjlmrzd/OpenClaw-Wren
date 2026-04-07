const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('D:/OpenClaw/.openclaw/memory/main.sqlite', sqlite3.OPEN_READONLY);

db.all("SELECT name FROM sqlite_master WHERE type='table'", function(err, tables) {
  if (err) { console.log('Error:', err.message); db.close(); return; }
  console.log('Tables:', JSON.stringify(tables, null, 2));
  
  // Check for conversations table
  if (tables.find(t => t.name === 'conversations')) {
    db.all("SELECT id, title, created_at, updated_at FROM conversations ORDER BY updated_at DESC LIMIT 10", function(err, rows) {
      if (err) { console.log('Error:', err.message); db.close(); return; }
      console.log('\nRecent conversations:');
      rows.forEach(r => console.log(JSON.stringify(r)));
      db.close();
    });
  } else {
    db.close();
  }
});
