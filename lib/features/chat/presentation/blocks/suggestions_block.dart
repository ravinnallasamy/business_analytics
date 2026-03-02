import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';

class SuggestionsBlock extends ConsumerWidget {
  final Map<String, dynamic> data;

  const SuggestionsBlock({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawItems = data['items'] ?? data['suggestions'] ?? data['actions'];
    final items = (rawItems as List<dynamic>? ?? []).cast<String>();

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: UIConstants.paddingMedium,
        horizontal: UIConstants.paddingSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "CHOOSE AN OPTION",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          Column(
            children: items.map((item) {
              return _SuggestionItem(
                text: item,
                onTap: () => ref.read(chatProvider.notifier).sendMessage(item),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SuggestionItem extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionItem({required this.text, required this.onTap});

  @override
  State<_SuggestionItem> createState() => _SuggestionItemState();
}

class _SuggestionItemState extends State<_SuggestionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(_isHovered ? 1.01 : 1.0),
          decoration: BoxDecoration(
            color: _isHovered 
                ? theme.colorScheme.surfaceContainerHighest 
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
            border: Border.all(
              color: _isHovered ? AppColors.accentGreen : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: _isHovered ? 1.5 : 1.0,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _isHovered ? AppColors.accentGreen : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_outlined,
                        size: 16,
                        color: _isHovered ? Colors.white : theme.colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: _isHovered ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.8),
                          fontWeight: _isHovered ? FontWeight.w900 : FontWeight.w600,
                          height: 1.3,
                        ),
                        child: Text(widget.text),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: _isHovered ? AppColors.accentGreen : theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
