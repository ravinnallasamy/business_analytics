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
        vertical: 12, // reduced from 24
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
    if (message.isLoading) {
      return const _LoaderMessage();
    }

    // Gemini: No bubble, pure text, breathing room
    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.blocks.asMap().entries.map((entry) {
          final index = entry.key;
          final block = entry.value;
          final isLast = index == message.blocks.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: BlockRenderer(block: block),
          );
        }).toList(),
      ),
    );
  }
}

class _LoaderMessage extends StatefulWidget {
  const _LoaderMessage();

  @override
  State<_LoaderMessage> createState() => _LoaderMessageState();
}

class _LoaderMessageState extends State<_LoaderMessage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Create a staggered fade/scale animation
              final double delay = index * 0.2;
              double value = (_controller.value - delay) % 1.0;
              // Simple curve: 0 -> 1 -> 0
              double opacity = 0.3 + (0.7 * (1.0 - (value - 0.5).abs() * 2).clamp(0.0, 1.0));
              double scale = 0.8 + (0.2 * (1.0 - (value - 0.5).abs() * 2).clamp(0.0, 1.0));

              return Container(
                margin: const EdgeInsets.only(right: 6),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
                transform: Matrix4.identity()..scale(scale),
              );
            },
          );
        }),
      ),
    );
  }
}
