import 'package:flutter/material.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class MetricsBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const MetricsBlock({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final metrics = data['metrics'] as List<dynamic>? ?? [];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: metrics.length,
        separatorBuilder: (context, index) => const SizedBox(width: UIConstants.paddingSmall),
        itemBuilder: (context, index) {
          final item = metrics[index] as Map<String, dynamic>;
          return Card(
            elevation: 2,
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(UIConstants.paddingMedium),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    item['label'] ?? '',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['value'] ?? '',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
