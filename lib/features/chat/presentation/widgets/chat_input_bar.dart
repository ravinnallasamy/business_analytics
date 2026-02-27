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
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 16, 
        12, 
        isMobile ? 12 : 16, 
        isMobile ? 12 : 16,
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.borderGray),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: TextField(
                          controller: _controller,
                          onChanged: (text) => setState(() => _isComposing = text.trim().isNotEmpty),
                          onSubmitted: _handleSubmitted,
                          maxLines: null,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Ask anything...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 0,
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send Button
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isComposing
                          ? IconButton(
                              key: const ValueKey('send'),
                              onPressed: () => _handleSubmitted(_controller.text),
                              icon: const Icon(Icons.arrow_upward_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.accentGreen,
                                foregroundColor: Colors.white,
                                fixedSize: const Size(40, 40),
                                padding: EdgeInsets.zero,
                              ),
                            )
                          : IconButton(
                              key: const ValueKey('disabled'),
                              onPressed: null,
                              icon: const Icon(Icons.arrow_upward_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: AppColors.textSecondary.withOpacity(0.3),
                                fixedSize: const Size(40, 40),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ],
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
