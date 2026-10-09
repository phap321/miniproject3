import 'dart:io';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/database_helper.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_theme.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionItem transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TransactionItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.transaction;
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa hóa đơn "${_item.merchant}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && _item.id != null) {
      await DatabaseHelper.instance.deleteTransaction(_item.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa hóa đơn thành công')),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _item.imagePath != null &&
        _item.imagePath!.isNotEmpty &&
        File(_item.imagePath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Hóa Đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteTransaction,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_item.category.color, _item.category.color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _item.category.color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(_item.category.icon, size: 40, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    _item.merchant,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(_item.amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _item.category.displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metadata Detail Table
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.calendar_month,
                      'Ngày thanh toán',
                      CurrencyFormatter.formatDateWithTime(_item.date),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      Icons.category_outlined,
                      'Phân loại chi tiêu',
                      _item.category.displayName,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      Icons.notes,
                      'Ghi chú',
                      _item.note != null && _item.note!.isNotEmpty ? _item.note! : 'Không có ghi chú',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Receipt Photo Thumbnail if available
            if (hasImage) ...[
              const Text(
                'Ảnh hóa đơn đã chụp / lưu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_item.imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 300,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
