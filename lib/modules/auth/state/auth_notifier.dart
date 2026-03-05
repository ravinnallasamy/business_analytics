
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:business_analytics_chat/modules/auth/services/auth_service.dart';
import 'package:business_analytics_chat/core/services/cache_service.dart';
import 'package:business_analytics_chat/modules/home_widget/home_widget_service.dart';
import 'package:business_analytics_chat/modules/chat/state/chat_state.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final authServiceProvider = Provider((ref) => AuthService());

class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    // Start the auth check asynchronously
    Future.microtask(() => _checkAuthStatus());
    // Return initial loading state
    return AuthState(isLoading: true); 
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Add timeout to prevent infinite loading
      await Future.any([
        _performAuthCheck(),
        Future.delayed(const Duration(seconds: 5), () {
          throw TimeoutException('Auth check timeout');
        }),
      ]);
    } catch (e) {
      // On timeout or any error, go to login
      print('Auth check error: $e');
      state = state.copyWith(isAuthenticated: false, isLoading: false);
    }
  }

  Future<void> _performAuthCheck() async {
    final token = await _authService.getToken();
    
    // If no token, go to login
    if (token == null || token.isEmpty) {
      state = state.copyWith(isAuthenticated: false, isLoading: false);
      return;
    }
    
    // Check if token is expired
    if (_authService.isTokenExpired(token)) {
      // Token expired, delete it and go to login
      await _authService.deleteToken();
      // Ensure widget also reflects this
      await HomeWidgetService.setLoginState(false);
      state = state.copyWith(isAuthenticated: false, isLoading: false);
      return;
    }
    
    // Token is valid, go to chat
    await _authService.extractAndSaveEmail(token);
    state = state.copyWith(isAuthenticated: true, isLoading: false);
    // Ensure widget knows we are logged in (sync check)
    await HomeWidgetService.setLoginState(true);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _authService.login(email, password);
      await _authService.saveToken(token);
      await _authService.extractAndSaveEmail(token);
      
      // Update widget state immediately
      await HomeWidgetService.setLoginState(true);
      
      state = state.copyWith(isAuthenticated: true, isLoading: false);
      
      // Prefetch conversations once authenticated
      ref.read(chatProvider.notifier).loadConversations();
    } catch (e) {
      state = state.copyWith(isAuthenticated: false, isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    // 1. Clear widget state IMMEDIATELY on logout
    await HomeWidgetService.setLoginState(false);
    
    // 2. Clear token and internal state
    await _authService.deleteToken();

    // 3. Clear weekly sales conversation ID persistence
    final storage = FlutterSecureStorage();
    await storage.delete(key: 'weekly_sales_conversation_id');

    try {
      // Clear all cache on logout to be safe
      await CacheService().clearAll();
    } catch (_) {}
    
    state = state.copyWith(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
