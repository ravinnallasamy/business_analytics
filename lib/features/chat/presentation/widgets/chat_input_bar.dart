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
    
    // Simplified Input Bar: Single clean floating box
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28), // Pill-shaped
            border: Border.all(color: AppColors.borderGray.withOpacity(0.8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (text) => setState(() => _isComposing = text.trim().isNotEmpty),
                  onSubmitted: _handleSubmitted,
                  maxLines: 4,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Ask anything...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _isComposing 
                ? IconButton(
                    onPressed: () => _handleSubmitted(_controller.text),
                    icon: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      padding: const EdgeInsets.all(8),
                    ),
                  )
                : Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: AppColors.accentGreen.withOpacity(0.4),
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
