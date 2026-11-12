// รับ snapshot จากชั้นประสานข้อมูล ไม่เปิด Firebase subscription ใน widget ย่อย
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/budget_summary.dart';
import '../services/budget_repository.dart';
import '../utils/money_format.dart';
import 'budget_progress.dart';

class BudgetSnapshotCard extends StatelessWidget {
  const BudgetSnapshotCard({
    super.key,
    required this.snapshot,
    required this.expenseSatang,
    this.onOpenBudget,
    this.onRetry,
  });

  final AsyncSnapshot<BudgetFeed>? snapshot;
  final int expenseSatang;
  final VoidCallback? onOpenBudget;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.outline),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'งบประมาณเดือนนี้',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._content(context),
        ],
      ),
    ),
  );

  List<Widget> _content(BuildContext context) {
    final state = snapshot;
    if (state == null) {
      return [
        const Text(
          'ยังไม่ได้เชื่อมแหล่งข้อมูลงบประมาณ',
          style: TextStyle(color: AppColors.muted),
        ),
      ];
    }
    if (state.hasError) {
      return [
        const Text(
          'โหลดงบประมาณไม่สำเร็จ',
          style: TextStyle(color: AppColors.expense),
        ),
        const SizedBox(height: 8),
        const Text(
          'ตรวจสอบการเชื่อมต่อ แล้วลองโหลดอีกครั้ง',
          style: TextStyle(color: AppColors.muted),
        ),
        if (onRetry != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ลองโหลดงบอีกครั้ง'),
            ),
          ),
      ];
    }
    final feed = state.data;
    if (feed == null) {
      return [
        const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'กำลังโหลดงบประมาณ',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ];
    }
    final summary = BudgetSummary(
      limitSatang: feed.budget?.limitSatang ?? 0,
      expenseSatang: expenseSatang,
    );
    return [
      if (!summary.hasBudget) ...[
        const Text(
          'ตั้งงบรายเดือน เพื่อช่วยควบคุมรายจ่าย',
          style: TextStyle(color: AppColors.muted),
        ),
        if (onOpenBudget != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: onOpenBudget,
              icon: const Icon(Icons.add_rounded),
              label: const Text('ตั้งงบประมาณ'),
            ),
          ),
        ],
      ] else ...[
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = MediaQuery.textScalerOf(context).scale(14) > 20
                ? 1
                : constraints.maxWidth < 400
                ? 2
                : 3;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _amount(
                  width,
                  'วงเงิน',
                  summary.limitSatang,
                  'dashboard-budget-limit',
                ),
                _amount(
                  width,
                  'ใช้ไป',
                  summary.expenseSatang,
                  'dashboard-budget-spent',
                ),
                _amount(
                  columns == 2 ? constraints.maxWidth : width,
                  'คงเหลือ',
                  summary.remainingSatang,
                  'dashboard-budget-remaining',
                  color: summary.isOverBudget
                      ? AppColors.expense
                      : AppColors.income,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        BudgetProgress(
          limitSatang: summary.limitSatang,
          expenseSatang: expenseSatang,
        ),
        if (onOpenBudget != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onOpenBudget,
              child: const Text('จัดการงบประมาณ'),
            ),
          ),
      ],
      if (feed.hasPendingWrites || feed.isFromCache) ...[
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (feed.hasPendingWrites)
                const Text(
                  'งบประมาณกำลังรอยืนยันจาก Firebase',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              if (feed.isFromCache)
                const Text(
                  'งบประมาณจากข้อมูลในเครื่อง',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    ];
  }

  Widget _amount(
    double width,
    String label,
    int amount,
    String key, {
    Color color = AppColors.text,
  }) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatBaht(amount, decimalPlaces: true),
            key: Key(key),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
      ],
    ),
  );
}
