# Telegram SSRF Protection Fix Patch

**Date**: 2026-03-25
**Issue**: Telegram Bot 发送图片/视频/sticker 时报错 `SSRF protection blocked request to internal address`

## Root Cause

`fetchRemoteMedia()` 调用没有传入 `ssrfPolicy` 参数。DNS 解析 api.telegram.org 时，Clash TUN 模式将其解析到 fake IP（如 127.0.0.1），触发 SSRF 防护拦截。

## Fix Applied

**File**: `C:/Users/Administrator/AppData/Roaming/npm/node_modules/openclaw-cn/dist/telegram/bot/delivery.js`

### Line 275 (sticker download)

```javascript
// BEFORE
const response = await fetchRemoteMedia(fileUrl);

// AFTER
const response = await fetchRemoteMedia(fileUrl, {
  ssrfPolicy: { allowedHostnames: ["api.telegram.org"] }
});
```

### Line 348 (image/video/document download)

```javascript
// BEFORE
const response = await fetchRemoteMedia(fileUrl);

// AFTER
const response = await fetchRemoteMedia(fileUrl, {
  ssrfPolicy: { allowedHostnames: ["api.telegram.org"] }
});
```

## Notes

- This is a direct code fix in node_modules, not a configuration change
- If OpenClaw updates, re-apply this fix to the new version
- Check if `fetchRemoteMedia()` calls elsewhere also need this fix

## Verification

After applying the fix, test sending:
- Image via Telegram
- Video via Telegram
- Sticker via Telegram

All should work without SSRF errors.
