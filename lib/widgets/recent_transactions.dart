// กล่องรายการล่าสุด แสดงลิสต์ที่ได้รับหรือข้อความเมื่อยังไม่มีข้อมูล

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/money_transaction.dart';
import 'transaction_tile.dart';

/// แสดงรายการตามลำดับที่ผู้เรียกส่งมา การเลือกรายการล่าสุดอยู่ในโมเดลสรุป
class RecentTransactions extends StatelessWidget {
  const RecentTransactions({super.key, required this.transactions});

  final List<MoneyTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: transactions.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.mintSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        size: 28,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ยังไม่มีรายการในตอนนี้',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < transactions.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),
                  TransactionTile(transaction: transactions[i]),
                ],
              ],
            ),
    );
  }
}
