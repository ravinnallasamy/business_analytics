import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';
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

  Widget _buildHeaderIcon(BuildContext context, IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.data['title'] as String? ?? '';
    final rawRows = (widget.data['rows'] as List<dynamic>? ?? []);

    if (_allColumns.isEmpty) return const SizedBox.shrink();

    final displayColumns = _allColumns.where((c) => _visibleColumns.contains(c)).toList();
    
    final List<List<dynamic>> displayRows = [];
    for (var row in rawRows) {
      if (row is List) {
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
              child: Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isCompact = screenWidth < 500;
                  
                  Widget headerTitle = title.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        )
                      : const SizedBox.shrink();

                  Widget searchField = Expanded(
                    flex: isCompact ? 0 : 1,
                    child: SizedBox(
                      height: 40,
                      width: isCompact ? double.infinity : null,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search data...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  );

                  Widget actions = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeaderIcon(context, Icons.visibility_outlined, 'Columns', _showColumnSelector),
                      const SizedBox(width: 8),
                      _buildHeaderIcon(context, Icons.download_rounded, 'Export CSV', () => _exportData(displayColumns, displayRows)),
                    ],
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        headerTitle,
                        Row(
                          children: [
                            searchField, 
                            const SizedBox(width: 8),
                            actions,
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      if (title.isNotEmpty) headerTitle,
                      const SizedBox(width: 16),
                      searchField,
                      const SizedBox(width: 8),
                      actions,
                    ],
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),

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
                    child: SizedBox(
                       width: tableWidth,
                       child: Table(
                         columnWidths: tableColumnWidths,
                         defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                         border: TableBorder.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1,
                         ),
                         children: [
                           TableRow(
                             decoration: BoxDecoration(
                               color: Theme.of(context).colorScheme.secondary,
                             ),
                             children: List.generate(displayColumns.length, (index) {
                               return Padding(
                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                 child: Align(
                                   alignment: headerAlignment,
                                   child: Text(
                                     displayColumns[index],
                                     style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                       color: Colors.white,
                                     ),
                                     textAlign: TextAlign.center,
                                     softWrap: false,
                                   ),
                                 ),
                               );
                             }),
                           ),
                           ...displayRows.map((row) {
                             return TableRow(
                               children: List.generate(displayColumns.length, (index) {
                                 final val = index < row.length ? row[index] : '';
                                 return Padding(
                                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                   child: Align(
                                     alignment: dataAlignment,
                                     child: SelectableText(
                                       val.toString(),
                                       style: Theme.of(context).textTheme.bodyMedium,
                                       maxLines: 1,
                                     ),
                                   ),
                                 );
                               }),
                             );
                           }),
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
