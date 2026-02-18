import 'package:flutter/material.dart';
import 'package:business_analytics_chat/features/chat/presentation/widgets/sidebar.dart';

class ScaffoldWithSidebar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithSidebar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sidebar as drawer (can be opened programmatically if needed)
      endDrawer: Drawer(
        width: 300,
        child: const Sidebar(),
      ),
      // Main content
      body: child,
    );
  }
}
