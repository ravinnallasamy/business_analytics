import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';

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
        color: Theme.of(context).scaffoldBackgroundColor, // Opaque background
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24, 
        12, 
        isMobile ? 16 : 24, 
        isMobile ? 16 : 24, // Bottom padding for navigation bar
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800), // Gemini max width
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF1E1F20) // Dark surface
                        : const Color(0xFFF0F4F9), // Light surface (Gemini grey)
                borderRadius: BorderRadius.circular(32),
                // Gemini: very subtle or no shadow in dark mode, light shadow in light mode
                boxShadow: Theme.of(context).brightness == Brightness.light ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ] : null,
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
                        maxLines: null, // Grows with text
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Ask anything...',
                          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
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
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              fixedSize: const Size(40, 40),
                              padding: EdgeInsets.zero,
                            ),
                          )
                        : IconButton(
                            key: const ValueKey('disabled'),
                            onPressed: null, // Disabled state
                            icon: const Icon(Icons.arrow_upward_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
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
