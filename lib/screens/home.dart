// ประกอบ Dashboard: คำทักทาย ยอดเงิน รายการล่าสุด และทางลัดเพิ่มรายการ/งบประมาณ
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../data/sample_transactions.dart';
import '../models/money_transaction.dart';
import '../utils/date_formatter.dart';
import '../widgets/balance_card.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/moneymate_navigation_bar.dart';

/// หน้านี้ยังไม่มี state ที่เปลี่ยนเอง จึงใช้ StatelessWidget
/// DashboardScreen ส่งข้อมูลจาก StreamBuilder และ callback การนำทางเข้ามา
class Home extends StatelessWidget {
  const Home({
    super.key,
    this.transactions,
    this.referenceMonth,
    this.onAddTransaction,
    this.notice,
    this.onDestinationSelected,
    this.showBalance = true,
    this.onToggleBalanceVisibility,
  });

  final List<MoneyTransaction>? transactions;
  final DateTime? referenceMonth;
  final VoidCallback? onAddTransaction;
  final String? notice;
  final ValueChanged<int>? onDestinationSelected;
  final bool showBalance;
  final VoidCallback? onToggleBalanceVisibility;

  void _showNextStep(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final month = referenceMonth ?? sampleReferenceMonth;
    final summary = DashboardSummary.fromTransactions(
      transactions ?? sampleTransactions,
      month: month,
    );

    return Scaffold(
      // SafeArea เว้นพื้นที่กล้องและแถบระบบ ส่วนเนื้อหาเลื่อนได้บนจอเล็ก
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'สวัสดี 👋',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'MoneyMate',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                        onPressed: onDestinationSelected != null
                            ? () => onDestinationSelected!(3)
                            : () => _showNextStep(
                                context,
                                'หน้ากระเป๋าเงินจะพร้อมในขั้นตอนถัดไป',
                              ),
                        icon: const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 22,
                        ),
                      ),
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
                      Text(
                        formatThaiMonth(month),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RecentTransactions(transactions: summary.recentTransactions),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      minimumSize: const Size(48, 52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onPressed:
                        onAddTransaction ??
                        () => _showNextStep(
                          context,
                          'ฟอร์มเพิ่มรายการจะพร้อมในขั้นตอนถัดไป',
                        ),
                    icon: const Icon(Icons.add_rounded, size: 22),
                    label: const Text(
                      'เพิ่มรายการ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: MoneyMateNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (onDestinationSelected != null) {
            onDestinationSelected!(index);
            return;
          }
          if (index == 0) return;
          const pages = ['หน้าหลัก', 'ประวัติ', 'สถิติ', 'งบประมาณ'];
          _showNextStep(context, 'หน้า${pages[index]}จะพร้อมในขั้นตอนถัดไป');
        },
      ),
    );
  }
}
