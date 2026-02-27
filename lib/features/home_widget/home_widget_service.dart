import 'package:business_analytics_chat/features/home_widget/home_widget_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:business_analytics_chat/features/home_widget/widget_data_service.dart';
import 'package:business_analytics_chat/core/routing/app_router.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Native called background task: $task");
    return await WidgetDataService.fetchAndUpdateWidget();
  });
}

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
      
      // Render the graph widget to an image so it can be shown natively
      await HomeWidget.renderFlutterWidget(
        HomeWidgetPlaceholder(message: message),
        key: 'widget_image',
        logicalSize: const Size(800, 400), // Larger resolution for better graph quality, scales down in Android ImageView
      );

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: 'HomeWidget', // Must match iOS Widget output name
      );
    } catch (e) {
      debugPrint("Error updating widget: $e");
    }
  }

  /// Initialize WorkManager for background updates
  static Future<void> initBackgroundService() async {
    if (kIsWeb) return;
    try {
      await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: kDebugMode 
      );
      await Workmanager().registerPeriodicTask(
          "1",
          "fetch_analytics_data",
          frequency: const Duration(minutes: 15),
          constraints: Constraints(
              networkType: NetworkType.connected,
          ),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
      
      // Fetch once immediately to populate widget without waiting 15 mins
      WidgetDataService.fetchAndUpdateWidget();
    } catch (e) {
       debugPrint("Error initializing background service: $e");
    }
  }

  /// Initialize and check if app was launched via widget
  static Future<void> init() async {
    if (kIsWeb) return; // Plugin not supported on web
    
    // Check if launched from widget
    final Uri? widgetUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (widgetUri != null) {
      _handleWidgetLaunch(widgetUri);
    }

    // Listen for widget clicks while app is in background/foreground
    HomeWidget.widgetClicked.listen((Uri? uri) {
      if (uri != null) {
        _handleWidgetLaunch(uri);
      }
    });
  }

  static void _handleWidgetLaunch(Uri uri) {
    // Android may pass homewidget://chat/new
    // Flutter might interpret the whole string. Normalize it to a path.
    String path = uri.path;
    
    // When uri is homewidget://chat/new
    if (uri.host == 'chat' && uri.path == '/new') {
      path = '/chat'; // '/chat' is the new chat screen in router
    } else if (uri.toString().contains('chat/new')) {
      path = '/chat';
    } else if (uri.host == 'chat' && uri.path == '/last') {
      // Legacy fallback just in case
      path = '/chat';
    }

    if (path == '/chat' || path == '/chat/last') {
       _navigateWhenReady('/chat');
    }
  }

  static Future<void> _navigateWhenReady(String path) async {
    // Wait for the context to become available (useful for cold starts)
    BuildContext? context;
    int retries = 0;
    while (context == null && retries < 20) {
      context = rootNavigatorKey.currentContext;
      if (context == null) {
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }
    }
    
    if (context != null) {
      // Ensure we are mounted
      if (context.mounted) {
         context.go(path); 
      }
    } else {
      debugPrint("Widget Launch Error: No running context to navigate to $path.");
    }
  }
}
