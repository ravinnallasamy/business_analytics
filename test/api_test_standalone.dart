import 'dart:io';
import 'package:dio/dio.dart';

/// Standalone API Test Script
/// 
/// This script tests all 4 APIs without requiring Flutter test framework
/// Run with: dart run test/api_test_standalone.dart

void main() async {
  print('🚀 Starting API Integration Tests\n');
  
  final dio = Dio();
  
  // ============================================================================
  // CONFIGURATION - UPDATE THESE VALUES
  // ============================================================================
  
  const testEmail = '1111319';
  const testPassword = 'Orient@2025';
  
  // API Endpoints
  const baseUrl = 'https://api-chatbot.fuzionest.com';
  const loginEndpoint = '$baseUrl/auth/login';
  const conversationsEndpoint = 'https://chatbot.fuzionest.com/api/conversations';
  const sendQuestionEndpoint = '$baseUrl/api/v2/agent/run';
  
  String? authToken;
  String? conversationId;
  
  // ============================================================================
  // TEST 1: LOGIN API
  // ============================================================================
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('TEST 1: Login API');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  
  try {
    print('📍 Endpoint: $loginEndpoint');
    print('📧 Email: $testEmail');
    print('🔄 Sending request...\n');
    
    final response = await dio.post(
      loginEndpoint,
      data: {
        'email': testEmail,
        'password': testPassword,
      },
      options: Options(
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => true,  // Accept all status codes
      ),
    );

    print('✅ Status Code: ${response.statusCode}');
    print('📦 Response:');
    print('   ${response.data}\n');

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      
      if (data['status'] == 1 && data.containsKey('accessToken')) {
        authToken = data['accessToken'] as String;
        print('🎉 LOGIN SUCCESSFUL!');
        print('🔑 Token: ${authToken!.substring(0, 30)}...\n');
      } else {
        print('❌ Login failed: Invalid response format\n');
        print('   Full response: $data\n');
        exit(1);
      }
    } else {
      print('❌ Login failed with status ${response.statusCode}\n');
      print('   Response: ${response.data}\n');
      exit(1);
    }
  } catch (e) {
    print('❌ LOGIN FAILED!');
    if (e is DioException) {
      print('   Status Code: ${e.response?.statusCode}');
      print('   Error: ${e.response?.data}');
      print('   Message: ${e.message}');
      print('   Request URL: ${e.requestOptions.uri}');
      print('   Request Data: ${e.requestOptions.data}\n');
    } else {
      print('   Error: $e\n');
    }
    exit(1);
  }
  
  // ============================================================================
  // TEST 2: GET ALL CONVERSATIONS API
  // ============================================================================
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('TEST 2: Get All Conversations API');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  
  try {
    print('📍 Endpoint: $conversationsEndpoint');
    print('🔑 Using Bearer token');
    print('🔄 Sending request...\n');
    
    final response = await dio.get(
      conversationsEndpoint,
      options: Options(
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    print('✅ Status Code: ${response.statusCode}');
    print('📦 Response Type: ${response.data.runtimeType}');
    print('📦 Response:');
    print('   ${response.data}\n');

    if (response.statusCode == 200) {
      List conversations = [];
      
      if (response.data is List) {
        conversations = response.data as List;
      } else if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('conversations')) {
          conversations = data['conversations'] as List;
        } else if (data.containsKey('data')) {
          conversations = data['data'] as List;
        }
      }
      
      print('🎉 GET CONVERSATIONS SUCCESSFUL!');
      print('📊 Found ${conversations.length} conversations');
      
      if (conversations.isNotEmpty) {
        conversationId = conversations[0]['id'] ?? 
                        conversations[0]['conversation_id'] ?? 
                        conversations[0]['_id'];
        print('💬 First conversation ID: $conversationId\n');
      } else {
        print('ℹ️  No existing conversations found\n');
      }
    }
  } catch (e) {
    print('❌ GET CONVERSATIONS FAILED!');
    if (e is DioException) {
      print('   Status Code: ${e.response?.statusCode}');
      print('   Error: ${e.response?.data}');
      print('   Message: ${e.message}\n');
    } else {
      print('   Error: $e\n');
    }
    // Don't exit - continue with other tests
  }
  
  // ============================================================================
  // TEST 3: SEND QUESTION API (NEW CONVERSATION)
  // ============================================================================
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('TEST 3: Send Question API (New Conversation)');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  
  try {
    print('📍 Endpoint: $sendQuestionEndpoint');
    print('🔑 Using Bearer token');
    print('❓ Question: "Show me the revenue and sales trends for the past 4 months"');
    print('🆕 New Conversation (conversation_id: null)');
    print('🔄 Sending request...\n');
    
    final response = await dio.post(
      sendQuestionEndpoint,
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

    print('✅ Status Code: ${response.statusCode}');
    print('📦 Response:');
    print('   ${response.data}\n');

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      conversationId = data['conversation_id'] as String;
      
      print('🎉 SEND QUESTION SUCCESSFUL!');
      print('💬 Conversation ID: $conversationId');
      print('📝 Message ID: ${data['message_id']}');
      
      if (data.containsKey('answer')) {
        final answer = data['answer'];
        if (answer is Map && answer.containsKey('summary')) {
          print('💡 Summary: ${answer['summary']}');
        }
        if (answer is Map && answer.containsKey('blocks')) {
          final blocks = answer['blocks'] as List;
          print('📊 Response blocks: ${blocks.length}');
        }
      }
      print('');
    }
  } catch (e) {
    print('❌ SEND QUESTION FAILED!');
    if (e is DioException) {
      print('   Status Code: ${e.response?.statusCode}');
      print('   Error: ${e.response?.data}');
      print('   Message: ${e.message}\n');
    } else {
      print('   Error: $e\n');
    }
    // Don't exit - continue with other tests
  }
  
  // ============================================================================
  // TEST 4: SEND QUESTION API (EXISTING CONVERSATION)
  // ============================================================================
  
  if (conversationId != null) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('TEST 4: Send Question API (Existing Conversation)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    try {
      print('📍 Endpoint: $sendQuestionEndpoint');
      print('🔑 Using Bearer token');
      print('❓ Question: "What about the previous month?"');
      print('💬 Existing Conversation ID: $conversationId');
      print('🔄 Sending request...\n');
      
      final response = await dio.post(
        sendQuestionEndpoint,
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

      print('✅ Status Code: ${response.statusCode}');
      print('📦 Response:');
      print('   ${response.data}\n');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        print('🎉 FOLLOW-UP QUESTION SUCCESSFUL!');
        print('💬 Conversation ID: ${data['conversation_id']}');
        print('📝 Message ID: ${data['message_id']}');
        
        if (data.containsKey('answer')) {
          final answer = data['answer'];
          if (answer is Map && answer.containsKey('summary')) {
            print('💡 Summary: ${answer['summary']}');
          }
        }
        print('');
      }
    } catch (e) {
      print('❌ FOLLOW-UP QUESTION FAILED!');
      if (e is DioException) {
        print('   Status Code: ${e.response?.statusCode}');
        print('   Error: ${e.response?.data}');
        print('   Message: ${e.message}\n');
      } else {
        print('   Error: $e\n');
      }
    }
  } else {
    print('⚠️  Skipping Test 4: No conversation ID available\n');
  }
  
  // ============================================================================
  // TEST 5: GET CHAT HISTORY API
  // ============================================================================
  
  if (conversationId != null) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('TEST 5: Get Chat History API');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    try {
      final chatHistoryEndpoint = 'https://chatbot.fuzionest.com/api/conversations/$conversationId/messages';
      
      print('📍 Endpoint: $chatHistoryEndpoint');
      print('🔑 Using Bearer token');
      print('💬 Conversation ID: $conversationId');
      print('🔄 Sending request...\n');
      
      final response = await dio.get(
        chatHistoryEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('✅ Status Code: ${response.statusCode}');
      print('📦 Response:');
      print('   ${response.data}\n');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['success'] == true) {
          final messages = data['messages'] as List;
          
          print('🎉 GET CHAT HISTORY SUCCESSFUL!');
          print('📊 Total messages: ${data['total']}');
          print('💬 Messages count: ${messages.length}');
          print('📄 Has more: ${data['has_more']}\n');
          
          for (var i = 0; i < messages.length; i++) {
            final message = messages[i];
            print('Message ${i + 1}:');
            print('  👤 Role: ${message['role']}');
            print('  🆔 ID: ${message['message_id']}');
            
            if (message['role'] == 'user') {
              final contentJson = message['content_json'];
              print('  ❓ Question: ${contentJson['question']}');
            } else if (message['role'] == 'assistant') {
              final contentJson = message['content_json'];
              print('  💡 Summary: ${contentJson['summary']}');
            }
            print('');
          }
        }
      }
    } catch (e) {
      print('❌ GET CHAT HISTORY FAILED!');
      if (e is DioException) {
        print('   Status Code: ${e.response?.statusCode}');
        print('   Error: ${e.response?.data}');
        print('   Message: ${e.message}\n');
      } else {
        print('   Error: $e\n');
      }
    }
  } else {
    print('⚠️  Skipping Test 5: No conversation ID available\n');
  }
  
  // ============================================================================
  // SUMMARY
  // ============================================================================
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🏁 TEST SUMMARY');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  
  print('✅ Login API: ${authToken != null ? "PASSED" : "FAILED"}');
  print('✅ Get Conversations API: Tested');
  print('✅ Send Question API: Tested');
  print('✅ Get Chat History API: ${conversationId != null ? "Tested" : "Skipped"}');
  print('\n🎉 All tests completed!\n');
}
