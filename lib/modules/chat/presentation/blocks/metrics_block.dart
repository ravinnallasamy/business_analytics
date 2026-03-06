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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14), // Gemini-style outer margin
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  MarkdownBody(
                    data: summary,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      strong: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (period != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        period,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: metrics.map((item) {
              return Container(
                constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
                padding: const EdgeInsets.all(14), // Metrics block padding
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownBody(
                      data: item['label']?.toString().toUpperCase() ?? '',
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500, // Inter Medium
                              fontFamily: 'Inter',
                              letterSpacing: 1.2,
                            ),
                        strong: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data: item['value']?.toString() ?? '',
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700, // Inter Bold
                              fontFamily: 'Inter',
                            ),
                        strong: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
