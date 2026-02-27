import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

class HomeWidgetPlaceholder extends StatelessWidget {
  const HomeWidgetPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Simulate widget environment
      body: Center(
        child: Container(
          width: 300,
          height: 150,
          padding: const EdgeInsets.all(UIConstants.paddingMedium),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26), // 0.1 opacity
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Glad you\'re here',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              // --- Stock Market Style Animated Graph ---
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: _AnimatedStockGraph(),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // In a real widget, this would be a PendingIntent
                  context.go('/chat');
                },
                child: Container(
                  width: double.infinity,
                  height: 44, // Slightly reduced to fit graph
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13), // 0.05 opacity
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ask here !!',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ),
                      Icon(Icons.arrow_upward, color: Colors.grey[400], size: 18),
                    ],
                  ),
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
  final List<double> _dataPoints = [0.4, 0.5, 0.45, 0.6, 0.55, 0.75, 0.7, 0.85, 0.8, 0.95];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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
            dataPoints: _dataPoints,
            lineColor: Colors.green.shade400,
            secondaryColor: Colors.yellow.shade600,
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
    
    // Create the path
    for (int i = 0; i < dataPoints.length; i++) {
        final x = i * stepX;
        final y = size.height * (1.0 - dataPoints[i]);
        if (i == 0) {
            path.moveTo(x, y);
        } else {
            // Cubic curve for smooth "stock" look
            final prevX = (i - 1) * stepX;
            final prevY = size.height * (1.0 - dataPoints[i - 1]);
            path.cubicTo(
                prevX + stepX / 2, prevY,
                x - stepX / 2, y,
                x, y
            );
        }
    }

    // Gradient Line
    paint.shader = LinearGradient(
      colors: [lineColor, secondaryColor],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Offset.zero & size);

    // Progressive Reveal Animation OR Shift Wave
    // We'll use a "drawing" effect combined with a subtle dash offset for the "alive" feel
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      // Line drawing effect
      // We'll add a subtle dash effect that moves to make it feel alive
      // Dash length 100, gap 20, moving by animationValue
      final dashPath = _createAnimatedDashPath(metric, animationValue);
      
      canvas.drawPath(dashPath, paint);
      
      // Draw a subtle glow under the line (optional but premium)
      final fillPath = Path()
        ..addPath(dashPath, Offset.zero)
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
  }

  Path _createAnimatedDashPath(PathMetric metric, double animation) {
    final dashPath = Path();
    final len = metric.length;
    final dashLen = 20.0;
    final gapLen = 10.0;
    final cycleLen = dashLen + gapLen;
    
    // Offset based on animation to make it flow
    double startOffset = -(animation * cycleLen * 5) % cycleLen;
    
    double currentPos = startOffset;
    while (currentPos < len) {
      if (currentPos + dashLen > 0) {
        final start = currentPos < 0 ? 0.0 : currentPos;
        final end = (currentPos + dashLen) > len ? len : (currentPos + dashLen);
        dashPath.addPath(metric.extractPath(start, end), Offset.zero);
      }
      currentPos += cycleLen;
    }
    return dashPath;
  }

  @override
  bool shouldRepaint(covariant _StockGraphPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
