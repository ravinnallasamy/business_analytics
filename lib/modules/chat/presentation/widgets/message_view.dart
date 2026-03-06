import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:business_analytics_chat/modules/chat/state/chat_state.dart';
import 'package:business_analytics_chat/modules/chat/presentation/blocks/block_renderer.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';
import 'package:business_analytics_chat/modules/chat/presentation/widgets/email_draft_sheet.dart';

class MessageView extends StatelessWidget {
  final ChatMessage message;

  const MessageView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message Bubble/Container
          Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: message.isUser
                    ? _buildUserMessage(context)
                    : _buildAssistantMessage(context),
              ),
            ],
          ),
          
          // Spacing to next message
          const SizedBox(height: 8),
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
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Soft light green (mint)
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: MarkdownBody(
        data: message.content,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: Colors.black, // Solid black for better contrast
            fontWeight: FontWeight.w400, // Regular weight
            fontFamily: 'Inter',
          ),
          strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(BuildContext context) {
    if (message.isLoading) {
      return const _LoaderMessage();
    }

    final contentBlocks = message.blocks.where((b) => b.type != 'suggestions').toList();
    final suggestionBlocks = message.blocks.where((b) => b.type == 'suggestions').toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content Blocks
          ...contentBlocks.map((block) {
            final isFullWidth = block.type == 'table' || block.type == 'chart' || block.type == 'metrics';
            return Padding(
              padding: EdgeInsets.only(
                bottom: 12,
                left: isFullWidth ? 2 : 8,
                right: isFullWidth ? 2 : 8,
              ),
              child: BlockRenderer(block: block, messageId: message.id),
            );
          }),

          // Mail Icon (Draft Email) - Placed above suggestions
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4, bottom: 8),
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
                backgroundColor: Colors.grey[100]?.withOpacity(0.5),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),

          // Suggestion Blocks (Follow-up)
          ...suggestionBlocks.map((block) {
            return BlockRenderer(block: block, messageId: message.id);
          }),
        ],
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
