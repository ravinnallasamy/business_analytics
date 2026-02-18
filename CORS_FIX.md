# CORS Fix for Web Development

Since the Flutter app is running in a browser (`localhost`), it cannot directly access the backend API (`https://chatbot.fuzionest.com`) due to browser security restrictions (CORS).

We have implemented a **Local Proxy Solution** to fix this.

## 🚀 How to Run correctly

1. **Start the Proxy Server** (Keep this terminal open)
   This script forwards requests from localhost to the real API, adding the necessary CORS headers.
   ```bash
   node cors_proxy.js
   ```
   You should see: `✅ CORS Proxy running on http://localhost:8080`

2. **Run Flutter** (In a separate terminal)
   We have updated `lib/core/config/api_config.dart` to automatically use this proxy when `_useLocalProxy = true`.
   ```bash
   flutter run -d chrome
   ```

## ⚙️ Configuration

Check `lib/core/config/api_config.dart`:
```dart
static const bool _useLocalProxy = true; // Set to false for production
```

## 🛠️ Troubleshooting

- **If you see "Connection refused"**: Make sure `node cors_proxy.js` is running.
- **If you deploy to production**: Set `_useLocalProxy = false` in `api_config.dart`.
