import 'package:flutter/material.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class TableBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const TableBlock({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final columns = (data['columns'] as List<dynamic>? ?? []).cast<String>();
    final rows = (data['rows'] as List<dynamic>? ?? []);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: UIConstants.paddingSmall),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: columns
                    .map((c) => DataColumn(
                          label: Text(
                            c,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ))
                    .toList(),
                rows: rows.map<DataRow>((row) {
                  // row is List<dynamic>, cells might be String, int, double (e.g. from JSON)
                  final List<dynamic> cellValues = row is List ? row : [];
                  
                  return DataRow(
                    cells: cellValues.map((c) => DataCell(Text(c.toString()))).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
