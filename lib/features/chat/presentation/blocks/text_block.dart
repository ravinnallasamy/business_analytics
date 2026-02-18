import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class TextBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const TextBlock({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final text = data['content'] as String? ?? data['text'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingSmall),
      child: MarkdownBody(
        data: text,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: Theme.of(context).textTheme.bodyLarge,
          h1: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          h2: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          h3: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          blockquoteDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 4)),
          ),
        ),
      ),
    );
  }
}
