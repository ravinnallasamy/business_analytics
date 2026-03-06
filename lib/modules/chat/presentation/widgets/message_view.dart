import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      padding: const EdgeInsets.symmetric(
          vertical: 12.0, horizontal: 1), // 10px screen padding
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message Bubble/Container
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: message.isUser
                    ? _buildUserMessage(context)
                    : _buildAssistantMessage(context),
              ),
            ],
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
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4), // Light neutral grey
        borderRadius: BorderRadius.circular(16),
      ),
      child: MarkdownBody(
        data: message.content,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                fontFamily: 'Inter',
              ),
          strong:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(BuildContext context) {
    if (message.isLoading) {
      return const _LoaderMessage();
    }

    final contentBlocks =
        message.blocks.where((b) => b.type != 'suggestions').toList();
    final suggestionBlocks =
        message.blocks.where((b) => b.type == 'suggestions').toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12), // Gemini-style internal padding
      decoration: const BoxDecoration(
        color: Colors.white, // Pure white background, no border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content Blocks
          ...contentBlocks.map((block) {
            return BlockRenderer(block: block, messageId: message.id);
          }),

          // Suggestion Blocks (Follow-up) - Moved above actions
          ...suggestionBlocks.map((block) {
            return BlockRenderer(block: block, messageId: message.id);
          }),

          const SizedBox(height: 12),

          // Action Row (Gemini style)
          _buildActionRow(context),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          _buildActionButton(Icons.thumb_up_outlined, 'Good response', () {}),
          _buildActionButton(Icons.thumb_down_outlined, 'Bad response', () {}),
          _buildActionButton(Icons.fact_check_outlined, 'Double-check', () {}),
          _buildActionButton(Icons.share_outlined, 'Share', () {}),
          _buildActionButton(Icons.content_copy_outlined, 'Copy', () {
            Clipboard.setData(ClipboardData(text: message.content));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copied to clipboard'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }),
          // Existing Mail Icon integrated into the row
          _buildActionButton(Icons.mail_outline_rounded, 'Draft Email',
              () => _showEmailDraft(context)),

          const Spacer(),

          _buildActionButton(Icons.more_vert_rounded, 'More', () {}),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Colors.grey[600]),
        tooltip: tooltip,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(6),
        style: IconButton.styleFrom(
          hoverColor: Colors.black.withOpacity(0.05),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
