import 'package:dio/dio.dart';
import 'package:business_analytics_chat/features/chat/domain/chat_models.dart';
import 'package:business_analytics_chat/core/network/auth_interceptor.dart';

class ChatRepository {
  final Dio _dio = Dio();
  
  static const String _apiUrl = 'http://127.0.0.1:8000/chat'; // Placeholder, user needs to update

  ChatRepository({required Function() onUnauthorized}) {
    _dio.options.headers = {
      'Content-Type': 'application/json',
    };
    _dio.interceptors.add(AuthInterceptor(onUnauthorized: onUnauthorized));
  }

  Future<ChatResponse> sendMessage(String question, String? conversationId) async {
    try {
      final response = await _dio.post(
        _apiUrl, // This needs to be checked
        data: {
          "question": question,
          "conversation_id": conversationId, // Null for new conversation
          "enable_cache": true,
        },
      );
      
      return ChatResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}
