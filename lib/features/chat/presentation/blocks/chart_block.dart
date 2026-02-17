import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class ChartBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const ChartBlock({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final xKey = data['x_key'] as String? ?? 'x';
    // Supporting multiple y_keys but for simplicity we take first for now or iterate
    final yKeys = (data['y_keys'] as List<dynamic>? ?? []).cast<String>();
    final primaryYKey = yKeys.isNotEmpty ? yKeys.first : 'value';

    final chartData = (data['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    if (chartData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: UIConstants.paddingMedium),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = chartData[groupIndex];
                        return BarTooltipItem(
                          '${item[xKey]}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: rod.toY.toString(),
                              style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= chartData.length) {
                             return const SizedBox.shrink();
                          }
                          final item = chartData[index];
                          // Truncate label if too long
                          String text = item[xKey]?.toString() ?? '';
                          if (text.length > 5) text = text.substring(0, 5) + '..';

                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            child: Text(
                              text, 
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  barGroups: chartData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    // Attempt to parse Y value safely
                    double yVal = 0;
                    final rawY = item[primaryYKey];
                    if (rawY is num) {
                      yVal = rawY.toDouble();
                    } else if (rawY is String) {
                      yVal = double.tryParse(rawY) ?? 0;
                    }

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: yVal,
                          color: Theme.of(context).colorScheme.primary,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        )
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
