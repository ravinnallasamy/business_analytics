import 'package:dio/dio.dart';

void main() async {
  print('🚀 Testing API Paths on api-chatbot.fuzionest.com...');
  
  final dio = Dio();
  // We need a token first
  final loginUrl = 'https://api-chatbot.fuzionest.com/auth/login';
  String? token;
  
  try {
     print('🔑 Logging in...');
     final loginResp = await dio.post(loginUrl, data: {
       'email': '1111319',
       'password': 'Orient@2025'
     });
     if (loginResp.statusCode == 200) {
       token = loginResp.data['accessToken'];
       print('✅ Got Token');
     }
  } catch (e) {
    print('❌ Login failed: $e');
    return;
  }

  // URLs to test
  final paths = [
    '/api/conversations',
    '/conversations',
    '/v1/conversations',
    '/api/v1/conversations',
    '/chat/conversations',
    '/api/v2/agent/conversations', // Try agent namespace
    '/v2/agent/conversations',
    '/agent/conversations',
    '/api/agent/conversations'
  ];

  final baseUrl = 'https://api-chatbot.fuzionest.com';

  for (final path in paths) {
    final url = '$baseUrl$path';
    print('\nTesting: $url');
    try {
      final resp = await dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print('✅ Status: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        print('🎉 FOUND IT! This path works on the main domain!');
      }
    } catch (e) {
      if (e is DioException) {
        print('❌ Status: ${e.response?.statusCode ?? 'Error'}');
      } else {
        print('❌ Error: $e');
      }
    }
  }
}
