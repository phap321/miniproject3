import 'dart:io';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';

class TransactionCard extends StatelessWidget {
  final TransactionItem transaction;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = transaction.imagePath != null &&
        transaction.imagePath!.isNotEmpty &&
        File(transaction.imagePath!).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // Icon or Thumbnail
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: transaction.category.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(transaction.imagePath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        transaction.category.icon,
                        color: transaction.category.color,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 14),
              // Merchant & Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchant,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          CurrencyFormatter.formatDate(transaction.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: transaction.category.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            transaction.category.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: transaction.category.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (transaction.note != null && transaction.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          transaction.note!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Amount
              Text(
                '-${CurrencyFormatter.format(transaction.amount)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
