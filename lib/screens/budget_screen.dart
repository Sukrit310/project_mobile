// หน้างบประมาณรายเดือน รับรายการเดิมมาคำนวณรายจ่ายและติดตามวงเงินแยกตามเดือน
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/budget_model.dart';
import '../models/budget_summary.dart';
import '../models/money_transaction.dart';
import '../services/budget_repository.dart';
import '../utils/date_formatter.dart';
import '../utils/money_format.dart';
import '../utils/statistics_calculator.dart';
import '../widgets/budget_editor_dialog.dart';
import '../widgets/budget_progress.dart';
import '../widgets/moneymate_navigation_bar.dart';

/// StatefulWidget เก็บเดือนที่เลือกและ stream ของเดือนนั้น โดยไม่เก็บยอดใช้ไปซ้ำในฐานข้อมูล
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({
    super.key,
    required this.transactions,
    required this.initialMonth,
    required this.repository,
    required this.onAddTransaction,
    required this.onDestinationSelected,
    this.notice,
    this.isDemo = false,
  });

  final List<MoneyTransaction> transactions;
  final DateTime initialMonth;
  final BudgetRepository repository;
  final VoidCallback onAddTransaction;
  final ValueChanged<int> onDestinationSelected;
  final String? notice;
  final bool isDemo;

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late DateTime _selectedMonth;
  late Stream<BudgetFeed> _budgetStream;
  var _streamGeneration = 0;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(
      widget.initialMonth.year,
      widget.initialMonth.month,
    );
    _watchMonth();
  }

  @override
  void didUpdateWidget(covariant BudgetScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) _watchMonth();
  }

  /// เปลี่ยน key ของ StreamBuilder ด้วย เพื่อไม่แสดง snapshot เดือนเก่าระหว่างรอเดือนใหม่
  void _watchMonth() {
    _budgetStream = widget.repository.watchBudget(_selectedMonth);
    _streamGeneration++;
  }

  void _selectMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    if (normalized == _selectedMonth) return;
    setState(() {
      _selectedMonth = normalized;
      _watchMonth();
    });
  }

  List<DateTime> get _availableMonths => <DateTime>{
    _selectedMonth,
    DateTime(widget.initialMonth.year, widget.initialMonth.month),
    for (final transaction in widget.transactions)
      DateTime(transaction.date.year, transaction.date.month),
  }.toList()..sort((a, b) => b.compareTo(a));

  Future<void> _editBudget(BudgetModel? budget) async {
    final saved = await showDialog<bool>(
      context: context,
      // มีปุ่มยกเลิกชัดเจน และ PopScope ภายในป้องกันย้อนกลับระหว่างส่งข้อมูล
      barrierDismissible: false,
      builder: (_) => BudgetEditorDialog(
        month: _selectedMonth,
        repository: widget.repository,
        initialBudget: budget,
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isDemo ? 'บันทึกงบประมาณตัวอย่างแล้ว' : 'บันทึกงบประมาณแล้ว',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('งบประมาณรายเดือน'),
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          tooltip: 'เพิ่มรายการ',
          onPressed: widget.onAddTransaction,
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 584),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.notice?.trim().isNotEmpty ?? false) ...[
                  _BudgetNotice(widget.notice!),
                  const SizedBox(height: 16),
                ],
                _monthSelector(),
                const SizedBox(height: 20),
                StreamBuilder<BudgetFeed>(
                  key: ValueKey(_streamGeneration),
                  stream: _budgetStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Column(
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 40,
                            color: AppColors.muted,
                          ),
                          const SizedBox(height: 12),
                          const Text('โหลดงบประมาณไม่สำเร็จ'),
                          const SizedBox(height: 8),
                          const Text(
                            'ตรวจสอบการเชื่อมต่อและสิทธิ์เข้าถึงงบประมาณ แล้วลองอีกครั้ง',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => setState(_watchMonth),
                            child: const Text('ลองอีกครั้ง'),
                          ),
                        ],
                      );
                    }
                    final feed = snapshot.data;
                    if (feed == null) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: 'กำลังโหลดงบประมาณ',
                          ),
                        ),
                      );
                    }
                    // เดือนและปีต้องตรงกัน ยอดรายจ่ายรวมทุกหมวด รวมถึงหมวดเก่าที่เคยบันทึกไว้
                    final expense = calculateMonthlyStatistics(
                      widget.transactions,
                      _selectedMonth,
                    ).expenseSatang;
                    final summary = BudgetSummary(
                      limitSatang: feed.budget?.limitSatang ?? 0,
                      expenseSatang: expense,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (feed.hasPendingWrites) ...[
                          const _BudgetNotice(
                            'กำลังรอยืนยันการบันทึกงบประมาณจาก Firebase',
                          ),
                          const SizedBox(height: 16),
                        ] else if (feed.isFromCache) ...[
                          const _BudgetNotice(
                            'แสดงงบประมาณในเครื่อง กำลังตรวจสอบกับ Firebase',
                          ),
                          const SizedBox(height: 16),
                        ],
                        _summaryCard(summary),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: BudgetProgress(
                            limitSatang: summary.limitSatang,
                            expenseSatang: expense,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          key: const Key('budget-edit'),
                          onPressed: () => _editBudget(feed.budget),
                          icon: Icon(
                            summary.hasBudget ? Icons.edit_outlined : Icons.add,
                          ),
                          label: Text(
                            summary.hasBudget
                                ? 'แก้ไขวงเงิน'
                                : 'ตั้งวงเงินรายเดือน',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ยอดใช้ไปคำนวณจากรายจ่ายในเดือนที่เลือก รายรับไม่หักลดยอดใช้ไป',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    bottomNavigationBar: MoneyMateNavigationBar(
      currentIndex: 3,
      onTap: widget.onDestinationSelected,
    ),
  );

  /// ใช้ปี/เดือนเป็นค่า Dropdown โดยตรง เดือนว่างยังเลือกย้อนกลับมาดูได้
  Widget _monthSelector() => Row(
    children: [
      IconButton(
        tooltip: 'เดือนก่อนหน้า',
        onPressed: _selectedMonth.year == 1 && _selectedMonth.month == 1
            ? null
            : () => _selectMonth(
                DateTime(_selectedMonth.year, _selectedMonth.month - 1),
              ),
        icon: const Icon(Icons.chevron_left),
      ),
      Expanded(
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'เดือน',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<DateTime>(
              key: const Key('budget-month'),
              value: _selectedMonth,
              isExpanded: true,
              itemHeight: null,
              menuMaxHeight: 340,
              items: [
                for (final month in _availableMonths)
                  DropdownMenuItem(
                    value: month,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(formatThaiMonth(month)),
                    ),
                  ),
              ],
              onChanged: (month) {
                if (month != null) _selectMonth(month);
              },
            ),
          ),
        ),
      ),
      IconButton(
        tooltip: 'เดือนถัดไป',
        onPressed: _selectedMonth.year == 9999 && _selectedMonth.month == 12
            ? null
            : () => _selectMonth(
                DateTime(_selectedMonth.year, _selectedMonth.month + 1),
              ),
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );

  Widget _summaryCard(BudgetSummary summary) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'วงเงินของเดือน',
          style: TextStyle(color: AppColors.balanceLabel),
        ),
        const SizedBox(height: 6),
        Text(
          summary.hasBudget
              ? formatBaht(summary.limitSatang, decimalPlaces: true)
              : 'ยังไม่กำหนดวงเงิน',
          key: const Key('budget-limit'),
          style: const TextStyle(
            color: AppColors.onPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: AppColors.balanceDivider, height: 1),
        ),
        _BudgetAmount(
          label: 'ใช้ไปแล้ว',
          valueKey: const Key('budget-spent'),
          amount: formatBaht(summary.expenseSatang, decimalPlaces: true),
          color: AppColors.expenseHighlight,
        ),
        const SizedBox(height: 16),
        // ไม่แสดงยอดคงเหลือติดลบเมื่อยังไม่มีวงเงิน เพราะยังไม่มีงบให้นำมาหัก
        _BudgetAmount(
          label: 'คงเหลือ',
          valueKey: const Key('budget-remaining'),
          amount: summary.hasBudget
              ? formatBaht(summary.remainingSatang, decimalPlaces: true)
              : '—',
          color: summary.isOverBudget
              ? AppColors.expenseHighlight
              : AppColors.incomeHighlight,
        ),
      ],
    ),
  );
}

/// กล่องแจ้งข้อมูลตัวอย่าง/cache/pending อ่านได้ด้วยตัวช่วยอ่านหน้าจอ
class _BudgetNotice extends StatelessWidget {
  const _BudgetNotice(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.noticeBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.primary)),
    ),
  );
}

/// แถวชื่อยอดกับจำนวนเงิน แยกบรรทัดเพื่อรองรับยอดยาวและตัวอักษรใหญ่
class _BudgetAmount extends StatelessWidget {
  const _BudgetAmount({
    required this.label,
    required this.valueKey,
    required this.amount,
    required this.color,
  });
  final String label;
  final Key valueKey;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppColors.balanceLabel)),
      const SizedBox(height: 4),
      Text(
        amount,
        key: valueKey,
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
