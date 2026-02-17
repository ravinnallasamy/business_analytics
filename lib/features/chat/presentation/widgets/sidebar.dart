import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart'; // Add import

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final activeId = chatState.activeConversationId;

    return Container(
      width: UIConstants.sidebarWidth,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(UIConstants.paddingMedium),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ref.read(chatProvider.notifier).clearActiveConversation();
                  // Close drawer if open (optional: context.pop() if active?)
                  // But context.go handles navigation well.
                  // If we are in drawer, check if Scaffold.of(context).hasDrawer && isDrawerOpen...
                  // Simplifying:
                  if (Scaffold.maybeOf(context)?.hasDrawer == true && Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                     Navigator.of(context).pop(); // Close drawer
                  }
                  context.go('/chat');
                },
                icon: const Icon(Icons.add),
                label: const Text('New Conversation'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: UIConstants.paddingSmall + 4,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: chatState.conversations.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1, 
                indent: UIConstants.paddingMedium, 
                endIndent: UIConstants.paddingMedium
              ),
              itemBuilder: (context, index) {
                final conversation = chatState.conversations[index];
                final isActive = conversation.id == activeId;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.paddingMedium,
                    vertical: 4,
                  ),
                  selected: isActive,
                  selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                  selectedColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  title: Text(
                    conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, h:mm a').format(conversation.lastUpdated),
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive 
                        ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    // ref.read(chatProvider.notifier).selectConversation(conversation.id);
                    // Navigation with GoRouter will trigger the selection in ConversationScreen
                    context.go('/chat/${conversation.id}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
