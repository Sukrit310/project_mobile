// กราฟวงแหวนรายจ่ายตามหมวดหมู่ พร้อมคำอธิบายยอดและสัดส่วนที่อ่านได้

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/money_transaction.dart';
import '../utils/categories.dart';
import '../utils/money_format.dart';

/// วาดเฉพาะหมวดที่มียอดรายจ่ายบวก และใช้ legend อ่านเงินได้ครบแม้ชิ้นกราฟเล็ก
class ExpenseChart extends StatelessWidget {
  const ExpenseChart({super.key, required this.expensesByCategory});

  final Map<TransactionCategory, int> expensesByCategory;

  @override
  Widget build(BuildContext context) {
    final categories = TransactionCategory.values
        .where((category) => (expensesByCategory[category] ?? 0) > 0)
        .toList();
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'ยังไม่มีรายจ่ายในเดือนนี้',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    // ยอดเงินจริงรวมเป็น int สตางค์ ใช้ double เฉพาะพิกัดกราฟและสัดส่วนภาพ
    final total = categories.fold<int>(
      0,
      (sum, category) => sum + expensesByCategory[category]!,
    );
    final largeText = MediaQuery.textScalerOf(context).scale(12) > 18;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Center(
            child: SizedBox.square(
              dimension: 200,
              child: PieChart(
                key: const Key('expense-pie-chart'),
                PieChartData(
                  centerSpaceRadius: 48,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(enabled: false),
                  sections: [
                    for (final category in categories)
                      PieChartSectionData(
                        value: expensesByCategory[category]!.toDouble(),
                        color: _categoryColor(category),
                        radius: 42,
                        title: _percentage(
                          expensesByCategory[category]!,
                          total,
                        ),
                        showTitle:
                            !largeText &&
                            expensesByCategory[category]! / total >= 0.12,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                duration: const Duration(milliseconds: 200),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _CategoryLegend(
              category: category,
              amountSatang: expensesByCategory[category]!,
              percentage: _percentage(expensesByCategory[category]!, total),
            ),
          ),
      ],
    );
  }
}

// ผูกสีกับหมวดหมู่ ทำให้หมวดเดิมมีสีเดิมแม้ข้อมูลในแต่ละเดือนต่างกัน
Color _categoryColor(TransactionCategory category) => switch (category) {
  TransactionCategory.food => AppColors.primary,
  TransactionCategory.salary => const Color(0xFF75508A),
  TransactionCategory.housing => const Color(0xFFAB5000),
  TransactionCategory.other => const Color(0xFF486D42),
};

/// รักษาความหมายของสัดส่วนที่เล็กมากหรือเกือบเต็มวง แทนการปัดเป็น 0% หรือ 100%
String _percentage(int amount, int total) {
  final percent = amount / total * 100;
  if (percent < 0.1) return '<0.1%';
  if (amount < total && percent > 99.9) return '>99.9%';
  final rounded = percent.toStringAsFixed(1);
  return '${rounded.endsWith('.0') ? rounded.substring(0, rounded.length - 2) : rounded}%';
}

/// รวมชื่อ ยอด และสัดส่วนให้โปรแกรมอ่านหน้าจออ่านเป็นข้อมูลหมวดเดียวกัน
class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({
    required this.category,
    required this.amountSatang,
    required this.percentage,
  });

  final TransactionCategory category;
  final int amountSatang;
  final String percentage;

  @override
  Widget build(BuildContext context) {
    final categoryLabel = transactionCategoryLabel(category);
    final amount = formatBaht(amountSatang);
    return Semantics(
      label: '$categoryLabel $amount $percentage ของรายจ่าย',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _categoryColor(category),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    Text(amount),
                    Text(
                      percentage,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
