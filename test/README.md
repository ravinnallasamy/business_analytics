# 🧪 API Integration Tests

## 📋 Overview

This directory contains comprehensive tests for all 4 backend APIs:
1. ✅ Login API
2. ✅ Get All Conversations API
3. ✅ Get Chat History API
4. ✅ Send Question API

## 🚀 Quick Start

### Option 1: Standalone Test (Recommended)

This is the easiest way to test all APIs without Flutter test framework.

#### Step 1: Update Credentials
Edit `test/api_test_standalone.dart` and update:
```dart
const testEmail = 'shankar.nambiar@orientbell.com';
const testPassword = 'YOUR_PASSWORD_HERE';  // ⚠️ UPDATE THIS!
```

#### Step 2: Run the Test
```bash
dart run test/api_test_standalone.dart
```

### Option 2: Flutter Test

```bash
flutter test test/api_integration_test.dart
```

## 📊 What Gets Tested

### Test 1: Login API ✅
- **Endpoint**: `POST /api/auth/login`
- **Tests**: Email/password authentication
- **Success**: Returns access token
- **Output**: Token saved for subsequent tests

### Test 2: Get All Conversations ✅
- **Endpoint**: `GET /api/conversations`
- **Tests**: Bearer token authentication
- **Success**: Returns list of conversations
- **Output**: First conversation ID saved

### Test 3: Send Question (New Conversation) ✅
- **Endpoint**: `POST /api/v2/agent/run`
- **Tests**: Creating new conversation
- **Input**: `conversation_id: null`
- **Success**: Returns new conversation ID
- **Output**: Conversation ID saved

### Test 4: Send Question (Existing Conversation) ✅
- **Endpoint**: `POST /api/v2/agent/run`
- **Tests**: Continuing existing conversation
- **Input**: `conversation_id: <from test 3>`
- **Success**: Returns same conversation ID
- **Output**: Follow-up answer

### Test 5: Get Chat History ✅
- **Endpoint**: `GET /api/conversations/:id/messages`
- **Tests**: Fetching conversation messages
- **Input**: Conversation ID from previous tests
- **Success**: Returns all messages
- **Output**: List of user/assistant messages

## 📝 Sample Output

```
🚀 Starting API Integration Tests

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 1: Login API
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Endpoint: https://api-chatbot.fuzionest.com/api/auth/login
📧 Email: shankar.nambiar@orientbell.com
🔄 Sending request...

✅ Status Code: 200
📦 Response:
   {status: 1, message: Login successful, httpCode: 200, accessToken: eyJhbGci...}

🎉 LOGIN SUCCESSFUL!
🔑 Token: eyJhbGciOiJIUzI1NiIsInR5cCI6Ik...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 2: Get All Conversations API
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Endpoint: https://chatbot.fuzionest.com/api/conversations
🔑 Using Bearer token
🔄 Sending request...

✅ Status Code: 200
📦 Response Type: List
📦 Response:
   [{id: c_abc123, title: Sales Analysis, ...}]

🎉 GET CONVERSATIONS SUCCESSFUL!
📊 Found 5 conversations
💬 First conversation ID: c_abc123

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 3: Send Question API (New Conversation)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Endpoint: https://api-chatbot.fuzionest.com/api/v2/agent/run
🔑 Using Bearer token
❓ Question: "Show me the revenue and sales trends for the past 4 months"
🆕 New Conversation (conversation_id: null)
🔄 Sending request...

✅ Status Code: 200
📦 Response:
   {conversation_id: c_xyz789, message_id: m_123, answer: {...}}

🎉 SEND QUESTION SUCCESSFUL!
💬 Conversation ID: c_xyz789
📝 Message ID: m_123
💡 Summary: Here are the revenue and sales trends...
📊 Response blocks: 3

...
```

## 🔧 Troubleshooting

### Error: 401 Unauthorized
- **Cause**: Invalid credentials or expired token
- **Fix**: Update `testEmail` and `testPassword` in the test file

### Error: 404 Not Found
- **Cause**: Incorrect API endpoint
- **Fix**: Check `ApiConfig` endpoints match the backend

### Error: Connection timeout
- **Cause**: Network issues or backend down
- **Fix**: Check internet connection and backend status

### Error: Invalid response format
- **Cause**: API response structure changed
- **Fix**: Update response parsing logic in repository

## 📁 Files

| File | Purpose |
|------|---------|
| `api_test_standalone.dart` | Standalone test script (recommended) |
| `api_integration_test.dart` | Flutter test framework tests |
| `README.md` | This file |

## 🎯 Expected Results

### All Tests Pass ✅
```
🏁 TEST SUMMARY

✅ Login API: PASSED
✅ Get Conversations API: PASSED
✅ Send Question API: PASSED
✅ Get Chat History API: PASSED

🎉 All tests completed!
```

### Some Tests Fail ❌
- Check error messages in output
- Verify API endpoints are correct
- Ensure backend is running
- Check credentials are valid

## 💡 Tips

1. **Update Password**: Don't forget to update the test password!
2. **Check Output**: Read the detailed output to understand what's happening
3. **Network**: Ensure you have internet connection
4. **Backend**: Verify backend APIs are accessible
5. **Token**: If tests fail after login, check token format

## 🔐 Security Note

⚠️ **Never commit credentials to version control!**

The test files contain placeholder passwords. Always:
- Use environment variables for production
- Keep test credentials separate
- Don't commit real passwords

## 📖 Next Steps

After all tests pass:
1. ✅ APIs are working correctly
2. ✅ Authentication is functional
3. ✅ Ready to integrate with UI
4. ✅ Can proceed with chat implementation

---

**Status**: Ready to test!  
**Run**: `dart run test/api_test_standalone.dart`  
**Update**: Password in test file first!
