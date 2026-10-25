import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Islamic 8-Pointed Star (Khatim / Rub el Hizb symbol)
class IslamicStarPainter extends CustomPainter {
  final Color color;
  final PaintingStyle style;
  final double strokeWidth;

  IslamicStarPainter({
    this.color = AppColors.gold,
    this.style = PaintingStyle.stroke,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = style
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.9;

    // Draw first square
    final path1 = Path();
    final halfSide = radius / math.sqrt(2);
    final rect1 = Rect.fromCenter(center: center, width: halfSide * 2, height: halfSide * 2);
    path1.addRect(rect1);

    // Draw second square rotated 45 degrees
    canvas.save();
    canvas.drawPath(path1, paint);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(path1, paint);
    canvas.restore();

    // Central small circle
    final circlePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.25, circlePaint);
  }

  @override
  bool shouldRepaint(covariant IslamicStarPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.style != style ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Geometric Arabesque Background Pattern
class ArabesqueBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final double opacity;

  ArabesqueBackgroundPainter({
    this.primaryColor = AppColors.gold,
    this.opacity = 0.05,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const double step = 60.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        // Draw intersecting octagram motifs
        final center = Offset(x, y);
        canvas.drawCircle(center, 18, paint);
        
        final path = Path();
        path.moveTo(x - 12, y);
        path.lineTo(x, y - 12);
        path.lineTo(x + 12, y);
        path.lineTo(x, y + 12);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ArabesqueBackgroundPainter oldDelegate) => false;
}

/// Islamic Mihrab Arch Header
class MihrabClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);

    // Create pointed arch curve (قوس إسلامي مدبب)
    final controlPoint1 = Offset(size.width * 0.25, size.height);
    final controlPoint2 = Offset(size.width * 0.75, size.height);
    final endPoint = Offset(size.width, size.height - 30);

    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      endPoint.dx, endPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Ornate Frame Widget for Islamic Cards and Headers
class IslamicOrnateBorder extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const IslamicOrnateBorder({
    super.key,
    required this.child,
    this.borderColor = AppColors.gold,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          // Top Left Corner Ornament
          Positioned(
            top: -10,
            left: -10,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CustomPaint(
                painter: IslamicStarPainter(color: borderColor, strokeWidth: 1.2),
              ),
            ),
          ),
          // Top Right Corner Ornament
          Positioned(
            top: -10,
            right: -10,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CustomPaint(
                painter: IslamicStarPainter(color: borderColor, strokeWidth: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
