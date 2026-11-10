// หน้าสถิติรายเดือน: สรุปรายรับ รายจ่าย และกราฟจากรายการชุดเดียวกับหน้าหลัก

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/money_transaction.dart';
import '../utils/date_formatter.dart';
import '../utils/money_format.dart';
import '../utils/statistics_calculator.dart';
import '../widgets/expense_chart.dart';
import '../widgets/income_expense_chart.dart';
import '../widgets/moneymate_navigation_bar.dart';

/// รับข้อมูลชุดเดียวกับ Dashboard โดยไม่เรียก Firestore ซ้ำในหน้ากราฟ
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    super.key,
    required this.transactions,
    required this.initialMonth,
    required this.onAddTransaction,
    required this.onDestinationSelected,
    this.notice,
  });

  final List<MoneyTransaction> transactions;
  final DateTime initialMonth;
  final VoidCallback onAddTransaction;
  final ValueChanged<int> onDestinationSelected;
  final String? notice;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

/// เก็บเดือนที่เลือกแยกจากรายการสด เพื่อไม่เด้งกลับเมื่อมีการเพิ่ม แก้ไข หรือลบ
class _StatisticsScreenState extends State<StatisticsScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = _month(widget.initialMonth);
  }

  DateTime _month(DateTime date) => DateTime(date.year, date.month);

  /// คงเดือนที่เลือกแม้ไม่มีรายการแล้ว พร้อมเดือนอ้างอิงและเดือนอื่นที่มีข้อมูล
  List<DateTime> get _availableMonths => <DateTime>{
    _selectedMonth,
    _month(widget.initialMonth),
    for (final transaction in widget.transactions) _month(transaction.date),
  }.toList()..sort((a, b) => b.compareTo(a));

  /// DateTime จัดการเดือนเกินขอบเขตให้เอง จึงเลื่อนข้ามธันวาคมกับมกราคมได้
  void _changeMonth(int offset) => setState(() {
    _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + offset,
    );
  });

  @override
  Widget build(BuildContext context) {
    // คำนวณใหม่เมื่อ stream ส่งรายการมา แต่เก็บเดือนที่ผู้ใช้เลือกไว้
    final summary = calculateMonthlyStatistics(
      widget.transactions,
      _selectedMonth,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('สถิติการเงิน'),
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
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.noticeBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.notice!,
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // ลูกศรกับ dropdown เปลี่ยน State เดือนเดียวกัน แล้วคำนวณสรุปใหม่ด้านบน
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'เดือนก่อนหน้า',
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'เดือน',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<DateTime>(
                              key: const Key('statistics-month'),
                              value: _selectedMonth,
                              isExpanded: true,
                              itemHeight: null,
                              menuMaxHeight: 340,
                              items: [
                                for (final month in _availableMonths)
                                  DropdownMenuItem(
                                    value: month,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(formatThaiMonth(month)),
                                    ),
                                  ),
                              ],
                              onChanged: (month) {
                                if (month != null) {
                                  setState(() => _selectedMonth = month);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'เดือนถัดไป',
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ยอดสุทธิและจำนวนรายการอิงเฉพาะเดือน ต่างจากยอดคงเหลือสะสมบนหน้าหลัก
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'สุทธิของเดือน',
                          style: TextStyle(color: AppColors.balanceLabel),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatBaht(summary.netSatang, decimalPlaces: true),
                          key: const Key('statistics-net'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${summary.transactionCount} รายการในเดือนนี้',
                          style: const TextStyle(color: AppColors.balanceLabel),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(
                            height: 1,
                            color: AppColors.balanceDivider,
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // จอกว้างแบ่งสองคอลัมน์ จอแคบ/ตัวอักษรใหญ่เรียงลงมา
                            final twoColumns =
                                constraints.maxWidth >= 320 &&
                                MediaQuery.textScalerOf(context).scale(14) <=
                                    21;
                            final width = twoColumns
                                ? (constraints.maxWidth - 16) / 2
                                : constraints.maxWidth;
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: width,
                                  child: _MonthlyTotal(
                                    label: 'รายรับ',
                                    valueKey: const Key('statistics-income'),
                                    amountSatang: summary.incomeSatang,
                                    color: AppColors.incomeHighlight,
                                    icon: Icons.arrow_downward,
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _MonthlyTotal(
                                    label: 'รายจ่าย',
                                    valueKey: const Key('statistics-expense'),
                                    amountSatang: summary.expenseSatang,
                                    color: AppColors.expenseHighlight,
                                    icon: Icons.arrow_upward,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (summary.transactionCount == 0) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'ยังไม่มีรายการในเดือนนี้',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    Align(
                      child: TextButton.icon(
                        onPressed: widget.onAddTransaction,
                        icon: const Icon(Icons.add),
                        label: const Text('เพิ่มรายการแรก'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // ส่งผลรวมสำเร็จรูปให้กราฟทั้งสอง จึงไม่ต้องอ่าน Firestore แยกอีกครั้ง
                  _ChartSection(
                    title: 'สัดส่วนรายจ่าย',
                    subtitle: 'แยกตามหมวดหมู่ในเดือนที่เลือก',
                    child: ExpenseChart(
                      expensesByCategory: summary.expensesByCategory,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ChartSection(
                    title: 'รายรับและรายจ่าย',
                    subtitle: 'เปรียบเทียบยอดรวมในเดือนที่เลือก',
                    child: IncomeExpenseChart(
                      incomeSatang: summary.incomeSatang,
                      expenseSatang: summary.expenseSatang,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: MoneyMateNavigationBar(
        currentIndex: 2,
        onTap: widget.onDestinationSelected,
      ),
    );
  }
}

/// ยอดรายรับหรือรายจ่ายหนึ่งช่อง ใช้สีและไอคอนช่วยแยกความหมาย
class _MonthlyTotal extends StatelessWidget {
  const _MonthlyTotal({
    required this.label,
    required this.valueKey,
    required this.amountSatang,
    required this.color,
    required this.icon,
  });

  final String label;
  final Key valueKey;
  final int amountSatang;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.balanceLabel)),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        formatBaht(amountSatang, decimalPlaces: true),
        key: valueKey,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

/// จัดกรอบ หัวข้อ และคำอธิบายให้แต่ละกราฟใช้รูปแบบเดียวกัน
class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}
