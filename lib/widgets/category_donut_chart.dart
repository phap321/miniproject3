import 'dart:math';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';

class CategoryDonutChart extends StatefulWidget {
  final Map<ReceiptCategory, double> categoryTotals;
  final double totalAmount;

  const CategoryDonutChart({
    super.key,
    required this.categoryTotals,
    required this.totalAmount,
  });

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _chartAnimation;
  ReceiptCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant CategoryDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalAmount == 0) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: const Text(
          'Chưa có dữ liệu chi tiêu',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    final sortedEntries = widget.categoryTotals.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        SizedBox(
          height: 220,
          width: 220,
          child: AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: _DonutChartPainter(
                  categoryTotals: widget.categoryTotals,
                  totalAmount: widget.totalAmount,
                  progress: _chartAnimation.value,
                  selectedCategory: _selectedCategory,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedCategory == null
                            ? 'Tổng chi tiêu'
                            : _selectedCategory!.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(
                          _selectedCategory == null
                              ? widget.totalAmount
                              : (widget.categoryTotals[_selectedCategory] ?? 0),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        // Custom Interactive Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: sortedEntries.map((entry) {
            final category = entry.key;
            final amount = entry.value;
            final percentage = (amount / widget.totalAmount * 100).toStringAsFixed(1);
            final isSelected = _selectedCategory == category;

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (_selectedCategory == category) {
                    _selectedCategory = null;
                  } else {
                    _selectedCategory = category;
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? category.color.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? category.color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${category.displayName} ($percentage%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? category.color : Colors.black80,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<ReceiptCategory, double> categoryTotals;
  final double totalAmount;
  final double progress;
  final ReceiptCategory? selectedCategory;

  _DonutChartPainter({
    required this.categoryTotals,
    required this.totalAmount,
    required this.progress,
    this.selectedCategory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalAmount <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = min(size.width, size.height) / 2 - 10;
    final strokeWidth = 28.0;
    final innerRadius = outerRadius - strokeWidth;

    double startAngle = -pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (var category in ReceiptCategory.values) {
      final amount = categoryTotals[category] ?? 0.0;
      if (amount <= 0) continue;

      final sweepAngle = (amount / totalAmount) * 2 * pi * progress;
      final isSelected = selectedCategory == category;

      paint.color = category.color;

      if (isSelected) {
        final highlightPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 6
          ..color = category.color;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerRadius - strokeWidth / 2),
          startAngle,
          sweepAngle,
          false,
          highlightPaint,
        );
      } else {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerRadius - strokeWidth / 2),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.totalAmount != totalAmount;
  }
}
