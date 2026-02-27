import 'package:flutter/material.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:business_analytics_chat/features/chat/presentation/blocks/block_renderer.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';

class MessageView extends StatelessWidget {
  final ChatMessage message;

  const MessageView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // Gemini: airy spacing between messages
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: message.isUser
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildUserMessage(context),
                  )
                : _buildAssistantMessage(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, {required bool isUser}) {
    if (isUser) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Icon(
        Icons.auto_awesome,
        size: 20,
        color: AppColors.accentGreen,
      ),
    );
  }

  Widget _buildUserMessage(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Text(
        message.content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.5,
          color: AppColors.textPrimary,
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
      constraints: const BoxConstraints(maxWidth: double.infinity),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.blocks.asMap().entries.map((entry) {
          final index = entry.key;
          final block = entry.value;
          final isLast = index == message.blocks.length - 1;
          final isTable = block.type == 'table';
          
          return Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : 12,
              left: isTable ? 0 : 16,
              right: isTable ? 0 : 16,
            ),
            child: BlockRenderer(block: block),
          );
        }).toList(),
      ),
    );
  }
}

class _LoaderMessage extends StatelessWidget {
  const _LoaderMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Image.asset(
        'assets/loader.gif',
        width: 120, // Slightly smaller for inline use
        height: 60,
        fit: BoxFit.contain,
      ),
    );
  }
}
