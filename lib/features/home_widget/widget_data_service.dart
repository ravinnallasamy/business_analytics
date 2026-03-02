import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:business_analytics_chat/core/config/api_config.dart';
import 'package:business_analytics_chat/features/home_widget/home_widget_service.dart';
import 'package:flutter/foundation.dart';

class WidgetDataService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final Dio _dio = Dio();

  /// background task entry point logic
  static Future<bool> fetchAndUpdateWidget() async {
    try {
      debugPrint("WidgetDataService: Starting background fetch...");

      // 1. Get Token
      final token = await _storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        await HomeWidgetService.updateWidget(
          title: "Past Week Sales",
          message: "Please login to view past week sales.",
        );
        return true;
      }

      // 2. Configure Dio
      // BaseUrl not set here, we use full path in request
      
      _dio.options.headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      // 3. Make Request
      // Question: Asking for this week's sales summary
      const question = "What's about the sales of this week? Give me a very short text summary.";
      
      final response = await _dio.post(
        ApiConfig.sendQuestionEndpoint,
        data: {
          "question": question,
          "conversation_id": null,
          "enable_cache": true,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final summary = _parseSummaryFromResponse(data is Map ? Map<String, dynamic>.from(data) : {});
        
        await HomeWidgetService.updateWidget(
          title: "Past Week Sales",
          message: summary,
        );
        debugPrint("WidgetDataService: Widget updated with: $summary");
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint("WidgetDataService: Auth error ${response.statusCode}. Updating state to logged out.");
        await HomeWidgetService.setLoginState(false);
        return false;
      } else {
        debugPrint("WidgetDataService: API error ${response.statusCode}");
        return false;
      }

    } catch (e) {
      debugPrint("WidgetDataService: Error: $e. Keeping cached data.");
      return false;
    }
  }

  static String _parseSummaryFromResponse(Map<String, dynamic> json) {
    try {
      if (json['answer'] != null && json['answer'] is Map) {
        final answer = json['answer'];
        final String summary = answer['summary']?.toString() ?? "";
        final List blocks = answer['blocks'] is List ? answer['blocks'] : [];

        // Combine summary and all text blocks to search for the value
        String combinedText = summary;
        for (var block in blocks) {
          if (block is Map && block['type'] == 'text' && block['content'] != null) {
            combinedText += " " + block['content'].toString();
          }
        }

        // Regex to match [number][optional decimals] + optional space + Lacs
        // We look for the first occurrence as the source of truth
        final RegExp regex = RegExp(r'(\d+(?:\.\d+)?)\s*Lacs', caseSensitive: false);
        final match = regex.firstMatch(combinedText);

        if (match != null) {
          return match.group(0)!; // Returns "82.06 Lacs"
        }
      }
      return "---"; // Return "---" instead of garbage if parsing fails
    } catch (e) {
      debugPrint("WidgetDataService: Parsing error: $e");
      return "---";
    }
  }
}
