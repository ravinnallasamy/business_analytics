
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/auth/services/auth_service.dart';

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
    _checkAuthStatus();
    return AuthState(isLoading: true); 
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _authService.getToken();
      if (token != null && !_authService.isTokenExpired(token)) {
         state = state.copyWith(isAuthenticated: true, isLoading: false);
      } else {
        await _authService.deleteToken();
        state = state.copyWith(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isAuthenticated: false, isLoading: false, error: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _authService.login(email, password);
      await _authService.saveToken(token);
      state = state.copyWith(isAuthenticated: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isAuthenticated: false, isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _authService.deleteToken();
    state = state.copyWith(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
