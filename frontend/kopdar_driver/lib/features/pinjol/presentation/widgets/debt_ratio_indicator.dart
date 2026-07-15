import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Visual debt-to-income ratio indicator.
/// Shows a circular gauge with the ratio percentage.
class DebtRatioIndicator extends StatelessWidget {
  final double ratio; // 0.0 to 1.0+
  final double size;

  const DebtRatioIndicator({
    super.key,
    required this.ratio,
    this.size = 100,
  });

  Color get _color {
    if (ratio <= 0.2) return AppColors.success;
    if (ratio <= 0.3) return AppColors.warning;
    return AppColors.danger;
  }

  String get _label {
    if (ratio <= 0.2) return 'Sehat';
    if (ratio <= 0.3) return 'Waspada';
    return 'Berisiko';
  }

  String get _emoji {
    if (ratio <= 0.2) return '🟢';
    if (ratio <= 0.3) return '🟡';
    return '🔴';
  }

  @override
  Widget build(BuildContext context) {
    final percent = (ratio * 100).round();
    final clampedRatio = ratio.clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _GaugePainter(
              ratio: clampedRatio,
              color: _color,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: size * 0.24,
                      fontWeight: FontWeight.w800,
                      color: _color,
                    ),
                  ),
                  Text(
                    _label,
                    style: TextStyle(
                      fontSize: size * 0.11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rasio Cicilan/Penghasilan',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double ratio;
  final Color color;

  _GaugePainter({required this.ratio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;
    const startAngle = -math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    // Background arc
    final bgPaint = Paint()
      ..color = AppColors.gray200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * ratio,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.ratio != ratio || oldDelegate.color != color;
  }
}
