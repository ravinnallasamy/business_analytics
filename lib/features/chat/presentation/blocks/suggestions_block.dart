import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class SuggestionsBlock extends ConsumerWidget {
  final Map<String, dynamic> data;

  const SuggestionsBlock({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = (data['actions'] as List<dynamic>? ?? []).cast<String>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingSmall),
      child: Wrap(
        spacing: UIConstants.paddingSmall,
        runSpacing: UIConstants.paddingSmall,
        children: actions.map((action) {
          return ActionChip(
            label: Text(action),
            onPressed: () {
              ref.read(chatProvider.notifier).sendMessage(action);
            },
          );
        }).toList(),
      ),
    );
  }
}
