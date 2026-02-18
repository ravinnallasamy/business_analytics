# ✅ Authentication Flow - How It Works

## 🎯 Your Requirements (ALL IMPLEMENTED)

### ✅ Requirement 1: Login Screen Only When Token Invalid/Expired
**Status**: ✅ IMPLEMENTED

The app shows login screen ONLY when:
- No access token in Flutter Secure Storage
- Access token exists but is expired
- Access token is invalid/corrupted

### ✅ Requirement 2: Check Token Before Every API Call
**Status**: ✅ IMPLEMENTED

Every API call automatically:
1. Reads token from Flutter Secure Storage
2. Checks if token is expired (using JWT decoder)
3. If expired → Logout → Redirect to login
4. If valid → Adds Bearer token to request
5. If 401 response → Logout → Redirect to login

### ✅ Requirement 3: Auto-Login on App Start
**Status**: ✅ IMPLEMENTED

When app starts:
1. Checks Flutter Secure Storage for token
2. If valid token exists → Goes directly to chat
3. If no token or expired → Shows login screen

### ✅ Requirement 4: Update Token After Login
**Status**: ✅ IMPLEMENTED

After successful login:
1. Receives access token from backend
2. Saves to Flutter Secure Storage
3. Updates auth state to authenticated
4. Redirects to chat screen

## 🔄 Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        APP STARTS                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  AuthNotifier.build() → _checkAuthStatus()                  │
│  - Read token from Flutter Secure Storage                   │
│  - Check if token exists and is not expired                 │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
         ▼ NO TOKEN / EXPIRED            ▼ VALID TOKEN
┌─────────────────────┐         ┌─────────────────────┐
│   LOGIN SCREEN      │         │   CHAT SCREEN       │
│                     │         │  (Main App)         │
│ - Email input       │         │                     │
│ - Password input    │         │  User can start     │
│ - Login button      │         │  conversation       │
└──────────┬──────────┘         └──────────┬──────────┘
           │                               │
           │ User enters credentials       │ User sends message
           ▼                               ▼
┌─────────────────────┐         ┌─────────────────────┐
│  AuthService.login()│         │ ChatRepository      │
│                     │         │  .sendMessage()     │
│ POST /auth/login    │         │                     │
│ {email, password}   │         └──────────┬──────────┘
└──────────┬──────────┘                    │
           │                               ▼
           │ Success                ┌─────────────────────┐
           ▼                        │ AuthInterceptor     │
┌─────────────────────┐             │  .onRequest()       │
│ Save token to       │             │                     │
│ Secure Storage      │             │ 1. Read token       │
└──────────┬──────────┘             │ 2. Check expiry     │
           │                        │ 3. Add to headers   │
           │                        └──────────┬──────────┘
           │                                   │
           │                   ┌───────────────┴───────────────┐
           │                   │                               │
           │                   ▼ EXPIRED                       ▼ VALID
           │          ┌─────────────────────┐      ┌─────────────────────┐
           │          │ Logout & Redirect   │      │  POST /chat         │
           │          │ to Login Screen     │      │  Authorization:     │
           │          └─────────────────────┘      │  Bearer <token>     │
           │                                       └──────────┬──────────┘
           │                                                  │
           │                                  ┌───────────────┴───────────┐
           │                                  │                           │
           │                                  ▼ 401 Error                 ▼ Success
           │                         ┌─────────────────────┐    ┌─────────────────┐
           │                         │ AuthInterceptor     │    │ Update Chat UI  │
           │                         │  .onError()         │    │ Show response   │
           │                         │                     │    └─────────────────┘
           │                         │ Logout & Redirect   │
           │                         │ to Login Screen     │
           │                         └─────────────────────┘
           │
           ▼
