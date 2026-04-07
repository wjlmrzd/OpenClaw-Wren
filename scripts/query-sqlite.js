// Query main.sqlite for conversations from this morning
const Database = require('better-sqlite3');
const path = 'D:/OpenClaw/.openclaw/memory/main.sqlite';

try {
    const db = new Database(path, { readonly: true, timeout: 5000 });
    
    // List tables
    const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table'").all();
    console.log('Tables:', JSON.stringify(tables, null, 2));
    
    // Check for conversation data
    if (tables.find(t => t.name === 'conversations')) {
        const convs = db.prepare("SELECT id, created_at, updated_at FROM conversations ORDER BY updated_at DESC LIMIT 5").all();
        console.log('Recent conversations:', JSON.stringify(convs, null, 2));
    }
    
    if (tables.find(t => t.name === 'messages')) {
        const msgs = db.prepare("SELECT id, conversation_id, role, created_at FROM messages ORDER BY created_at DESC LIMIT 5").all();
        console.log('Recent messages:', JSON.stringify(msgs, null, 2));
    }
    
    if (tables.find(t => t.name === 'summaries')) {
        const sums = db.prepare("SELECT id, conversation_id, created_at FROM summaries ORDER BY created_at DESC LIMIT 5").all();
        console.log('Recent summaries:', JSON.stringify(sums, null, 2));
    }
    
    db.close();
} catch (e) {
    console.log('Error:', e.message);
}
