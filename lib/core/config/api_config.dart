import 'package:flutter/foundation.dart';

/// ============================================================================
/// API Configuration - All Backend Endpoints
/// ============================================================================
///
/// HOW CORS WORKS ON WEB:
/// When running as Flutter Web, the browser enforces CORS. The backend at
/// chatbot.fuzionest.com must return `Access-Control-Allow-Origin: *` headers.
///
/// FOR DEVELOPMENT: Run the app with CORS disabled:
///   flutter run -d chrome --web-browser-flag "--disable-web-security"
///
/// OR run the local CORS proxy (cors_proxy.js) and set useProxy = true below.
///
/// FOR PRODUCTION: The backend team must add CORS headers to the API server.
/// ============================================================================

class ApiConfig {
  // ── Toggle this to true when running cors_proxy.js locally ────────────────
  static const bool _useLocalProxy = false;
  static const String _proxyBase = 'http://localhost:8080';

  // ── Real backend URLs ──────────────────────────────────────────────────────
  static const String _realApiChatbotBase = 'https://api-chatbot.fuzionest.com';
  static const String _realChatbotBase    = 'https://chatbot.fuzionest.com';

  // ── Resolved base URLs (proxy-aware) ──────────────────────────────────────
  static String get _apiChatbotBase =>
      (_useLocalProxy && kIsWeb) ? '$_proxyBase/api-chatbot' : _realApiChatbotBase;

  static String get _chatbotBase =>
      (_useLocalProxy && kIsWeb) ? '$_proxyBase/chatbot' : _realChatbotBase;

  // ── Auth ───────────────────────────────────────────────────────────────────
  static String get authBaseUrl => '$_apiChatbotBase/auth';

  // ── Conversation base (for sidebar + history) ──────────────────────────────
  static String get conversationBaseUrl => '$_chatbotBase/api';

  // ── Legacy (kept for backward compatibility) ───────────────────────────────
  static String get chatBaseUrl => '$_apiChatbotBase/api';

  // ============================================================================
  // API 1: LOGIN
  // ============================================================================
  /// POST /auth/login
  /// Body: { "email": "1111319", "password": "Orient" }
  /// Response: { "status": 1, "accessToken": "..." }
  static String get loginEndpoint => '$_apiChatbotBase/auth/login';

  // ============================================================================
  // API 2: GET ALL CONVERSATIONS (Sidebar)
  // ============================================================================
  /// GET /api/conversations
  /// Headers: Authorization: Bearer <token>
  static String get getAllConversationsEndpoint => '$_chatbotBase/api/conversations';

  // ============================================================================
  // API 3: SEND QUESTION / GET ANSWER
  // ============================================================================
  /// POST /api/v2/agent/run
  /// Body: { "question": "...", "conversation_id": null, "enable_cache": true }
  static String get sendQuestionEndpoint => '$_apiChatbotBase/api/v2/agent/run';

  // ============================================================================
  // API 4: GET CHAT HISTORY
  // ============================================================================
  /// GET /api/conversations/:id/messages
  static String getChatHistoryEndpoint(String conversationId) =>
      '$_chatbotBase/api/conversations/$conversationId/messages';

  // ============================================================================
  // API 5: RENAME / DELETE CONVERSATION
  // ============================================================================
  /// PATCH /api/conversations/:id
  static String renameConversationEndpoint(String conversationId) =>
      '$_chatbotBase/api/conversations/$conversationId';

  /// DELETE /api/conversations/:id
  static String deleteConversationEndpoint(String conversationId) =>
      '$_chatbotBase/api/conversations/$conversationId';

  /// DELETE /api/conversations
  static String get deleteAllConversationsEndpoint =>
      '$_chatbotBase/api/conversations';

  // ============================================================================
  // TIMEOUTS
  // ============================================================================
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 60); // AI responses can be slow
  static const Duration sendTimeout    = Duration(seconds: 15);

  // ============================================================================
  // HELPERS
  // ============================================================================
  static bool get isDevelopment =>
      _realApiChatbotBase.contains('localhost') ||
      _realApiChatbotBase.contains('127.0.0.1');

  static bool get isProduction => !isDevelopment;
  static String get environment => isDevelopment ? 'Development' : 'Production';
}
