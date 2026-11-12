// ประกอบ Dashboard จากข้อมูลและ callback ที่ชั้นประสานส่งมา โดยไม่เรียก Firebase เอง
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../data/sample_transactions.dart';
import '../models/money_transaction.dart';
import '../services/budget_repository.dart';
import '../utils/date_formatter.dart';
import '../utils/finance_insights.dart';
import '../widgets/balance_card.dart';
import '../widgets/budget_snapshot_card.dart';
import '../widgets/finance_insight_card.dart';
import '../widgets/moneymate_navigation_bar.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_transactions.dart';

/// DashboardScreen ดูแล streams และ state; Home รับเพียงภาพข้อมูลและการกระทำที่ใช้ได้จริง
class Home extends StatelessWidget {
  const Home({
    super.key,
    this.transactions,
    this.referenceMonth,
    this.onAddTransaction,
    this.onAddTypedTransaction,
    this.budgetSnapshot,
    this.onRetryBudget,
    this.notice,
    this.onDestinationSelected,
    this.showBalance = true,
    this.onToggleBalanceVisibility,
  });

  final List<MoneyTransaction>? transactions;
  final DateTime? referenceMonth;
  final VoidCallback? onAddTransaction;
  final ValueChanged<TransactionType>? onAddTypedTransaction;
  final AsyncSnapshot<BudgetFeed>? budgetSnapshot;
  final VoidCallback? onRetryBudget;
  final String? notice;
  final ValueChanged<int>? onDestinationSelected;
  final bool showBalance;
  final VoidCallback? onToggleBalanceVisibility;

  @override
  Widget build(BuildContext context) {
    // การประกอบ Home เดี่ยวใช้ตัวอย่างเดิม; แอปจริงส่ง transactions เสมอ รวมถึงลิสต์ว่าง
    final records = transactions ?? sampleTransactions;
    final month = referenceMonth ?? sampleReferenceMonth;
    final summary = DashboardSummary.fromTransactions(records, month: month);
    final insight = monthlyExpenseInsight(records, month: month);
    final navigate = onDestinationSelected;
    final addTyped = onAddTypedTransaction;
    final hasQuickActions =
        addTyped != null || onAddTransaction != null || navigate != null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          key: const PageStorageKey('dashboard-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 104),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MoneyMate',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatThaiMonth(month),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (navigate != null) ...[
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          tooltip: 'กระเป๋าเงิน',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.mintSurface,
                            foregroundColor: AppColors.primaryDeep,
                            minimumSize: const Size(48, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => navigate(3),
                          icon: const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 22,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (notice != null && notice!.trim().isNotEmpty) ...[
                    Semantics(
                      liveRegion: true,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.noticeBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  notice!,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  BalanceCard(
                    summary: summary,
                    showBalance: showBalance,
                    onToggleBalanceVisibility: onToggleBalanceVisibility,
                  ),
                  const SizedBox(height: 20),
                  BudgetSnapshotCard(
                    snapshot: budgetSnapshot,
                    expenseSatang: summary.expenseSatang,
                    onOpenBudget: navigate == null ? null : () => navigate(3),
                    onRetry: onRetryBudget,
                  ),
                  if (hasQuickActions) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'จัดการเงินของคุณ',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    QuickActions(
                      onAddExpense: addTyped == null
                          ? onAddTransaction
                          : () => addTyped(TransactionType.expense),
                      onAddIncome: addTyped == null
                          ? null
                          : () => addTyped(TransactionType.income),
                      onStatistics: navigate == null ? null : () => navigate(2),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      const Text(
                        'รายการล่าสุด',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (navigate != null)
                        TextButton(
                          onPressed: () => navigate(1),
                          child: const Text('ดูทั้งหมด'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RecentTransactions(transactions: summary.recentTransactions),
                  if (summary.recentTransactions.isEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'เริ่มต้นบันทึกรายรับ–รายจ่ายรายการแรกของคุณ',
                      style: TextStyle(color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (insight != null) ...[
                    const SizedBox(height: 24),
                    FinanceInsightCard(insight: insight),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: onAddTransaction == null
          ? null
          : FloatingActionButton.extended(
              onPressed: onAddTransaction,
              tooltip: 'เพิ่มรายการ',
              icon: const Icon(Icons.add_rounded),
              label: const Text('เพิ่มรายการ'),
            ),
      bottomNavigationBar: navigate == null
          ? null
          : MoneyMateNavigationBar(currentIndex: 0, onTap: navigate),
    );
  }
}
