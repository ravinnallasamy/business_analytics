import 'package:flutter/material.dart'; // For debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:business_analytics_chat/modules/home_widget/home_widget_service.dart';
import 'package:business_analytics_chat/modules/chat/data/conversation_repository.dart'; // Use ConversationRepository
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
  // Nullable internally so hot-reload can never produce a null-cast TypeError.
  final bool? _thinkingModeEnabled;
  bool get thinkingModeEnabled => _thinkingModeEnabled ?? false;

  final bool? _isGenerating;
  /// True while awaiting a sendQuestion API response.
  bool get isGenerating => _isGenerating ?? false;

  /// Current stage label shown in the loading indicator. Null when not generating.
  final String? generationStage;

  ChatState({
    this.conversations = const [],
    this.activeConversationId,
    this.isLoading = false,
    this.error,
    bool thinkingModeEnabled = false,
    bool isGenerating = false,
    this.generationStage,
  })  : _thinkingModeEnabled = thinkingModeEnabled,
        _isGenerating = isGenerating;

  ChatState copyWith({
    List<Conversation>? conversations,
    String? activeConversationId,
    bool? isLoading,
    String? error,
    bool? thinkingModeEnabled,
    bool? isGenerating,
    // Use Object? + sentinel to allow explicitly setting generationStage to null
    Object? generationStage = _kUnset,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      activeConversationId: activeConversationId ?? this.activeConversationId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      thinkingModeEnabled: thinkingModeEnabled ?? this.thinkingModeEnabled,
      isGenerating: isGenerating ?? this.isGenerating,
      generationStage: identical(generationStage, _kUnset)
          ? this.generationStage
          : generationStage as String?,
    );
  }
}

