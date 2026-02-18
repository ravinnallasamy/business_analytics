import 'package:dio/dio.dart';
import 'package:business_analytics_chat/core/config/api_config.dart';
import 'package:business_analytics_chat/core/services/cache_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Repository for managing conversations with CLIENT-SIDE CACHING
class ConversationRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final CacheService _cache = CacheService();

  ConversationRepository(this._dio);

  // --- Helpers ---
  Future<String?> _getUserId(String token) async {
    try {
      final decoded = JwtDecoder.decode(token);
      return decoded['user_id'] ?? decoded['sub'] ?? decoded['id'];
    } catch (_) {
      return null;
    }
  }

  // --- CACHE KEYS ---
  String _conversationsKey(String userId) => 'conversations_$userId';
  String _historyKey(String userId, String convId) => 'history_${userId}_$convId';

  /// Clear user cache
  Future<void> clearCache() async {
    await _cache.clearAll();
  }

  // --- API + CACHE LOGIC ---

  /// Fetch Cached Conversations (Fast)
  Future<List<Map<String, dynamic>>?> getCachedConversations() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return null;
      
      final userId = await _getUserId(token);
      if (userId == null) return null;

      final cached = await _cache.get(_conversationsKey(userId));
      if (cached != null) {
        debugPrint('📦 Cache Hit: Conversations ($userId)');
        return List<Map<String, dynamic>>.from(cached);
      }
    } catch (_) {}
    return null;
  }

  /// Fetch all conversations from the API and refresh cache
  Future<List<Map<String, dynamic>>> getAllConversations() async {
    try {
      debugPrint('🌐 ConversationRepository: Fetching all conversations...');
      // Get token from secure storage
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null || token.isEmpty) {
        debugPrint('❌ ConversationRepository: No auth token found');
        throw Exception('No authentication token found');
      }

      final userId = await _getUserId(token);

      debugPrint('🌐 ConversationRepository: Fetching from: ${ApiConfig.getAllConversationsEndpoint}');

      // Make API request with Bearer token
      final response = await _dio.get(
        ApiConfig.getAllConversationsEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('✅ ConversationRepository: getAllConversations response code: ${response.statusCode}');

      // Handle successful response
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Handle different response formats
        List<Map<String, dynamic>> conversations = [];
        if (data is List) {
          conversations = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('conversations')) {
          conversations = List<Map<String, dynamic>>.from(data['conversations']);
        } else if (data is Map && data.containsKey('data')) {
          conversations = List<Map<String, dynamic>>.from(data['data']);
        }
        
        debugPrint('✅ ConversationRepository: Found ${conversations.length} conversations');

        // CACHE UPDATE
        if (userId != null) {
          try {
            await _cache.set(
              _conversationsKey(userId), 
              conversations, 
              const Duration(minutes: 10),
            );
          } catch (e) {
            debugPrint('⚠️ ConversationRepository: Cache update failed: $e');
          }
        }

        return conversations;
      } else {
        debugPrint('❌ ConversationRepository: Failed to fetch conversations: ${response.statusCode}');
        throw Exception('Failed to fetch conversations: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ ConversationRepository: getAllConversations failed: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        // Fallback: If network fails, try returning cache if caller hasn't tried already
        // Ideally, caller manages this, but repo throws so caller can decide
        throw Exception('Failed to fetch conversations: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ ConversationRepository: Unexpected error in getAllConversations: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetch Cached Chat History
  Future<Map<String, dynamic>?> getCachedHistory(String conversationId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return null;
      
      final userId = await _getUserId(token);
      if (userId == null) return null;

      final cached = await _cache.get(_historyKey(userId, conversationId));
      if (cached != null) {
        debugPrint('📦 Cache Hit: History ($conversationId)');
        return cached as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Fetch chat history for a specific conversation
  Future<Map<String, dynamic>> getChatHistory(String conversationId) async {
    try {
      debugPrint('🌐 ConversationRepository: Fetching history for $conversationId...');
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null || token.isEmpty) throw Exception('No authentication token found');
      
      final userId = await _getUserId(token);

      final endpoint = ApiConfig.getChatHistoryEndpoint(conversationId);
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        if (!data.containsKey('success') || data['success'] != true) {
          throw Exception('API returned unsuccessful response');
        }
       
        // CACHE UPDATE
        if (userId != null) {
          try {
            await _cache.set(
              _historyKey(userId, conversationId), 
              data, 
              const Duration(days: 1),
            );
          } catch (e) {
            debugPrint('⚠️ ConversationRepository: History cache update failed: $e');
          }
        }

        return data;
      } else {
        throw Exception('Failed to fetch chat history: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw Exception('Unauthorized: Please login again');
      if (e.response?.statusCode == 404) throw Exception('Conversation not found');
      throw Exception('Failed to fetch chat history: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Send a question to the agent
  Future<Map<String, dynamic>> sendQuestion({
    required String question,
    String? conversationId,  // null for new conversation
    bool enableCache = true,
  }) async {
    try {
      debugPrint('🌐 ConversationRepository: Sending question: "$question" (ConversationID: $conversationId)');
      // Get token from secure storage
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // Build request body
      final requestBody = {
        'question': question,
        'conversation_id': conversationId,  // null for new conversation
        'enable_cache': enableCache,
      };

      debugPrint('🌐 ConversationRepository: Posting to: ${ApiConfig.sendQuestionEndpoint}');

      // Make API request with Bearer token
      final response = await _dio.post(
        ApiConfig.sendQuestionEndpoint,
        data: requestBody,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('✅ ConversationRepository: sendQuestion response code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        // Note: No caching here as the question response is dynamic and context specific.
        // It will be cached when we refresh history or conversation list next time.
        return data;
      } else {
        debugPrint('❌ ConversationRepository: Failed to send question: ${response.statusCode}');
        throw Exception('Failed to send question: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ ConversationRepository: sendQuestion failed: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server response timeout. The question is taking longer than expected.');
      } else {
        throw Exception('Failed to send question: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ ConversationRepository: Unexpected error in sendQuestion: $e');
      throw Exception('Unexpected error: $e');
    }
  }


  /// Parse messages from chat history response
  /// 
  /// Extracts and formats messages for display
  List<Map<String, dynamic>> parseMessages(Map<String, dynamic> chatHistory) {
    if (!chatHistory.containsKey('messages')) {
      return [];
    }

    final messages = chatHistory['messages'] as List;
    return List<Map<String, dynamic>>.from(messages);
  }

  /// Get message content for display
  /// 
  /// Handles both user and assistant messages
  String getMessageContent(Map<String, dynamic> message) {
    final role = message['role'] as String;
    final contentJson = message['content_json'] as Map<String, dynamic>;

    if (role == 'user') {
      // User message: extract question
      return contentJson['question'] as String? ?? 
             contentJson['reconstructed_intent'] as String? ?? 
             'User message';
    } else if (role == 'assistant') {
      // Assistant message: extract summary or first text block
      if (contentJson.containsKey('summary')) {
        return contentJson['summary'] as String;
      }
      
      if (contentJson.containsKey('blocks')) {
        final blocks = contentJson['blocks'] as List;
        for (var block in blocks) {
          if (block['type'] == 'text') {
            return block['content'] as String;
          }
        }
      }
      
      return 'Assistant response';
    }

    return 'Message';
  }

  /// Get suggestions from assistant message
  /// 
  /// Returns list of suggestion strings
  List<String> getSuggestions(Map<String, dynamic> message) {
    if (message['role'] != 'assistant') {
      return [];
    }

    final contentJson = message['content_json'] as Map<String, dynamic>;
    
    if (!contentJson.containsKey('blocks')) {
      return [];
    }

    final blocks = contentJson['blocks'] as List;
    
    for (var block in blocks) {
      if (block['type'] == 'suggestions' && block.containsKey('items')) {
        return List<String>.from(block['items']);
      }
    }

    return [];
  }

  /// Get all content blocks from assistant message
  /// 
  /// Returns list of blocks (text, suggestions, charts, etc.)
  List<Map<String, dynamic>> getContentBlocks(Map<String, dynamic> message) {
    if (message['role'] != 'assistant') {
      return [];
    }

    final contentJson = message['content_json'] as Map<String, dynamic>;
    
    if (!contentJson.containsKey('blocks')) {
      return [];
    }

    final blocks = contentJson['blocks'] as List;
    return List<Map<String, dynamic>>.from(blocks);
  }
}
