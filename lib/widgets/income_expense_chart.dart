// กราฟแท่งเปรียบเทียบรายรับกับรายจ่ายของเดือน พร้อมป้ายจำนวนเงินที่แม่นยำ

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../utils/money_format.dart';

/// รับยอด int สตางค์ แปลงเป็นหน่วยบาทเฉพาะพิกัดกราฟและคงป้ายยอดแบบแม่นยำ
class IncomeExpenseChart extends StatelessWidget {
  const IncomeExpenseChart({
    super.key,
    required this.incomeSatang,
    required this.expenseSatang,
  }) : assert(incomeSatang >= 0),
       assert(expenseSatang >= 0);

  final int incomeSatang;
  final int expenseSatang;

  @override
  Widget build(BuildContext context) {
    final largest = incomeSatang > expenseSatang ? incomeSatang : expenseSatang;
    // แกนต้องมีช่วงบวกเสมอ เพื่อรองรับยอดศูนย์ทั้งคู่และยอดเล็กเพียงหนึ่งสตางค์
    final maxY = largest == 0 ? 1.0 : largest / 100 * 1.2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'หน่วย: บาท',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ExcludeSemantics(
          child: SizedBox(
            height: 180,
            child: BarChart(
              key: const Key('income-expense-bar-chart'),
              BarChartData(
                minY: 0,
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: false),
                titlesData: const FlTitlesData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: AppColors.muted),
                  ),
                ),
                barGroups: [
                  _bar(0, incomeSatang, AppColors.income),
                  _bar(1, expenseSatang, AppColors.expense),
                ],
              ),
              duration: const Duration(milliseconds: 200),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ป้ายอยู่ตรงแท่งทั้งสองและขึ้นบรรทัดใหม่ได้ จึงอ่านยอดครบเมื่อขยายตัวอักษร
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _BarLabel(
                label: 'รายรับ',
                amountSatang: incomeSatang,
                color: AppColors.income,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BarLabel(
                label: 'รายจ่าย',
                amountSatang: expenseSatang,
                color: AppColors.expense,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// สร้างแท่งหนึ่งประเภท โดยสีอิงความหมายรายรับหรือรายจ่าย
BarChartGroupData _bar(int x, int amountSatang, Color color) =>
    BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: amountSatang / 100,
          color: color,
          width: 42,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );

/// แสดงยอดจริงใต้แท่งและให้โปรแกรมอ่านหน้าจออ่านแทนรายละเอียดรูปกราฟ
class _BarLabel extends StatelessWidget {
  const _BarLabel({
    required this.label,
    required this.amountSatang,
    required this.color,
  });

  final String label;
  final int amountSatang;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label ${formatBaht(amountSatang)}',
    excludeSemantics: true,
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          formatBaht(amountSatang),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
