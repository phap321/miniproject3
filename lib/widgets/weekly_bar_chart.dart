import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_theme.dart';

class WeeklyBarChart extends StatefulWidget {
  final List<double> weeklySpend; // 7 elements (Index 0 = Mon, 6 = Sun)

  const WeeklyBarChart({
    super.key,
    required this.weeklySpend,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedIndex;

  final List<String> _dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxSpend = widget.weeklySpend.fold(0.0, (prev, element) => max(prev, element));
    final double targetMax = maxSpend == 0 ? 100000 : maxSpend * 1.25;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedIndex != null && _selectedIndex! < widget.weeklySpend.length)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  'Chi tiêu ${_dayLabels[_selectedIndex!]}: ',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  CurrencyFormatter.format(widget.weeklySpend[_selectedIndex!]),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 180,
          width: double.infinity,
          child: GestureDetector(
            onTapDown: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localPos = details.localPosition;
              final width = box.size.width;
              final itemWidth = width / 7;
              final index = (localPos.dx / itemWidth).floor().clamp(0, 6);
              setState(() {
                _selectedIndex = index;
              });
            },
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BarChartPainter(
                    weeklySpend: widget.weeklySpend,
                    dayLabels: _dayLabels,
                    maxSpend: targetMax,
                    progress: _animation.value,
                    selectedIndex: _selectedIndex,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> weeklySpend;
  final List<String> dayLabels;
  final double maxSpend;
  final double progress;
  final int? selectedIndex;

  _BarChartPainter({
    required this.weeklySpend,
    required this.dayLabels,
    required this.maxSpend,
    required this.progress,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double bottomMargin = 28.0;
    const double topMargin = 20.0;
    final double chartHeight = size.height - bottomMargin - topMargin;
    const double barWidth = 22.0;
    final double stepX = size.width / 7;

    // Draw horizontal grid lines (0%, 50%, 100%)
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 2; i++) {
      final y = topMargin + chartHeight * (i / 2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    const textStyle = TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500);

    for (int i = 0; i < 7; i++) {
      final double xCenter = stepX * i + stepX / 2;
      final double spend = weeklySpend[i];
      final double animatedHeight = (spend / maxSpend) * chartHeight * progress;
      final double yTop = topMargin + chartHeight - animatedHeight;
      final double yBottom = topMargin + chartHeight;

      final isSelected = selectedIndex == i;

      // Bar Background Slot
      final bgPaint = Paint()
        ..color = Colors.grey.withOpacity(0.08)
        ..style = PaintingStyle.fill;
      final bgRRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(xCenter - barWidth / 2, topMargin, xCenter + barWidth / 2, yBottom),
        const Radius.circular(6),
      );
      canvas.drawRRect(bgRRect, bgPaint);

      // Active Value Bar
      if (animatedHeight > 0) {
        final barGradient = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: isSelected
              ? [const Color(0xFF0052D4), const Color(0xFF4364F7)]
              : [AppTheme.primaryColor.withOpacity(0.7), AppTheme.primaryColor],
        );

        final barPaint = Paint()
          ..shader = barGradient.createShader(
            Rect.fromLTRB(xCenter - barWidth / 2, yTop, xCenter + barWidth / 2, yBottom),
          );

        final barRRect = RRect.fromRectAndRadius(
          Rect.fromLTRB(xCenter - barWidth / 2, yTop, xCenter + barWidth / 2, yBottom),
          const Radius.circular(6),
        );
        canvas.drawRRect(barRRect, barPaint);
      }

      // Day Label Text
      final textSpan = TextSpan(
        text: dayLabels[i],
        style: textStyle.copyWith(
          color: isSelected ? AppTheme.primaryColor : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xCenter - textPainter.width / 2, size.height - bottomMargin + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.maxSpend != maxSpend;
  }
}
