# ✅ Backend Integration - Ready to Test

## 🎯 Backend Configuration Complete

### API Endpoint
```
https://api-chatbot.fuzionest.com/auth/login
```

### Request Format
```json
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

### Response Format (Your Backend)
```json
{
  "status": 1,
  "message": "Login successful",
  "httpCode": 200,
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

## ✅ What Was Updated

### 1. API Base URL
**File**: `lib/core/config/api_config.dart`
```dart
static const String baseUrl = 'https://api-chatbot.fuzionest.com';
```

### 2. Login Response Handling
**File**: `lib/features/auth/services/auth_service.dart`

Updated to handle your exact response format:
- ✅ Checks `status` field (1 = success, 0 = error)
- ✅ Extracts `accessToken` field
- ✅ Shows `message` field for errors
- ✅ Stores token in Flutter Secure Storage

### 3. Token Storage
The `accessToken` from your response is automatically:
- ✅ Saved to Flutter Secure Storage
- ✅ Used for all subsequent API calls
- ✅ Validated for expiration (JWT)
- ✅ Added to headers as `Authorization: Bearer <token>`

## 🚀 How to Test

### Step 1: Run the App
```bash
flutter run -d chrome
```

### Step 2: You Should See
1. **Splash Screen** (brief loading)
2. **Login Screen** (no token exists)

### Step 3: Enter Credentials
- Enter your email
- Enter your password
- Click "Login"

### Step 4: What Happens
```
1. App calls: POST https://api-chatbot.fuzionest.com/auth/login
2. Backend returns:
   {
     "status": 1,
     "message": "Login successful",
     "httpCode": 200,
     "accessToken": "eyJ..."
   }
3. App extracts accessToken
4. Saves to Flutter Secure Storage
5. Updates auth state to authenticated
6. Redirects to chat screen
```

### Step 5: Verify Token Storage
After successful login:
- Token is stored in Secure Storage
- Close and reopen app
- Should go directly to chat (no login screen)
- Token automatically added to all API calls

## 🔐 Token Usage in Other APIs

All your other APIs will automatically get the token:

### API 2: Get Conversations
```dart
// Token automatically added by AuthInterceptor
GET https://api-chatbot.fuzionest.com/chat/conversations
Headers:
  Authorization: Bearer eyJhbGci...
```

### API 3: Get Chat History
```dart
// Token automatically added by AuthInterceptor
GET https://api-chatbot.fuzionest.com/chat/conversations/:id
Headers:
  Authorization: Bearer eyJhbGci...
```

### API 4: Send Question
```dart
// Token automatically added by AuthInterceptor
POST https://api-chatbot.fuzionest.com/chat
Headers:
  Authorization: Bearer eyJhbGci...
Body:
  {
    "question": "What are today's sales?",
    "conversation_id": "conv-123"
  }
```

## 🧪 Test Scenarios

### Test 1: First Login
```
✅ App opens → Splash → Login screen
✅ Enter email and password
✅ Click Login
✅ Should redirect to chat screen
✅ Token saved in Secure Storage
```

### Test 2: Invalid Credentials
```
✅ Enter wrong email/password
✅ Click Login
✅ Should show error message from backend
✅ Stay on login screen
```

### Test 3: Auto-Login
```
✅ Login successfully (Test 1)
✅ Close app
✅ Reopen app
✅ Should go directly to chat (no login)
✅ Token still in Secure Storage
```

### Test 4: Token Expiration
```
✅ Login successfully
✅ Wait for token to expire (check JWT exp)
✅ Try to use app (send message, etc.)
✅ Should auto-logout
✅ Redirect to login screen
```

## 📋 Response Handling

### Success Response (status: 1)
```json
{
  "status": 1,
  "message": "Login successful",
  "httpCode": 200,
  "accessToken": "eyJhbGci..."
}
```
**What happens:**
- ✅ Extract `accessToken`
- ✅ Save to Secure Storage
- ✅ Update auth state
- ✅ Redirect to chat

### Error Response (status: 0)
```json
{
  "status": 0,
  "message": "Invalid email or password",
  "httpCode": 401
}
```
**What happens:**
- ✅ Show error message to user
- ✅ Stay on login screen
- ✅ User can try again

## 🔧 Troubleshooting

### Issue: "Connection timeout"
**Solution:**
- Check internet connection
- Verify backend URL is correct
- Test URL in browser/Postman

### Issue: "No access token received"
**Solution:**
- Verify backend returns `accessToken` field
- Check response structure matches expected format
- Look at console logs for actual response

### Issue: "Invalid email or password"
**Solution:**
- Verify credentials are correct
- Check backend accepts email/password format
- Test login in Postman first

### Issue: Login works but redirects back to login
**Solution:**
- Check if token is being saved
- Verify token is valid JWT
- Check token expiration time

## 📱 Expected User Flow

```
┌─────────────────┐
│   App Opens     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Splash Screen   │
│  (Checking...)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Login Screen   │
│                 │
│  Email: ______  │
│  Pass:  ______  │
│  [Login]        │
└────────┬────────┘
         │
         │ Click Login
         ▼
┌─────────────────┐
│ POST /auth/login│
│ to fuzionest.com│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Response:       │
│ status: 1       │
│ accessToken: ...│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Save Token to   │
│ Secure Storage  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Chat Screen    │
│  (Logged In!)   │
└─────────────────┘
```

## ✅ Summary

**Backend URL**: ✅ Updated to `https://api-chatbot.fuzionest.com`  
**Login Endpoint**: ✅ `/auth/login`  
**Response Format**: ✅ Handles `status`, `message`, `accessToken`  
**Token Storage**: ✅ Saves to Flutter Secure Storage  
**Token Usage**: ✅ Automatically added to all API calls  
**Auto-Login**: ✅ Works if valid token exists  
**Auto-Logout**: ✅ Works when token expires or 401  

**You're ready to test!** 🚀

Just run `flutter run -d chrome` and try logging in with your credentials!
