import 'package:flutter/material.dart'; // For debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:business_analytics_chat/modules/home_widget/home_widget_service.dart';
import 'package:business_analytics_chat/modules/chat/data/conversation_repository.dart'; // Use ConversationRepository
import 'package:business_analytics_chat/modules/auth/state/auth_notifier.dart';
import 'package:business_analytics_chat/core/config/api_config.dart';
import 'package:dio/dio.dart'; // Needed for provider

// Models
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<BlockData> blocks; // For assistant structured response
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.blocks = const [],
    this.isLoading = false,
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
  final String? error;

  ChatState({
    this.conversations = const [],
    this.activeConversationId,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<Conversation>? conversations,
    String? activeConversationId,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      activeConversationId: activeConversationId ?? this.activeConversationId,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Allow null to clear error
    );
  }
}

// Notifier
final conversationRepositoryProvider = Provider((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    sendTimeout: ApiConfig.sendTimeout,
  ));
  return ConversationRepository(dio);
});

class ChatNotifier extends Notifier<ChatState> {
  late final ConversationRepository _repository;

  @override
  ChatState build() {
    _repository = ref.read(conversationRepositoryProvider);
    // Auto-load conversations on build
    Future.microtask(() => loadConversations());
    return ChatState(
      conversations: [], 
      activeConversationId: null,
      isLoading: false,
      error: null,
    );
  }

