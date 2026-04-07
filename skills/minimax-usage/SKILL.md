# minimax-usage - MiniMax Coding Plan 使用量查询

通过 MiniMax API 查询当前 Coding Plan 的 token 剩余额度。

## 触发词

- "查询 minimax 用量"
- "minimax token 剩余"
- "MiniMax 用量"
- "minimax usage"

## API 端点

```
GET https://www.minimaxi.com/v1/api/openplatform/coding_plan/remains
Authorization: Bearer <MINIMAX_API>
Content-Type: application/json
```

## 执行方式

直接调用 API，返回 JSON 结果。

```bash
curl --location 'https://www.minimaxi.com/v1/api/openplatform/coding_plan/remains' \
  --header 'Authorization: Bearer <MINIMAX_API>' \
  --header 'Content-Type: application/json'
```

## 工具函数 (可选)

如果需要通过 Node.js 脚本调用：

```javascript
// scripts/minimax-usage.js
const https = require('https');
const { MINIMAX_API } = process.env;

const options = {
  hostname: 'www.minimaxi.com',
  path: '/v1/api/openplatform/coding_plan/remains',
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${MINIMAX_API}`,
    'Content-Type': 'application/json'
  }
};

const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => data += chunk);
  res.on('end', () => console.log(data));
});

req.end();
```

运行：`MINIMAX_API=sk-xxx node scripts/minimax-usage.js`
