# 🚀 SEND QUESTION API - COMPLETE!

## 📋 API Details

### Endpoint
```
POST https://api-chatbot.fuzionest.com/api/v2/agent/run
```

### Authentication
```
Headers:
  Authorization: Bearer <access_token>
  Content-Type: application/json
```

## 📊 Request Format

### New Conversation (conversation_id = null)
```json
{
  "question": "Show me the revenue and sales trends for the past 4 months",
  "conversation_id": null,
  "enable_cache": true
}
```

### Existing Conversation
```json
{
  "question": "What about the previous month?",
  "conversation_id": "c_b18261ed461a",
  "enable_cache": true
}
```

## 📥 Response Format

### Success Response (200)
```json
{
  "conversation_id": "c_b18261ed461a",  // New ID if it was null
  "message_id": "m_xxx",
  "answer": {
    "blocks": [...],
    "summary": "...",
    "meta": {...}
  },
  "status": "success"
}
```

## 🔧 Repository Method

### sendQuestion()
```dart
final repository = ConversationRepository(dio);

// Send question (new conversation)
final response = await repository.sendQuestion(
  question: "Show me the revenue trends",
  conversationId: null,  // null for new conversation
  enableCache: true,
);

// Extract conversation ID for subsequent questions
final conversationId = response['conversation_id'];

// Send follow-up question (same conversation)
final response2 = await repository.sendQuestion(
  question: "What about last month?",
  conversationId: conversationId,  // Use the ID from first response
  enableCache: true,
);
```

## 🔄 Complete Conversation Flow

### Step 1: Start New Conversation
```dart
// User asks first question
final response1 = await repository.sendQuestion(
  question: "Show me the revenue and sales trends for the past 4 months",
  conversationId: null,  // NEW conversation
  enableCache: true,
);

// Extract the new conversation ID
final conversationId = response1['conversation_id'];
print('New conversation created: $conversationId');

// Save this ID for subsequent questions
```

### Step 2: Continue Conversation
```dart
// User asks follow-up question
final response2 = await repository.sendQuestion(
  question: "What about the previous month?",
  conversationId: conversationId,  // SAME conversation
  enableCache: true,
);

// Same conversation ID in response
print('Conversation ID: ${response2['conversation_id']}');
```

### Step 3: Another Follow-up
```dart
// User asks another question
final response3 = await repository.sendQuestion(
  question: "Show me a chart",
  conversationId: conversationId,  // SAME conversation
  enableCache: true,
);
```

## 💡 Usage Patterns

### Pattern 1: New Conversation
```dart
// When user starts a new chat
String? currentConversationId;

final response = await repository.sendQuestion(
  question: userInput,
  conversationId: null,  // Start new
);

// Save the ID for future questions
currentConversationId = response['conversation_id'];
```

### Pattern 2: Continue Conversation
```dart
// When user sends another message in same chat
final response = await repository.sendQuestion(
  question: userInput,
  conversationId: currentConversationId,  // Continue existing
);

// ID remains the same
assert(response['conversation_id'] == currentConversationId);
```

### Pattern 3: Switch Conversation
```dart
// When user selects a different conversation from sidebar
currentConversationId = selectedConversationId;

final response = await repository.sendQuestion(
  question: userInput,
  conversationId: currentConversationId,  // Use selected ID
);
```

## 🎯 Integration with Chat State

### In ChatNotifier
```dart
class ChatNotifier extends StateNotifier<ChatState> {
  final ConversationRepository _repository;
  String? _currentConversationId;

  Future<void> sendMessage(String question) async {
    try {
      // Show loading
      state = state.copyWith(isLoading: true);

      // Send question
      final response = await _repository.sendQuestion(
        question: question,
        conversationId: _currentConversationId,  // null for new, ID for existing
        enableCache: true,
      );

      // Update conversation ID (new or existing)
      _currentConversationId = response['conversation_id'];

      // Extract answer
      final answer = response['answer'];
      
      // Update UI with response
      state = state.copyWith(
        conversationId: _currentConversationId,
        messages: [...state.messages, answer],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void startNewConversation() {
    _currentConversationId = null;  // Reset to start new
    state = state.copyWith(messages: []);
  }

  void loadConversation(String conversationId) {
    _currentConversationId = conversationId;
    // Fetch chat history...
  }
}
```

