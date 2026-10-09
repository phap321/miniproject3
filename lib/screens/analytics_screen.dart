import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/database_helper.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_theme.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/weekly_bar_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<ReceiptCategory, double> _categoryTotals = {};
  List<double> _weeklySpend = List.filled(7, 0.0);
  double _totalSpend = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    final totals = await DatabaseHelper.instance.getCategoryTotals();
    final weekly = await DatabaseHelper.instance.getWeeklyDailySpend();
    final double total = totals.values.fold(0.0, (sum, val) => sum + val);

    if (mounted) {
      setState(() {
        _categoryTotals = totals;
        _weeklySpend = weekly;
        _totalSpend = total;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống Kê Chi Tiêu Canvas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Summary Banner Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, Color(0xFF0052D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng ngân sách chi tiêu',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            CurrencyFormatter.format(_totalSpend),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 1: Weekly Spending Bar Chart (CustomPainter)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.bar_chart_rounded, color: AppTheme.primaryColor),
                                SizedBox(width: 8),
                                Text(
                                  'Chi Tiêu Theo Tuần (Thứ 2 - CN)',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Vẽ trực tiếp trên Canvas bằng CustomPainter (Sub-100ms)',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            WeeklyBarChart(weeklySpend: _weeklySpend),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Category Distribution Donut Chart (CustomPainter)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.pie_chart_rounded, color: AppTheme.primaryColor),
                                SizedBox(width: 8),
                                Text(
                                  'Cơ Cấu Chi Tiêu Theo Danh Mục',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Biểu đồ Donut hoạt họa (Animated Donut Chart)',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: CategoryDonutChart(
                                categoryTotals: _categoryTotals,
                                totalAmount: _totalSpend,
                              ),
                            ),
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
