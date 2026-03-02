import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class MetricsBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const MetricsBlock({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final metrics = (data['metrics'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    // Extract summary and period
    final summary = data['summary'] as String?;
    final period = data['period'] as String?;
    
    if (metrics.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: MarkdownBody(
                    data: summary,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.normal,
                          ),
                      strong: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (period != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      period,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        Wrap(
          spacing: UIConstants.paddingMedium,
          runSpacing: UIConstants.paddingMedium,
          children: metrics.map((item) {
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              color: Theme.of(context).colorScheme.surface,
              child: Container(
                constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
                padding: const EdgeInsets.all(UIConstants.paddingMedium),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownBody(
                      data: item['label']?.toString().toUpperCase() ?? '',
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.normal,
                              letterSpacing: 1.2,
                            ),
                        strong: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data: item['value']?.toString() ?? '',
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.normal,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        strong: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
