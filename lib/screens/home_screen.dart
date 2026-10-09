import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/database_helper.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_theme.dart';
import '../widgets/category_chip.dart';
import '../widgets/transaction_card.dart';
import 'analytics_screen.dart';
import 'camera_scanner_screen.dart';
import 'transaction_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TransactionItem> _allTransactions = [];
  List<TransactionItem> _filteredTransactions = [];
  ReceiptCategory? _selectedCategoryFilter;
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  Future<void> _refreshTransactions() async {
    setState(() => _isLoading = true);

    final list = await DatabaseHelper.instance.getAllTransactions();

    if (mounted) {
      setState(() {
        _allTransactions = list;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<TransactionItem> result = List.from(_allTransactions);

    if (_selectedCategoryFilter != null) {
      result = result.where((tx) => tx.category == _selectedCategoryFilter).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      result = result.where((tx) {
        final merchantMatch = tx.merchant.toLowerCase().contains(query);
        final noteMatch = tx.note != null && tx.note!.toLowerCase().contains(query);
        final amountMatch = tx.amount.toString().contains(query);
        return merchantMatch || noteMatch || amountMatch;
      }).toList();
    }

    _filteredTransactions = result;
  }

  double get _totalSpending {
    return _filteredTransactions.fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> _openCameraScanner() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const CameraScannerScreen()),
    );

    if (result == true) {
      _refreshTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Hóa Đơn & Chi Tiêu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppTheme.primaryColor),
            tooltip: 'Xem Thống kê Canvas',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTransactions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dashboard Total Spend Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066FF), Color(0xFF0044B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng chi tiêu hóa đơn',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_filteredTransactions.length} hóa đơn',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(_totalSpending),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nhận diện trên thiết bị ML Kit',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                            );
                          },
                          child: const Row(
                            children: [
                              Text(
                                'Biểu đồ CustomPainter',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Icon(Icons.chevron_right, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Search Bar
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFilters();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm cửa hàng, ghi chú...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Category Filter Chips (Tất cả, Ăn uống, Học tập, ...)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // "Tất cả" chip
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryFilter = null;
                          _applyFilters();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _selectedCategoryFilter == null
                              ? AppTheme.primaryColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _selectedCategoryFilter == null
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          'Tất cả',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _selectedCategoryFilter == null
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    // Category Chips
                    ...ReceiptCategory.values.map((cat) {
                      final isSelected = cat == _selectedCategoryFilter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CategoryChip(
                          category: cat,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (_selectedCategoryFilter == cat) {
                                _selectedCategoryFilter = null;
                              } else {
                                _selectedCategoryFilter = cat;
                              }
                              _applyFilters();
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Transaction History Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lịch Sử Hóa Đơn Chi Tiêu',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '${_filteredTransactions.length} mục',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Transaction List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_filteredTransactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Không tìm thấy hóa đơn nào',
                        style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final item = _filteredTransactions[index];
                    return TransactionCard(
                      transaction: item,
                      onTap: () async {
                        final updated = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (context) => TransactionDetailScreen(transaction: item),
                          ),
                        );
                        if (updated == true) {
                          _refreshTransactions();
                        }
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCameraScanner,
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Quét Hóa Đơn', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
