import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/app.dart';

import 'package:business_analytics_chat/modules/home_widget/home_widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidgetService.initBackgroundService();
  runApp(
    const ProviderScope(
      child: BusinessAnalyticsApp(),
    ),
  );
}
