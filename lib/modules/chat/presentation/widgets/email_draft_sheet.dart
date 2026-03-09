import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:business_analytics_chat/modules/chat/state/chat_state.dart';
import 'package:business_analytics_chat/modules/auth/state/auth_notifier.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';

class EmailDraftSheet extends ConsumerStatefulWidget {
  final ChatMessage message;

  const EmailDraftSheet({super.key, required this.message});

  @override
  ConsumerState<EmailDraftSheet> createState() => _EmailDraftSheetState();
}

class _EmailDraftSheetState extends ConsumerState<EmailDraftSheet> {
  late TextEditingController _fromController;
  late TextEditingController _toController;
  late TextEditingController _subjectController;
  late TextEditingController _commentsController;
  
  // Custom controllers for each block to maintain editability
  final List<TextEditingController> _blockControllers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: 'drishti@orientbell.com');
    _toController = TextEditingController();
    _subjectController = TextEditingController();
    _commentsController = TextEditingController();
    _initializeFields();
  }

  Future<void> _initializeFields() async {
    final authService = ref.read(authServiceProvider);
    final userEmail = await authService.getUserEmail();
    
    final token = await authService.getToken();
    String? userName;
    if (token != null) {
      final data = authService.getTokenData(token);
      userName = data?['name'] ?? data?['username'] ?? data?['first_name'];
    }
    
    // Default TO address as requested
    _toController.text = "ravinit001@gmail.com";

    // Attempt to find the question that generated this report
    String? question;
    final conversation = ref.read(activeConversationProvider);
    if (conversation != null) {
      final msgIndex = conversation.messages.indexWhere((m) => m.id == widget.message.id);
      if (msgIndex > 0) {
        final prevMsg = conversation.messages[msgIndex - 1];
        if (prevMsg.isUser) {
          question = prevMsg.content;
        }
      }
    }

    _generateSubject();
    _generateBlocks(userName, question);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateSubject() {
    String subject = '';
    for (var block in widget.message.blocks) {
      if (block.type == 'text') {
        final text = block.data['text'] as String? ?? '';
        final lines = text.split('\n');
        for (var line in lines) {
          if (line.startsWith('#')) {
            subject = line.replaceAll('#', '').trim();
            break;
          }
        }
      }
      if (subject.isNotEmpty) break;
    }

    if (subject.isEmpty) {
      final summary = widget.message.content.trim();
      if (summary.startsWith('Hello') || summary.startsWith('Dear')) {
        subject = 'Analytics Insights Report';
      } else {
        subject = summary.split('\n').first;
        if (subject.length > 50) {
          subject = '${subject.substring(0, 47)}...';
        }
      }
    }
    _subjectController.text = 'Analytics Report: $subject';
  }

  void _generateBlocks(String? userName, String? question) {
    _blockControllers.clear();
    
    // 0. Header Controller (Greeting, Date, Subject, Query)
    String greeting = userName != null ? 'Dear $userName,' : 'Dear Customer,';
    String dateStr = "${DateTime.now().day} ${_getMonth(DateTime.now().month)} ${DateTime.now().year}";
    String headerText = '$greeting\n\nDate: $dateStr\nSubject: ${_subjectController.text}';
    if (question != null && question.isNotEmpty) {
      headerText += '\n\nQUERY: "$question"';
    }
    headerText += '\n\nPlease find the detailed business analytics report prepared by Drishti AI below. This report provides key insights and metrics based on your latest data queries.\n';
    _blockControllers.add(TextEditingController(text: headerText));

    // 1. Executive Summary Controller
    _blockControllers.add(TextEditingController(
      text: 'EXECUTIVE SUMMARY\n${'=' * 17}\n${widget.message.content.trim()}\n'
    ));

    // 2+. Middle content controllers mapping to message blocks
    for (var block in widget.message.blocks) {
      if (_shouldBlockHaveTextArea(block)) {
        final content = _getRawBlockContent(block).trim();
        if (content.isEmpty) continue;
        
        String header = '';
        if (block.type == 'metrics') header = 'KEY PERFORMANCE INDICATORS\n${'-' * 26}\n';
        
        _blockControllers.add(TextEditingController(text: '$header$content'));
      }
    }

    // Last: Closing block controller
    _blockControllers.add(TextEditingController(
      text: '\nWe hope this analysis proves valuable for your business decisions. Please reach out if you require further assistance or deeper insights.\n\nBest regards,'
    ));
  }

  bool _shouldBlockHaveTextArea(BlockData block) {
    if (block.type == 'table' || block.type == 'chart' || block.type == 'suggestions') return false;
    final content = _getRawBlockContent(block).trim();
    if (content.isEmpty) return false;

    if (block.type == 'text') {
      // 1. Skip if it's already in the executive summary
      bool isAlreadyInSummary = content == widget.message.content.trim() || 
                               content.contains(widget.message.content.trim()) ||
                               widget.message.content.trim().contains(content);
      if (isAlreadyInSummary) return false;

      // 2. Allow if it contains a table - we will format it in _formatToHtml
      // Previously skipped to avoid redundancy, but now we ensure it's rendered correctly.
      if (content.contains('|') && content.contains('---')) return true;

      // 3. Skip if it looks like a simple table title/placeholder
      final upperContent = content.toUpperCase();
      if ((upperContent.contains('TABLE') || upperContent.contains('CHART')) && 
          (content.contains('📊') || content.contains('📈') || content.contains('---')) &&
          content.length < 100) {
        return false;
      }
    }
    return true;
  }

  String _getRawBlockContent(BlockData block) {
    if (block.type == 'text') {
      return block.data['content'] as String? ?? block.data['text'] as String? ?? '';
    }
    if (block.type == 'metrics') return _processMetricsData(block.data);
    if (block.type == 'suggestions') return _processSuggestionsData(block.data);
    if (block.type == 'table') return _processTableData(block.data);
    if (block.type == 'chart') return _processChartData(block.data);
    return '';
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  String _processMetricsData(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    final summary = data['summary'] as String?;
    final period = data['period'] as String?;
    final metrics = (data['metrics'] as List? ?? []).cast<Map<String, dynamic>>();

    if (summary != null) buffer.writeln(summary);
    if (period != null) buffer.writeln("Reporting Period: $period");
    buffer.writeln();

    for (var m in metrics) {
      final label = m['label']?.toString().toUpperCase() ?? '';
      final value = m['value']?.toString() ?? '';
      final change = m['change'] != null ? " (${m['change']})" : "";
      buffer.writeln("• $label: $value$change");
    }
    return buffer.toString();
  }

  String _processTableData(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    final title = data['title'] as String? ?? 'Data Table';
    final headers = List<String>.from(data['headers'] ?? data['columns'] ?? []);
    final rows = List<dynamic>.from(data['rows'] ?? []);

    if (title.isNotEmpty) buffer.writeln("📊 $title\n${"-" * (title.length + 3)}");
    if (headers.isNotEmpty) {
      buffer.writeln("| ${headers.join(" | ")} |");
      buffer.writeln("| ${headers.map((_) => "---").join(" | ")} |");
    }
    for (var row in rows) {
      if (row is List) {
        buffer.writeln("| ${row.join(" | ")} |");
      } else if (row is Map) {
        final values = headers.map((h) => row[h]?.toString() ?? "").toList();
        buffer.writeln("| ${values.join(" | ")} |");
      }
    }
    return buffer.toString();
  }

  String _processChartData(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    final title = data['title'] as String? ?? 'Analytics Chart';
    buffer.writeln("📈 Chart: $title");
    
    final rawItems = data['data'] ?? data['items'] ?? data['rows'] ?? data['chart_data'] ?? data['chartData'];
    if (rawItems is List) {
      for (var point in rawItems) {
        buffer.writeln("• $point");
      }
    }
    return buffer.toString();
  }

  String? _getChartUrl(Map<String, dynamic> data) {
    try {
      debugPrint('📊 _getChartUrl: Processing block data: $data');
      final type = (data['chart_type'] ?? data['chartType'] ?? 'bar').toString().toLowerCase();
      final List<String> labels = [];
      final List<Map<String, dynamic>> datasetsConfig = [];
      
      // NEW: Support for Axis-based structure (x_axis and y_axis)
      if (data.containsKey('x_axis') && data.containsKey('y_axis')) {
        final xAxis = data['x_axis'] as Map<String, dynamic>;
        final yAxis = data['y_axis'] as Map<String, dynamic>;
        
        final xData = xAxis['data'] as List?;
        if (xData != null) {
          labels.addAll(xData.map((e) => "'${e.toString().replaceAll("'", "\\'")}'"));
        }
        
        final yDatasets = yAxis['datasets'] as List?;
        if (yDatasets != null) {
          final List<String> colors = ['rgba(45, 106, 79, 0.8)', 'rgba(255, 192, 0, 0.8)', 'rgba(0, 121, 107, 0.8)', 'rgba(211, 47, 47, 0.8)'];
          int colorIdx = 0;
          
          for (var ds in yDatasets) {
            if (ds is Map) {
              final dsLabel = (ds['label'] ?? 'Series').toString().toUpperCase();
              final dsValues = ds['data'] as List?;
              if (dsValues != null) {
                final color = colors[colorIdx % colors.length];
                datasetsConfig.add({
                  'label': dsLabel,
                  'backgroundColor': color,
                  'borderColor': color,
                  'borderWidth': 1,
                  'data': dsValues
                });
                colorIdx++;
              }
            }
          }
        }
      } 
      // FALLBACK: Row-based orientation (the previous logic)
      else {
        dynamic rawItems = data['data'] ?? data['items'] ?? data['rows'] ?? data['chart_data'] ?? data['chartData'];
        if (rawItems == null || rawItems is! List) {
          if (data['series'] is List) rawItems = data['series'];
          else if (data['points'] is List) rawItems = data['points'];
        }

        if (rawItems == null || rawItems is! List || (rawItems as List).isEmpty) {
          // One final check: looking into any list
          for (var value in data.values) {
            if (value is List && value.isNotEmpty) { rawItems = value; break; }
          }
        }

        if (rawItems != null && rawItems is List && (rawItems as List).isNotEmpty) {
          final List<dynamic> items = rawItems;
          final List<String> seriesKeys = [];
          final Set<String> labelKeys = {'label', 'name', 'category', 'x', 'month', 'date', 'day', 'dealer', 'city', 'product', 'branch'};

          bool isNumeric(dynamic v) => v is num || (v is String && double.tryParse(v) != null);

          if (items.first is Map) {
            final Map firstMap = items.first;
            firstMap.forEach((k, v) {
              if (isNumeric(v) && !labelKeys.contains(k.toString().toLowerCase())) seriesKeys.add(k.toString());
            });
            if (seriesKeys.isEmpty) {
              for (var k in firstMap.keys) if (isNumeric(firstMap[k])) { seriesKeys.add(k.toString()); break; }
            }
          }

          if (seriesKeys.isNotEmpty || items.first is List) {
            final Map<String, List<num>> seriesData = {for (var k in seriesKeys) k: []};
            for (var item in items) {
              if (item is Map) {
                String l = 'Point';
                for (var lk in labelKeys) if (item.containsKey(lk)) { l = item[lk].toString().replaceAll("'", "\\'"); break; }
                labels.add("'$l'");
                for (var sk in seriesKeys) seriesData[sk]!.add(double.tryParse(item[sk].toString()) ?? 0.0);
              } else if (item is List && item.length >= 2) {
                labels.add("'${item[0].toString().replaceAll("'", "\\'")}'");
                seriesData['Value'] = seriesData['Value'] ?? [];
                seriesData['Value']!.add(double.tryParse(item[1].toString()) ?? 0.0);
              }
            }

            final List<String> colors = ['rgba(45, 106, 79, 0.8)', 'rgba(255, 192, 0, 0.8)'];
            int colorIdx = 0;
            seriesData.forEach((key, vals) {
              final color = colors[colorIdx % colors.length];
              datasetsConfig.add({
                'label': key.toUpperCase(),
                'backgroundColor': color,
                'borderColor': color,
                'borderWidth': 1,
                'data': vals
              });
              colorIdx++;
            });
          }
        }
      }

      if (labels.isEmpty || datasetsConfig.isEmpty) {
        debugPrint('⚠️ _getChartUrl: Labels or Datasets empty. Labels: ${labels.length}, Datasets: ${datasetsConfig.length}');
        return null;
      }

      final List<String> datasetsJson = datasetsConfig.map((ds) => 
        "{label:'${ds['label']}',backgroundColor:'${ds['backgroundColor']}',borderColor:'${ds['borderColor']}',borderWidth:1,data:[${ds['data'].join(',')}]}"
      ).toList();

      final chartConfig = "{type:'$type',data:{labels:[${labels.join(',')}],datasets:[${datasetsJson.join(',')}]},options:{plugins:{legend:{display:true}}}}";
      final finalUrl = "https://quickchart.io/chart?c=${Uri.encodeComponent(chartConfig)}&w=600&h=300&v=2.9.4";
      debugPrint('📊 _getChartUrl: Success! Generated URL: $finalUrl');
      return finalUrl;
    } catch (e) {
      debugPrint('❌ _getChartUrl Error: $e');
      return null;
    }
  }

  String _processChartToHtml(Map<String, dynamic> data) {
    final title = (data['title'] ?? data['label'] ?? 'Data Visualization').toString();
    final url = _getChartUrl(data);
    
    if (url == null) return '';

    return '''
    <div style="margin: 30px 0; padding: 20px; border: 1px solid #f0f0f0; border-radius: 16px; background-color: #ffffff; text-align: center; box-shadow: 0 4px 15px rgba(0,0,0,0.05);">
      <h4 style="margin: 0 0 15px 0; color: #1a1a1a; font-family: Arial, sans-serif; font-size: 16px;">📊 $title</h4>
      <div style="overflow: hidden; border-radius: 8px;">
        <a href="$url" target="_blank">
          <img src="$url" style="width: 100%; max-width: 500px;" alt="$title" />
        </a>
      </div>
      <p style="margin: 12px 0 0 0; font-size: 11px; color: #999;">(Tap to enlarge visualization)</p>
    </div>
    ''';
  }

  String _processSuggestionsData(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    final items = List<String>.from(data['items'] ?? data['suggestions'] ?? []);
    if (items.isEmpty) return "";
    buffer.writeln("Suggested follow-ups (optional):\n${"-" * 26}");
    for (var item in items) {
      buffer.writeln("• $item");
    }
    return buffer.toString();
  }

  String _formatToHtml(String text) {
    if (text.isEmpty) return '';

    // 1. Process Headings: ### Title (###) -> <h3 style="...">Title</h3>
    // Use multi-line and more lenient pattern to catch headers correctly
    String html = text.replaceAllMapped(RegExp(r'^\s*(#{1,6})\s+(.*?)\s*$', multiLine: true), (match) {
      final level = match.group(1)!.length;
      final fontSize = level == 1 ? '24px' : (level == 2 ? '20px' : '18px');
      return '<h$level style="margin: 24px 0 12px 0; color: #2D6A4F; font-size: $fontSize; font-weight: bold; padding-bottom: 4px;">${match.group(2)}</h$level>';
    });

    // 2. Process Bold Highlights: **text** -> <strong>text</strong>
    // Styled as high-premium highlights matching the image requirement
    html = html.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (match) {
      return '<strong style="font-weight: 600; color: #1a1a1a; background-color: #f5f5f5; padding: 1px 6px; border-radius: 4px; display: inline-block;">${match.group(1)}</strong>';
    });
    
    // 3. Process Italics: *text* -> <em>text</em>
    html = html.replaceAllMapped(RegExp(r'\*(.*?)\*'), (match) {
      return '<em style="font-style: italic; color: #555;">${match.group(1)}</em>';
    });

    // 4. Process Horizontal Rules: --- or ===
    html = html.replaceAll(RegExp(r'^\s*[\-\=]{3,}\s*$', multiLine: true), '<hr style="border: 0; border-top: 1px solid #eee; margin: 16px 0;"/>');

    // 5. Process Lists: lines starting with * or - -> <li>
    // Find blocks of list items and wrap them in <ul>
    final listRegex = RegExp(r'^(\s*[\*\-]\s+.*(?:\n\s*[\*\-]\s+.*)*)', multiLine: true);
    html = html.replaceAllMapped(listRegex, (match) {
      final listContent = match.group(1)!;
      final items = listContent.trim().split('\n');
      final listItemsHtml = items.map((item) {
        final content = item.replaceFirst(RegExp(r'^\s*[\*\-]\s+'), '').trim();
        return '<li style="margin-bottom: 6px; padding-left: 4px;">$content</li>';
      }).join('');
      return '<ul style="margin: 12px 0; padding-left: 24px; list-style-type: disc;">$listItemsHtml</ul>';
    });

    // 6. Process Tables: Markdown style | h1 | h2 | -> <table>
    // This is a simplified markdown table parser
    final tableRegex = RegExp(r'((?:^\|.*\|$\n?)+)', multiLine: true);
    html = html.replaceAllMapped(tableRegex, (match) {
      final tableContent = match.group(1)!;
      final lines = tableContent.trim().split('\n');
      if (lines.length < 2) return tableContent;

      final buffer = StringBuffer();
      buffer.writeln('<table style="border-collapse: collapse; width: 100%; margin: 15px 0; font-size: 13px; border: 1px solid #eee;">');
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('---|')) continue; // Skip separator line
        
        final cells = line.split('|').where((s) => s.trim().split('').isNotEmpty || s == '').toList();
        // Remove first and last empty cells if they exist (from leading/trailing pipelines)
        if (cells.isNotEmpty && cells.first.trim().isEmpty) cells.removeAt(0);
        if (cells.isNotEmpty && cells.last.trim().isEmpty) cells.removeAt(cells.length - 1);

        final tag = (i == 0) ? 'th' : 'td';
        final style = (i == 0) 
            ? 'background-color: #f8f8f8; font-weight: bold; padding: 10px; border: 1px solid #eee; text-align: left;'
            : 'padding: 8px; border: 1px solid #eee; text-align: left;';
            
        buffer.writeln('<tr>');
        for (var cell in cells) {
          buffer.writeln('<$tag style="$style">${cell.trim()}</$tag>');
        }
        buffer.writeln('</tr>');
      }
      buffer.writeln('</table>');
      return buffer.toString();
    });

    // 7. Final wrapping of paragraphs
    final lines = html.split('\n');
    final buffer = StringBuffer();
    bool inList = false;
    bool inTable = false;

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        if (!inList && !inTable) buffer.write('<div style="height: 12px;"></div>');
        continue;
      }

      // If it's already a tag we shouldn't wrap (H1-6, UL, LI, HR, TABLE)
      if (trimmed.startsWith('<h') || 
          trimmed.startsWith('<ul') || 
          trimmed.startsWith('<li') || 
          trimmed.startsWith('</ul') || 
          trimmed.startsWith('<hr') ||
          trimmed.startsWith('<table') ||
          trimmed.startsWith('<tr') ||
          trimmed.startsWith('</table')) {
        buffer.write(trimmed);
        inList = trimmed.startsWith('<ul') || (trimmed.startsWith('<li') && inList);
        if (trimmed.startsWith('</ul')) inList = false;
        
        if (trimmed.startsWith('<table')) inTable = true;
        if (trimmed.startsWith('</table')) inTable = false;
      } else {
        if (inTable) {
          buffer.write(trimmed);
        } else {
          buffer.write('<p style="margin: 0 0 12px 0; font-size: 14px; color: #333; line-height: 1.6;">$trimmed</p>');
        }
      }
    }

    return buffer.toString();
  }

  String _processTableToHtml(Map<String, dynamic> data, String tableStyle, String thStyle, String tdStyle) {
    final buffer = StringBuffer();
    final title = data['title'] as String? ?? 'Data Table';
    
    // Support multiple row keys
    final rows = List<dynamic>.from(data['rows'] ?? data['data'] ?? data['items'] ?? []);
    
    // Support multiple header keys or auto-extract from Map rows
    List<String> headers = List<String>.from(data['headers'] ?? data['columns'] ?? []);
    if (headers.isEmpty && rows.isNotEmpty && rows.first is Map) {
      headers = (rows.first as Map).keys.map((k) => k.toString()).toList();
    }

    if (title.isNotEmpty) buffer.writeln('<h4 style="margin-bottom: 5px; color: #1a1a1a;">📊 $title</h4>');
    
    buffer.writeln('<table style="$tableStyle">');
    
    // Headers
    if (headers.isNotEmpty) {
      buffer.writeln('<thead><tr>');
      for (var h in headers) {
        buffer.writeln('<th style="$thStyle">$h</th>');
      }
      buffer.writeln('</tr></thead>');
    }

    // Rows
    buffer.writeln('<tbody>');
    for (var row in rows) {
      buffer.writeln('<tr>');
      if (row is List) {
        for (var cell in row) {
          buffer.writeln('<td style="$tdStyle">${cell.toString()}</td>');
        }
      } else if (row is Map) {
        for (var h in headers) {
          buffer.writeln('<td style="$tdStyle">${row[h]?.toString() ?? ""}</td>');
        }
      }
      buffer.writeln('</tr>');
    }
    buffer.writeln('</tbody></table>');
    
    return buffer.toString();
  }

  String _processMetricsToHtml(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    final metrics = (data['metrics'] as List? ?? []).cast<Map<String, dynamic>>();

    buffer.writeln('<div style="margin: 20px 0; padding: 15px; background-color: #fdfaf0; border: 1px solid #D4AF37; border-radius: 8px;">');
    buffer.writeln('<h4 style="margin: 0 0 15px 0; color: #D4AF37; text-transform: uppercase;">KEY PERFORMANCE INDICATORS</h4>');
    
    buffer.writeln('<div style="display: flex; flex-wrap: wrap; gap: 20px;">');
    for (var m in metrics) {
      final label = m['label']?.toString().toUpperCase() ?? '';
      final value = m['value']?.toString() ?? '';
      final change = m['change'] != null ? " (${m['change']})" : "";
      
      buffer.writeln('<div style="margin-bottom: 10px; min-width: 200px;">'
                     '<span style="font-weight: bold; color: #666; font-size: 11px;">$label</span><br/>'
                     '<span style="font-size: 18px; color: #1a1a1a; font-weight: bold;">$value</span>'
                     '<span style="color: ${m['change']?.toString().contains('-') == true ? '#d32f2f' : '#2e7d32'}; font-size: 12px; margin-left: 5px;">$change</span>'
                     '</div>');
    }
    buffer.writeln('</div></div>');
    return buffer.toString();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _subjectController.dispose();
    _commentsController.dispose();
    for (var c in _blockControllers) {
      c.dispose();
    }
    super.dispose();
  }


  void _sendEmail() async {
    setState(() => _isLoading = true);
    
    try {
      final List<String> htmlParts = [];
      
      // CSS Styling for formal appearance - Using Brand Colors (Drishti Green)
      const String tableStyle = 'border-collapse: collapse; width: 100%; margin: 20px 0; font-size: 14px; font-family: Arial, sans-serif; border: 1px solid #eee;';
      const String thStyle = 'background-color: #2D6A4F; color: white; text-align: left; padding: 12px; border: 1px solid #2D6A4F;';
      const String tdStyle = 'padding: 10px; border: 1px solid #eee; text-align: left; color: #333;';
      
      htmlParts.add('<div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 800px; margin: 0 auto; padding: 20px; border: 1px solid #f0f0f0;">');
      
      // 1. Initial greeting/header block
      if (_blockControllers.isNotEmpty) {
        htmlParts.add(_formatToHtml(_blockControllers[0].text));
      }
      
      // 2. Additional user comments (inserted after the header)
      if (_commentsController.text.trim().isNotEmpty) {
        htmlParts.add('<div style="background-color: #f9f9f9; border-left: 4px solid #2D6A4F; padding: 12px; margin: 20px 0;">'
                      '<h4 style="margin-top: 0; color: #2D6A4F;">USER COMMENTS</h4>'
                      '${_formatToHtml(_commentsController.text.trim())}'
                      '</div>');
      }
      
      int controllerIndex = 1;
      
      // 2. Executive summary (Always use the controller so user edits are preserved)
      if (controllerIndex < _blockControllers.length) {
        htmlParts.add('<div style="margin-bottom: 20px;">' + _formatToHtml(_blockControllers[controllerIndex++].text) + '</div>');
      }
      
      // 4. Middle blocks (text, tables, charts, metrics)
      for (var block in widget.message.blocks) {
        if (block.type == 'table') {
          htmlParts.add(_processTableToHtml(block.data, tableStyle, thStyle, tdStyle));
        } else if (block.type == 'chart') {
          final chartHtml = _processChartToHtml(block.data);
          if (chartHtml.isNotEmpty) {
            htmlParts.add(chartHtml);
          } else {
            // Fallback to text representation if visual chart generation failed
            htmlParts.add(_formatToHtml(_processChartData(block.data)));
          }
        } else if (_shouldBlockHaveTextArea(block)) {
          // Note: metrics are covered here because _shouldBlockHaveTextArea returns true for them
          if (controllerIndex < _blockControllers.length - 1) { // Leave the last one for closing
            htmlParts.add('<div style="margin-bottom: 20px;">' + _formatToHtml(_blockControllers[controllerIndex++].text) + '</div>');
          }
        }
      }
      
      // 5. Closing block (Last controller)
      if (controllerIndex < _blockControllers.length) {
        htmlParts.add('<div style="margin-top: 30px;">' + _formatToHtml(_blockControllers.last.text) + '</div>');
      }

      htmlParts.add('</div>');

      final htmlContent = htmlParts.join('');
      final subject = _subjectController.text;
      final to = _toController.text;

      final token = await ref.read(authServiceProvider).getToken();
      
      final dio = Dio();
      final response = await dio.post(
        'https://chatbot.fuzionest.com/api/send-email',
        data: {
            "to": to,
            "subject": subject,
            "html": htmlContent,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email sent successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else {
          throw Exception('Failed to send email: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 400,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                Text('Email Draft', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    _buildLabel('Additional Comments (Optional)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _commentsController,
                      maxLines: 4,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Type your comments or notes here...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderGray)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderGray)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Subject'),
                    _buildTextField(_subjectController, readOnly: true),
                    const SizedBox(height: 24),
                    
                    _buildLabel('Draft Body'),
                    const SizedBox(height: 12),
                    
                    // Render blocks
                    ..._buildDraftBlocks(),
                    
                    const SizedBox(height: 16),
                 ],
               ),
             ),
           ),
          
          // Send Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _sendEmail,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text('Send', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDraftBlocks() {
    final List<Widget> widgets = [];
    int controllerIndex = 0;

    // 1. Header (Greeting, Subject, Query)
    if (controllerIndex < _blockControllers.length) {
      widgets.add(_buildEditableTextBlock(_blockControllers[controllerIndex++]));
      widgets.add(const SizedBox(height: 16));
    }

    // 2. Executive Summary
    if (controllerIndex < _blockControllers.length) {
      widgets.add(_buildEditableTextBlock(_blockControllers[controllerIndex++]));
      widgets.add(const SizedBox(height: 16));
    }

    // 3. Dynamic Sequential Blocks
    for (var block in widget.message.blocks) {
      if (block.type == 'table') {
        widgets.add(_buildZoomableTable(block.data));
        widgets.add(const SizedBox(height: 24));
      } else if (block.type == 'chart') {
        widgets.add(_buildChartPlaceholder(block.data));
        widgets.add(const SizedBox(height: 24));
      } else if (_shouldBlockHaveTextArea(block)) {
        if (controllerIndex < _blockControllers.length - 1) { // Leave the last one for footer
          widgets.add(_buildEditableTextBlock(_blockControllers[controllerIndex++]));
          widgets.add(const SizedBox(height: 16));
        }
      }
    }

    // 4. Footer (Closing)
    if (controllerIndex < _blockControllers.length) {
      widgets.add(_buildEditableTextBlock(_blockControllers.last));
    }

    return widgets;
  }

  Widget _buildEditableTextBlock(TextEditingController controller) {
    return TextField(
      controller: controller,
      maxLines: null,
      readOnly: true, // Mail content is not editable as per requirement
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5, color: Colors.black87),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.grey[50], // Light gray to indicate read-only status
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[100]!)),
      ),
    );
  }

  Widget _buildChartPlaceholder(Map<String, dynamic> data) {
    final title = (data['title'] ?? data['label'] ?? 'Data Visualization').toString();
    final url = _getChartUrl(data);

    if (url == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             const Icon(Icons.bar_chart_rounded, size: 16, color: AppColors.accentGreen),
             const SizedBox(width: 8),
            Expanded(
              child: Text("VISUALIZATION PREVIEW: $title", 
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: 200,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                height: 100,
                color: Colors.grey[100],
                child: const Center(child: Text("Preview unavailable - Check connection")),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoomableTable(Map<String, dynamic> data) {
    // Robust data extraction
    final rows = List<dynamic>.from(data['rows'] ?? data['data'] ?? data['items'] ?? []);
    if (rows.isEmpty) return const SizedBox.shrink();
    
    List<String> headers = List<String>.from(data['headers'] ?? data['columns'] ?? []);
    if (headers.isEmpty && rows.first is Map) {
      headers = (rows.first as Map).keys.map((k) => k.toString()).toList();
    }
    
    final title = (data['title'] ?? data['label'] ?? 'Business Analytics Table').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.table_chart_rounded, size: 18, color: AppColors.accentGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title.toUpperCase(), 
                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.accentGreen, letterSpacing: 0.5)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text("(Scroll table to view all data • Pinch to zoom)", 
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[500], fontSize: 10)),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.accentGreen.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(40),
              minScale: 1.0,
              maxScale: 2.5,
              child: DataTable(
                headingRowHeight: 44,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 56,
                columnSpacing: 24,
                headingRowColor: WidgetStateProperty.all(AppColors.accentGreen),
                columns: headers.map((h) => DataColumn(
                  label: Text(h.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12))
                )).toList(),
                rows: rows.map((row) {
                  final cells = rows.first is List 
                      ? (row as List).map((c) => DataCell(Text(c.toString(), style: const TextStyle(fontSize: 13)))).toList()
                      : headers.map((h) => DataCell(Text((row as Map)[h]?.toString() ?? "", style: const TextStyle(fontSize: 13)))).toList();
                  return DataRow(cells: cells);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[600])),
    );
  }

  Widget _buildTextField(TextEditingController controller, {bool readOnly = false}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: readOnly ? Colors.black54 : Colors.black87,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[50] : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
    );
  }
}
