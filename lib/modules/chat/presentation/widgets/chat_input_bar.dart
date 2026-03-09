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
    // Cast to bool? first so a null JS-runtime value falls back safely to false
    final thinkingEnabled =
        (ref.watch(chatProvider.select((s) => s.thinkingModeEnabled as bool?)) ?? false);
    final isGenerating =
        (ref.watch(chatProvider.select((s) => s.isGenerating as bool?)) ?? false);

    // Gemini-style Input Panel: Pinned to absolute bottom
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating suggestions list above the input box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSuggestions(),
        ),

        // Fully Enlarged Input Bar Container
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F2), // Off-white as in image
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.grey[200]!, width: 1.0),
              bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1.0), // Screen bottom border look
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Thinking Mode Badge Row ──────────────────────────────
                  _ThinkingBadge(
                    enabled: thinkingEnabled,
                    onTap: () =>
                        ref.read(chatProvider.notifier).toggleThinkingMode(),
                  ),
                  const SizedBox(height: 4),
                  // ── Text Input + Send Button Row ─────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onChanged: (text) {
                            setState(() => _isComposing = text.trim().isNotEmpty);
                            ref
                                .read(suggestionProvider.notifier)
                                .fetchSuggestions(text);
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
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      _buildSendButton(isGenerating: isGenerating),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton({bool isGenerating = false}) {
    if (isGenerating) {
      // ── Stop Button ──────────────────────────────────────────────────────
      return GestureDetector(
        onTap: () => ref.read(chatProvider.notifier).cancelGeneration(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4444), // Vivid red stop colour
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4444).withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3), // Slightly rounded square
              ),
            ),
          ),
        ),
      );
    }

    // ── Send Button (default) ─────────────────────────────────────────────
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

  Widget _buildSuggestions() {
    final suggestionState = ref.watch(suggestionProvider);
    final hasSuggestions = suggestionState.suggestions.isNotEmpty;
    final isLoading = suggestionState.isLoading;

    // Visibility Rules: Hide when empty, zero suggestions, or API returns nothing
    if ((!hasSuggestions && !isLoading) ||
        (_controller.text.trim().length < 3)) {
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
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFFFFC000)),
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
                          _handleSubmitted(suggestionItem.question,
                              toolId: suggestionItem.toolId);
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
                                  border:
                                      Border.all(color: Colors.grey[200]!),
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

// ─── Thinking Mode Badge ──────────────────────────────────────────────────────

class _ThinkingBadge extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ThinkingBadge({required this.enabled, required this.onTap});

  @override
  State<_ThinkingBadge> createState() => _ThinkingBadgeState();
}

class _ThinkingBadgeState extends State<_ThinkingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color activeGreen = const Color(0xFF22C55E);
    final Color activeBg = const Color(0xFFDCFCE7);
    final Color inactiveBg = const Color(0xFFF3F4F6);
    final Color inactiveFg = const Color(0xFF6B7280);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: widget.enabled ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.enabled
                ? activeGreen.withOpacity(0.6)
                : Colors.grey.withOpacity(0.2),
            width: 1.0,
          ),
          boxShadow: widget.enabled
              ? [
                  BoxShadow(
                    color: activeGreen.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spark / lightning icon
            Icon(
              Icons.bolt_rounded,
              size: 14,
              color: widget.enabled ? activeGreen : inactiveFg,
            ),
            const SizedBox(width: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    widget.enabled ? FontWeight.w600 : FontWeight.w500,
                color: widget.enabled ? activeGreen : inactiveFg,
                fontFamily: 'Inter',
                letterSpacing: 0.1,
              ),
              child: const Text('Thinking'),
            ),
            // Active indicator dot
            if (widget.enabled) ...[
              const SizedBox(width: 5),
              AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeGreen.withOpacity(_glowAnim.value),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
