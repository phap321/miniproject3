import 'dart:io';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/database_helper.dart';
import '../services/ocr_heuristic_engine.dart';
import '../services/storage_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_theme.dart';
import '../widgets/category_chip.dart';

class ReviewReceiptScreen extends StatefulWidget {
  final OCRParsedResult parsedResult;
  final String? imagePath;

  const ReviewReceiptScreen({
    super.key,
    required this.parsedResult,
    this.imagePath,
  });

  @override
  State<ReviewReceiptScreen> createState() => _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends State<ReviewReceiptScreen> {
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late ReceiptCategory _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: widget.parsedResult.merchant);
    _amountController = TextEditingController(text: widget.parsedResult.amount.toInt().toString());
    _noteController = TextEditingController();
    _selectedDate = widget.parsedResult.date;
    _selectedCategory = widget.parsedResult.category;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    final merchantText = _merchantController.text.trim();
    final amountText = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();

    if (merchantText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên cửa hàng / người nhận')),
      );
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    String? savedThumbnailPath;
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      final imageFile = File(widget.imagePath!);
      if (await imageFile.exists()) {
        savedThumbnailPath = await StorageService.saveReceiptImage(imageFile);
      }
    }

    final newTransaction = TransactionItem(
      merchant: merchantText,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      note: _noteController.text.trim(),
      imagePath: savedThumbnailPath ?? widget.imagePath,
    );

    await DatabaseHelper.instance.insertTransaction(newTransaction);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu hóa đơn thành công!'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imagePath != null &&
        widget.imagePath!.isNotEmpty &&
        File(widget.imagePath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận & Kiểm tra Hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'Xem văn bản nhận diện OCR',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Văn bản thô từ OCR (ML Kit)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: SelectableText(
                            widget.parsedResult.rawText,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receipt Image Thumbnail Card
            if (hasImage)
              Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(widget.imagePath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // OCR Smart Recognition Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Thông tin đã được OCR tự động trích xuất. Vui lòng kiểm tra lại trước khi lưu.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0D47A1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Merchant Field
            const Text(
              'Tên Đơn vị / Cửa hàng',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _merchantController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.storefront),
                hintText: 'Nhập tên siêu thị, quán ăn, cửa hàng...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Amount Field
            const Text(
              'Tổng tiền thanh toán (VND)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: 'VNĐ',
                hintText: '0',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Date Picker Field
            const Text(
              'Ngày giao dịch',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          CurrencyFormatter.formatDate(_selectedDate),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Selection Chips
            const Text(
              'Danh mục chi tiêu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: ReceiptCategory.values.map((cat) {
                final isSelected = cat == _selectedCategory;
                return CategoryChip(
                  category: cat,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Note Field
            const Text(
              'Ghi chú bổ sung',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.notes),
                hintText: 'Chi tiết các món đồ đã mua, mục đích chi tiêu...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTransaction,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_rounded),
                          SizedBox(width: 8),
                          Text('Lưu Hóa Đơn Chi Tiêu', style: TextStyle(fontSize: 16)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
