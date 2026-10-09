import 'package:flutter/material.dart';

enum ReceiptCategory {
  food,
  study,
  travel,
  gear,
  entertainment,
  other;

  String get displayName {
    switch (this) {
      case ReceiptCategory.food:
        return 'Ăn uống';
      case ReceiptCategory.study:
        return 'Học tập';
      case ReceiptCategory.travel:
        return 'Di chuyển';
      case ReceiptCategory.gear:
        return 'Thiết bị & Dụng cụ';
      case ReceiptCategory.entertainment:
        return 'Giải trí';
      case ReceiptCategory.other:
        return 'Khác';
    }
  }

  IconData get icon {
    switch (this) {
      case ReceiptCategory.food:
        return Icons.restaurant;
      case ReceiptCategory.study:
        return Icons.menu_book;
      case ReceiptCategory.travel:
        return Icons.directions_bus;
      case ReceiptCategory.gear:
        return Icons.build_circle;
      case ReceiptCategory.entertainment:
        return Icons.sports_esports;
      case ReceiptCategory.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case ReceiptCategory.food:
        return const Color(0xFFFF5252); // Đỏ cam
      case ReceiptCategory.study:
        return const Color(0xFF448AFF); // Xanh dương
      case ReceiptCategory.travel:
        return const Color(0xFFFFB300); // Vàng hổ phách
      case ReceiptCategory.gear:
        return const Color(0xFF7C4DFF); // Tím
      case ReceiptCategory.entertainment:
        return const Color(0xFF00E676); // Xanh lá
      case ReceiptCategory.other:
        return const Color(0xFF78909C); // Xám xanh
    }
  }

  static ReceiptCategory fromString(String key) {
    return ReceiptCategory.values.firstWhere(
      (e) => e.name == key,
      orElse: () => ReceiptCategory.other,
    );
  }
}

class TransactionItem {
  final int? id;
  final String merchant;
  final double amount;
  final DateTime date;
  final ReceiptCategory category;
  final String? note;
  final String? imagePath;
  final DateTime createdAt;

  TransactionItem({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.note,
    this.imagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'merchant': merchant,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name,
      'note': note ?? '',
      'imagePath': imagePath ?? '',
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as int?,
      merchant: map['merchant'] as String? ?? 'Chưa rõ',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      category: ReceiptCategory.fromString(map['category'] as String? ?? 'other'),
      note: map['note'] as String?,
      imagePath: map['imagePath'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  TransactionItem copyWith({
    int? id,
    String? merchant,
    double? amount,
    DateTime? date,
    ReceiptCategory? category,
    String? note,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
