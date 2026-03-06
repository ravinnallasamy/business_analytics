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
  int _rowsLimit = 10;

  @override
  void initState() {
    super.initState();
    final rawColumns = widget.data['headers'] ?? widget.data['columns'];
    _allColumns = (rawColumns is List)
        ? rawColumns.map((e) => e.toString()).toList()
        : <String>[];
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

  Future<void> _exportData(
      List<String> columns, List<List<dynamic>> rows) async {
    try {
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
            if (!status.isGranted) return;
          }
        }
        // iOS does not require storage permission for getApplicationDocumentsDirectory()
      }

      List<List<dynamic>> csvData = [columns, ...rows];

      String csv = const ListToCsvConverter().convert(csvData);

      if (kIsWeb) {
        debugPrint('CSV Export Content:\n$csv');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Export functionality is limited on Web demo')),
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/table_export_${DateTime.now().millisecondsSinceEpoch}.csv';
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

  Widget _buildHeaderIcon(BuildContext context, IconData icon, String tooltip,
      VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.5),
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

    final displayColumns =
        _allColumns.where((c) => _visibleColumns.contains(c)).toList();

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

    final List<double> minWidths =
        displayColumns.map((c) => (c.length * 11.0) + 40.0).toList();
    for (var row in displayRows) {
      for (int i = 0; i < displayColumns.length; i++) {
        if (i < row.length) {
          final double w = (row[i].toString().length * 11.0) + 40.0;
          if (w > minWidths[i]) minWidths[i] = w;
        }
      }
    }
    final widths = minWidths
        .map((w) => w < 100.0 ? 100.0 : (w > 400.0 ? 400.0 : w))
        .toList();

    final tableColumnWidths = {
      for (var i = 0; i < displayColumns.length; i++)
        i: FlexColumnWidth(widths[i]),
    };

    final totalWidth = widths.fold(0.0, (sum, w) => sum + w);

    const headerAlignment = Alignment.center;
    const dataAlignment = Alignment.centerLeft;

    return Container(
      margin: const EdgeInsets.symmetric(
          vertical: 14), // Gemini-style outer spacing
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isCompact = screenWidth < 500;

              Widget headerTitle = title.isNotEmpty
                  ? Text(
                      title,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                    )
                  : const SizedBox.shrink();

              Widget searchField = TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search data...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.1)),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              );

              Widget actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeaderIcon(context, Icons.visibility_outlined,
                      'Columns', _showColumnSelector),
                  const SizedBox(width: 8),
                  _buildHeaderIcon(
                      context,
                      Icons.download_rounded,
                      'Export CSV',
                      () => _exportData(displayColumns, displayRows)),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (title.isNotEmpty) Expanded(child: headerTitle),
                        const SizedBox(width: 8),
                        actions,
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                        height: 40, width: double.infinity, child: searchField),
                  ],
                );
              }

              return Row(
                children: [
                  if (title.isNotEmpty) headerTitle,
                  const SizedBox(width: 16),
                  Expanded(child: SizedBox(height: 40, child: searchField)),
                  const SizedBox(width: 8),
                  actions,
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = totalWidth > constraints.maxWidth
                  ? totalWidth
                  : constraints.maxWidth;
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
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: TableBorder.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                        width: 1,
                      ),
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            color: AppColors.accentGold,
                          ),
                          children:
                              List.generate(displayColumns.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10), // Cell padding
                              child: Align(
                                alignment: headerAlignment,
                                child: Text(
                                  displayColumns[index],
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                  softWrap: false,
                                ),
                              ),
                            );
                          }),
                        ),
                        ...displayRows.take(_rowsLimit).map((row) {
                          return TableRow(
                            children:
                                List.generate(displayColumns.length, (index) {
                              final val = index < row.length ? row[index] : '';
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10), // Cell padding
                                child: Align(
                                  alignment: dataAlignment,
                                  child: Text(
                                    val.toString(),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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

          // Show More / Show Less Buttons
          if (displayRows.length > 10 || _rowsLimit > 10)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_rowsLimit > 10)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _rowsLimit = (_rowsLimit - 10).clamp(10, 1000);
                        });
                      },
                      icon: const Icon(Icons.arrow_drop_up, size: 20),
                      label: const Text('Show Less'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary),
                    ),
                  if (displayRows.length > _rowsLimit)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _rowsLimit += 10;
                          });
                        },
                        icon: const Icon(Icons.arrow_drop_down,
                            size: 20, color: Colors.white),
                        label: const Text('Show More (+10)',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
