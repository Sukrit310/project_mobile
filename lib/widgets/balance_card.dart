// การ์ดยอดคงเหลือสะสม พร้อมรายรับและรายจ่ายของเดือนที่กำลังแสดง

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/money_transaction.dart';
import '../utils/money_format.dart';
import 'animated_money.dart';

/// แสดงยอดจาก DashboardSummary ซึ่งคำนวณจากข้อมูลเดียวกับรายการบนหน้าหลัก
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.summary,
    this.showBalance = true,
    this.onToggleBalanceVisibility,
  });

  final DashboardSummary summary;
  final bool showBalance;
  final VoidCallback? onToggleBalanceVisibility;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'ยอดสุทธิทั้งหมด',
                    style: TextStyle(
                      color: AppColors.balanceLabel,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  key: const Key('balance-visibility'),
                  tooltip: showBalance ? 'ซ่อนยอดบนการ์ด' : 'แสดงยอดบนการ์ด',
                  onPressed: onToggleBalanceVisibility,
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.balanceLabel,
                    disabledForegroundColor: AppColors.balanceLabel,
                    minimumSize: const Size(48, 48),
                  ),
                  icon: Icon(
                    showBalance
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // ย่อเฉพาะยอดเงินที่ยาวเกินการ์ด ไม่ให้ล้นขอบ
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: _CardAmount(
                amount: formatBaht(summary.balanceSatang, decimalPlaces: true),
                showBalance: showBalance,
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'สะสมจากทุกรายการ',
              style: TextStyle(color: AppColors.balanceLabel, fontSize: 12),
            ),
            const SizedBox(height: 20),
            // แยกยอดเฉพาะเดือนออกจากยอดสะสมด้วยพื้นผิวเดียวกันทั้งสองประเภท
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // เมื่อตัวอักษรใหญ่ ให้ยอดรายเดือนเรียงเต็มแถวแทนการบีบสองคอลัมน์
                  final stacked =
                      MediaQuery.textScalerOf(context).scale(14) > 20 ||
                      constraints.maxWidth < 200;
                  final width = stacked
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 16) / 2;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 20,
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
                          icon: Icons.south_west_rounded,
                          showBalance: showBalance,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _MonthlyAmount(
                          label: 'รายจ่ายเดือนนี้',
                          amount: formatBaht(-summary.expenseSatang),
                          color: AppColors.expenseHighlight,
                          icon: Icons.north_east_rounded,
                          showBalance: showBalance,
                        ),
                      ),
                    ],
                  );
                },
              ),
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
    required this.icon,
    required this.showBalance,
  });

  final String label;
  final String amount;
  final Color color;
  final IconData icon;
  final bool showBalance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.balanceLabel,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: _CardAmount(
            amount: amount,
            showBalance: showBalance,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// ถอดยอดจริงออกทันทีเมื่อซ่อน เพื่อไม่ให้ภาพเคลื่อนไหวหรือระบบอ่านหน้าจอเผยยอดเดิม
class _CardAmount extends StatelessWidget {
  const _CardAmount({
    required this.amount,
    required this.showBalance,
    required this.style,
  });

  final String amount;
  final bool showBalance;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return showBalance
        ? AnimatedMoney(amount: amount, style: style)
        : Text('••••••', style: style);
  }
}
