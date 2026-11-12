// แถวแสดงรายการเงิน: ไอคอนหมวดหมู่ วันที่ และยอดที่แยกสีรายรับกับรายจ่าย

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/money_transaction.dart';
import '../utils/categories.dart';
import '../utils/date_formatter.dart';
import '../utils/money_format.dart';
import 'animated_money.dart';

/// ใช้โมเดลเดียวกันสำหรับแถวหน้าหลักและประวัติ เพื่อให้รูปแบบวันที่และยอดตรงกัน
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final MoneyTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final categoryLabel = transactionCategoryLabel(transaction.category);
    final icon = switch (transaction.category) {
      TransactionCategory.food => Icons.restaurant,
      TransactionCategory.salary => Icons.payments_outlined,
      TransactionCategory.housing => Icons.home_outlined,
      TransactionCategory.other => Icons.receipt_long_outlined,
    };
    final amount = AnimatedMoney(
      amount: formatBaht(transaction.signedAmountSatang, showPlus: true),
      style: TextStyle(
        color: transaction.isIncome ? AppColors.income : AppColors.expense,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          transaction.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          children: [
            if (transaction.title.trim() != categoryLabel)
              Text(
                categoryLabel,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(
              formatThaiDate(transaction.date),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // โหมดตัวอักษรใหญ่ย้ายยอดลงใต้ชื่อ เพื่อให้รายละเอียดไม่แย่งพื้นที่กัน
          final stacked =
              MediaQuery.textScalerOf(context).scale(15) > 22 ||
              constraints.maxWidth < 280;
          return Row(
            crossAxisAlignment: stacked
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: transaction.isIncome
                      ? AppColors.incomeSurface
                      : AppColors.expenseSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: transaction.isIncome
                      ? AppColors.income
                      : AppColors.expense,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          details,
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: amount,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: details),
                          const SizedBox(width: 12),
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
