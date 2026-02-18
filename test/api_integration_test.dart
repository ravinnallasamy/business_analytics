import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:business_analytics_chat/features/auth/services/auth_service.dart';
import 'package:business_analytics_chat/features/chat/data/conversation_repository.dart';
import 'package:business_analytics_chat/core/config/api_config.dart';

/// API Integration Test
/// 
/// This test file validates all 4 APIs:
/// 1. Login API
/// 2. Get All Conversations API
/// 3. Get Chat History API
/// 4. Send Question API
/// 
/// Run with: flutter test test/api_integration_test.dart

void main() {
  late Dio dio;
  late AuthService authService;
  late ConversationRepository conversationRepository;
  
  // Test credentials (replace with actual test credentials)
  const testEmail = 'shankar.nambiar@orientbell.com';
  const testPassword = 'your_password_here';  // UPDATE THIS
  
  setUp(() {
    dio = Dio();
    authService = AuthService(dio);
    conversationRepository = ConversationRepository(dio);
  });

  group('API Integration Tests', () {
    String? authToken;
    String? conversationId;

    test('1. Test API Endpoints Configuration', () {
      print('\n=== Testing API Configuration ===');
      print('Base URL: ${ApiConfig.baseUrl}');
      print('Login Endpoint: ${ApiConfig.loginEndpoint}');
      print('Conversations Endpoint: ${ApiConfig.getAllConversationsEndpoint}');
      print('Send Question Endpoint: ${ApiConfig.sendQuestionEndpoint}');
      
      expect(ApiConfig.baseUrl, isNotEmpty);
      expect(ApiConfig.loginEndpoint, isNotEmpty);
      expect(ApiConfig.sendQuestionEndpoint, isNotEmpty);
    });

    test('2. Test Login API', () async {
      print('\n=== Testing Login API ===');
      print('Endpoint: ${ApiConfig.loginEndpoint}');
      print('Email: $testEmail');
      
      try {
        final response = await dio.post(
          ApiConfig.loginEndpoint,
          data: {
            'email': testEmail,
            'password': testPassword,
          },
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );

        print('Status Code: ${response.statusCode}');
        print('Response: ${response.data}');

        expect(response.statusCode, 200);
        
        final data = response.data as Map<String, dynamic>;
        expect(data['status'], 1);
        expect(data['accessToken'], isNotNull);
        
        authToken = data['accessToken'] as String;
        print('✅ Login successful!');
        print('Token: ${authToken!.substring(0, 20)}...');
      } catch (e) {
        print('❌ Login failed: $e');
        if (e is DioException) {
          print('Status Code: ${e.response?.statusCode}');
          print('Response: ${e.response?.data}');
        }
        rethrow;
      }
    });

    test('3. Test Get All Conversations API', () async {
      print('\n=== Testing Get All Conversations API ===');
      print('Endpoint: ${ApiConfig.getAllConversationsEndpoint}');
      
      // Skip if no token
      if (authToken == null) {
        print('⚠️ Skipping - No auth token from login test');
        return;
      }

      try {
        final response = await dio.get(
          ApiConfig.getAllConversationsEndpoint,
          options: Options(
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
          ),
        );

        print('Status Code: ${response.statusCode}');
        print('Response Type: ${response.data.runtimeType}');
        print('Response: ${response.data}');

        expect(response.statusCode, 200);
        
        // Handle different response formats
        if (response.data is List) {
          final conversations = response.data as List;
          print('✅ Found ${conversations.length} conversations');
          
          if (conversations.isNotEmpty) {
            conversationId = conversations[0]['id'] ?? conversations[0]['conversation_id'];
            print('First conversation ID: $conversationId');
          }
        } else if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('conversations')) {
            final conversations = data['conversations'] as List;
            print('✅ Found ${conversations.length} conversations');
            
            if (conversations.isNotEmpty) {
              conversationId = conversations[0]['id'] ?? conversations[0]['conversation_id'];
              print('First conversation ID: $conversationId');
            }
          }
        }
      } catch (e) {
        print('❌ Get conversations failed: $e');
        if (e is DioException) {
          print('Status Code: ${e.response?.statusCode}');
          print('Response: ${e.response?.data}');
        }
        rethrow;
      }
    });

    test('4. Test Send Question API (New Conversation)', () async {
      print('\n=== Testing Send Question API (New Conversation) ===');
      print('Endpoint: ${ApiConfig.sendQuestionEndpoint}');
      
      // Skip if no token
      if (authToken == null) {
        print('⚠️ Skipping - No auth token from login test');
        return;
      }

      try {
        final response = await dio.post(
          ApiConfig.sendQuestionEndpoint,
          data: {
            'question': 'Show me the revenue and sales trends for the past 4 months',
            'conversation_id': null,  // New conversation
            'enable_cache': true,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
          ),
        );

        print('Status Code: ${response.statusCode}');
        print('Response: ${response.data}');

        expect(response.statusCode, 200);
        
        final data = response.data as Map<String, dynamic>;
        expect(data['conversation_id'], isNotNull);
        
        conversationId = data['conversation_id'] as String;
        print('✅ Question sent successfully!');
        print('New Conversation ID: $conversationId');
        print('Message ID: ${data['message_id']}');
        
        if (data.containsKey('answer')) {
          final answer = data['answer'];
          print('Answer Summary: ${answer['summary'] ?? 'N/A'}');
        }
      } catch (e) {
        print('❌ Send question failed: $e');
        if (e is DioException) {
          print('Status Code: ${e.response?.statusCode}');
          print('Response: ${e.response?.data}');
        }
        rethrow;
      }
    });

    test('5. Test Send Question API (Existing Conversation)', () async {
      print('\n=== Testing Send Question API (Existing Conversation) ===');
      print('Endpoint: ${ApiConfig.sendQuestionEndpoint}');
      
      // Skip if no token or conversation ID
      if (authToken == null) {
        print('⚠️ Skipping - No auth token from login test');
        return;
      }
      
      if (conversationId == null) {
        print('⚠️ Skipping - No conversation ID from previous test');
        return;
      }

      try {
        final response = await dio.post(
          ApiConfig.sendQuestionEndpoint,
          data: {
            'question': 'What about the previous month?',
            'conversation_id': conversationId,  // Existing conversation
            'enable_cache': true,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
          ),
        );

        print('Status Code: ${response.statusCode}');
        print('Response: ${response.data}');

        expect(response.statusCode, 200);
        
        final data = response.data as Map<String, dynamic>;
        expect(data['conversation_id'], conversationId);  // Same conversation
        
        print('✅ Follow-up question sent successfully!');
        print('Conversation ID: ${data['conversation_id']}');
        print('Message ID: ${data['message_id']}');
      } catch (e) {
        print('❌ Send follow-up question failed: $e');
        if (e is DioException) {
          print('Status Code: ${e.response?.statusCode}');
          print('Response: ${e.response?.data}');
        }
        rethrow;
      }
    });

    test('6. Test Get Chat History API', () async {
      print('\n=== Testing Get Chat History API ===');
      
      // Skip if no token or conversation ID
      if (authToken == null) {
        print('⚠️ Skipping - No auth token from login test');
        return;
      }
      
      if (conversationId == null) {
        print('⚠️ Skipping - No conversation ID from previous tests');
        return;
      }

      final endpoint = 'https://chatbot.fuzionest.com/api/conversations/$conversationId/messages';
      print('Endpoint: $endpoint');

      try {
        final response = await dio.get(
          endpoint,
          options: Options(
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
          ),
        );

        print('Status Code: ${response.statusCode}');
        print('Response: ${response.data}');

        expect(response.statusCode, 200);
        
        final data = response.data as Map<String, dynamic>;
        expect(data['success'], true);
        expect(data['messages'], isNotNull);
        
        final messages = data['messages'] as List;
        print('✅ Chat history retrieved successfully!');
        print('Total messages: ${data['total']}');
        print('Messages count: ${messages.length}');
        
        for (var i = 0; i < messages.length; i++) {
          final message = messages[i];
          print('\nMessage ${i + 1}:');
          print('  Role: ${message['role']}');
          print('  ID: ${message['message_id']}');
          
          if (message['role'] == 'user') {
            final contentJson = message['content_json'];
            print('  Question: ${contentJson['question']}');
          } else if (message['role'] == 'assistant') {
            final contentJson = message['content_json'];
            print('  Summary: ${contentJson['summary']}');
          }
        }
      } catch (e) {
        print('❌ Get chat history failed: $e');
        if (e is DioException) {
          print('Status Code: ${e.response?.statusCode}');
          print('Response: ${e.response?.data}');
        }
        rethrow;
      }
    });
  });

  group('Repository Tests', () {
    test('7. Test ConversationRepository.sendQuestion()', () async {
      print('\n=== Testing ConversationRepository ===');
      
      // This test requires manual token setup
      // You need to login first and save the token to secure storage
      
      print('⚠️ This test requires authentication token in Secure Storage');
      print('Please run the app and login first, then run this test');
      
      // Uncomment to test:
      // try {
      //   final response = await conversationRepository.sendQuestion(
      //     question: 'Show me sales data',
      //     conversationId: null,
      //     enableCache: true,
      //   );
      //   
      //   print('✅ Repository test successful!');
      //   print('Conversation ID: ${response['conversation_id']}');
      // } catch (e) {
      //   print('❌ Repository test failed: $e');
      // }
    });
  });
}
