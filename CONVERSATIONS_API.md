# 🔗 CONVERSATIONS API INTEGRATION

## 📋 API Details

### Endpoint
```
GET https://chatbot.fuzionest.com/api/conversations
```

### Authentication
```
Headers:
  Authorization: Bearer <access_token>
  Content-Type: application/json
```

The access token is automatically retrieved from Flutter Secure Storage.

## 📁 Files Created/Updated

### 1. API Configuration
**File**: `lib/core/config/api_config.dart`

Updated base URL:
```dart
static const String baseUrl = 'https://chatbot.fuzionest.com/api';
static const String getAllConversationsEndpoint = '$baseUrl/conversations';
```

### 2. Conversation Repository
**File**: `lib/features/chat/data/conversation_repository.dart`

New repository that:
- ✅ Fetches conversations from the API
- ✅ Automatically adds Bearer token from Secure Storage
- ✅ Handles authentication errors (401)
- ✅ Handles network errors
- ✅ Supports multiple response formats

## 🔧 How It Works

### Flow Diagram
```
User Opens App
    ↓
Login Successful
    ↓
Token Saved to Secure Storage
    ↓
Navigate to Chat Screen
    ↓
ConversationRepository.getAllConversations()
    ↓
Read token from Secure Storage
    ↓
GET https://chatbot.fuzionest.com/api/conversations
Headers: Authorization: Bearer <token>
    ↓
Response Received
    ↓
Parse conversations
    ↓
Display in Sidebar
```

### Code Example
```dart
// In your chat state or notifier
final repository = ConversationRepository(dio);

try {
  final conversations = await repository.getAllConversations();
  // conversations is List<Map<String, dynamic>>
  
  // Update state with conversations
  state = state.copyWith(conversations: conversations);
} catch (e) {
  // Handle error
  print('Error fetching conversations: $e');
}
```

## 📊 Response Format Support

The repository supports multiple response formats:

### Format 1: Direct Array
```json
[
  {
    "id": "conv-123",
    "title": "Sales Analysis",
    "created_at": "2024-02-17T10:30:00Z"
  },
  ...
]
```

### Format 2: Wrapped in 'conversations' Key
```json
{
  "conversations": [
    {
      "id": "conv-123",
      "title": "Sales Analysis"
    },
    ...
  ]
}
```

### Format 3: Wrapped in 'data' Key
```json
{
  "data": [
    {
      "id": "conv-123",
      "title": "Sales Analysis"
    },
    ...
  ]
}
```

## 🎯 Next Steps

### Step 1: Provide Mock Data Structure

Please paste your mock data response here so I can update the repository to parse it correctly.

Example:
```json
{
  // Paste your actual API response here
}
```

### Step 2: Update Repository (if needed)

Once you provide the mock data, I'll update the repository to:
- Parse the exact response format
- Map to your conversation model
- Handle all fields correctly

### Step 3: Integrate with Chat State

Update `chat_state.dart` to:
- Use `ConversationRepository`
- Fetch conversations on app start
- Display in sidebar

## 🔐 Authentication

### Token Handling
```dart
// Token is automatically retrieved from Secure Storage
final token = await _storage.read(key: 'auth_token');

// Added to request headers
headers: {
  'Authorization': 'Bearer $token',
}
```

### Error Handling
```dart
// 401 Unauthorized
if (e.response?.statusCode == 401) {
  throw Exception('Unauthorized: Please login again');
}

// Connection timeout
if (e.type == DioExceptionType.connectionTimeout) {
  throw Exception('Connection timeout');
}
```

## 📝 API Endpoints Summary

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/conversations` | GET | Bearer | Get all conversations |
| `/conversations/:id` | GET | Bearer | Get specific conversation |
| `/auth/login` | POST | None | User login |

## ✅ What's Ready

✅ **API Configuration**: Updated to `chatbot.fuzionest.com/api`  
✅ **Repository Created**: `ConversationRepository`  
✅ **Bearer Token**: Automatically added from Secure Storage  
✅ **Error Handling**: 401, timeout, network errors  
✅ **Multiple Formats**: Supports various response structures  

## 🚀 What's Needed

📋 **Mock Data**: Please provide the actual API response structure  
🔧 **Integration**: Connect repository to chat state  
🎨 **UI Update**: Display fetched conversations in sidebar  

## 📖 Usage Example

```dart
import 'package:business_analytics_chat/features/chat/data/conversation_repository.dart';

// Create repository
final repository = ConversationRepository(dio);

// Fetch conversations
try {
  final conversations = await repository.getAllConversations();
  
  print('Fetched ${conversations.length} conversations');
  
  for (var conv in conversations) {
    print('ID: ${conv['id']}');
    print('Title: ${conv['title']}');
  }
} catch (e) {
  print('Error: $e');
}
```

## 🔍 Testing

### Test the API
1. Login to get access token
2. Token saved to Secure Storage
3. Call `getAllConversations()`
4. Check console for response
5. Verify conversations are fetched

### Debug Mode
Add print statements to see:
```dart
print('Token: $token');
print('Endpoint: ${ApiConfig.getAllConversationsEndpoint}');
print('Response: ${response.data}');
```

---

**API Endpoint**: `https://chatbot.fuzionest.com/api/conversations`  
**Authentication**: Bearer token from Secure Storage  
**Status**: ✅ Repository ready, waiting for mock data structure  

**Next**: Please provide the mock data response so I can complete the integration!
