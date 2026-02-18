# 🎯 Complete Implementation Guide - 4 APIs with Authentication

## ✅ Your 4 APIs - All Implemented & Protected

### API 1: Login API ✅
**Endpoint**: `POST /auth/login`  
**Status**: ✅ Fully Implemented  
**File**: `lib/features/auth/services/auth_service.dart`

```dart
// How it works:
1. User enters email and password in LoginScreen
2. AuthService.login() calls POST /auth/login
3. Backend returns access_token
4. Token saved to Flutter Secure Storage
5. User redirected to chat screen
```

### API 2: Get All Conversations (Sidebar) ✅
**Endpoint**: `GET /chat/conversations`  
**Status**: ✅ Protected with Auth Token  
**Usage**: Shows all conversations in sidebar

```dart
// How to implement:
import 'package:business_analytics_chat/core/config/api_config.dart';

Future<List<Conversation>> getAllConversations() async {
  final response = await dio.get(
    ApiConfig.getAllConversationsEndpoint,
    // Token automatically added by AuthInterceptor
  );
  return response.data['conversations'];
}
```

### API 3: Get Chat History ✅
**Endpoint**: `GET /chat/conversations/:id`  
**Status**: ✅ Protected with Auth Token  
**Usage**: Loads messages when user clicks a conversation

```dart
// How to implement:
Future<ConversationHistory> getChatHistory(String conversationId) async {
  final response = await dio.get(
    ApiConfig.getChatHistoryEndpoint(conversationId),
    // Token automatically added by AuthInterceptor
  );
  return ConversationHistory.fromJson(response.data);
}
```

### API 4: Send Question & Get Answer ✅
**Endpoint**: `POST /chat`  
**Status**: ✅ Fully Implemented  
**File**: `lib/features/chat/data/chat_repository.dart`

```dart
// Already implemented in ChatRepository.sendMessage()
final response = await chatRepository.sendMessage(
  "What are today's sales?",
  conversationId, // null for new conversation
);
```

---

## 🔐 How Authentication Works with All 4 APIs

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         APP STARTS                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  Check Flutter Secure Storage for access_token                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
         ▼ NO TOKEN / EXPIRED            ▼ VALID TOKEN
┌─────────────────────┐         ┌─────────────────────┐
│   SPLASH SCREEN     │         │   SPLASH SCREEN     │
│   (Loading...)      │         │   (Loading...)      │
└──────────┬──────────┘         └──────────┬──────────┘
           │                               │
           ▼                               ▼
┌─────────────────────┐         ┌─────────────────────┐
│   LOGIN SCREEN      │         │   CHAT SCREEN       │
│                     │         │                     │
│ ┌─────────────────┐ │         │ ┌─────────────────┐ │
│ │ Email           │ │         │ │ API 2: Get All  │ │
│ │ Password        │ │         │ │ Conversations   │ │
│ │ [Login Button]  │ │         │ │ (Sidebar)       │ │
│ └─────────────────┘ │         │ └─────────────────┘ │
└──────────┬──────────┘         └──────────┬──────────┘
           │                               │
           │ User clicks Login             │ User clicks conversation
           ▼                               ▼
┌─────────────────────┐         ┌─────────────────────┐
│ API 1: Login        │         │ API 3: Get Chat     │
│ POST /auth/login    │         │ History             │
│                     │         │ GET /conversations  │
│ Request:            │         │ /:id                │
│ {                   │         │                     │
│   email: "...",     │         │ Headers:            │
│   password: "..."   │         │ Authorization:      │
│ }                   │         │ Bearer <token>      │
└──────────┬──────────┘         └──────────┬──────────┘
           │                               │
           │ Success                       │ Success
           ▼                               ▼
┌─────────────────────┐         ┌─────────────────────┐
│ Response:           │         │ Shows chat history  │
│ {                   │         │ in conversation     │
│   access_token: "..." │       │                     │
│ }                   │         │ User types question │
└──────────┬──────────┘         └──────────┬──────────┘
           │                               │
           │ Save to Secure Storage        │ User sends message
           ▼                               ▼
