import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:business_analytics_chat/features/auth/state/auth_notifier.dart';
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
    
    if (userEmail != null) {
      _toController.text = userEmail;
    }

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
      subject = widget.message.content.split('\n').first;
      if (subject.length > 50) {
        subject = '${subject.substring(0, 47)}...';
      }
    }
    _subjectController.text = 'Analytics Report: $subject';
  }

  void _generateBlocks(String? userName, String? question) {
    _blockControllers.clear();
    
    // 1. Initial greeting block with formal header
    String greeting = userName != null ? 'Dear $userName,' : 'Dear Customer,';
    String dateStr = "${DateTime.now().day} ${_getMonth(DateTime.now().month)} ${DateTime.now().year}";
    
    String headerText = '$greeting\n\nDate: $dateStr\nSubject: ${_subjectController.text}';
    if (question != null && question.isNotEmpty) {
      headerText += '\n\nQUERY: "$question"';
    }
    
    headerText += '\n\nPlease find the detailed business analytics report prepared by Drishti AI below. This report provides key insights and metrics based on your latest data queries.\n';

    _blockControllers.add(TextEditingController(text: headerText));

    // 2. Executive Summary
    if (widget.message.content.trim().isNotEmpty) {
      _blockControllers.add(TextEditingController(
        text: 'EXECUTIVE SUMMARY\n${'=' * 17}\n${widget.message.content.trim()}\n'
      ));
    }

    // 3. Middle content (text, metrics)
    for (var block in widget.message.blocks) {
      if (_shouldBlockHaveTextArea(block)) {
        final content = _getRawBlockContent(block).trim();
        String header = '';
        if (block.type == 'metrics') header = 'KEY PERFORMANCE INDICATORS\n${'-' * 26}\n';
        
        _blockControllers.add(TextEditingController(
          text: '$header$content'
        ));
      }
    }

    // 4. Closing block
    _blockControllers.add(TextEditingController(
      text: '\nWe hope this analysis proves valuable for your business decisions. Please reach out if you require further assistance or deeper insights.\n\nBest regards,\n\nDrishti AI Team\ndrishti@orientbell.com\nOrientbell Tiles'
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

      // 2. Skip if it contains a markdown table (AI redundant output)
      if (content.contains('|') && content.contains('---')) return false;

      // 3. Skip if it looks like a table header/placeholder (e.g. "📊 DATA TABLE")
      final upperContent = content.toUpperCase();
      if ((upperContent.contains('TABLE') || upperContent.contains('CHART')) && 
          (content.contains('📊') || content.contains('📈') || content.contains('---') || content.contains('===')) &&
          content.length < 150) {
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
    buffer.writeln("📈 $title\n${"-" * (title.length + 3)}");
    final chartData = data['data'] as List?;
    if (chartData != null) {
      for (var point in chartData) buffer.writeln("• $point");
    }
    return buffer.toString();
  }

  String _processSuggestionsData(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    final items = List<String>.from(data['items'] ?? data['suggestions'] ?? []);
    if (items.isEmpty) return "";
    buffer.writeln("Suggested follow-ups (optional):\n${"-" * 26}");
    for (var item in items) buffer.writeln("• $item");
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
                Text('Email Draft', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                      style: const TextStyle(fontSize: 14),
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
                    _buildTextField(_subjectController),
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
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mail sending will be enabled later'), behavior: SnackBarBehavior.floating)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Send', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

    // 1. Initial greeting block
    if (controllerIndex < _blockControllers.length) {
      widgets.add(_buildEditableTextBlock(_blockControllers[controllerIndex++]));
      widgets.add(const SizedBox(height: 16));
    }

    // 2. Executive summary block
    if (widget.message.content.trim().isNotEmpty && controllerIndex < _blockControllers.length) {
      widgets.add(_buildEditableTextBlock(_blockControllers[controllerIndex++]));
      widgets.add(const SizedBox(height: 16));
    }

    // 3. Middle blocks
    for (var block in widget.message.blocks) {
      if (block.type == 'table') {
        widgets.add(_buildZoomableTable(block.data));
        widgets.add(const SizedBox(height: 16));
      } else if (block.type == 'chart') {
        widgets.add(_buildChartPlaceholder(block.data));
        widgets.add(const SizedBox(height: 16));
      } else if (_shouldBlockHaveTextArea(block)) {
        if (controllerIndex < _blockControllers.length) {
          widgets.add(_buildEditableTextBlock(_blockControllers[controllerIndex++]));
          widgets.add(const SizedBox(height: 16));
        }
      }
    }

    // 4. Closing block
    if (controllerIndex < _blockControllers.length) {
      widgets.add(_buildEditableTextBlock(_blockControllers[controllerIndex]));
    }

    return widgets;
  }

  Widget _buildEditableTextBlock(TextEditingController controller) {
    return TextField(
      controller: controller,
      maxLines: null,
      readOnly: true, // Mail content is not editable as per requirement
      style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
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
    final title = data['title'] as String? ?? 'Analytics Chart';
    final chartType = (data['chart_type'] as String? ?? 'bar').toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             const Icon(Icons.bar_chart_rounded, size: 16, color: Colors.blueAccent),
             const SizedBox(width: 8),
             Text("HIGH-RES VISUAL: $title ($chartType CHART)", 
               style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent.withOpacity(0.05), Colors.blueAccent.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insert_chart_outlined_rounded, size: 48, color: Colors.blueAccent.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                "Image Placeholder for $chartType Chart",
                style: TextStyle(color: Colors.blueAccent.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                "Final email will include the generated visualization.",
                style: TextStyle(color: Colors.blueAccent.withOpacity(0.6), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZoomableTable(Map<String, dynamic> data) {
    final headers = List<String>.from(data['headers'] ?? data['columns'] ?? []);
    final rows = List<dynamic>.from(data['rows'] ?? []);
    final title = data['title'] as String? ?? 'Data Table';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.zoom_in, size: 16, color: AppColors.accentGreen),
            const SizedBox(width: 8),
            Text("INTERACTIVE TABLE: $title (Pinch to zoom)", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 300,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.1,
            maxScale: 3.0,
            constrained: false,
            child: Theme(
              data: Theme.of(context).copyWith(cardColor: Colors.white),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.accentGreen),
                columns: headers.map((h) => DataColumn(
                  label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
                )).toList(),
                rows: rows.map((row) {
                  final cells = (row is List) 
                      ? row.map((c) => DataCell(Text(c.toString()))).toList()
                      : headers.map((h) => DataCell(Text((row as Map)[h]?.toString() ?? ""))).toList();
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
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600])),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
    );
  }
}
