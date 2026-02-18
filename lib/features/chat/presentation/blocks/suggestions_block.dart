import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class SuggestionsBlock extends ConsumerWidget {
  final Map<String, dynamic> data;

  const SuggestionsBlock({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawItems = data['items'] ?? data['suggestions'] ?? data['actions'];
    final items = (rawItems as List<dynamic>? ?? []).cast<String>();

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "Suggested Actions",
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ref.read(chatProvider.notifier).sendMessage(item);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75, // Responsive max width
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined, 
                          size: 16, 
                          color: Theme.of(context).colorScheme.primary
                        ),
                        const SizedBox(width: 8),
                        Flexible( 
                          child: Text(
                            item, 
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 14,
                            ),
                            softWrap: true,
                            maxLines: 3, 
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
