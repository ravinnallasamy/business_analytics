import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/foundation.dart'; // Add this import

class HomeWidgetService {
  static const String appGroupId = 'group.business_analytics_chat'; // Use your actual App Group ID
  static const String androidWidgetName = 'HomeWidgetProvider'; // Must match Android XML

  /// Save data to be displayed in the widget
  static Future<void> updateWidget({
    required String title,
    required String message,
  }) async {
    if (kIsWeb) return; // Plugin not supported on web
    try {
      await HomeWidget.saveWidgetData<String>('title', title);
      await HomeWidget.saveWidgetData<String>('message', message);
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: 'HomeWidget', // Must match iOS Widget output name
      );
    } catch (e) {
      debugPrint("Error updating widget: $e");
    }
  }

  /// Initialize and check if app was launched via widget
  static Future<void> init(BuildContext context) async {
    if (kIsWeb) return; // Plugin not supported on web
    
    // Check if launched from widget
    final Uri? widgetUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (widgetUri != null) {
      _handleWidgetLaunch(context, widgetUri);
    }

    // Listen for widget clicks while app is in background/foreground
    HomeWidget.widgetClicked.listen((Uri? uri) {
      if (uri != null) {
        _handleWidgetLaunch(context, uri);
      }
    });
  }

  static void _handleWidgetLaunch(BuildContext context, Uri uri) {
    if (uri.path == '/chat/last') {
      context.go('/chat/last'); 
    }
  }
}
