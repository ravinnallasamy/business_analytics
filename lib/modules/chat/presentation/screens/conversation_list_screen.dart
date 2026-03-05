import 'package:flutter/material.dart';
import 'package:business_analytics_chat/modules/chat/presentation/widgets/sidebar.dart';
import 'package:business_analytics_chat/modules/chat/presentation/screens/empty_chat_screen.dart';

class ConversationListScreen extends StatelessWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800; // Same breakpoint as Shell

    if (isDesktop) {
      // On desktop, the Shell already shows the Sidebar.
      // So this route (/) corresponds to the "Content" area when no chat is selected.
      return const EmptyChatScreen();
    }

    // On mobile, this is the main screen showing the list.
    return const Scaffold(
      body: Sidebar(),
    );
  }
}
