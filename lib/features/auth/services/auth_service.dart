
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:business_analytics_chat/core/config/api_config.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();
  static const String _tokenKey = 'auth_token';

  AuthService() {
    _dio.options.baseUrl = ApiConfig.authBaseUrl;
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
    _dio.options.sendTimeout = ApiConfig.sendTimeout;
  }

  /// Save access token to secure storage
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Retrieve access token from secure storage
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Delete access token from secure storage
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Login with email and password
  /// Returns the access token on success
  Future<String> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.loginEndpoint,  // Use full endpoint URL
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      // Handle successful response
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Check status field (1 = success)
        if (data['status'] == 1) {
          // Extract accessToken from response
          final token = data['accessToken'];
          
          if (token == null || token.toString().isEmpty) {
            throw Exception('No access token received from server');
          }
          
          return token.toString();
        } else {
          // Status is not 1, login failed
          final message = data['message'] ?? 'Login failed';
          throw Exception(message);
        }
      } else {
        throw Exception('Login failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Invalid request';
        throw Exception(message);
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server response timeout. Please try again.');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error during login: $e');
    }
  }

  /// Check if the token is expired
  /// Returns true if token is expired or invalid
  bool isTokenExpired(String token) {
    try {
      // Decode and check expiration
      return JwtDecoder.isExpired(token);
    } catch (e) {
      // If we can't decode the token, consider it expired/invalid
      return true;
    }
  }

  /// Validate if token exists and is not expired
  Future<bool> isAuthenticated() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return false;
      }
      return !isTokenExpired(token);
    } catch (e) {
      return false;
    }
  }

  /// Get decoded token data
  Map<String, dynamic>? getTokenData(String token) {
    try {
      return JwtDecoder.decode(token);
    } catch (e) {
      return null;
    }
  }
}
