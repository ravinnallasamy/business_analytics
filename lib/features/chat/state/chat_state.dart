import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/home_widget/home_widget_service.dart';
import 'package:business_analytics_chat/features/chat/data/chat_repository.dart';
import 'package:business_analytics_chat/features/auth/state/auth_notifier.dart';

// Models
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<BlockData> blocks; // For assistant structured response

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.blocks = const [],
  });
}

class BlockData {
  final String type; // 'text', 'metrics', 'table', 'chart', 'suggestions'
  final Map<String, dynamic> data;

  BlockData({required this.type, required this.data});
}

class Conversation {
  final String id;
  final String title;
  final DateTime lastUpdated;
  final List<ChatMessage> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.lastUpdated,
    required this.messages,
  });
}

// State
class ChatState {
  final List<Conversation> conversations;
  final String? activeConversationId;
  final bool isLoading;

  ChatState({
    this.conversations = const [],
    this.activeConversationId,
    this.isLoading = false,
  });

  ChatState copyWith({
    List<Conversation>? conversations,
    String? activeConversationId,
    bool? isLoading,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      activeConversationId: activeConversationId ?? this.activeConversationId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Notifier
final chatRepositoryProvider = Provider((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  return ChatRepository(onUnauthorized: () {
    authNotifier.logout();
  });
});

class ChatNotifier extends Notifier<ChatState> {
  late final ChatRepository _repository;

  @override
  ChatState build() {
    _repository = ref.read(chatRepositoryProvider);
    return ChatState(
      conversations: [], // Start empty, fetch history later if needed
      activeConversationId: null,
      isLoading: false,
    );
  }

  void selectConversation(String id) {
    state = state.copyWith(activeConversationId: id);
    // Ideally fetch history here if not already loaded
  }

  String createNewConversation() {
    // Just reset the UI state to allow sending a new message which will create the ID
    state = state.copyWith(activeConversationId: null); // Ensure null
    return ''; // ID is not known yet
  }

  void clearActiveConversation() {
     // We can't use copyWith here because passing null means "keep existing value" in the current implementation
    state = ChatState(
      conversations: state.conversations,
      activeConversationId: null,
      isLoading: state.isLoading,
    );
  }

  Future<void> sendMessage(String content) async {
    // 1. Optimistic Update (User Message)
    final tempId = DateTime.now().toString();
    String? currentId = state.activeConversationId;
    
    // Create a temporary conversation object if new
    if (currentId == null) {
       // We don't have a real ID yet, so we don't add to conversations list yet
       // OR we add a temporary one. Let's add a temporary one to show the UI immediate feedback.
       // But waiting for the API response is safer to get the real ID.
       // Hybrid: detailed local state? 
       // Simpler: Just set loading, and once response comes, we create the full conversation structure.
    }

    final userMessage = ChatMessage(
          id: tempId,
          content: content,
          isUser: true,
          timestamp: DateTime.now(),
    );

    // Update locally to show user message immediately
    if (currentId != null) {
      final updatedConversations = state.conversations.map((c) {
        if (c.id == currentId) {
          return Conversation(
            id: c.id,
            title: c.title,
            lastUpdated: DateTime.now(),
            messages: [...c.messages, userMessage],
          );
        }
        return c;
      }).toList();
      state = state.copyWith(conversations: updatedConversations, isLoading: true);
    } else {
      // New conversation pending... we can show a loader or a temp conversation
       // For UI responsiveness, let's create a temp place holder
       // currentId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
       // Actually, let's just wait for the response to create the conversation in the list 
       // IF it's the very first message.
       // BUT the UI needs a non-null activeConversation to show the chat screen.
       // So we MUST create a temporary conversation.
       currentId = 'temp_pending';
       final newConv = Conversation(
         id: currentId,
         title: content,
         lastUpdated: DateTime.now(),
         messages: [userMessage],
       );
       state = state.copyWith(
         conversations: [newConv, ...state.conversations],
         activeConversationId: currentId,
         isLoading: true,
       );
    }

    try {
      // 2. Call API
      // If currentId is temporary, send null to API
      String? apiConversationId = currentId!.startsWith('temp_') ? null : currentId;

      final response = await _repository.sendMessage(content, apiConversationId);

      // 3. Handle Response
      final realConversationId = response.conversationId;
      
      // Map API Blocks to UI Blocks
      final uiBlocks = response.answer.blocks.map((b) {
        if (b.type == 'text') {
          return BlockData(type: 'text', data: {'text': b.content ?? ''});
        } else if (b.type == 'metrics') {
           return BlockData(type: 'metrics', data: {
             'metrics': b.metrics?.map((m) => {'label': m.label, 'value': m.value}).toList() ?? []
           });
        } else if (b.type == 'table') {
          return BlockData(type: 'table', data: {
             'title': b.title,
             'columns': b.headers ?? [],
             'rows': b.rows ?? []
          });
        } else if (b.type == 'chart') {
           return BlockData(type: 'chart', data: {
             'title': b.title,
             'x_key': b.xKey,
             'y_keys': b.yKeys,
             'data': b.data,
             'chart_type': b.chartType
           });
        } else if (b.type == 'suggestions') {
          return BlockData(type: 'suggestions', data: {
            'actions': b.items ?? []
          });
        }
        return BlockData(type: 'unknown', data: {});
      }).toList();

      final botMessage = ChatMessage(
        id: response.messageId ?? DateTime.now().toString(),
        content: '', // content handled by blocks
        isUser: false,
        timestamp: DateTime.now(),
        blocks: uiBlocks,
      );

      // 4. Update interactions with real ID
      List<Conversation> finalConversations;
      
      if (currentId.startsWith('temp_') && realConversationId != null) {
        // Replace temp conversation with real one
        finalConversations = state.conversations.map((c) {
          if (c.id == currentId) {
             return Conversation(
               id: realConversationId,
               title: c.title,
               lastUpdated: DateTime.now(),
               messages: [...c.messages, botMessage],
             );
          }
          return c;
        }).toList();
        currentId = realConversationId;
      } else {
        // Update existing
        finalConversations = state.conversations.map((c) {
          if (c.id == currentId) {
            return Conversation(
              id: c.id,
              title: c.title,
              lastUpdated: DateTime.now(),
              messages: [...c.messages, botMessage],
            );
          }
          return c;
        }).toList();
      }

      state = state.copyWith(
        conversations: finalConversations,
        activeConversationId: currentId,
        isLoading: false,
      );
      
      HomeWidgetService.updateWidget(title: 'New Insight', message: 'Analysis ready');

    } catch (e) {
      // Revert/Error handling
      state = state.copyWith(isLoading: false);
      // Ideally add an error message to the chat
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

// Selectors
final activeConversationProvider = Provider<Conversation?>((ref) {
  final state = ref.watch(chatProvider);
  if (state.activeConversationId == null) return null;
  try {
    return state.conversations.firstWhere((c) => c.id == state.activeConversationId);
  } catch (_) {
    return null;
  }
});