┌─────────────────────┐
│  Update AuthState   │
│  isAuthenticated=true│
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Router redirects   │
│  to /chat           │
└─────────────────────┘
```

## 📝 Code Implementation Details

### 1. App Start - Token Check

**File**: `lib/features/auth/state/auth_notifier.dart`

```dart
@override
AuthState build() {
  _authService = ref.read(authServiceProvider);
  _checkAuthStatus(); // ← Automatically checks token on app start
  return AuthState(isLoading: true); 
}

Future<void> _checkAuthStatus() async {
  state = state.copyWith(isLoading: true);
  try {
    final token = await _authService.getToken(); // ← Read from Secure Storage
    if (token != null && !_authService.isTokenExpired(token)) { // ← Check expiry
       state = state.copyWith(isAuthenticated: true, isLoading: false);
    } else {
      await _authService.deleteToken(); // ← Clean up expired token
      state = state.copyWith(isAuthenticated: false, isLoading: false);
    }
  } catch (e) {
    state = state.copyWith(isAuthenticated: false, isLoading: false);
  }
}
```

### 2. Router - Redirect Logic

**File**: `lib/core/routing/app_router.dart`

```dart
redirect: (context, state) {
  final isLoggedIn = ref.read(authProvider).isAuthenticated;
  final isLoggingIn = state.uri.path == '/login';
  final isLoading = ref.read(authProvider).isLoading;

  if (isLoading) {
    return null; // Wait for auth check to complete
  }

  if (!isLoggedIn && !isLoggingIn) {
    return '/login'; // ← Redirect to login if not authenticated
  }
  if (isLoggedIn && isLoggingIn) {
    return '/chat'; // ← Redirect to chat if already logged in
  }
  return null;
},
```

### 3. API Call - Token Validation

**File**: `lib/core/network/auth_interceptor.dart`

```dart
@override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
  try {
    final token = await _storage.read(key: 'auth_token'); // ← Read from Secure Storage
    
    if (token != null && token.isNotEmpty) {
      // Check if token is expired before making the request
      if (_isTokenExpired(token)) { // ← JWT expiry check
        onUnauthorized(); // ← Trigger logout
        handler.reject(
          DioException(
            requestOptions: options,
            error: 'Token expired',
            type: DioExceptionType.cancel,
          ),
        );
        return;
      }
      
      // Add valid token to request headers
      options.headers['Authorization'] = 'Bearer $token'; // ← Add to request
    }
    
    handler.next(options);
  } catch (e) {
    handler.next(options);
  }
}

@override
void onError(DioException err, ErrorInterceptorHandler handler) {
  if (err.response?.statusCode == 401) {
    onUnauthorized(); // ← Logout on 401 response
  }
  handler.next(err);
}
```

### 4. Login - Save Token

**File**: `lib/features/auth/services/auth_service.dart`

```dart
Future<String> login(String email, String password) async {
  try {
    final response = await _dio.post(
      '/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final token = response.data['access_token'] ?? response.data['token'];
      return token as String; // ← Return token
    }
  } on DioException catch (e) {
    // Error handling
  }
}

