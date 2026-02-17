import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

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
    // If prominent (New Chat), use floating card style with white background.
    // If default (Active Chat), use standard bottom bar style.
        
    final fillColor = widget.isProminent
        ? Colors.white // Explicit white for Gemini look
        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
        
    final containerDecoration = widget.isProminent
        ? BoxDecoration(
            color: Colors.transparent, // floating container has no bg, the inner text field container will have it (or we wrap the whole row)
          )
        : BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          );

    return Container(
      padding: widget.isProminent 
          ? const EdgeInsets.fromLTRB(24, 0, 24, 24) // Float above bottom
          : const EdgeInsets.symmetric(
              horizontal: UIConstants.paddingMedium,
              vertical: UIConstants.paddingMedium,
            ),
      decoration: containerDecoration,
      child: SafeArea(
        child: widget.isProminent 
          ? Container(
             // The floating pill container
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(32),
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withValues(alpha: 0.1),
                   blurRadius: 12,
                   offset: const Offset(0, 4),
                 ),
               ],
             ),
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
             child: _buildInputRow(fillColor: Colors.transparent, showSendButton: true),
          )
          : _buildInputRow(fillColor: fillColor, showSendButton: true),
      ),
    );
  }

  Widget _buildInputRow({required Color fillColor, required bool showSendButton}) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onChanged: (text) {
              setState(() {
                _isComposing = text.trim().isNotEmpty;
              });
            },
            onSubmitted: _handleSubmitted,
            decoration: InputDecoration(
              hintText: widget.isProminent ? 'Ask here !!' : 'Ask about business insights...', // Matching screenshot hint purely for style, user can change
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: fillColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: UIConstants.paddingMedium,
                vertical: UIConstants.paddingSmall + 4,
              ),
            ),
          ),
        ),
        const SizedBox(width: UIConstants.paddingSmall),
        if (_isComposing || !widget.isProminent) 
          IconButton.filled(
            onPressed: _isComposing ? () => _handleSubmitted(_controller.text) : null,
            icon: const Icon(Icons.arrow_upward),
             style: widget.isProminent ? IconButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white) : null,
          ),
      ],
    );
  }
}
