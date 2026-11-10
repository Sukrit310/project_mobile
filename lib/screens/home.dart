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
  });

  final List<MoneyTransaction>? transactions;
  final DateTime? referenceMonth;
  final VoidCallback? onAddTransaction;
  final String? notice;
  final ValueChanged<int>? onDestinationSelected;

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
          padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
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
                            Text('สวัสดี 👋', style: TextStyle(fontSize: 12)),
                            SizedBox(height: 2),
                            Text(
                              'MoneyMate',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'กระเป๋าเงิน',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.text,
                        ),
                        onPressed: onDestinationSelected != null
                            ? () => onDestinationSelected!(3)
                            : () => _showNextStep(
                                context,
                                'หน้ากระเป๋าเงินจะพร้อมในขั้นตอนถัดไป',
                              ),
                        icon: const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (notice != null && notice!.trim().isNotEmpty) ...[
                    Semantics(
                      liveRegion: true,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.noticeBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            notice!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  BalanceCard(summary: summary),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      const Text(
                        'รายการล่าสุด',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formatThaiMonth(month),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RecentTransactions(transactions: summary.recentTransactions),
                  const SizedBox(height: 12),
                  Center(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        minimumSize: const Size(0, 50),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed:
                          onAddTransaction ??
                          () => _showNextStep(
                            context,
                            'ฟอร์มเพิ่มรายการจะพร้อมในขั้นตอนถัดไป',
                          ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'เพิ่มรายการ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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
