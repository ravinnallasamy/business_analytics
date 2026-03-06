import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';

class HomeWidgetPlaceholder extends StatelessWidget {
  final String message;

  const HomeWidgetPlaceholder({super.key, this.message = '---'});

  @override
  Widget build(BuildContext context) {
    // The message is now the clean extracted value (e.g., "82.06 Lacs")
    final String displayValue = message;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF000000), // Strict Pure Black background
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Graph filling the whole widget edge-to-edge
            const Positioned.fill(
              child: _AnimatedStockGraph(),
            ),
            
            // 2. Bold, centered value (Financial Ticker Style)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  displayValue,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 48, // Aggressively large
                    fontWeight: FontWeight.w900, // Extra bold
                    color: Color(0xFFFFFFFF), // Pure white
                    height: 1.0,
                    letterSpacing: -1.0,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible, // Value is the priority
                ),
              ),
            ),
          ],
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