## 📝 Response Structure

### Full Response
```json
{
  "conversation_id": "c_b18261ed461a",
  "message_id": "m_2afdf27007de",
  "answer": {
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
        "content": "### Revenue Trends\n\nHere are the trends..."
      },
      {
        "type": "chart",
        "chart_type": "line",
        "data": [...]
      },
      {
        "type": "suggestions",
        "items": [
          "Show me by region",
          "Compare with last year"
        ]
      }
    ],
    "summary": "Here are the revenue and sales trends...",
    "step_logs": [],
    "response_type": "text",
    "reconstructed_intent": "show revenue trends"
  },
  "status": "success"
}
```

## ✅ Features

✅ **New Conversations**: Pass `conversation_id: null`  
✅ **Continue Conversations**: Pass existing `conversation_id`  
✅ **Bearer Token**: Automatically from Secure Storage  
✅ **Cache Control**: `enable_cache` parameter  
✅ **Error Handling**: 401, timeout, network errors  
✅ **Response Parsing**: Full answer with blocks  

## 🔐 Security

- ✅ Bearer token automatically retrieved from Secure Storage
- ✅ Token added to all requests
- ✅ 401 errors handled (redirect to login)
- ✅ Secure HTTPS communication

## 📊 Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `question` | string | Yes | The user's question |
| `conversation_id` | string? | No | Conversation ID (null for new) |
| `enable_cache` | bool | No | Enable caching (default: true) |

## 📥 Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `conversation_id` | string | Conversation identifier (new or existing) |
| `message_id` | string | Message identifier |
| `answer` | object | The agent's response with blocks |
| `status` | string | Request status ("success") |

## 🧪 Testing

### Test 1: New Conversation
```dart
final response = await repository.sendQuestion(
  question: "Show me revenue trends",
  conversationId: null,
);

print('New conversation: ${response['conversation_id']}');
// Output: New conversation: c_abc123
```

### Test 2: Continue Conversation
```dart
final conversationId = 'c_abc123';

final response = await repository.sendQuestion(
  question: "What about last month?",
  conversationId: conversationId,
);

print('Same conversation: ${response['conversation_id']}');
// Output: Same conversation: c_abc123
```

### Test 3: Extract Answer
```dart
final response = await repository.sendQuestion(
  question: "Show me sales data",
  conversationId: null,
);

final answer = response['answer'];
final blocks = answer['blocks'];
final summary = answer['summary'];

print('Summary: $summary');
print('Blocks: ${blocks.length}');
```

## 💻 Complete Example

```dart
import 'package:business_analytics_chat/features/chat/data/conversation_repository.dart';

class ChatService {
  final ConversationRepository _repository;
  String? _currentConversationId;

  ChatService(this._repository);

  Future<void> askQuestion(String question) async {
    try {
      // Send question
      final response = await _repository.sendQuestion(
        question: question,
        conversationId: _currentConversationId,
        enableCache: true,
      );

      // Update conversation ID
      _currentConversationId = response['conversation_id'];

      // Extract answer
      final answer = response['answer'];
      final summary = answer['summary'];
      final blocks = answer['blocks'];

      print('Conversation: $_currentConversationId');
      print('Summary: $summary');
      print('Blocks: ${blocks.length}');

      // Display blocks
      for (var block in blocks) {
        if (block['type'] == 'text') {
          print('Text: ${block['content']}');
        } else if (block['type'] == 'suggestions') {
          print('Suggestions: ${block['items']}');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void startNewChat() {
    _currentConversationId = null;
    print('Starting new conversation');
  }

  void loadChat(String conversationId) {
    _currentConversationId = conversationId;
    print('Loaded conversation: $conversationId');
  }
}
```

---

**API Endpoint**: `https://api-chatbot.fuzionest.com/api/v2/agent/run`  
**Method**: POST  
**Authentication**: Bearer token (automatic)  
**Status**: ✅ **FULLY IMPLEMENTED AND READY TO USE!**

🎉 **You can now send questions and get AI responses!**