/// Sentinel value used in copyWith to distinguish "not provided" from explicit null.
const _kUnset = Object();

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
  /// Held so cancelGeneration() can abort in-flight Dio requests.
  CancelToken? _pendingCancelToken;
  /// Incremented on every new request. Stage timer callbacks check this
  /// before mutating state so old timers never bleed into new requests.
  int _stageToken = 0;

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

  /// Toggle thinking mode on/off
  void toggleThinkingMode() {
    final newValue = !state.thinkingModeEnabled;
    state = state.copyWith(thinkingModeEnabled: newValue);
    debugPrint('🧠 ChatNotifier: Thinking mode ${newValue ? 'ENABLED' : 'DISABLED'}');
  }

  /// Cancel the in-flight API request and remove the loading message.
  void cancelGeneration() {
    // Invalidate stage timers immediately
    _stageToken++;
    if (_pendingCancelToken != null && !_pendingCancelToken!.isCancelled) {
      debugPrint('🛑 ChatNotifier: Cancelling generation');
      _pendingCancelToken!.cancel('User cancelled');
    }
  }

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
      thinkingModeEnabled: state.thinkingModeEnabled, // Preserve session toggle
    );
  }

  Future<void> sendMessage(String content, {String? toolId, bool? thinkingMode}) async {
    debugPrint('📤 ChatNotifier: Sending message: "$content" (ToolId: $toolId)');
    // 1. Optimistic Update (User Message)
    final tempId = DateTime.now().toString();
    String? currentId = state.activeConversationId;
    
    final userMessage = ChatMessage(
          id: tempId,
          content: content,
          isUser: true,
          timestamp: DateTime.now(),
    );

    // Resolve thinking mode: param overrides state
    final bool isThinking = thinkingMode ?? state.thinkingModeEnabled;
    debugPrint('🧠 ChatNotifier: thinkingModeEnabled=${state.thinkingModeEnabled}, isThinking=$isThinking');

    // 1.5 Add loading assistant message (use __thinking__ sentinel when thinking mode is on)
    final loadingMessage = ChatMessage(
          id: 'loading_$tempId',
          content: isThinking ? '__thinking__' : '',
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: true,
    );

    // Update locally to show user message + set isGenerating
    state = state.copyWith(isGenerating: true, generationStage: isThinking ? 'Thinking…' : 'Processing results…');

    // ——— Stage timer chain: steps fire until the request completes ———
    final int token = ++_stageToken;
    void _scheduleStage(String label, int ms) {
      Future.delayed(Duration(milliseconds: ms), () {
        if (_stageToken == token) {
          state = state.copyWith(generationStage: label);
        }
      });
    }

    if (isThinking) {
      _scheduleStage('Analyzing question…', 1000);
      _scheduleStage('Fetching relevant data…', 2000);
      _scheduleStage('Preparing insights…', 3000);
      _scheduleStage('Generating response…', 4000);
    } else {
      _scheduleStage('Generating response…', 1200);
    }
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

      // Create a fresh cancel token for this request
      _pendingCancelToken = CancelToken();

      // Use ConversationRepository.sendQuestion
      final response = await _repository.sendQuestion(
        question: content,
        conversationId: apiConversationId,
        toolId: toolId,
        thinkingMode: isThinking ? true : null,
        cancelToken: _pendingCancelToken,
      );
      _pendingCancelToken = null;

      // 3. Handle Response
      debugPrint('📥 ChatNotifier: Raw response keys: ${response.keys.toList()}');
      debugPrint('📥 ChatNotifier: Full response: $response');

      final realConversationId = response['conversation_id'] as String?;
      final messageId = response['message_id'] as String?;

      // Safely extract the answer — handle both `answer` key and flat structure
      final dynamic rawAnswer = response['answer'] ?? response;
      final Map<String, dynamic> answer = rawAnswer is Map
          ? Map<String, dynamic>.from(rawAnswer)
          : <String, dynamic>{};

      debugPrint('📥 ChatNotifier: answer keys: ${answer.keys.toList()}');

      // Parse Answer Blocks — null-safe with node_steps deep fallback
      List<BlockData> uiBlocks = [];

      // Helper: convert a raw block map to BlockData
      BlockData _toBlock(dynamic b) {
        if (b is Map) {
          // Normalise: some blocks use 'content', others use 'text'
          final data = Map<String, dynamic>.from(b);
          if (!data.containsKey('text') && data.containsKey('content')) {
            data['text'] = data['content'];
          }
          return BlockData(type: (data['type'] as String?) ?? 'text', data: data);
        }
        return BlockData(type: 'unknown', data: {});
      }

      // 1️⃣  Primary: answer.blocks (non-empty list)
      final dynamic rawBlocks = answer['blocks'];
      if (rawBlocks is List && rawBlocks.isNotEmpty) {
        uiBlocks = rawBlocks.map(_toBlock).toList();
        debugPrint('📥 ChatNotifier: Parsed ${uiBlocks.length} blocks from answer.blocks');
      }

      // 2️⃣  Fallback: dig into node_steps → react_agent → execution_result.data.blocks
      //     This is where the real content lives when answer.blocks is empty
      if (uiBlocks.isEmpty) {
        try {
          final nodeSteps = response['node_steps'];
          if (nodeSteps is List) {
            for (final step in nodeSteps) {
              if (step is Map && step['node'] == 'react_agent') {
                final execResult = step['output']?['execution_result'];
                if (execResult is Map) {
                  final data = execResult['data'];
                  if (data is Map) {
                    final stepBlocks = data['blocks'];
                    if (stepBlocks is List && stepBlocks.isNotEmpty) {
                      uiBlocks = stepBlocks.map(_toBlock).toList();
                      debugPrint('📥 ChatNotifier: Parsed ${uiBlocks.length} blocks from node_steps.react_agent');
                      break;
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ ChatNotifier: node_steps extraction failed: $e');
        }
      }

      // 3️⃣  Fallback: answer.summary (only if non-empty string)
      if (uiBlocks.isEmpty) {
        final summary = answer['summary']?.toString() ?? '';
        if (summary.isNotEmpty) {
          uiBlocks.add(BlockData(type: 'text', data: {'text': summary}));
          debugPrint('📥 ChatNotifier: Using answer.summary fallback');
        }
      }

      // 4️⃣  Fallback: answer.text
      if (uiBlocks.isEmpty) {
        final text = answer['text']?.toString() ?? '';
        if (text.isNotEmpty) {
          uiBlocks.add(BlockData(type: 'text', data: {'text': text}));
          debugPrint('📥 ChatNotifier: Using answer.text fallback');
        }
      }

      // 5️⃣  Last resort: stringify the whole answer so nothing is silently lost
      if (uiBlocks.isEmpty && answer.isNotEmpty) {
        uiBlocks.add(BlockData(type: 'text', data: {'text': answer.toString()}));
        debugPrint('📥 ChatNotifier: Using raw answer stringify fallback');
      }

      if (uiBlocks.isEmpty) {
        debugPrint('⚠️ ChatNotifier: No renderable content found in response');
      }

      // Derive a readable summary string for the ChatMessage.content field
      final contentSummary = answer['summary']?.toString().isNotEmpty == true
          ? answer['summary'].toString()
          : (uiBlocks.isNotEmpty && uiBlocks.first.data['text'] != null
              ? uiBlocks.first.data['text'].toString()
              : '');

      final botMessage = ChatMessage(
        id: messageId ?? DateTime.now().toString(),
        content: contentSummary,
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

      // Invalidate any pending stage timers before updating final state
      _stageToken++;
      state = state.copyWith(
        conversations: finalConversations,
        activeConversationId: currentId,
        isLoading: false,
        isGenerating: false,
        generationStage: null,
      );
      
      HomeWidgetService.updateWidget(title: 'New Insight', message: 'Analysis ready');

    } on DioException catch (e) {
      _pendingCancelToken = null;
      // User-initiated cancel: silently remove the loading bubble, no error shown
      if (e.type == DioExceptionType.cancel) {
        debugPrint('🛑 ChatNotifier: Request cancelled by user');
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
          _stageToken++;
          state = state.copyWith(
            conversations: updatedConversations,
            isLoading: false,
            isGenerating: false,
            generationStage: null,
          );
        } else {
          _stageToken++;
          state = state.copyWith(isLoading: false, isGenerating: false, generationStage: null);
        }
        return;
      }
      // Other Dio errors — fall through to generic handler
      debugPrint('❌ ChatNotifier: Dio error: ${e.message}');
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
        state = state.copyWith(
          conversations: updatedConversations,
          isLoading: false,
          isGenerating: false,
          generationStage: null,
          error: e.message,
        );
      } else {
        state = state.copyWith(isLoading: false, isGenerating: false, generationStage: null, error: e.message);
      }
    } catch (e) {
      _pendingCancelToken = null;
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
        state = state.copyWith(
          conversations: updatedConversations,
          isLoading: false,
          isGenerating: false,
        );
      } else {
        state = state.copyWith(isLoading: false, isGenerating: false);
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