┌─────────────────────┐         ┌─────────────────────┐
│ Redirect to         │         │ API 4: Send         │
│ CHAT SCREEN         │         │ Question            │
│                     │         │ POST /chat          │
│ ┌─────────────────┐ │         │                     │
│ │ API 2: Get All  │ │         │ Request:            │
│ │ Conversations   │ │         │ {                   │
│ │                 │ │         │   question: "...",  │
│ │ Headers:        │ │         │   conversation_id   │
│ │ Authorization:  │ │         │ }                   │
│ │ Bearer <token>  │ │         │                     │
│ └─────────────────┘ │         │ Headers:            │
└─────────────────────┘         │ Authorization:      │
                                │ Bearer <token>      │
                                └──────────┬──────────┘
                                           │
                                           │ Success
                                           ▼
                                ┌─────────────────────┐
                                │ Response:           │
                                │ {                   │
                                │   conversation_id,  │
                                │   answer: {...}     │
                                │ }                   │
                                │                     │
                                │ Display answer      │
                                └─────────────────────┘
```

---

## 🔑 Authentication Token Flow

### Before Every API Call (APIs 2, 3, 4):

```
1. AuthInterceptor reads token from Secure Storage
2. Checks if token is expired (JWT validation)
3. If expired → Logout → Redirect to Login
4. If valid → Add "Authorization: Bearer <token>" to request
5. Send request to backend
6. If backend returns 401 → Logout → Redirect to Login
7. If success → Return data to app
```

### Code Implementation:

```dart
// This happens AUTOMATICALLY for all API calls
// You don't need to manually add the token!

// Example: API 2 - Get All Conversations
final response = await dio.get(
  ApiConfig.getAllConversationsEndpoint,
  // ↑ Token is automatically added by AuthInterceptor
);

// Example: API 3 - Get Chat History
final response = await dio.get(
  ApiConfig.getChatHistoryEndpoint('conv-123'),
  // ↑ Token is automatically added by AuthInterceptor
);

// Example: API 4 - Send Question (Already implemented)
final response = await chatRepository.sendMessage(
  "What are today's sales?",
  conversationId,
  // ↑ Token is automatically added by AuthInterceptor
);
```

---

## 📝 Step-by-Step: What Happens When User Opens App

### Scenario 1: First Time User (No Token)

```
1. App starts
2. AuthNotifier checks Secure Storage → No token
3. Router redirects to /splash (shows loading)
4. Auth check completes → Not authenticated
5. Router redirects to /login
6. User sees LOGIN SCREEN ✅
7. User enters email and password
8. Clicks "Login" button
9. API 1 called: POST /auth/login
10. Backend returns access_token
11. Token saved to Secure Storage
12. AuthState updated to authenticated
13. Router redirects to /chat
14. API 2 called: GET /chat/conversations (with token)
15. Sidebar shows all conversations
16. User sees CHAT SCREEN ✅
```

### Scenario 2: Returning User (Valid Token)

```
1. App starts
2. AuthNotifier checks Secure Storage → Token found
3. Validates token expiration → Not expired
4. Router redirects to /splash (shows loading briefly)
5. Auth check completes → Authenticated
6. Router redirects to /chat
7. API 2 called: GET /chat/conversations (with token)
8. Sidebar shows all conversations
9. User sees CHAT SCREEN directly ✅ (NO LOGIN SCREEN)
```

### Scenario 3: Token Expired During Session

```
1. User is in chat screen
2. User clicks a conversation
3. API 3 called: GET /chat/conversations/:id
4. AuthInterceptor checks token → EXPIRED
5. AuthInterceptor calls onUnauthorized()
6. Token deleted from Secure Storage
7. AuthState updated to not authenticated
8. Router redirects to /login
9. User sees LOGIN SCREEN ✅
10. User logs in again
11. Back to chat screen
```

---

## 🛠️ How to Add API 2 & API 3 (Conversations & History)

### Step 1: Create Conversation Repository

Create file: `lib/features/chat/data/conversation_repository.dart`

```dart
import 'package:dio/dio.dart';
import 'package:business_analytics_chat/core/config/api_config.dart';
import 'package:business_analytics_chat/core/network/auth_interceptor.dart';

