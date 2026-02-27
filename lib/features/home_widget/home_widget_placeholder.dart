import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';

class HomeWidgetPlaceholder extends StatelessWidget {
  final String message;

  const HomeWidgetPlaceholder({super.key, this.message = 'No data available'});

  @override
  Widget build(BuildContext context) {
    // Extract the numerical value if possible to make it huge, but fallback to the raw message
    String displayValue = message.replaceAll('**', '');
    
    // Simple heuristic to extract something like "₹66.12 Lacs" if the message is multi-line
    final lines = displayValue.split('\n');
    for (var line in lines) {
      if (line.contains('₹') || line.contains('\$')) {
        // Try to get just the value part if there's a colon
        final parts = line.split(':');
        if (parts.length > 1) {
          displayValue = parts.last.trim();
          break;
        } else {
          displayValue = line.trim();
          break;
        }
      }
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity, // Force full constraints
        decoration: BoxDecoration(
          color: AppColors.sidebarBackground, // Use a dark background to make the value pop
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Graph filling the whole widget
              const Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(top: 40.0), // Push graph down a bit so text is readable
                  child: _AnimatedStockGraph(),
                ),
              ),
              
              // 2. Bright Overlay Text
              Padding(
                padding: const EdgeInsets.all(UIConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayValue,
                      style: const TextStyle(
                        fontSize: 36, // Huge font
                        fontWeight: FontWeight.w900, // Extra bold
                        color: Colors.white, // Very bright
                        height: 1.1,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedStockGraph extends StatefulWidget {
  const _AnimatedStockGraph();

  @override
  State<_AnimatedStockGraph> createState() => _AnimatedStockGraphState();
}

class _AnimatedStockGraphState extends State<_AnimatedStockGraph> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Make the data points a bit longer so the wave can travel through
  final List<double> _baseDataPoints = [0.4, 0.5, 0.45, 0.6, 0.55, 0.75, 0.7, 0.85, 0.8, 0.95];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // Slower, calmer animation
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _StockGraphPainter(
            animationValue: _controller.value,
            dataPoints: _baseDataPoints,
            lineColor: AppColors.accentGreen,
            secondaryColor: AppColors.accentGold,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _StockGraphPainter extends CustomPainter {
  final double animationValue;
  final List<double> dataPoints;
  final Color lineColor;
  final Color secondaryColor;

  _StockGraphPainter({
    required this.animationValue,
    required this.dataPoints,
    required this.lineColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final double stepX = size.width / (dataPoints.length - 1);
    
    // Create the path with a subtle sine wave added based on animationValue
    // This creates a "breathing" or "flowing" effect without moving the data points horizontally
    for (int i = 0; i < dataPoints.length; i++) {
        final x = i * stepX;
        
        // Add a gentle vertical wave offset
        // The wave moves left-to-right with animationValue (0 to 1)
        // Amplitude depends on height, frequency depends on width
        final waveOffset = math.sin((i / (dataPoints.length - 1) * math.pi * 4) - (animationValue * math.pi * 2)) * (size.height * 0.05);
        
        // Ensure y stays mostly within bounds (clip at bottom if needed)
        final baseY = size.height * (1.0 - dataPoints[i]);
        final y = (baseY + waveOffset).clamp(0.0, size.height);
        
        if (i == 0) {
            path.moveTo(x, y);
        } else {
            // Cubic curve for smooth "stock" look
            final prevX = (i - 1) * stepX;
            final prevWaveOffset = math.sin(((i - 1) / (dataPoints.length - 1) * math.pi * 4) - (animationValue * math.pi * 2)) * (size.height * 0.05);
            final prevBaseY = size.height * (1.0 - dataPoints[i - 1]);
            final prevY = (prevBaseY + prevWaveOffset).clamp(0.0, size.height);
            
            path.cubicTo(
                prevX + stepX / 2, prevY,
                x - stepX / 2, y,
                x, y
            );
        }
    }

    // Gradient Line with animated start/end points for a shifting color effect
    // Color shifts slowly back and forth
    final colorShift = math.sin(animationValue * math.pi * 2);
    
    paint.shader = LinearGradient(
      colors: [lineColor, secondaryColor],
      begin: Alignment(-1.0 + colorShift, 0),
      end: Alignment(1.0 + colorShift, 0),
    ).createShader(Offset.zero & size);

    // Draw the main animated path
    canvas.drawPath(path, paint);
    
    // Draw a subtle glow/fill under the line
    final fillPath = Path()
      ..addPath(path, Offset.zero)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withAlpha(51), // 0.2 opacity
          Colors.white.withAlpha(0), // 0.0 opacity
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _StockGraphPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
