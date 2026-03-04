import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  final bool isProminent;
  const ChatInputBar({super.key, this.isProminent = false});

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isComposing = false;

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
    ref.read(chatProvider.notifier).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    // Gemini: Input is always floating at bottom, constrained width
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: AppColors.borderGray.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGray),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (text) => setState(() => _isComposing = text.trim().isNotEmpty),
                  onSubmitted: _handleSubmitted,
                  maxLines: null,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Ask anything...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              IconButton(
                onPressed: _isComposing ? () => _handleSubmitted(_controller.text) : null,
                icon: Icon(
                  Icons.send_rounded,
                  color: _isComposing ? AppColors.accentGreen : AppColors.inactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }

  Widget _buildInputRow({
    required Color fillColor,
    required bool showSendButton,
    required bool isMobile,
  }) {
      return const SizedBox.shrink(); // Deprecated helper
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