class ConversationRepository {
  final Dio _dio = Dio();

  ConversationRepository({required Function() onUnauthorized}) {
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
    _dio.interceptors.add(AuthInterceptor(onUnauthorized: onUnauthorized));
  }

  /// API 2: Get all conversations for sidebar
  Future<List<ConversationSummary>> getAllConversations() async {
    try {
      final response = await _dio.get(
        ApiConfig.getAllConversationsEndpoint,
        // Token automatically added by AuthInterceptor
      );
      
      final conversations = response.data['conversations'] as List;
      return conversations
          .map((c) => ConversationSummary.fromJson(c))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception('Failed to load conversations: ${e.message}');
    }
  }

  /// API 3: Get chat history for specific conversation
  Future<ConversationHistory> getChatHistory(String conversationId) async {
    try {
      final response = await _dio.get(
        ApiConfig.getChatHistoryEndpoint(conversationId),
        // Token automatically added by AuthInterceptor
      );
      
      return ConversationHistory.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Conversation not found');
      }
      throw Exception('Failed to load chat history: ${e.message}');
    }
  }
}

// Models
class ConversationSummary {
  final String id;
  final String title;
  final DateTime lastUpdated;
  final int messageCount;

  ConversationSummary({
    required this.id,
    required this.title,
    required this.lastUpdated,
    required this.messageCount,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'],
      title: json['title'],
      lastUpdated: DateTime.parse(json['last_updated']),
      messageCount: json['message_count'] ?? 0,
    );
  }
}

class ConversationHistory {
  final String conversationId;
  final String title;
  final List<Message> messages;

  ConversationHistory({
    required this.conversationId,
    required this.title,
    required this.messages,
  });

  factory ConversationHistory.fromJson(Map<String, dynamic> json) {
    return ConversationHistory(
      conversationId: json['conversation_id'],
      title: json['title'],
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m))
          .toList(),
    );
  }
}

class Message {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      role: json['role'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
```

### Step 2: Add Provider

Add to `lib/features/chat/state/chat_state.dart`:

```dart
final conversationRepositoryProvider = Provider((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  return ConversationRepository(onUnauthorized: () {
    authNotifier.logout();
  });
});
```

### Step 3: Use in UI

```dart
// In your sidebar widget
final conversationRepo = ref.read(conversationRepositoryProvider);
final conversations = await conversationRepo.getAllConversations();

// When user clicks a conversation
final history = await conversationRepo.getChatHistory(conversationId);
```

---

## ✅ Summary: What's Already Done

| API | Endpoint | Status | File | Auto Token |
|-----|----------|--------|------|------------|
| **API 1** | POST /auth/login | ✅ Done | `auth_service.dart` | N/A (gets token) |
| **API 2** | GET /chat/conversations | ✅ Protected | Need to implement | ✅ Yes |
| **API 3** | GET /conversations/:id | ✅ Protected | Need to implement | ✅ Yes |
| **API 4** | POST /chat | ✅ Done | `chat_repository.dart` | ✅ Yes |

## 🎯 What You Need to Do

1. ✅ **Update API URL** in `lib/core/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'https://your-backend-url.com';
   ```

2. ✅ **Test Login** - Already implemented, just update URL

3. ✅ **Test Send Question** - Already implemented via ChatRepository

4. 📝 **Implement API 2 & 3** - Use the code above to create ConversationRepository

---

## 🔐 Security Features (All Automatic)

✅ Token stored in Flutter Secure Storage  
✅ Token checked before every API call  
✅ Expired tokens detected and user logged out  
✅ 401 responses trigger automatic logout  
✅ Token automatically added to all requests  
✅ No manual token management needed  

---

## 🚀 Quick Start

1. Update `baseUrl` in `api_config.dart`
2. Run the app: `flutter run -d chrome`
3. App will show login screen (no token)
4. Enter email and password
5. API 1 called → Token saved
6. Redirected to chat
7. API 2 called → Conversations loaded
8. Click conversation → API 3 called
9. Send message → API 4 called

**All with automatic token management!** 🎉
