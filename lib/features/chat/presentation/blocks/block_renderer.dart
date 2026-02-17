import 'package:flutter/material.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:business_analytics_chat/features/chat/presentation/blocks/text_block.dart';
import 'package:business_analytics_chat/features/chat/presentation/blocks/metrics_block.dart';
import 'package:business_analytics_chat/features/chat/presentation/blocks/table_block.dart';
import 'package:business_analytics_chat/features/chat/presentation/blocks/chart_block.dart';
import 'package:business_analytics_chat/features/chat/presentation/blocks/suggestions_block.dart';

class BlockRenderer extends StatelessWidget {
  final BlockData block;

  const BlockRenderer({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case 'text':
        return TextBlock(data: block.data);
      case 'metrics':
        return MetricsBlock(data: block.data);
      case 'table':
        return TableBlock(data: block.data);
      case 'chart':
        return ChartBlock(data: block.data);
      case 'suggestions':
        return SuggestionsBlock(data: block.data);
      default:
        return Text('Unknown block type: ${block.type}');
    }
  }
}
