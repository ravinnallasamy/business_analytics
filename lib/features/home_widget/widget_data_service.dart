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
        debugPrint("WidgetDataService: Auth error ${response.statusCode}");
        HomeWidgetService.updateWidget(
            title: "Past Week Sales",
            message: "Session expired. Please login."
        );
        return false;
      } else {
        debugPrint("WidgetDataService: API error ${response.statusCode}");
        HomeWidgetService.updateWidget(
            title: "Past Week Sales",
            message: "Unable to update data."
        );
        return false;
      }

    } catch (e) {
      debugPrint("WidgetDataService: Error: $e");
      HomeWidgetService.updateWidget(
          title: "Business Analytics",
          message: "Data refresh failed: $e"
      );
      return false;
    }
  }

  static String _parseSummaryFromResponse(Map<String, dynamic> json) {
    try {
      if (json['answer'] != null && json['answer'] is Map) {
          final answer = json['answer'];

          // 1. Aggressively search for actual numerical metrics first
          // because the 'summary' is often just a generic greeting ("Hello Shankar...")
          if (answer['blocks'] != null && answer['blocks'] is List) {
            final List blocks = answer['blocks'];
            List<String> metricStrings = [];
            
            for (var block in blocks) {
               if (block is Map && block['type'] == 'metric' && block['metrics'] is List) {
                 final List metrics = block['metrics'];
                 for (var metric in metrics) {
                   if (metric is Map && metric['label'] != null && metric['value'] != null) {
                     metricStrings.add("${metric['label']}: ${metric['value']}");
                   }
                 }
               }
            }
            // If we found any actual data numbers, return them joined!
            if (metricStrings.isNotEmpty) {
               return metricStrings.join('\n');
            }
            
            // 2. If no metrics, look for a text block that might contain the data
            for (var block in blocks) {
               if (block is Map && block['type'] == 'text' && block['content'] != null) {
                 final content = block['content'].toString();
                 // Ignore if it's just a greeting repetition
                 if (!content.toLowerCase().contains("here's the sales summary")) {
                    return content;
                 }
               }
            }
          }

          // 3. Fallback to summary ONLY if we didn't find any real blocks
          if (answer['summary'] != null && answer['summary'].toString().isNotEmpty) {
             return answer['summary'].toString();
          }
      }
      return "Fetching latest insights...";
    } catch (e) {
      return "Data format error.";
    }
  }
}
