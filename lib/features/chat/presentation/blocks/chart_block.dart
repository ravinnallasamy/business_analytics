import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class ChartBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const ChartBlock({super.key, required this.data});

  // ── Compact number formatter ─────────────────────────────────────────────
  static String _formatY(double v) {
    if (v.abs() >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v.abs() >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v.abs() >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(v == v.truncate() ? 0 : 1);
  }

  // ── Truncate long x-axis labels ──────────────────────────────────────────
  static String _truncateLabel(String text, {int max = 9}) {
    if (text.length <= max) return text;
    return '${text.substring(0, max - 1)}…';
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> processedData = Map.from(data);

    // FIX: Handle API column-based format (x_axis / y_axis)
    if (data['x_axis'] != null && data['y_axis'] != null) {
      try {
        final xAxis = data['x_axis'] as Map;
        final yAxis = data['y_axis'] as Map;
        final xLabels = List<String>.from((xAxis['data'] as List? ?? []).map((e) => e.toString()));
        final datasets = (yAxis['datasets'] as List? ?? []);

        if (xLabels.isNotEmpty && datasets.isNotEmpty) {
          List<Map<String, dynamic>> rows = [];
          List<String> derivedYKeys = [];

          for (var ds in datasets) {
            if (ds is Map) derivedYKeys.add(ds['label']?.toString() ?? 'Value');
          }

          for (int i = 0; i < xLabels.length; i++) {
            final row = <String, dynamic>{'x': xLabels[i]};
            for (int j = 0; j < datasets.length; j++) {
              final ds = datasets[j] as Map;
              final dsData = ds['data'] as List? ?? [];
              final key = derivedYKeys[j];
              if (i < dsData.length) {
                row[key] = dsData[i];
              }
            }
            rows.add(row);
          }
          processedData['x_key'] = 'x';
          processedData['y_keys'] = derivedYKeys;
          processedData['data'] = rows;
        }
      } catch (e) {
        debugPrint('Error parsing chart data: $e');
      }
    }

    final title = processedData['title'] as String? ?? '';
    final chartType = processedData['chart_type'] as String? ?? 'bar';
    final xKey = processedData['x_key'] as String? ?? 'x';
    final yKeys = List<String>.from(
        (processedData['y_keys'] as List<dynamic>? ?? []).cast<String>());

    if (yKeys.isEmpty) yKeys.add('value');

    final chartData = List<Map<String, dynamic>>.from(
        (processedData['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());

    if (chartData.isEmpty) return const SizedBox.shrink();

    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.secondary,
      const Color(0xFFE65100),
      const Color(0xFF1565C0),
    ];

    // Dynamic chart height: taller when more data points
    final chartH = (chartData.length > 12 ? 320.0 : 260.0);

    // Bottom label area: rotate when many items
    final rotateLabels = chartData.length > 6;
    final bottomReserved = rotateLabels ? 56.0 : 36.0;
    final leftReserved = 52.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          UIConstants.paddingMedium,
          UIConstants.paddingMedium,
          UIConstants.paddingSmall, // less right so Y labels aren't clipped
          UIConstants.paddingMedium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──────────────────────────────────────────────────────
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: UIConstants.paddingMedium),
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),

            // ── Data Table (Numerical View) ──────────────────────────────────
            if (chartData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 36,
                        dataRowMinHeight: 32,
                        dataRowMaxHeight: 32,
                        horizontalMargin: 12,
                        columnSpacing: 24,
                        headingRowColor: WidgetStateProperty.all(
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        columns: [
                          DataColumn(
                            label: Text(
                              xKey.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...yKeys.map((key) => DataColumn(
                                label: Text(
                                  key.replaceAll('_', ' ').toUpperCase(),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                numeric: true,
                              )),
                        ],
                        rows: chartData.take(10).map((row) {
                          return DataRow(
                            cells: [
                              DataCell(Text(
                                row[xKey]?.toString() ?? '',
                                style: Theme.of(context).textTheme.bodySmall,
                              )),
                              ...yKeys.map((key) {
                                final val = row[key];
                                return DataCell(Text(
                                  val is num ? _formatY(val.toDouble()) : val.toString(),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ));
                              }),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Chart (horizontally scrollable when many data points) ──────
            SizedBox(
              height: chartH + bottomReserved + 8,
              child: chartType == 'line'
                  ? _buildLineChart(
                      context, chartData, xKey, yKeys, colors,
                      chartH: chartH,
                      bottomReserved: bottomReserved,
                      leftReserved: leftReserved,
                      rotateLabels: rotateLabels,
                    )
                  : _buildBarChart(
                      context, chartData, xKey, yKeys, colors,
                      chartH: chartH,
                      bottomReserved: bottomReserved,
                      leftReserved: leftReserved,
                      rotateLabels: rotateLabels,
                    ),
            ),

            // ── Legend ─────────────────────────────────────────────────────
            if (yKeys.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: List.generate(yKeys.length, (i) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[i % colors.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          yKeys[i].replaceAll('_', ' ').toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Helper to calculate max Y value with headroom ────────────────────────
  double _calculateMaxY(List<Map<String, dynamic>> data, List<String> keys) {
    double max = 0;
    for (final item in data) {
      for (final key in keys) {
        final raw = item[key];
        double val = 0;
        if (raw is num) val = raw.toDouble();
        else if (raw is String) val = double.tryParse(raw) ?? 0;
        if (val > max) max = val;
      }
    }
    // Add 20% headroom for labels, minimum 10
    return max <= 0 ? 10 : max * 1.2;
  }

  // ── Bar Chart ─────────────────────────────────────────────────────────────
  Widget _buildBarChart(
    BuildContext context,
    List<Map<String, dynamic>> chartData,
    String xKey,
    List<String> yKeys,
    List<Color> colors, {
    required double chartH,
    required double bottomReserved,
    required double leftReserved,
    required bool rotateLabels,
  }) {
    // Dynamic bar width based on data count
    double barWidth = 12;
    if (chartData.length <= 6) barWidth = 24;
    else if (chartData.length <= 12) barWidth = 18;
    
    // Compute min bar width so chart is scrollable when crowded
    final minBarGroupWidth = (yKeys.length * (barWidth + 4)) + 16.0;
    final minChartWidth = chartData.length * minBarGroupWidth;
    
    final maxY = _calculateMaxY(chartData, yKeys);

    Widget chart = BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY, // Prevent top label cutoff
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = chartData[groupIndex];
              final yKey = yKeys[rodIndex % yKeys.length];
              return BarTooltipItem(
                '${item[xKey]}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '${yKey.replaceAll('_', ' ')}: ${_formatY(rod.toY)}',
                    style: TextStyle(
                      color: colors[rodIndex % colors.length],
                      fontSize: 13,
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
              reservedSize: bottomReserved,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= chartData.length) {
                  return const SizedBox.shrink();
                }
                final text = _truncateLabel(
                  chartData[index][xKey]?.toString() ?? '',
                );
                final label = Text(
                  text,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                );
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: rotateLabels
                      ? Transform.rotate(
                          angle: -0.6, // ~35°
                          child: label,
                        )
                      : label,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: leftReserved,
              getTitlesWidget: (value, meta) {
                // Hide max label if it's too close to the top
                if (value == meta.max && value > 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: Text(
                    _formatY(value),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.grey.withOpacity(0.15),
            strokeWidth: 1,
          ),
        ),
        barGroups: chartData.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final rods = <BarChartRodData>[];
          for (int i = 0; i < yKeys.length; i++) {
            final rawY = item[yKeys[i]];
            double yVal = 0;
            if (rawY is num) yVal = rawY.toDouble();
            else if (rawY is String) yVal = double.tryParse(rawY) ?? 0;
            rods.add(BarChartRodData(
              toY: yVal,
              color: colors[i % colors.length],
              width: barWidth,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ));
          }
          return BarChartGroupData(x: index, barsSpace: 3, barRods: rods);
        }).toList(),
      ),
    );

    // Wrap in horizontal scroll if chart would be too narrow
    return LayoutBuilder(builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;
      if (minChartWidth > availableWidth) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minChartWidth, height: chartH, child: chart),
        );
      }
      return SizedBox(height: chartH, child: chart);
    });
  }

  // ── Line Chart ────────────────────────────────────────────────────────────
  Widget _buildLineChart(
    BuildContext context,
    List<Map<String, dynamic>> chartData,
    String xKey,
    List<String> yKeys,
    List<Color> colors, {
    required double chartH,
    required double bottomReserved,
    required double leftReserved,
    required bool rotateLabels,
  }) {
    final maxY = _calculateMaxY(chartData, yKeys);

    Widget chart = LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final item = chartData[spot.x.toInt()];
                final yKey = yKeys[spot.barIndex % yKeys.length];
                return LineTooltipItem(
                  '${item[xKey]}\n${yKey.replaceAll('_', ' ')}: ${_formatY(spot.y)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        maxY: maxY, // Headroom
        minY: 0,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: bottomReserved,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= chartData.length) {
                  return const SizedBox.shrink();
                }
                // Show every nth label to avoid crowding
                final step = (chartData.length / 8).ceil().clamp(1, 99);
                if (index % step != 0 && index != chartData.length - 1) {
                  return const SizedBox.shrink();
                }
                final text = _truncateLabel(
                  chartData[index][xKey]?.toString() ?? '',
                );
                final label = Text(
                  text,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                );
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: rotateLabels
                      ? Transform.rotate(angle: -0.6, child: label)
                      : label,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: leftReserved,
              getTitlesWidget: (value, meta) {
                if (value == meta.max && value > 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: Text(
                    _formatY(value),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.grey.withOpacity(0.15),
            strokeWidth: 1,
          ),
        ),
        lineBarsData: List.generate(yKeys.length, (i) {
          final key = yKeys[i];
          final spots = chartData.asMap().entries.map((entry) {
            final item = entry.value;
            final rawY = item[key];
            double yVal = 0;
            if (rawY is num) yVal = rawY.toDouble();
            else if (rawY is String) yVal = double.tryParse(rawY) ?? 0;
            return FlSpot(entry.key.toDouble(), yVal);
          }).toList();

          return LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colors[i % colors.length],
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: chartData.length <= 20,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: colors[i % colors.length],
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: colors[i % colors.length].withOpacity(0.08),
            ),
          );
        }),
      ),
    );

    return SizedBox(height: chartH, child: chart);
  }
}
