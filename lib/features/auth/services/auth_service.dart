
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();
  static const String _tokenKey = 'auth_token';
  // Placeholder API URL - user must update
  static const String _baseUrl = 'http://127.0.0.1:8000/auth'; 

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<String> login(String email, String password) async {
    try {
      // Mock or real API call
      // Since user provided a specific token in previous steps, this might be a placeholder implementation
      // until the real /login endpoint is confirmed.
      
      // Real implementation would look like:
      /*
      final response = await _dio.post(
        '$_baseUrl/login',
        data: {'username': email, 'password': password}, // common OAuth2 form
      );
      if (response.statusCode == 200) {
        return response.data['access_token'];
      }
      */

      // For simulate succesful login with the previously provided token for testing:
      await Future.delayed(const Duration(seconds: 1)); // simulate network
      if (email.isNotEmpty && password.length > 3) {
         // Using the token from the user prompt as the valid token for now
         return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMzA5NTU3OGQtNTVkYS00NGI1LWExMDktNzZjZWY3ODU5MDAzIiwiZW1haWwiOiJzaGFua2FyLm5hbWJpYXJAb3JpZW50YmVsbC5jb20iLCJ1c2VyX25hbWUiOiJTaGFua2FyIE5hbWJpYXIiLCJhZ2VudF9pZCI6ImJhYWIyYTQyLWRkZjMtNGU4Zi05MjA4LTA3MGU3ZjZjYzFhMyIsImFnZW50X3JvbGUiOiJCcmFuY2ggTWFuYWdlciIsImFnZW50X3VzZXJfdW5pcXVlX2lkIjoiMTExMTMxOSIsImFnZW50X3VzZXJfcm9sZV9pZCI6Ijg5Y2M1MDdlLTcyYzUtNGI3Yi1iZTg0LTBlYzdlNGNlNmZiYSIsInJvbGUiOiJ1c2VyIiwic2NvcGUiOlsic2FsZXMucmVhZCJdLCJleHAiOjE3NzA5NjA1MzAsImlhdCI6MTc3MDg3NDEzMCwiaXNzIjoib3JpZW50YmVsbC1jaGF0Ym90In0.OyLXxhgaV7tay4PMyKB9HH8MYmugGdWee1rR51DEtKY';
      } else {
        throw Exception('Invalid credentials');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Optional: Check if token is expired (basic decoding or API check)
  bool isTokenExpired(String token) {
    // Basic JWT check could be done here (decode payload, check 'exp')
    // For now, we rely on API returning 401
    return false; 
  }
}
