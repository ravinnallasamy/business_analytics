import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';

class TextBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const TextBlock({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final text = data['content'] as String? ?? data['text'] as String? ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    final lines = text.split('\n');
    final List<Widget> widgets = [];
    String currentParagraph = '';

    void flushParagraph() {
      if (currentParagraph.trim().isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: UIConstants.paddingMedium),
            child: MarkdownBody(
              data: currentParagraph.trim(),
              selectable: true,
              styleSheet: _getStyleSheet(context, type: _BlockType.body),
            ),
          ),
        );
        currentParagraph = '';
      }
    }

    bool isFirstBlock = true;
    bool isAfterHeading = false;

    for (final line in lines) {
      final trimmedLine = line.trim();
      
      if (trimmedLine.startsWith('#')) {
        flushParagraph();
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              top: isFirstBlock ? 0 : UIConstants.paddingXLarge,
              bottom: UIConstants.paddingSmall,
            ),
            child: MarkdownBody(
              data: trimmedLine,
              styleSheet: _getStyleSheet(context, type: _BlockType.heading),
            ),
          ),
        );
        isFirstBlock = false;
        isAfterHeading = true;
      } else if (trimmedLine.startsWith('- ') || 
                 trimmedLine.startsWith('* ') || 
                 RegExp(r'^\d+\.\s').hasMatch(trimmedLine)) {
        flushParagraph();
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingVSmall),
            child: MarkdownBody(
              data: trimmedLine,
              styleSheet: _getStyleSheet(context, type: _BlockType.action),
            ),
          ),
        );
        isAfterHeading = false;
      } else if (trimmedLine.isEmpty) {
        flushParagraph();
        isAfterHeading = false;
      } else if (isAfterHeading && trimmedLine.contains(':') && !trimmedLine.startsWith('-')) {
        // Metadata detection: Split label and value for explicit weighting
        widgets.add(_buildMetadataLine(context, trimmedLine));
      } else {
        currentParagraph += '$line\n';
        isAfterHeading = false;
      }
    }
    flushParagraph();

    return Padding(
      padding: const EdgeInsets.only(
        top: UIConstants.paddingSmall,
        bottom: UIConstants.paddingLarge,
        left: UIConstants.paddingMedium,
        right: UIConstants.paddingMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  Widget _buildMetadataLine(BuildContext context, String line) {
    final styleSheet = _getStyleSheet(context, type: _BlockType.metadata);
    final style = styleSheet.p!;
    final colonIndex = line.indexOf(':');
    
    if (colonIndex == -1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: UIConstants.paddingVSmall),
        child: MarkdownBody(data: line, styleSheet: styleSheet),
      );
    }

    // Split at the first colon
    final labelPart = line.substring(0, colonIndex + 1);
    final valuePart = line.substring(colonIndex + 1);

    // Clean up markdown bold markers if present in both parts
    final cleanLabel = labelPart.replaceAll('**', '').trim();
    final cleanValue = valuePart.replaceAll('**', '').trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.paddingVSmall),
      child: RichText(
        text: TextSpan(
          style: style,
          children: [
            TextSpan(
              text: cleanLabel,
              style: style.copyWith(
                fontWeight: FontWeight.bold, // Label-only bolding
                color: AppColors.textPrimary, 
              ),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: cleanValue,
              style: style.copyWith(
                fontWeight: FontWeight.normal, // Explicit style reset for value
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  MarkdownStyleSheet _getStyleSheet(BuildContext context, {required _BlockType type}) {
    final theme = Theme.of(context);
    
    final neutralDark = AppColors.textPrimary;
    final neutralMuted = AppColors.textSecondary;
    final accentColor = AppColors.accentGreen;

    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyLarge?.copyWith(
        height: 1.6, // Slightly increased for better rhythm
        fontSize: switch (type) {
          _BlockType.metadata => theme.textTheme.bodySmall?.fontSize,
          _BlockType.heading => theme.textTheme.headlineLarge?.fontSize,
          _BlockType.body => theme.textTheme.bodyLarge?.fontSize,
          _BlockType.action => theme.textTheme.bodyLarge?.fontSize,
        },
        color: switch (type) {
          _BlockType.heading => neutralDark,
          _BlockType.action => accentColor,
          _BlockType.body => neutralDark.withOpacity(0.85),
          _BlockType.metadata => neutralMuted,
        },
        fontWeight: type == _BlockType.heading
            ? FontWeight.w700
            : (type == _BlockType.action ? FontWeight.w500 : FontWeight.normal),
      ),
      strong: TextStyle(
        fontWeight: FontWeight.bold,
        color: neutralDark,
      ),
      h1: theme.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: neutralDark,
      ),
      h2: theme.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: neutralDark,
      ),
      h3: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: neutralDark,
      ),
      listBullet: theme.textTheme.bodyLarge?.copyWith(
        color: accentColor,
        fontWeight: FontWeight.bold,
      ),
      listBulletPadding: const EdgeInsets.only(right: 12, top: 2), // Improved alignment
      listIndent: 24.0,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            width: 1.0,
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      code: TextStyle(
        fontFamily: 'monospace',
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: theme.textTheme.bodyMedium?.fontSize,
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
      ),
    );
  }
}

enum _BlockType { heading, body, action, metadata }
