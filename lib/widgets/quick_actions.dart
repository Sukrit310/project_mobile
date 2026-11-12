import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// แสดงเฉพาะทางลัดที่ต่อกับการทำงานจริงแล้ว
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    this.onAddExpense,
    this.onAddIncome,
    this.onStatistics,
  });
  final VoidCallback? onAddExpense;
  final VoidCallback? onAddIncome;
  final VoidCallback? onStatistics;

  @override
  Widget build(BuildContext context) {
    final actions = [
      if (onAddExpense != null)
        (
          label: 'เพิ่มรายจ่าย',
          icon: Icons.north_east_rounded,
          color: AppColors.expense,
          background: AppColors.expenseSurface,
          callback: onAddExpense!,
        ),
      if (onAddIncome != null)
        (
          label: 'เพิ่มรายรับ',
          icon: Icons.south_west_rounded,
          color: AppColors.income,
          background: AppColors.incomeSurface,
          callback: onAddIncome!,
        ),
      if (onStatistics != null)
        (
          label: 'ดูสถิติ',
          icon: Icons.bar_chart_rounded,
          color: AppColors.primary,
          background: AppColors.mintSurface,
          callback: onStatistics!,
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
        final columns = largeText || constraints.maxWidth < 280
            ? 1
            : actions.length;
        if (columns == 0) return const SizedBox.shrink();
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final action in actions)
              SizedBox(
                width: width,
                child: Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.outline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: action.callback,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: action.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                action.icon,
                                color: action.color,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            action.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
