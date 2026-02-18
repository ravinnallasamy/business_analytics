# Authentication Implementation Guide

## Overview
This Flutter application implements a comprehensive JWT-based authentication system with automatic token management and expiration handling.

## Features

### ✅ Implemented Features
1. **Secure Token Storage**: Access tokens are stored in Flutter Secure Storage
2. **Automatic Token Validation**: Tokens are checked for expiration before every API call
3. **Auto-Logout on Expiry**: Users are automatically redirected to login when token expires
4. **401 Error Handling**: All API calls handle unauthorized responses
5. **JWT Decoding**: Client-side token expiration checking
6. **Centralized API Configuration**: All endpoints managed in one place

## Architecture

### Authentication Flow

```
┌─────────────┐
│  App Start  │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│ Check Token Exists? │
└──────┬──────────────┘
       │
       ├─── No ──────► Login Screen
       │
       ▼ Yes
┌─────────────────────┐
│ Is Token Expired?   │
└──────┬──────────────┘
       │
       ├─── Yes ─────► Login Screen
       │
       ▼ No
┌─────────────────────┐
│   Main App (Chat)   │
└─────────────────────┘
```

### API Request Flow

```
┌──────────────┐
│ API Request  │
└──────┬───────┘
       │
       ▼
┌────────────────────────┐
│ AuthInterceptor        │
│ - Read token           │
│ - Check expiration     │
└──────┬─────────────────┘
       │
       ├─── Expired ────► Logout & Redirect to Login
       │
       ▼ Valid
┌────────────────────────┐
│ Add Bearer Token       │
│ to Request Headers     │
└──────┬─────────────────┘
       │
       ▼
┌────────────────────────┐
│ Send Request to API    │
└──────┬─────────────────┘
       │
       ├─── 401 Response ──► Logout & Redirect to Login
       │
       ▼ Success
┌────────────────────────┐
│ Return Response        │
└────────────────────────┘
```

## Configuration

### 1. Update API Base URL

Edit `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  // Update this to your backend URL
  static const String baseUrl = 'https://your-api-server.com';
  
  // Endpoints are automatically configured
  static const String authBaseUrl = '$baseUrl/auth';
  static const String chatBaseUrl = '$baseUrl/chat';
}
```

### 2. Backend API Requirements

Your backend must implement the following endpoints:

#### Login Endpoint
- **URL**: `POST /auth/login`
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "password123"
  }
  ```
- **Success Response** (200):
  ```json
  {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "token_type": "bearer",
    "expires_in": 3600
  }
  ```
- **Error Response** (401):
  ```json
  {
    "error": "Invalid credentials"
  }
  ```

#### Protected Endpoints
All protected endpoints should:
- Accept `Authorization: Bearer <token>` header
- Return `401 Unauthorized` when token is invalid/expired

## Key Components

### 1. AuthService (`lib/features/auth/services/auth_service.dart`)
Handles all authentication operations:
- `login(email, password)` - Authenticate user and get token
- `saveToken(token)` - Store token securely
- `getToken()` - Retrieve stored token
- `deleteToken()` - Remove token (logout)
- `isTokenExpired(token)` - Check if JWT token is expired
- `isAuthenticated()` - Validate current authentication status

### 2. AuthInterceptor (`lib/core/network/auth_interceptor.dart`)
Dio interceptor that:
- Automatically adds Bearer token to all requests
- Checks token expiration before each request
- Triggers logout on 401 responses
- Handles token-related errors

### 3. AuthNotifier (`lib/features/auth/state/auth_notifier.dart`)
Riverpod state manager for authentication:
- Manages `AuthState` (isAuthenticated, isLoading, error)
- Handles login/logout actions
- Checks auth status on app start

### 4. Login Screen (`lib/features/auth/presentation/screens/login_screen.dart`)
User interface for authentication:
- Email and password input
- Form validation
- Loading states
- Error display

## Usage Examples

### Check if User is Authenticated

```dart
final authState = ref.watch(authProvider);
if (authState.isAuthenticated) {
  // User is logged in
} else {
  // User needs to login
}
```

### Login

```dart
await ref.read(authProvider.notifier).login(email, password);
```

### Logout

```dart
await ref.read(authProvider.notifier).logout();
```

### Making Authenticated API Calls

All repositories automatically use `AuthInterceptor`:

```dart
final chatRepository = ref.read(chatRepositoryProvider);
final response = await chatRepository.sendMessage("Hello", null);
// Token is automatically added to request
// If token is expired or 401 received, user is logged out
```

## Security Features

### 1. Secure Storage
- Tokens stored using `flutter_secure_storage`
- Platform-specific encryption (Keychain on iOS, KeyStore on Android)

### 2. Token Expiration
- Client-side JWT expiration checking
- Automatic logout before making requests with expired tokens
- Server-side validation as fallback

### 3. Automatic Cleanup
- Tokens deleted on logout
- Invalid tokens automatically removed

## Testing

### Test Login Flow
1. Run the app
2. Enter any email and password (4+ characters)
3. App will attempt to call your backend `/auth/login`
4. On success, token is stored and user is redirected to chat

### Test Token Expiration
1. Login successfully
2. Wait for token to expire (check JWT `exp` claim)
3. Try to send a chat message
4. App should automatically logout and redirect to login

### Test 401 Handling
1. Login successfully
2. Manually invalidate token on backend
3. Make any API call
4. App should logout and redirect to login

## Troubleshooting

### Issue: "Connection timeout"
- Check that `ApiConfig.baseUrl` points to your backend
- Ensure backend is running and accessible
- Check network connectivity

### Issue: "No token received from server"
- Verify backend returns `access_token` or `token` in response
- Check response structure matches expected format

### Issue: "Token expired" immediately
- Verify JWT token has valid `exp` claim
- Check server and client time synchronization
- Ensure token expiration time is reasonable (e.g., 1 hour+)

### Issue: App doesn't redirect to login on 401
- Verify `AuthInterceptor` is added to all repositories
- Check that repositories use `onUnauthorized` callback
- Ensure `chatRepositoryProvider` connects to `authProvider.notifier.logout()`

## Next Steps

1. **Update API URLs**: Change `ApiConfig.baseUrl` to your backend
2. **Test Login**: Verify login endpoint works with your backend
3. **Add Refresh Token**: Implement token refresh logic (optional)
4. **Add Remember Me**: Store user preferences (optional)
5. **Add Biometric Auth**: Use local_auth package (optional)

## Additional Resources

- [JWT Decoder Package](https://pub.dev/packages/jwt_decoder)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [Dio HTTP Client](https://pub.dev/packages/dio)
- [Riverpod State Management](https://riverpod.dev)
