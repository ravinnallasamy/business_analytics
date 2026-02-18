import 'package:flutter/material.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class TableBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const TableBlock({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final rawColumns = data['headers'] ?? data['columns'];
    final columns = (rawColumns is List) ? rawColumns.map((e) => e.toString()).toList() : <String>[];
    final rows = (data['rows'] as List<dynamic>? ?? []);

    if (columns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: UIConstants.paddingMedium),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
LayoutBuilder(
              builder: (context, constraints) {
                // Use LayoutBuilder for local constraints or MediaQuery for screen width
                final isMobile = MediaQuery.of(context).size.width < 600;

                if (isMobile) {
                  return Column(
                    children: rows.map<Widget>((row) {
                      final List<dynamic> cellValues = row is List ? row : [];
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(columns.length, (index) {
                            if (index >= columns.length) return const SizedBox.shrink();
                            
                            final header = columns[index];
                            final value = index < cellValues.length ? cellValues[index] : '';
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 120, // Fixed width for labels
                                    child: Text(
                                      header,
                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      value.toString(),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      );
                    }).toList(),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    headingRowHeight: 40,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 64, // Allow multiline
                    headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    border: TableBorder(
                       horizontalInside: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    columns: columns
                        .map((c) => DataColumn(
                              label: Text(c),
                            ))
                        .toList(),
                    rows: rows.map<DataRow>((row) {
                      final List<dynamic> cellValues = row is List ? row : [];
                      return DataRow(
                        cells: List.generate(columns.length, (index) {
                           final cellValue = index < cellValues.length ? cellValues[index] : '';
                           return DataCell(
                             ConstrainedBox(
                               constraints: const BoxConstraints(maxWidth: 200),
                               child: Text(
                                 cellValue.toString(),
                                 softWrap: true,
                                 overflow: TextOverflow.visible,
                               ),
                             ),
                           );
                        }),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
