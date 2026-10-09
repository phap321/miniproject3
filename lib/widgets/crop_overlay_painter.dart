import 'package:flutter/material.dart';

class CropOverlayPainter extends CustomPainter {
  final double scanAnimationProgress;
  final bool isScanning;

  CropOverlayPainter({
    required this.scanAnimationProgress,
    this.isScanning = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cardWidth = size.width * 0.82;
    final double cardHeight = size.height * 0.62;
    final double left = (size.width - cardWidth) / 2;
    final double top = (size.height - cardHeight) / 2 - 30;
    final Rect cropRect = Rect.fromLTWH(left, top, cardWidth, cardHeight);

    // 1. Dark background overlay with cutout window
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.65);
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cropRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(bgPath, backgroundPaint);

    // 2. Corner Bracket Framers
    final cornerPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double cornerLength = 28.0;
    final double radius = 16.0;

    // Top-Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + radius)
        ..arcToPoint(Offset(left + radius, top), radius: Radius.circular(radius))
        ..lineTo(left + cornerLength, top),
      cornerPaint,
    );

    // Top-Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(left + cardWidth - cornerLength, top)
        ..lineTo(left + cardWidth - radius, top)
        ..arcToPoint(Offset(left + cardWidth, top + radius), radius: Radius.circular(radius))
        ..lineTo(left + cardWidth, top + cornerLength),
      cornerPaint,
    );

    // Bottom-Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cardHeight - cornerLength)
        ..lineTo(left, top + cardHeight - radius)
        ..arcToPoint(Offset(left + radius, top + cardHeight), radius: Radius.circular(radius), clockwise: false)
        ..lineTo(left + cornerLength, top + cardHeight),
      cornerPaint,
    );

    // Bottom-Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(left + cardWidth - cornerLength, top + cardHeight)
        ..lineTo(left + cardWidth - radius, top + cardHeight)
        ..arcToPoint(Offset(left + cardWidth, top + cardHeight - radius), radius: Radius.circular(radius), clockwise: false)
        ..lineTo(left + cardWidth, top + cardHeight - cornerLength),
      cornerPaint,
    );

    // 3. Grid Lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1.0;

    // Vertical grid lines
    canvas.drawLine(Offset(left + cardWidth / 3, top), Offset(left + cardWidth / 3, top + cardHeight), gridPaint);
    canvas.drawLine(Offset(left + cardWidth * 2 / 3, top), Offset(left + cardWidth * 2 / 3, top + cardHeight), gridPaint);
    // Horizontal grid lines
    canvas.drawLine(Offset(left, top + cardHeight / 3), Offset(left + cardWidth, top + cardHeight / 3), gridPaint);
    canvas.drawLine(Offset(left, top + cardHeight * 2 / 3), Offset(left + cardWidth, top + cardHeight * 2 / 3), gridPaint);

    // 4. Animated Laser Scanner Bar
    if (isScanning) {
      final double scanY = top + (cardHeight * scanAnimationProgress);

      final laserPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF00E676).withOpacity(0.0),
            const Color(0xFF00E676),
            const Color(0xFF00E676).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(left, scanY - 2, cardWidth, 4));

      canvas.drawLine(
        Offset(left + 8, scanY),
        Offset(left + cardWidth - 8, scanY),
        laserPaint..strokeWidth = 3.0,
      );

      // Soft Glow
      final glowPaint = Paint()
        ..color = const Color(0xFF00E676).withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawRect(Rect.fromLTWH(left + 12, scanY - 6, cardWidth - 24, 12), glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) {
    return oldDelegate.scanAnimationProgress != scanAnimationProgress ||
        oldDelegate.isScanning != isScanning;
  }
}
