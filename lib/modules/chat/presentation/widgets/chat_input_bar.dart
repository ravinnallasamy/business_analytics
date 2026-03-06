import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/modules/chat/state/chat_state.dart';
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

    // Gemini-style Input Panel: Pinned to absolute bottom
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        // Subtle borders as requested
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1.0),
          bottom: BorderSide(color: Colors.grey[200]!, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false, // Don't respect safe area on top as it's at the bottom
        bottom: true, // Respect safe area for navigation bars
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section: Input & Send Row (The prompt is now the hint)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (text) =>
                          setState(() => _isComposing = text.trim().isNotEmpty),
                      onSubmitted: _handleSubmitted,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF444746), // Dimmed text color
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Inter',
                          ),
                      cursorColor: AppColors.accentGreen,
                      decoration: const InputDecoration(
                        hintText: 'Ask Drishti',
                        hintStyle: TextStyle(
                          color: Color(0xFF6B6B6B),
                          fontSize: 18,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildSendButton(),
                ],
              ),

              // Bottom Section: Future control area (Empty for now)
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Future: [+] button, document upload, etc. will be placed here
                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isComposing ? 1.0 : 0.4,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: AppColors.accentGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGreen.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: IconButton(
            onPressed: () => _handleSubmitted(_controller.text),
            icon: const Icon(Icons.arrow_upward_rounded),
            color: Colors.white,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Send',
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
