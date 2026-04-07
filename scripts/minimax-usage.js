// MiniMax Token Plan Usage Query
const https = require('https');

const API_KEY = process.env.MINIMAX_API || 'sk-cp-J4dHoVGNGiYhzz8OJR6pZqwuWQDCXD6EKP04nk0jVJRd0HkVAteV6aNos8UCa8zST8jLrVWwRremkRKQxue5b2lmkQcekajrrr8Uyh2tfn-n84ok_7EdgL4';

// Try different hostnames
const hostnames = ['api.minimaxi.com', 'www.minimaxi.com', 'minimaxi.com'];
let hostname = hostnames[0];

const options = {
  hostname: hostname,
  port: 443,
  path: '/v1/api/openplatform/coding_plan/remains',
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${API_KEY}`,
    'Content-Type': 'application/json'
  }
};

console.log('Querying MiniMax Token Plan usage...');

const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => {
    console.log(`Status: ${res.statusCode}`);
    try {
      const json = JSON.parse(data);
      console.log('\n========== MiniMax Token Plan ==========');
      console.log(JSON.stringify(json, null, 2));
    } catch (e) {
      console.log('Raw response:', data);
    }
  });
});

req.on('error', (e) => {
  console.error('Error:', e.message);
});

req.end();