# 💬 CHAT HISTORY API INTEGRATION

## 📋 API Details

### Endpoint
```
GET https://chatbot.fuzionest.com/api/conversations/{conversation_id}/messages
```

### Example
```
GET https://chatbot.fuzionest.com/api/conversations/c_XDEH9ouvwcLbzNhYcIll-/messages
```

### Authentication
```
Headers:
  Authorization: Bearer <access_token>
  Content-Type: application/json
```

## 📊 Response Format

### Success Response (200)
```json
{
    "success": true,
    "conversation_id": "c_XDEH9ouvwcLbzNhYcIll-",
    "messages": [
        {
            "id": "5a5fa77b-d878-4641-a114-0c051c7fddbf",
            "message_id": "m_184c93313d3a",
            "role": "user",
            "content_json": {
                "type": "query",
                "module": "sales",
                "user_id": "df0d98de-e2c1-4e93-a3b1-46c613556dcb",
                "question": "Give me the Visit plan",
                "reconstructed_intent": "give me the visit plan"
            },
            "created_at": "2026-02-17 04:48:38.656587",
            "updated_at": "2026-02-17 04:48:38.656587",
            "trace_id": null
        },
        {
            "id": "c2e278f0-8591-40a4-a93b-c5f6136a0b84",
            "message_id": "m_2afdf27007de",
            "role": "assistant",
            "content_json": {
                "meta": {
                    "mode": "MONGO_AGENT",
                    "model": "gemini-2.5-flash-lite",
                    "status": "success",
                    "tool_used": "mongo_agent",
                    "execution_time_ms": 703.84
                },
                "mode": "MONGO_AGENT",
                "type": "answer",
                "blocks": [
                    {
                        "type": "text",
                        "content": "### No Data Available..."
                    },
                    {
                        "type": "suggestions",
                        "items": [
                            "What specific dates would you like?",
                            "Show me the dashboard."
                        ]
                    }
                ],
                "summary": "Hello Shankar, I'm unable to generate...",
                "step_logs": [],
                "response_type": "text",
                "reconstructed_intent": "give me the visit plan"
            },
            "created_at": "2026-02-17 04:48:38.660113",
            "updated_at": "2026-02-17 04:48:38.660113",
            "trace_id": "e3e44b54-0dc7-4371-aeea-90b52682865f"
        }
    ],
    "total": 2,
    "has_more": false
}
```

## 🔧 Repository Methods

### 1. Get Chat History
```dart
final repository = ConversationRepository(dio);

// Fetch chat history for a conversation
final chatHistory = await repository.getChatHistory('c_XDEH9ouvwcLbzNhYcIll-');

// Response structure:
// {
//   "success": true,
//   "conversation_id": "c_XDEH9ouvwcLbzNhYcIll-",
//   "messages": [...],
//   "total": 2,
//   "has_more": false
// }
```

### 2. Parse Messages
```dart
// Extract messages array from response
final messages = repository.parseMessages(chatHistory);

// Returns: List<Map<String, dynamic>>
// Each message has: id, message_id, role, content_json, created_at, etc.
```

### 3. Get Message Content
```dart
for (var message in messages) {
  final content = repository.getMessageContent(message);
  print('$content');
}

// For user messages: Returns the question
// For assistant messages: Returns the summary or first text block
```

### 4. Get Suggestions
```dart
for (var message in messages) {
  if (message['role'] == 'assistant') {
    final suggestions = repository.getSuggestions(message);
    
    for (var suggestion in suggestions) {
      print('Suggestion: $suggestion');
    }
  }
}

// Returns: List<String> of suggestion items
```

### 5. Get Content Blocks
```dart
for (var message in messages) {
  if (message['role'] == 'assistant') {
    final blocks = repository.getContentBlocks(message);
    
    for (var block in blocks) {
      if (block['type'] == 'text') {
        print('Text: ${block['content']}');
      } else if (block['type'] == 'suggestions') {
        print('Suggestions: ${block['items']}');
      }
    }
  }
}

// Returns: List<Map<String, dynamic>> of all content blocks
```

## 📝 Message Structure

### User Message
```dart
{
  "id": "uuid",
  "message_id": "m_xxx",
  "role": "user",
  "content_json": {
    "type": "query",
    "module": "sales",
    "user_id": "uuid",
    "question": "Give me the Visit plan",
    "reconstructed_intent": "give me the visit plan"
  },
  "created_at": "timestamp",
  "updated_at": "timestamp",
  "trace_id": null
}
```

