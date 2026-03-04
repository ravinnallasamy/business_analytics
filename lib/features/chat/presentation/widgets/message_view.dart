import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:business_analytics_chat/features/chat/presentation/blocks/block_renderer.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';
import 'package:business_analytics_chat/features/chat/presentation/widgets/email_draft_sheet.dart';

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
          Expanded(
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
      child: MarkdownBody(
        data: message.content,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: AppColors.textPrimary,
          ),
          strong: const TextStyle(fontWeight: FontWeight.bold),
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
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.blocks.asMap().entries.map((entry) {
          final index = entry.key;
          final block = entry.value;
          final isLast = index == message.blocks.length - 1;
          final isFullWidth = block.type == 'table' || block.type == 'chart' || block.type == 'metrics';
          
          return Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 8 : 12,
              left: isFullWidth ? 0 : 16,
              right: isFullWidth ? 0 : 16,
            ),
            child: BlockRenderer(block: block),
          );
        }).toList()
          ..add(
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: IconButton(
                onPressed: () => _showEmailDraft(context),
                icon: Icon(
                  Icons.mail_outline_rounded,
                  size: 20,
                  color: Colors.grey[600],
                ),
                tooltip: 'Draft Email',
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
      ),
    );
  }

  void _showEmailDraft(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmailDraftSheet(message: message),
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
        width: 50, // Significant size reduction for inline loader
        height: 25,
        fit: BoxFit.contain,
      ),
    );
  }
}
