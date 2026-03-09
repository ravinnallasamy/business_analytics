import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/modules/chat/state/chat_state.dart';
import 'package:business_analytics_chat/modules/chat/state/suggestion_state.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  final bool isProminent;
  const ChatInputBar({super.key, this.isProminent = false});

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Hide suggestions when focus is lost (taps outside)
      // Delay slightly to allow any pending taps on the suggestions list to register
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          // Check if we are actually still empty or if user is just refocusing
          if (_controller.text.isEmpty) {
            ref.read(suggestionProvider.notifier).clear();
          }
        }
      });
    }
  }

  void _handleSubmitted(String text, {String? toolId}) {
    if (text.trim().isEmpty) return;
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
    ref.read(suggestionProvider.notifier).clear();
    ref.read(chatProvider.notifier).sendMessage(text, toolId: toolId);
  }

  @override
  Widget build(BuildContext context) {
    // Gemini-style Input Panel: Pinned to absolute bottom
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating suggestions list above the input box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSuggestions(),
        ),
        
        // Listen for external prompt requests (from suggestions cards)
        Consumer(
          builder: (context, ref, _) {
            ref.listen(chatInputProvider, (previous, next) {
              if (next.isNotEmpty) {
                _controller.text = next;
                setState(() => _isComposing = true);
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length),
                );
                _focusNode.requestFocus();
                // Reset so it can be triggered again with same text
                Future.microtask(() => ref.read(chatInputProvider.notifier).state = '');
              }
            });
            return const SizedBox.shrink();
          },
        ),
        
        // Fully Enlarged Input Bar Container
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F2), // Off-white as in image
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.grey[200]!, width: 1.0),
              bottom: BorderSide(color: Colors.grey[200]!, width: 1.0), // Screen bottom border look
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: true, // Bleed to screen bottom while respecting gesture area
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: (text) {
                        setState(() => _isComposing = text.trim().isNotEmpty);
                        ref.read(suggestionProvider.notifier).fetchSuggestions(text);
                      },
                      onSubmitted: (text) => _handleSubmitted(text),
                      onTapOutside: (_) => _focusNode.unfocus(),
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Inter',
                      ),
                      cursorColor: Colors.black54,
                      decoration: const InputDecoration(
                        hintText: 'Ask Drishti...',
                        hintStyle: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 16,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  _buildSendButton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: _isComposing ? 1.0 : 0.9,
      child: GestureDetector(
        onTap: () => _handleSubmitted(_controller.text),
        child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFC000), // Prominent yellow as in image
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFC000).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.arrow_upward_rounded,
              color: Color(0xFF424242), // Dark grey icon
              size: 24,
            ),
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

  Widget _buildSuggestions() {
    final suggestionState = ref.watch(suggestionProvider);
    final hasSuggestions = suggestionState.suggestions.isNotEmpty;
    final isLoading = suggestionState.isLoading;

    // Visibility Rules: Hide when empty, zero suggestions, or API returns nothing
    if ((!hasSuggestions && !isLoading) || (_controller.text.trim().length < 3)) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F2), // Matching input bg
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          left: BorderSide(color: Colors.grey[200]!),
          right: BorderSide(color: Colors.grey[200]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC000)),
              ),
            if (hasSuggestions)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: suggestionState.suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestionItem = suggestionState.suggestions[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _controller.text = suggestionItem.question;
                            _isComposing = true;
                            // Ensure cursor is at the end
                            _controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: _controller.text.length),
                            );
                          });
                          // Close suggestions
                          ref.read(suggestionProvider.notifier).clear();
                          // Ensure keyboard stays open/focus is kept
                          _focusNode.requestFocus();
                        },
                        hoverColor: Colors.black.withOpacity(0.04),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  size: 16,
                                  color: AppColors.accentGreen,
                                ),
                               ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  suggestionItem.question,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_outward_rounded,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }
}
