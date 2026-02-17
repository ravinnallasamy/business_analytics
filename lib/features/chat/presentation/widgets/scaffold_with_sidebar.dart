import 'package:flutter/material.dart';
import 'package:business_analytics_chat/features/chat/presentation/widgets/sidebar.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class ScaffoldWithSidebar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithSidebar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800; // Breakpoint

    if (!isDesktop) {
      return child;
    }

    return Scaffold(
      body: Row(
        children: [
          const SizedBox(
            width: UIConstants.sidebarWidth,
            child: Sidebar(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