### Assistant Message
```dart
{
  "id": "uuid",
  "message_id": "m_xxx",
  "role": "assistant",
  "content_json": {
    "meta": { ... },
    "mode": "MONGO_AGENT",
    "type": "answer",
    "blocks": [
      {
        "type": "text",
        "content": "..."
      },
      {
        "type": "suggestions",
        "items": ["...", "..."]
      }
    ],
    "summary": "...",
    "step_logs": [],
    "response_type": "text",
    "reconstructed_intent": "..."
  },
  "created_at": "timestamp",
  "updated_at": "timestamp",
  "trace_id": "uuid"
}
```

## 🎨 Content Block Types

### 1. Text Block
```dart
{
  "type": "text",
  "content": "### Markdown formatted text..."
}
```

### 2. Suggestions Block
```dart
{
  "type": "suggestions",
  "items": [
    "What specific dates would you like?",
    "Show me the dashboard."
  ]
}
```

### 3. Other Block Types (Future)
- Charts
- Tables
- Metrics
- Images
- etc.

## 🔄 Complete Usage Example

```dart
import 'package:business_analytics_chat/features/chat/data/conversation_repository.dart';

// Create repository
final repository = ConversationRepository(dio);

try {
  // 1. Fetch chat history
  final chatHistory = await repository.getChatHistory('c_XDEH9ouvwcLbzNhYcIll-');
  
  print('Success: ${chatHistory['success']}');
  print('Conversation ID: ${chatHistory['conversation_id']}');
  print('Total messages: ${chatHistory['total']}');
  print('Has more: ${chatHistory['has_more']}');
  
  // 2. Parse messages
  final messages = repository.parseMessages(chatHistory);
  
  // 3. Display messages
  for (var message in messages) {
    final role = message['role'];
    final content = repository.getMessageContent(message);
    
    print('[$role]: $content');
    
    // 4. Show suggestions if available
    if (role == 'assistant') {
      final suggestions = repository.getSuggestions(message);
      if (suggestions.isNotEmpty) {
        print('Suggestions:');
        for (var suggestion in suggestions) {
          print('  - $suggestion');
        }
      }
      
      // 5. Get all content blocks
      final blocks = repository.getContentBlocks(message);
      for (var block in blocks) {
        print('Block type: ${block['type']}');
      }
    }
  }
} catch (e) {
  print('Error: $e');
}
```

## ✅ Features Implemented

✅ **Fetch chat history** with Bearer token  
✅ **Parse messages** from response  
✅ **Extract user questions** from content_json  
✅ **Extract assistant summaries** from content_json  
✅ **Get suggestions** from blocks  
✅ **Get all content blocks** for rendering  
✅ **Error handling** (401, 404, timeout)  
✅ **Automatic token** from Secure Storage  

## 🎯 Integration Steps

### Step 1: Add Repository to Providers
```dart
// In your providers file
final conversationRepositoryProvider = Provider((ref) {
  final dio = Dio();
  return ConversationRepository(dio);
});
```

### Step 2: Use in Chat Notifier
```dart
class ChatNotifier extends StateNotifier<ChatState> {
  final ConversationRepository _repository;
  
  Future<void> loadConversation(String conversationId) async {
    try {
      final chatHistory = await _repository.getChatHistory(conversationId);
      final messages = _repository.parseMessages(chatHistory);
      
      // Update state with messages
      state = state.copyWith(messages: messages);
    } catch (e) {
      // Handle error
    }
  }
}
```

### Step 3: Display in UI
```dart
// In your message widget
Widget buildMessage(Map<String, dynamic> message) {
  final content = repository.getMessageContent(message);
  final suggestions = repository.getSuggestions(message);
  
  return Column(
    children: [
      Text(content),
      if (suggestions.isNotEmpty)
        ...suggestions.map((s) => SuggestionChip(label: Text(s))),
    ],
  );
}
```

## 🔐 Security

- ✅ Bearer token automatically retrieved from Secure Storage
- ✅ Token added to all requests
- ✅ 401 errors handled (redirect to login)
- ✅ Secure HTTPS communication

## 📊 Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Request success status |
| `conversation_id` | string | Conversation identifier |
| `messages` | array | List of messages |
| `total` | integer | Total message count |
| `has_more` | boolean | Pagination flag |

## 💡 Helper Methods Summary

| Method | Purpose | Returns |
|--------|---------|---------|
| `getChatHistory()` | Fetch chat history | Full response object |
| `parseMessages()` | Extract messages array | List of messages |
| `getMessageContent()` | Get displayable text | String |
| `getSuggestions()` | Get suggestion items | List of strings |
| `getContentBlocks()` | Get all blocks | List of blocks |

---

**API Endpoint**: `https://chatbot.fuzionest.com/api/conversations/:id/messages`  
**Authentication**: Bearer token (automatic)  
**Status**: ✅ Fully implemented and ready to use!
