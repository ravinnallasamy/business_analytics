import 'package:flutter/material.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:business_analytics_chat/features/chat/presentation/blocks/block_renderer.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class MessageView extends StatelessWidget {
  final ChatMessage message;

  const MessageView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.paddingMedium,
        vertical: UIConstants.paddingSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar(context, isUser: false),
          const SizedBox(width: UIConstants.paddingSmall),
          Flexible(
            child: message.isUser
                ? _buildUserMessage(context)
                : _buildAssistantMessage(context),
          ),
          const SizedBox(width: UIConstants.paddingSmall),
          if (message.isUser) _buildAvatar(context, isUser: true),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, {required bool isUser}) {
    return CircleAvatar(
      radius: UIConstants.iconSizeSmall,
      backgroundColor: isUser 
          ? Theme.of(context).colorScheme.primary 
          : Theme.of(context).colorScheme.secondary,
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: UIConstants.iconSizeSmall,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildUserMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
      ),
      child: Text(
        message.content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: message.blocks.map((block) {
        return BlockRenderer(block: block);
      }).toList(),
    );
  }
}
