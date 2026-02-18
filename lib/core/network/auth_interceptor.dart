
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Interceptor that automatically adds authentication token to requests
/// and handles 401 unauthorized responses
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Function() onUnauthorized;

  AuthInterceptor({required this.onUnauthorized});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      if (token != null && token.isNotEmpty) {
        // Check if token is expired before making the request
        if (_isTokenExpired(token)) {
          // Token is expired, trigger logout
          onUnauthorized();
          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Token expired',
              type: DioExceptionType.cancel,
            ),
          );
          return;
        }
        
        // Add valid token to request headers
        options.headers['Authorization'] = 'Bearer $token';
      }
      
      handler.next(options);
    } catch (e) {
      // If there's an error reading the token, proceed without it
      handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid - trigger logout
      onUnauthorized();
    }
    handler.next(err);
  }

  /// Check if JWT token is expired
  bool _isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      // If we can't decode the token, consider it expired
      return true;
    }
  }
}
