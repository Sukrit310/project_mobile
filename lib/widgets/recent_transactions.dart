// กล่องรายการล่าสุด แสดงลิสต์ที่ได้รับหรือข้อความเมื่อยังไม่มีข้อมูล

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/money_transaction.dart';
import 'transaction_tile.dart';

/// แสดงรายการตามลำดับที่ผู้เรียกส่งมา การเลือกสองรายการล่าสุดอยู่ในโมเดลสรุป
class RecentTransactions extends StatelessWidget {
  const RecentTransactions({super.key, required this.transactions});

  final List<MoneyTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: transactions.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'ยังไม่มีรายการในตอนนี้',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < transactions.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),
                  TransactionTile(transaction: transactions[i]),
                ],
              ],
            ),
    );
  }
}
