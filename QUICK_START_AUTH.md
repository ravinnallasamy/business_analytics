# Quick Start Guide - Authentication Setup

## ✅ What's Been Implemented

Your Flutter app now has a **complete authentication system** with:

1. **JWT Token Management**
   - Tokens stored securely in Flutter Secure Storage
   - Automatic expiration checking before every API call
   - Client-side JWT decoding and validation

2. **Auto-Logout on Token Expiry**
   - Expired tokens detected before making requests
   - 401 responses automatically trigger logout
   - Users redirected to login screen

3. **Login Screen**
   - Email and password authentication
   - Form validation
   - Error handling and display
   - Loading states

4. **Protected API Calls**
   - All API requests automatically include Bearer token
   - AuthInterceptor added to all repositories
   - Centralized error handling

## 🚀 How to Use

### Step 1: Update Your Backend URL

Open `lib/core/config/api_config.dart` and update:

```dart
class ApiConfig {
  // Change this to your actual backend URL
  static const String baseUrl = 'http://127.0.0.1:8000';  // ← Update this!
}
```

### Step 2: Ensure Your Backend Has These Endpoints

#### Login Endpoint
```
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}

Response (200 OK):
{
  "access_token": "eyJhbGci...",  // JWT token
  "token_type": "bearer"
}
```

#### Chat Endpoint (Protected)
```
POST /chat
Authorization: Bearer eyJhbGci...
Content-Type: application/json

{
  "question": "What are the sales?",
  "conversation_id": null,
  "enable_cache": true
}
```

All protected endpoints should:
- Accept `Authorization: Bearer <token>` header
- Return `401 Unauthorized` when token is invalid/expired

### Step 3: Run the App

```bash
flutter run -d chrome
# or
flutter run -d windows
```

### Step 4: Test the Flow

1. **App starts** → Checks for valid token
2. **No token or expired** → Shows login screen
3. **User logs in** → Token saved, redirected to chat
4. **User sends message** → Token automatically added to request
5. **Token expires** → Auto-logout, back to login

## 🔒 Security Features

### Automatic Token Validation
Every API call goes through this flow:

```
Request → Check Token Exists → Check Expiration → Add to Headers → Send
                ↓                      ↓
           No Token            Token Expired
                ↓                      ↓
           Logout & Redirect to Login
```

### 401 Error Handling
If the backend returns 401:
1. AuthInterceptor catches it
2. Triggers logout
3. Clears stored token
4. Redirects to login screen

## 📝 Code Examples

### Check Authentication Status
```dart
final authState = ref.watch(authProvider);

if (authState.isAuthenticated) {
  print('User is logged in');
} else {
  print('User needs to login');
}
```

### Manual Login
```dart
try {
  await ref.read(authProvider.notifier).login(
    'user@example.com',
    'password123'
  );
  // Success - user is now authenticated
} catch (e) {
  print('Login failed: $e');
}
```

### Manual Logout
```dart
await ref.read(authProvider.notifier).logout();
// Token cleared, user redirected to login
```

### Making Authenticated API Calls
```dart
// ChatRepository automatically uses AuthInterceptor
final response = await chatRepository.sendMessage(
  "What are today's sales?",
  conversationId
);
// Token is automatically:
// 1. Checked for expiration
// 2. Added to request headers
// 3. Validated by backend
```

## 🔧 Configuration Files

### API Endpoints
`lib/core/config/api_config.dart` - Centralized API configuration

### Authentication Service
`lib/features/auth/services/auth_service.dart` - Login, token management

### Auth Interceptor
`lib/core/network/auth_interceptor.dart` - Automatic token handling

### Auth State
`lib/features/auth/state/auth_notifier.dart` - Authentication state management

### Login UI
`lib/features/auth/presentation/screens/login_screen.dart` - Login screen

## 🐛 Troubleshooting

### "Connection timeout"
- Check `ApiConfig.baseUrl` is correct
- Ensure backend is running
- Test backend URL in browser/Postman

### "No token received from server"
- Backend must return `access_token` or `token` field
- Check response structure matches expected format

### "Token expired" immediately
- Verify JWT has valid `exp` claim
- Check server/client time sync
- Ensure token expiration is reasonable (e.g., 1+ hour)

### App doesn't logout on 401
- Verify all repositories use `AuthInterceptor`
- Check `onUnauthorized` callback is connected
- Ensure `chatRepositoryProvider` calls `authProvider.notifier.logout()`

## 📚 Additional Documentation

See `AUTHENTICATION.md` for:
- Detailed architecture diagrams
- Complete API specifications
- Advanced configuration options
- Security best practices

## ✨ What Happens Automatically

✅ Token added to every API request  
✅ Token expiration checked before requests  
✅ Auto-logout when token expires  
✅ Auto-logout on 401 responses  
✅ Secure token storage  
✅ Navigation to login when needed  
✅ Error messages displayed to user  

## 🎯 Next Steps

1. Update `ApiConfig.baseUrl` to your backend
2. Test login with your credentials
3. Verify token is stored (check Flutter Secure Storage)
4. Test API calls work with token
5. Test auto-logout by waiting for token expiry

Your authentication system is ready to use! 🚀
