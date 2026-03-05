import 'package:flutter/material.dart';
import 'package:business_analytics_chat/modules/chat/presentation/widgets/sidebar.dart';

class ScaffoldWithSidebar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithSidebar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    
    return Scaffold(
      drawer: isDesktop ? null : const Drawer(width: 300, child: Sidebar()),
      body: Row(
        children: [
          if (isDesktop)
            const SizedBox(
              width: 300,
              child: Sidebar(),
            ),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
