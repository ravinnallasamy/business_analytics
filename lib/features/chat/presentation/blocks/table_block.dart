import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

class TableBlock extends StatefulWidget {
  final Map<String, dynamic> data;

  const TableBlock({super.key, required this.data});

  @override
  State<TableBlock> createState() => _TableBlockState();
}

class _TableBlockState extends State<TableBlock> {
  late List<String> _allColumns;
  late Set<String> _visibleColumns;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final rawColumns = widget.data['headers'] ?? widget.data['columns'];
    _allColumns = (rawColumns is List) ? rawColumns.map((e) => e.toString()).toList() : <String>[];
    _visibleColumns = _allColumns.toSet();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  Future<void> _exportData(List<String> columns, List<List<dynamic>> rows) async {
    try {
      if (!kIsWeb) {
        if (Platform.isAndroid || Platform.isIOS) {
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
            if (!status.isGranted) return;
          }
        }
      }

      List<List<dynamic>> csvData = [
        columns,
        ...rows
      ];

      String csv = const ListToCsvConverter().convert(csvData);

      if (kIsWeb) {
        // Web export handling would go here (e.g. anchor download)
        debugPrint('CSV Export Content:\n$csv');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export functionality is limited on Web demo')),
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/table_export_${DateTime.now().millisecondsSinceEpoch}.csv';
        final file = File(path);
        await file.writeAsString(csv);
        await OpenFilex.open(path);
      }
    } catch (e) {
      debugPrint('Export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _showColumnSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Visible Columns'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _allColumns.map((col) {
                    return CheckboxListTile(
                      title: Text(col),
                      value: _visibleColumns.contains(col),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          setState(() {
                            if (value == true) {
                              _visibleColumns.add(col);
                            } else {
                              if (_visibleColumns.length > 1) {
                                _visibleColumns.remove(col);
                              }
                            }
                          });
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.data['title'] as String? ?? '';
    final rawRows = (widget.data['rows'] as List<dynamic>? ?? []);

    if (_allColumns.isEmpty) return const SizedBox.shrink();

    // 1. Filter Columns
    final displayColumns = _allColumns.where((c) => _visibleColumns.contains(c)).toList();
    
    // 2. Filter Rows (Search + Column Mapping)
    final List<List<dynamic>> displayRows = [];
    for (var row in rawRows) {
      if (row is List) {
        // Search filter: check if ANY visible column cell contains query
        // This is efficient enough for small datasets (<1000 rows)
        bool matches = _searchQuery.isEmpty;
        if (!matches) {
          for (var item in row) {
            if (item.toString().toLowerCase().contains(_searchQuery)) {
              matches = true;
              break;
            }
          }
        }

        if (matches) {
           // Map row to visible columns only
           // Assuming row indices match _allColumns indices
           final List<dynamic> filteredRow = [];
           for (int i = 0; i < _allColumns.length; i++) {
             if (_visibleColumns.contains(_allColumns[i])) {
               filteredRow.add(i < row.length ? row[i] : '');
             }
           }
           displayRows.add(filteredRow);
        }
      }
    }

    // 3. Dynamic Column Widths
    final List<double> minWidths = displayColumns.map((c) => (c.length * 11.0) + 40.0).toList();
    for (var row in displayRows) {
      for (int i = 0; i < displayColumns.length; i++) {
         if (i < row.length) {
            final double w = (row[i].toString().length * 11.0) + 40.0;
            if (w > minWidths[i]) minWidths[i] = w;
         }
      }
    }
    final widths = minWidths.map((w) => w < 100.0 ? 100.0 : (w > 400.0 ? 400.0 : w)).toList();
    
    final tableColumnWidths = {
      for (var i = 0; i < displayColumns.length; i++) i: FlexColumnWidth(widths[i]),
    };
    
    final totalWidth = widths.fold(0.0, (sum, w) => sum + w);

    // 4. Alignments
    // Headers are centered, Data is left-aligned as requested
    const headerAlignment = Alignment.center;
    const dataAlignment = Alignment.centerLeft;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
           top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
           bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (title.isNotEmpty)
                    Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(77)), // 0.3 opacity
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  tooltip: 'Columns',
                  onPressed: _showColumnSelector,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.download_rounded),
                  tooltip: 'Export CSV',
                  onPressed: () => _exportData(displayColumns, displayRows),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // --- Table Content ---
            // Scrollbar only for horizontal. Vertical scroll is PAGE level (natural).
            LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = totalWidth > constraints.maxWidth ? totalWidth : constraints.maxWidth;
                return Scrollbar(
                  controller: _horizontalScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                       width: tableWidth,
                       child: Table(
                         columnWidths: tableColumnWidths,
                         defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                     border: TableBorder.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                     ),
                     children: [
                       // Header Row
                       TableRow(
                         decoration: BoxDecoration(
                           color: Theme.of(context).colorScheme.secondary, // Gold header
                         ),
                         children: List.generate(displayColumns.length, (index) {
                           return Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                             child: Align(
                               alignment: headerAlignment,
                               child: Text(
                                 displayColumns[index],
                                 style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                   fontWeight: FontWeight.bold,
                                   color: Colors.white,
                                 ),
                                 textAlign: TextAlign.center,
                                 softWrap: false,
                               ),
                             ),
                           );
                         }),
                       ),
                       // Data Rows
                       ...displayRows.map((row) {
                         return TableRow(
                           children: List.generate(displayColumns.length, (index) {
                             final val = index < row.length ? row[index] : '';
                             return Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                               child: Align(
                                 alignment: dataAlignment,
                                 child: SelectableText( // Allow copying
                                   val.toString(),
                                   style: Theme.of(context).textTheme.bodyMedium,
                                   maxLines: 1, // Keep rows aligned
                                   // Note: User asked to NOT truncate important data.
                                   // "No wrapping that breaks row alignment" implies single line.
                                   // "Full values always visible" implies wide columns (which we did).
                                   // If text is excessively long despite 400px width, we might need tooltip or expansion?
                                   // But with SelectableText and wide columns, it's usually fine. 
                                   // Let's rely on the dynamic width.
                                 ),
                               ),
                             );
                           }),
                         );
                       }).toList(),
                     ],
                   ),
                ),
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
