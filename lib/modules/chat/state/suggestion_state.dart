import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:business_analytics_chat/core/config/api_config.dart';
import 'package:business_analytics_chat/core/network/auth_interceptor.dart';
import 'dart:async';

class SuggestionItem {
  final String question;
  final String? toolId;

  SuggestionItem({required this.question, this.toolId});
}

class SuggestionState {
  final List<SuggestionItem> suggestions;
  final bool isLoading;
  final String? error;

  SuggestionState({
    this.suggestions = const <SuggestionItem>[],
    this.isLoading = false,
    this.error,
  });

  SuggestionState copyWith({
    List<SuggestionItem>? suggestions,
    bool? isLoading,
    String? error,
  }) {
    return SuggestionState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SuggestionNotifier extends StateNotifier<SuggestionState> {
  final Dio _dio = Dio();
  Timer? _debounce;
  CancelToken? _cancelToken;
  
  // Simple in-memory cache
  final Map<String, List<SuggestionItem>> _cache = {};

  SuggestionNotifier({required Function() onUnauthorized}) : super(SuggestionState()) {
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
    _dio.interceptors.add(AuthInterceptor(onUnauthorized: onUnauthorized));
  }

  Future<void> fetchSuggestions(String query) async {
    final trimmed = query.trim();
    
    // Stop API call and hide suggestions if input length < 3
    if (trimmed.length < 3) {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _cancelToken?.cancel("New request started");
      state = state.copyWith(suggestions: <SuggestionItem>[], isLoading: false);
      return;
    }

    // Reuse cached results if available
    if (_cache.containsKey(trimmed)) {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _cancelToken?.cancel("New request started");
      state = state.copyWith(suggestions: _cache[trimmed], isLoading: false);
      return;
    }

    // Debounce control of 400 milliseconds
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      // Cancel previous in-flight request
      _cancelToken?.cancel("New request started");
      _cancelToken = CancelToken();
      
      state = state.copyWith(isLoading: true, error: null);

      try {
        final response = await _dio.get(
          ApiConfig.suggestEndpoint,
          queryParameters: {
            'q': trimmed,
            'limit': 5,
          },
          cancelToken: _cancelToken,
        );

        List<SuggestionItem> results = <SuggestionItem>[];
        if (response.data is Map && response.data['suggestions'] != null) {
          final List suggestionsList = response.data['suggestions'];
          results = suggestionsList.map<SuggestionItem>((s) {
            if (s is Map) {
              return SuggestionItem(
                question: (s['question'] ?? '').toString(),
                toolId: s['tool_id']?.toString(),
              );
            }
            return SuggestionItem(question: s.toString());
          }).toList();
        }

        // Cache the results
        _cache[trimmed] = results;

        state = state.copyWith(
          suggestions: results,
          isLoading: false,
        );
      } catch (e) {
        // Handle errors silently
        if (e is DioException && CancelToken.isCancel(e)) {
          return;
        }
        state = state.copyWith(isLoading: false, suggestions: <SuggestionItem>[]);
      }
    });
  }

  void clear() {
    state = SuggestionState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }
}

final suggestionProvider = StateNotifierProvider<SuggestionNotifier, SuggestionState>((ref) {
  return SuggestionNotifier(onUnauthorized: () {});
});
