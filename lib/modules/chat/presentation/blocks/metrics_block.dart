import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class MetricsBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const MetricsBlock({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Safe cast: avoids dart2js LinkedHashMap cast failures
    final rawMetrics = data['metrics'];
    final List<Map<String, dynamic>> metrics = rawMetrics is List
        ? rawMetrics
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
        : [];

    final String? summary = data['summary']?.toString().isNotEmpty == true
        ? data['summary'].toString()
        : null;
    final String? period = data['period']?.toString().isNotEmpty == true
        ? data['period'].toString()
        : null;

    if (metrics.isEmpty) {
      debugPrint('⚠️ MetricsBlock: metrics list is empty, data keys: ${data.keys.toList()}');
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period pill — shown even when there is no summary (node_steps format)
          if (period != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer,
                    width: 1,
                  ),
                ),
                child: Text(
                  period,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                ),
              ),
            ),

          // Optional summary header (when present)
          if (summary != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: MarkdownBody(
                data: summary,
                selectable: true,
                styleSheet:
                    MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // KPI cards
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: metrics.map((item) {
              final label = (item['label'] ?? item['name'] ?? '').toString();
              final value = (item['value'] ?? item['val'] ?? '').toString();
              return Container(
                constraints:
                    const BoxConstraints(minWidth: 140, maxWidth: 220),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                                letterSpacing: 0.8,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
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

