const https = require('https');

const tests = [
  { name: 'Dashscope', url: 'https://coding.dashscope.aliyuncs.com/v1/chat/completions' },
  { name: 'MiniMax', url: 'https://api.minimaxi.com/anthropic/v1/messages' },
  { name: 'Telegram', url: 'https://api.telegram.org/bot8329757047:AAEas5LRhvSSGBY6t0zsHzyV8nv_8CZyczA/getMe' }
];

for (const test of tests) {
  const start = Date.now();
  const req = https.request(test.url, {
    method: 'POST',
    timeout: 8000,
    headers: { 'Content-Type': 'application/json' }
  }, (res) => {
    console.log(`${test.name}: ${res.statusCode} (${Date.now() - start}ms)`);
  });
  
  req.on('error', (e) => {
    console.log(`${test.name}: FAIL - ${e.message} (${Date.now() - start}ms)`);
  });
  
  req.on('timeout', () => {
    console.log(`${test.name}: TIMEOUT (${Date.now() - start}ms)`);
    req.destroy();
  });
  
  req.write('{}');
  req.end();
}