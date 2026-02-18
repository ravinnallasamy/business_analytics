import 'package:flutter/material.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:business_analytics_chat/features/chat/presentation/blocks/block_renderer.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class MessageView extends StatelessWidget {
  final ChatMessage message;

  const MessageView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // Gemini: airy spacing between messages
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24, // increased vertical spacing
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(context, isUser: false),
            const SizedBox(width: 16),
          ],
          Flexible(
            child: message.isUser
                ? _buildUserMessage(context)
                : _buildAssistantMessage(context),
          ),
          // No avatar for user on the right, keeps it clean like Gemini mobile
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, {required bool isUser}) {
    // Gemini Icon: minimal, often just the sparkle
    if (isUser) return const SizedBox.shrink(); // Hide user avatar for cleaner look
    
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Icon(
        Icons.auto_awesome, // Sparkle icon
        size: 20, // Smaller, more refined
        color: Theme.of(context).colorScheme.primary,
        // Gradient effect is hard with just Icon, but color is enough
      ),
    );
  }

  Widget _buildUserMessage(BuildContext context) {
    // User: Soft grey/blue bubble, rounded corners
    return Container(
      constraints: const BoxConstraints(maxWidth: 600), // Max width for reading
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(4), // Subtle indication of origin
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Text(
        message.content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(BuildContext context) {
    // Gemini: No bubble, pure text, breathing room
    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.blocks.map((block) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BlockRenderer(block: block),
          );
        }).toList(),
      ),
    );
  }
}
