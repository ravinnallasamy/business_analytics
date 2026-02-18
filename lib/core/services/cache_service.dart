
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle local caching using SharedPreferences (Web/Mobile Safe)
class CacheService {
  static final CacheService _instance = CacheService._internal();

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  /// Save data to cache
  Future<void> set(String key, dynamic data, Duration ttl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiration = DateTime.now().add(ttl).millisecondsSinceEpoch;
      
      final cacheObject = {
        'expires_at': expiration,
        'data': data,
      };

      await prefs.setString('cache_$key', jsonEncode(cacheObject));
    } catch (e) {
      debugPrint('⚠️ CacheService: Failed to write cache for $key: $e');
    }
  }

  /// Retrieve data from cache
  Future<dynamic> get(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString('cache_$key');
      
      if (content == null) return null;

      final cacheObject = jsonDecode(content);

      if (DateTime.now().millisecondsSinceEpoch > cacheObject['expires_at']) {
        // Expired, delete it
        await prefs.remove('cache_$key');
        return null;
      }

      return cacheObject['data'];
    } catch (e) {
      debugPrint('⚠️ CacheService: Failed to read from cache for $key: $e');
      return null;
    }
  }

  /// Remove specific cache entry
  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_$key');
    } catch (e) {
      debugPrint('⚠️ CacheService: Failed to remove cache for $key: $e');
    }
  }

  /// Clear all cache files
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('⚠️ CacheService: Failed to clear all cache: $e');
    }
  }
}
