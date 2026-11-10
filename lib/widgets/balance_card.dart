// การ์ดยอดคงเหลือสะสม พร้อมรายรับและรายจ่ายของเดือนที่กำลังแสดง

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/money_transaction.dart';
import '../utils/money_format.dart';

/// แสดงยอดจาก DashboardSummary ซึ่งคำนวณจากข้อมูลเดียวกับรายการบนหน้าหลัก
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ยอดสุทธิทั้งหมด',
              style: TextStyle(
                color: AppColors.balanceLabel,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // ย่อเฉพาะยอดเงินที่ยาวเกินการ์ด ไม่ให้ล้นขอบ
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatBaht(summary.balanceSatang, decimalPlaces: true),
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: AppColors.balanceDivider),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                // เมื่อตัวอักษรใหญ่ ให้ยอดรายเดือนเรียงเต็มแถวแทนการบีบสองคอลัมน์
                final largeText =
                    MediaQuery.textScalerOf(context).scale(14) > 20;
                final width = largeText
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 16) / 2;
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: width,
                      child: _MonthlyAmount(
                        label: 'รายรับเดือนนี้',
                        amount: formatBaht(
                          summary.incomeSatang,
                          showPlus: true,
                        ),
                        color: AppColors.incomeHighlight,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _MonthlyAmount(
                        label: 'รายจ่ายเดือนนี้',
                        amount: formatBaht(-summary.expenseSatang),
                        color: AppColors.expenseHighlight,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ป้ายและยอดรายเดือนที่ใช้ซ้ำได้ทั้งรายรับและรายจ่าย
class _MonthlyAmount extends StatelessWidget {
  const _MonthlyAmount({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.balanceLabel,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
