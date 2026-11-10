// แถวแสดงรายการเงิน: ไอคอนหมวดหมู่ วันที่ และยอดที่แยกสีรายรับกับรายจ่าย

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/money_transaction.dart';
import '../utils/date_formatter.dart';
import '../utils/money_format.dart';

/// ใช้โมเดลเดียวกันสำหรับแถวหน้าหลักและประวัติ เพื่อให้รูปแบบวันที่และยอดตรงกัน
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final MoneyTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final icon = switch (transaction.category) {
      TransactionCategory.food => Icons.restaurant,
      TransactionCategory.salary => Icons.payments_outlined,
      TransactionCategory.housing => Icons.home_outlined,
      TransactionCategory.other => Icons.receipt_long_outlined,
    };
    final amount = Text(
      formatBaht(transaction.signedAmountSatang, showPlus: true),
      style: TextStyle(
        color: transaction.isIncome ? AppColors.income : AppColors.expense,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          transaction.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          formatThaiDate(transaction.date),
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // โหมดตัวอักษรใหญ่ย้ายยอดลงใต้ชื่อ เพื่อให้รายละเอียดไม่แย่งพื้นที่กัน
          final stacked = MediaQuery.textScalerOf(context).scale(15) > 22;
          return Row(
            crossAxisAlignment: stacked
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.onPrimary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: AppColors.text),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [details, const SizedBox(height: 8), amount],
                      )
                    : Row(
                        children: [
                          Expanded(child: details),
                          const SizedBox(width: 10),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth * 0.45,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: amount,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
