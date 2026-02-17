import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class TextBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const TextBlock({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final text = data['text'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingSmall),
      child: MarkdownBody(data: text),
    );
  }
}
