import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/modules/chat/state/chat_state.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';

class SuggestionsBlock extends ConsumerWidget {
  final Map<String, dynamic> data;
  final String? messageId;

  const SuggestionsBlock({super.key, required this.data, this.messageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Logic: Suggestions should only be visible for the very last message in the thread.
    final activeConv = ref.watch(activeConversationProvider);
    if (activeConv != null && messageId != null) {
      if (activeConv.messages.isNotEmpty && activeConv.messages.last.id != messageId) {
        return const SizedBox.shrink();
      }
    }

    final rawItems = data['items'] ?? data['suggestions'] ?? data['actions'] ?? [];
    final items = (rawItems as List<dynamic>).map((e) => e.toString()).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8), // Gemini-style suggestion top margin
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Perplexity-style follow-up list
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final text = entry.value;
                final isLast = index == items.length - 1;

                return Column(
                  children: [
                    _SuggestionRow(
                      text: text,
                      onTap: () => ref.read(chatProvider.notifier).sendMessage(text),
                    ),
                    if (!isLast)
                      const Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFEEEEEE),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionRow({required this.text, required this.onTap});

  @override
  State<_SuggestionRow> createState() => _SuggestionRowState();
}

class _SuggestionRowState extends State<_SuggestionRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent, // Controlled by AnimatedContainer
        highlightColor: Colors.transparent,
        splashColor: AppColors.accentGreen.withOpacity(0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered 
                ? const Color(0xFFF7F7F7) 
                : Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.subdirectory_arrow_right_rounded,
                  size: 18,
                  color: _isHovered ? AppColors.accentGreen : AppColors.textSecondary.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _isHovered
                            ? AppColors.textPrimary
                            : const Color(0xFF444444),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
