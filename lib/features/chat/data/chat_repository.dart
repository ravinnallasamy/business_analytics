import 'package:dio/dio.dart';
import 'package:business_analytics_chat/features/chat/domain/chat_models.dart';
import 'package:business_analytics_chat/core/network/auth_interceptor.dart';
import 'package:business_analytics_chat/core/config/api_config.dart';

class ChatRepository {
  final Dio _dio = Dio();

  ChatRepository({required Function() onUnauthorized}) {
    _dio.options.baseUrl = ApiConfig.chatBaseUrl;
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
    _dio.options.headers = {
      'Content-Type': 'application/json',
    };
    _dio.interceptors.add(AuthInterceptor(onUnauthorized: onUnauthorized));
  }

  Future<ChatResponse> sendMessage(String question, String? conversationId) async {
    try {
      final response = await _dio.post(
        '', // Empty string because baseUrl already points to chat endpoint
        data: {
          "question": question,
          "conversation_id": conversationId,
          "enable_cache": true,
        },
      );
      
      return ChatResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Request cancelled: ${e.error}');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid request: ${e.response?.data['message'] ?? 'Bad request'}');
      } else {
        throw Exception('Failed to send message: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
