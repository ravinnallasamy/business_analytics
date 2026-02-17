import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:business_analytics_chat/features/chat/presentation/widgets/message_view.dart';
import 'package:business_analytics_chat/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:business_analytics_chat/features/chat/presentation/widgets/sidebar.dart';
import 'package:business_analytics_chat/features/chat/presentation/blocks/suggestions_block.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String? conversationId;

  const ConversationScreen({super.key, this.conversationId});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  @override
  void initState() {
    super.initState();
    // Defer state update to allow build to finish
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.conversationId == 'last') {
        // Fetch last conversation
        // For now, no-op or select most recent
        debugPrint("Opening last conversation requested");
      } else if (widget.conversationId != null) {
        ref.read(chatProvider.notifier).selectConversation(widget.conversationId!);
      } else {
        // New conversation state
        ref.read(chatProvider.notifier).clearActiveConversation();
      }
    });
  }

  @override
  void didUpdateWidget(ConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conversationId != oldWidget.conversationId) {
      // Logic for changing conversation
       WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.conversationId != null) {
          ref.read(chatProvider.notifier).selectConversation(widget.conversationId!);
        } else {
          ref.read(chatProvider.notifier).clearActiveConversation();
        }
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeConversation = ref.watch(activeConversationProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800; // Match Shell breakpoint
    final isNewChat = widget.conversationId == null;

    // Show loading only if ID provided but not found, AND not creating new
    if (activeConversation == null && !isNewChat) {
       return const Scaffold(
         body: Center(child: CircularProgressIndicator()),
       );
    }

    return Scaffold(
      drawer: !isDesktop ? const Drawer(child: Sidebar()) : null,
      appBar: AppBar(
        title: Text(activeConversation?.title ?? 'Business Analytics'), // Reverted title
        leading: !isDesktop ? Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          }
        ) : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: activeConversation != null 
              ? ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: activeConversation.messages.length,
              itemBuilder: (context, index) {
                final message = activeConversation.messages[index];
                return MessageView(message: message);
              },
            )
            : Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        'Glad you’re here', // Restored as requested
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 48,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                          background: Paint()..shader = const LinearGradient(
                            colors: [Color(0xFF4285F4), Color(0xFF9B72CB)],
                          ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0))
                        ),
                      ),
                      Text(
                        'Where should we start?', // Restored subtitle
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 48, 
                          height: 1.2,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Suggestions
                      SizedBox(
                        width: double.infinity,
                        child: SuggestionsBlock(data: const {
                          'actions': [
                            'Analyze Q3 Revenue',
                            'Compare Market Trends',
                            'Generate Monthly Report',
                            'Draft Email Summary'
                          ]
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ChatInputBar(isProminent: activeConversation == null),
        ],
      ),
    );
  }
}
