// แสดงสถานะและแถบการใช้งบ พร้อมข้อมูลเงินบาทสำหรับโปรแกรมอ่านหน้าจอ
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/budget_summary.dart';
import '../utils/money_format.dart';

/// ส่วนแสดงความคืบหน้าที่ใช้ซ้ำได้ โดยรับยอดจริงจากหน้าจอเจ้าของข้อมูล
class BudgetProgress extends StatelessWidget {
  const BudgetProgress({
    super.key,
    required this.limitSatang,
    required this.expenseSatang,
  });

  final int limitSatang;
  final int expenseSatang;

  @override
  Widget build(BuildContext context) {
    final summary = BudgetSummary(
      limitSatang: limitSatang,
      expenseSatang: expenseSatang,
    );
    final status = !summary.hasBudget
        ? 'ยังไม่ได้ตั้งงบประมาณ'
        : summary.isOverBudget
        ? 'เกินงบแล้ว'
        : summary.isAtLimit
        ? 'ใช้ครบวงเงินแล้ว'
        : summary.isNearLimit
        ? 'ใกล้ถึงวงเงิน'
        : 'ยังอยู่ในงบ';
    final color = !summary.hasBudget
        ? AppColors.muted
        : summary.isOverBudget || summary.isNearLimit
        ? AppColors.expense
        : AppColors.primary;
    final percentage = _percentageLabel(summary);

    // อ่านยอดถึงสตางค์ในโหนดเดียว; งบที่ยังไม่ตั้งยังไม่มีวงเงิน/ยอดคงเหลือให้รายงาน
    final semantics = summary.hasBudget
        ? '$status, '
              'วงเงิน ${formatBaht(limitSatang, decimalPlaces: true)}, '
              'รายจ่าย ${formatBaht(expenseSatang, decimalPlaces: true)}, '
              'คงเหลือ ${formatBaht(summary.remainingSatang, decimalPlaces: true)}, '
              'ใช้ไป $percentage ของงบประมาณ'
        : '$status, รายจ่าย ${formatBaht(expenseSatang, decimalPlaces: true)}';
    return Semantics(
      container: true,
      label: semantics,
      excludeSemantics: true,
      // วางข้อความเป็นแนวตั้งและปล่อยให้ขึ้นบรรทัด เพื่อรองรับจอแคบ/อักษรใหญ่
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            key: const Key('budget-progress'),
            // ให้ค่าเสมอ แม้ยังไม่ตั้งงบ เพื่อไม่เริ่มภาพเคลื่อนไหวแบบไม่สิ้นสุด
            value: summary.progressValue,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
            backgroundColor: AppColors.divider,
            color: color,
          ),
          if (summary.hasBudget) ...[
            const SizedBox(height: 8),
            Text(
              'ใช้ไป $percentage ของงบประมาณ',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

// ปัดเฉพาะข้อความสองตำแหน่ง และรักษาความหมายเมื่อยอดต่างจากวงเงินเพียงนิดเดียว
String _percentageLabel(BudgetSummary summary) {
  final percentage = summary.usedPercentage;
  if (summary.expenseSatang > 0 && percentage < 0.01) return '<0.01%';
  final rounded = percentage.toStringAsFixed(2);
  if (summary.isOverBudget && double.parse(rounded) <= 100) return '>100%';
  if (summary.hasBudget &&
      summary.expenseSatang < summary.limitSatang &&
      double.parse(rounded) >= 100) {
    return '<100%';
  }
  return '${rounded.replaceFirst(RegExp(r'\.?0+$'), '')}%';
}