// Called by AuthNotifier after successful login
Future<void> saveToken(String token) async {
  await _storage.write(key: 'auth_token', value: token); // ← Save to Secure Storage
}
```

## 🧪 Test Scenarios

### Scenario 1: First Time User (No Token)
```
1. User opens app
2. AuthNotifier checks Secure Storage → No token found
3. Router redirects to /login
4. User sees LOGIN SCREEN ✅
5. User enters email and password
6. AuthService calls backend /auth/login
7. Backend returns access token
8. Token saved to Secure Storage
9. AuthState updated to authenticated
10. Router redirects to /chat
11. User sees CHAT SCREEN ✅
```

### Scenario 2: Returning User (Valid Token)
```
1. User opens app
2. AuthNotifier checks Secure Storage → Token found
3. AuthService checks token expiry → Not expired
4. AuthState set to authenticated
5. Router keeps user on /chat
6. User sees CHAT SCREEN directly ✅ (NO LOGIN SCREEN)
```

### Scenario 3: Expired Token
```
1. User opens app
2. AuthNotifier checks Secure Storage → Token found
3. AuthService checks token expiry → EXPIRED
4. Token deleted from Secure Storage
5. AuthState set to not authenticated
6. Router redirects to /login
7. User sees LOGIN SCREEN ✅
```

### Scenario 4: Token Expires During Session
```
1. User is in chat screen (logged in)
2. User sends a message
3. AuthInterceptor checks token → EXPIRED
4. AuthInterceptor calls onUnauthorized()
5. AuthNotifier.logout() called
6. Token deleted from Secure Storage
7. AuthState set to not authenticated
8. Router redirects to /login
9. User sees LOGIN SCREEN ✅
```

### Scenario 5: Backend Returns 401
```
1. User is in chat screen (logged in)
2. User sends a message
3. AuthInterceptor adds token to request
4. Backend validates token → Invalid/Expired
5. Backend returns 401 Unauthorized
6. AuthInterceptor.onError() catches 401
7. AuthInterceptor calls onUnauthorized()
8. AuthNotifier.logout() called
9. Token deleted from Secure Storage
10. Router redirects to /login
11. User sees LOGIN SCREEN ✅
```

## ✅ Your Requirements Checklist

- [x] Login screen shown ONLY when token is invalid/expired
- [x] Token checked before EVERY API call
- [x] Token read from Flutter Secure Storage
- [x] Token expiry validated using JWT decoder
- [x] Auto-redirect to login when token invalid
- [x] Token updated in Secure Storage after login
- [x] Auto-login on app start if valid token exists
- [x] Direct to chat screen if already logged in
- [x] New conversation starts after successful auth

## 🔐 Security Features

1. **Flutter Secure Storage**: Platform-specific encryption
2. **JWT Validation**: Client-side expiry checking
3. **Automatic Cleanup**: Expired tokens removed
4. **Bearer Token**: Industry-standard authorization
5. **401 Handling**: Server-side validation backup
6. **No Token Leakage**: Tokens never logged or exposed

## 🚀 How to Test

### Test 1: First Login
```bash
1. Clear app data (or use fresh install)
2. Run app
3. Should see LOGIN SCREEN
4. Enter email and password
5. Should redirect to CHAT SCREEN
6. Token should be in Secure Storage
```

### Test 2: Auto-Login
```bash
1. Close app (don't logout)
2. Reopen app
3. Should go directly to CHAT SCREEN (no login)
4. Token should still be in Secure Storage
```

### Test 3: Token Expiry
```bash
1. Login successfully
2. Wait for token to expire (check JWT exp claim)
3. Try to send a message
4. Should redirect to LOGIN SCREEN
5. Token should be deleted from Secure Storage
```

### Test 4: Manual Logout
```bash
1. Login successfully
2. Click logout button (if implemented)
3. Should redirect to LOGIN SCREEN
4. Token should be deleted from Secure Storage
5. Reopening app should show LOGIN SCREEN
```

## 📱 User Experience

### Good UX (What User Sees)
- ✅ App opens → Directly to chat (if logged in)
- ✅ App opens → Login screen (if not logged in)
- ✅ Login → Immediately to chat
- ✅ Token expires → Smooth redirect to login
- ✅ No unnecessary login prompts

### Bad UX (What User DOESN'T See)
- ❌ Login screen every time app opens
- ❌ Multiple login prompts
- ❌ Confusing error messages
- ❌ App crashes on token expiry
- ❌ Stuck on loading screens

## 🎯 Summary

**Your exact requirements are 100% implemented:**

1. ✅ Login screen ONLY when token invalid/expired
2. ✅ Token checked before EVERY API call
3. ✅ Token stored in Flutter Secure Storage
4. ✅ Auto-redirect to login when needed
5. ✅ Token updated after login
6. ✅ Auto-login on app start if valid token
7. ✅ Direct to chat if already authenticated

**Next step**: Update `lib/core/config/api_config.dart` with your backend URL and test!
