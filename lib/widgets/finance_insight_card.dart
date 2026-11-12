import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../utils/categories.dart';
import '../utils/finance_insights.dart';
import '../utils/money_format.dart';

/// ข้อเท็จจริงหนึ่งเรื่องจากรายจ่ายของเดือน ไม่คาดการณ์หรือสร้างคำแนะนำที่ไม่มีฐานข้อมูล
class FinanceInsightCard extends StatelessWidget {
  const FinanceInsightCard({super.key, required this.insight});
  final MonthlyExpenseInsight insight;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.mintSurface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'มองการใช้จ่ายเดือนนี้',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${transactionCategoryLabel(insight.category)}${insight.isTied ? 'เป็นหนึ่งในหมวดที่มีรายจ่ายสูงสุด' : 'เป็นหมวดที่มีรายจ่ายสูงสุด'}',
                  style: const TextStyle(color: AppColors.primaryDeep),
                ),
                const SizedBox(height: 4),
                Text(
                  'รวม ${formatBaht(insight.categorySatang, decimalPlaces: true)} จากรายจ่ายเดือนนี้ ${formatBaht(insight.totalSatang, decimalPlaces: true)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