  /// Load all conversations
  Future<void> loadConversations() async {
    // Prevent redundant rapid calls, but allow refresh
    if (state.isLoading && state.conversations.isNotEmpty) return;

    const storage = FlutterSecureStorage();
    final weeklySalesId = await storage.read(key: 'weekly_sales_conversation_id');

    // 1. Stale-While-Revalidate: Try Cache First (Instant)
    try {
      final cached = await _repository.getCachedConversations();
      if (cached != null) {
        final conversations = cached.map((data) {
          final id = data['conversation_id'] ?? data['id'] ?? data['_id'] ?? '';
          return Conversation(
            id: id,
            title: id == weeklySalesId ? 'Weekly Sales Summary' : (data['title'] ?? 'New Conversation'),
            lastUpdated: DateTime.parse(data['updated_at'] ?? DateTime.now().toIso8601String()),
            messages: [], // Message history not in list cache
          );
        }).toList();

        // Update state with cached data immediately
        state = state.copyWith(conversations: conversations);
        debugPrint('📦 ChatNotifier: Loaded ${conversations.length} conversations from CACHE');
      }
    } catch (e) {
      debugPrint('⚠️ ChatNotifier: Cache load failed: $e');
    }

    // 2. Fetch Fresh Data (Background)
    state = state.copyWith(isLoading: true, error: null);

    try {
      final conversationsData = await _repository.getAllConversations();
      debugPrint('✅ ChatNotifier: Loaded ${conversationsData.length} conversations from NETWORK');
      
      final conversations = conversationsData.map((data) {
        final id = data['conversation_id'] ?? data['id'] ?? data['_id'] ?? '';
        
        final existingIndex = state.conversations.indexWhere((c) => c.id == id);
        final existingMessages = existingIndex != -1 
            ? state.conversations[existingIndex].messages 
            : <ChatMessage>[];

        return Conversation(
          id: id,
          title: id == weeklySalesId ? 'Weekly Sales Summary' : (data['title'] ?? 'New Conversation'),
          lastUpdated: DateTime.parse(data['updated_at'] ?? DateTime.now().toIso8601String()),
          messages: existingMessages, 
        );
      }).toList();

      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );

      // Prefetch the most recent conversation's history in the background
      if (conversations.isNotEmpty && state.activeConversationId == null) {
        Future.microtask(() => prefetchHistory(conversations.first.id));
      }
    } catch (e) {
      debugPrint('❌ ChatNotifier: Failed to load conversations: $e');
      state = state.copyWith(
        isLoading: false, 
        error: state.conversations.isEmpty ? e.toString() : null,
      );
    }
  }

  /// Prefetch history for a conversation without updating global loading state
  Future<void> prefetchHistory(String conversationId) async {
    try {
      // Only prefetch if we don't already have messages
      final conv = state.conversations.firstWhere((c) => c.id == conversationId, orElse: () => Conversation(id: '', title: '', lastUpdated: DateTime.now(), messages: []));
      if (conv.messages.isNotEmpty) return;

      debugPrint('🔍 ChatNotifier: Prefetching history for $conversationId');
      
      // Try cache first
      final cachedHistory = await _repository.getCachedHistory(conversationId);
      if (cachedHistory != null) {
        final messagesData = _repository.parseMessages(cachedHistory);
        final messages = _parseMessagesHelper(messagesData);
        _updateConversationMessages(conversationId, messages);
      }

      // Fetch fresh in background
      final chatHistory = await _repository.getChatHistory(conversationId);
      final messagesData = _repository.parseMessages(chatHistory);
      final messages = _parseMessagesHelper(messagesData);
      _updateConversationMessages(conversationId, messages);
    } catch (e) {
      debugPrint('⚠️ ChatNotifier: Prefetch failed for $conversationId: $e');
    }
  }

  void _updateConversationMessages(String conversationId, List<ChatMessage> messages) {
    final updatedConversations = state.conversations.map((c) {
      if (c.id == conversationId) {
        return Conversation(
          id: c.id,
          title: c.title,
          lastUpdated: c.lastUpdated,
          messages: messages,
        );
      }
      return c;
    }).toList();
    state = state.copyWith(conversations: updatedConversations);
  }

  /// Select a conversation and load its history
  Future<void> selectConversation(String conversationId) async {
    // 0. Handle 'last' pseudo-ID
    if (conversationId == 'last') {
      if (state.conversations.isEmpty) {
        // Wait for initial load if we launched directly into 'last'
        await loadConversations();
      }
      
      if (state.conversations.isNotEmpty) {
        // Find most recently updated
        final sorted = List<Conversation>.from(state.conversations)
          ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        conversationId = sorted.first.id;
        debugPrint('🪄 ChatNotifier: Resolved "last" to $conversationId');
      } else {
        debugPrint('⚠️ ChatNotifier: Could not resolve "last", no conversations. Creating new chat.');
        createNewConversation();
        return; // Early return because createNewConversation assigns activeConversationId.
      }
    }

    // 1. Update selection immediately
    state = state.copyWith(
        activeConversationId: conversationId,
        error: null,
    );
    
    // Check if we already have messages in memory
    final existingConv = state.conversations.firstWhere(
      (c) => c.id == conversationId, 
      orElse: () => Conversation(id: '', title: '', lastUpdated: DateTime.now(), messages: [])
    );
    
    // If in memory, we are good for now. Detailed refresh happens below.
    if (existingConv.messages.isNotEmpty) {
       debugPrint('🚀 ChatNotifier: Using memory messages for $conversationId');
       // We still might want to refresh from cache/network to get new messages? 
       // For this strict requirement "faster app startup", we assume memory is fastest.
       // But if we want to ensure we have latest, we should proceed. 
       // Let's assume hitting back button -> selectConversation needs to be fast. 
       // If logic allows, we can return. But let's do the Cache check at least.
    }

    // 2. Try Cache First (Instant Message History)
    bool hasCachedHistory = false;
    try {
       final cachedHistory = await _repository.getCachedHistory(conversationId);
       if (cachedHistory != null) {
          final messagesData = _repository.parseMessages(cachedHistory);
           final messages = _parseMessagesHelper(messagesData);

           // Update specific conversation with CACHED messages
            final updatedConversations = state.conversations.map((c) {
              if (c.id == conversationId) {
                return Conversation(
                  id: c.id,
                  title: c.title,
                  lastUpdated: c.lastUpdated,
                  messages: messages,
                );
              }
              return c;
            }).toList();
            
            state = state.copyWith(conversations: updatedConversations);
            hasCachedHistory = true;
            debugPrint('📦 ChatNotifier: Loaded ${messages.length} messages from CACHE for $conversationId');
       }
    } catch (e) {
      debugPrint('⚠️ ChatNotifier: Hist Cache load failed: $e');
    }

    // 3. Fetch Fresh History (Background)
    
    // If we have cached history, we don't show global loading spinner, 
    // maybe just a small indicator or nothing (seamless update).
    if (!hasCachedHistory && existingConv.messages.isEmpty) {
      state = state.copyWith(isLoading: true);
    }

    try {
      final chatHistory = await _repository.getChatHistory(conversationId);
      final messagesData = _repository.parseMessages(chatHistory);
      final messages = _parseMessagesHelper(messagesData);

      // Update specific conversation with FRESH messages
      final updatedConversations = state.conversations.map((c) {
        if (c.id == conversationId) {
          return Conversation(
            id: c.id,
            title: c.title,
            lastUpdated: c.lastUpdated,
            messages: messages,
          );
        }
        return c;
      }).toList();

      state = state.copyWith(
        conversations: updatedConversations,
        isLoading: false, 
      );
      debugPrint('✅ ChatNotifier: Loaded ${messages.length} messages from NETWORK for $conversationId');

    } catch (e) {
      debugPrint('❌ ChatNotifier: Failed to load chat history: $e');
      // Don't set global error if we have cached data visible, keeps valid UI state
      state = state.copyWith(
        isLoading: false,
        error: (!hasCachedHistory && existingConv.messages.isEmpty) ? e.toString() : null
      );
    }
  }
  
  // Helper to parse messages consistently
  List<ChatMessage> _parseMessagesHelper(List<Map<String, dynamic>> messagesData) {
      return messagesData.map((msg) {
        try {
          final isUser = msg['role'] == 'user';
          dynamic rawContent = msg['content_json'];
          Map<String, dynamic> contentData = {};
          
          if (rawContent is Map) {
            contentData = Map<String, dynamic>.from(rawContent);
          }
          
          List<BlockData> blocks = [];
          
          if (isUser) {
            blocks.add(BlockData(
              type: 'text', 
              data: {'text': contentData['question'] ?? contentData['text'] ?? ''}
            ));
          } else {
            if (contentData['blocks'] != null && contentData['blocks'] is List) {
              final apiBlocks = contentData['blocks'] as List;
              blocks = apiBlocks.map((b) {
                if (b is Map) {
                   return BlockData(
                    type: b['type'] ?? 'unknown',
                    data: Map<String, dynamic>.from(b),
                  );
                }
                return BlockData(type: 'unknown', data: {});
              }).toList();
            } else if (contentData['summary'] != null) {
              blocks.add(BlockData(
                type: 'text',
                data: {'text': contentData['summary']}
              ));
            }
          }
          
          return ChatMessage(
            id: msg['message_id'] ?? DateTime.now().toString(),
            content: isUser ? (contentData['question'] ?? '') : (contentData['summary'] ?? ''),
            isUser: isUser,
            timestamp: DateTime.now(), 
            blocks: blocks,
          );
        } catch (e) {
          return null;
        }
      }).whereType<ChatMessage>().toList();
  }
  
  // ignore: unused_element
  Future<void> _loadConversationHistory(String id) async {}

  String createNewConversation() {
    debugPrint('✨ ChatNotifier: Preparing new conversation');
    state = state.copyWith(activeConversationId: null); 
    return ''; 
  }

  void clearActiveConversation() {
    debugPrint('🧹 ChatNotifier: Clearing active conversation');
    state = ChatState(
      conversations: state.conversations,
      activeConversationId: null,
      isLoading: state.isLoading,
      error: null,
    );
  }

  Future<void> sendMessage(String content) async {
    debugPrint('📤 ChatNotifier: Sending message: "$content"');
    // 1. Optimistic Update (User Message)
    final tempId = DateTime.now().toString();
    String? currentId = state.activeConversationId;
    
    final userMessage = ChatMessage(
          id: tempId,
          content: content,
          isUser: true,
          timestamp: DateTime.now(),
    );

    // 1.5 Add loading assistant message
    final loadingMessage = ChatMessage(
          id: 'loading_$tempId',
          content: '',
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: true,
    );

    // Update locally to show user message immediately
    if (currentId != null) {
      final updatedConversations = state.conversations.map((c) {
        if (c.id == currentId) {
          return Conversation(
            id: c.id,
            title: c.title,
            lastUpdated: DateTime.now(),
            messages: [...c.messages, userMessage, loadingMessage],
          );
        }
        return c;
      }).toList();
      state = state.copyWith(conversations: updatedConversations);
    } else {
       currentId = 'temp_pending';
       final newConv = Conversation(
         id: currentId,
         title: content,
         lastUpdated: DateTime.now(),
         messages: [userMessage, loadingMessage],
       );
       state = state.copyWith(
         conversations: [newConv, ...state.conversations],
         activeConversationId: currentId,
       );
    }

    try {
      // 2. Call API
      // If currentId is temporary, send null to API
      String? apiConversationId = currentId.startsWith('temp_') ? null : currentId;

      // Use ConversationRepository.sendQuestion
      final response = await _repository.sendQuestion(
        question: content,
        conversationId: apiConversationId,
      );

      // 3. Handle Response
      final realConversationId = response['conversation_id'];
      final answer = response['answer'];
      final messageId = response['message_id'];
      
      // Parse Answer Blocks
      List<BlockData> uiBlocks = [];
      if (answer['blocks'] != null) {
        final apiBlocks = answer['blocks'] as List;
        uiBlocks = apiBlocks.map((b) => BlockData(
          type: b['type'] ?? 'unknown',
          data: b,
        )).toList();
      } else if (answer['summary'] != null) {
        uiBlocks.add(BlockData(
          type: 'text',
          data: {'text': answer['summary']}
        ));
      }

      final botMessage = ChatMessage(
        id: messageId ?? DateTime.now().toString(),
        content: answer['summary'] ?? '', // content handled by blocks
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
              // Remove the loading message and add real message
              final msgs = c.messages.where((m) => !m.isLoading).toList();
              return Conversation(
                id: realConversationId,
                title: c.title,
                lastUpdated: DateTime.now(),
                messages: [...msgs, botMessage],
              );
          }
          return c;
        }).toList();
        currentId = realConversationId;
      } else {
        // Update existing
        finalConversations = state.conversations.map((c) {
          if (c.id == currentId) {
            // Remove the loading message and add real message
            final msgs = c.messages.where((m) => !m.isLoading).toList();
            return Conversation(
              id: c.id,
              title: c.title,
              lastUpdated: DateTime.now(),
              messages: [...msgs, botMessage],
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
      debugPrint('❌ ChatNotifier: Failed to send message: $e');
      // Remove loading message on error
      if (currentId != null) {
        final updatedConversations = state.conversations.map((c) {
          if (c.id == currentId) {
            return Conversation(
              id: c.id,
              title: c.title,
              lastUpdated: c.lastUpdated,
              messages: c.messages.where((m) => !m.isLoading).toList(),
            );
          }
          return c;
        }).toList();
        state = state.copyWith(conversations: updatedConversations, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }
  void simulateResponse(Map<String, dynamic> answer) {
    debugPrint('🧪 ChatNotifier: Simulating response');
    
    // Parse Answer Blocks
    List<BlockData> uiBlocks = [];
    if (answer['blocks'] != null) {
      final apiBlocks = answer['blocks'] as List;
      uiBlocks = apiBlocks.map((b) => BlockData(
        type: b['type'] ?? 'unknown',
        data: b,
      )).toList();
    } else if (answer['summary'] != null) {
      uiBlocks.add(BlockData(
        type: 'text',
        data: {'text': answer['summary']}
      ));
    }

    final botMessage = ChatMessage(
      id: DateTime.now().toString(),
      content: answer['summary'] ?? 'Simulated Response',
      isUser: false,
      timestamp: DateTime.now(),
      blocks: uiBlocks,
    );

    // Update conversation
    final currentId = state.activeConversationId;
    if (currentId != null) {
      final updatedConversations = state.conversations.map((c) {
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

      state = state.copyWith(
        conversations: updatedConversations,
      );
    } else {
       // Create new temp conversation if none exists
       final newId = 'simulated_${DateTime.now().millisecondsSinceEpoch}';
       final newConv = Conversation(
         id: newId,
         title: 'Simulated Chat',
         lastUpdated: DateTime.now(),
         messages: [botMessage],
       );
       state = state.copyWith(
         conversations: [newConv, ...state.conversations],
         activeConversationId: newId,
       );
    }
  }

  /// Rename a conversation and update local state
  Future<void> renameConversation(String conversationId, String newTitle) async {
    try {
      // Call API
      await _repository.renameConversation(conversationId, newTitle);
      
      // Update local state immediately
      final updatedConversations = state.conversations.map((c) {
        if (c.id == conversationId) {
          return Conversation(
            id: c.id,
            title: newTitle,
            lastUpdated: c.lastUpdated,
            messages: c.messages,
          );
        }
        return c;
      }).toList();
      
      state = state.copyWith(conversations: updatedConversations);
      debugPrint('✅ ChatNotifier: Renamed conversation $conversationId to $newTitle');
    } catch (e) {
      debugPrint('❌ ChatNotifier: Failed to rename conversation: $e');
      state = state.copyWith(error: 'Failed to rename conversation');
    }
  }

  /// Delete a single conversation and update local state
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Call API
      await _repository.deleteConversation(conversationId);
      
      // Update local state immediately
      final updatedConversations = state.conversations.where((c) => c.id != conversationId).toList();
      
      String? newActiveId = state.activeConversationId;
      if (state.activeConversationId == conversationId) {
        newActiveId = null; // Clear if active was deleted
      }
      
      state = state.copyWith(
        conversations: updatedConversations,
        activeConversationId: newActiveId,
      );
      debugPrint('✅ ChatNotifier: Deleted conversation $conversationId');
    } catch (e) {
      debugPrint('❌ ChatNotifier: Failed to delete conversation: $e');
      state = state.copyWith(error: 'Failed to delete conversation');
    }
  }

  /// Delete all conversations and reset state
  Future<void> deleteAllConversations() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Call API
      await _repository.deleteAllConversations();
      
      // Reset state
      state = state.copyWith(
        conversations: [],
        activeConversationId: null,
        isLoading: false,
        error: null,
      );
      
      // Also clear local weekly sales ID if any
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'weekly_sales_conversation_id');
      
      debugPrint('✅ ChatNotifier: Deleted all conversations');
    } catch (e) {
      debugPrint('❌ ChatNotifier: Failed to delete all conversations: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete all conversations',
      );
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
