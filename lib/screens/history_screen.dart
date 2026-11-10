// หน้าประวัติ: กรอง ค้นหา และส่งคำขอแก้ไขหรือลบรายการกลับไปยังผู้ดูแลข้อมูล

import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/money_transaction.dart';
import '../utils/date_formatter.dart';
import '../utils/history_filter.dart';
import '../utils/money_format.dart';
import '../widgets/moneymate_navigation_bar.dart';
import '../widgets/transaction_tile.dart';

/// รับรายการจากผู้ดูแล stream ส่วนกลาง และเก็บเฉพาะตัวกรองกับสถานะงานของหน้านี้
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.transactions,
    required this.initialMonth,
    required this.onEditTransaction,
    required this.onDeleteTransaction,
    required this.onAddTransaction,
    required this.onDestinationSelected,
    this.notice,
  });

  final List<MoneyTransaction> transactions;
  final DateTime initialMonth;
  final Future<void> Function(MoneyTransaction) onEditTransaction;
  final Future<void> Function(MoneyTransaction) onDeleteTransaction;
  final VoidCallback onAddTransaction;
  final ValueChanged<int> onDestinationSelected;
  final String? notice;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum _HistoryAction { edit, delete }

/// ตัวกรองอยู่ใน State จึงยังคงค่าที่ผู้ใช้เลือกเมื่อรายการจาก stream เปลี่ยน
class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime? _selectedMonth;
  TransactionType? _selectedType;
  String _query = '';
  // ล็อกงานแยกตาม ID: ป้องกันเมนูซ้อน แต่ยังจัดการรายการอื่นได้
  final Set<String> _busyIds = {};
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _selectedMonth = _month(widget.initialMonth);
  }

  DateTime _month(DateTime date) => DateTime(date.year, date.month);
  String _monthKey(DateTime date) => '${date.year}-${date.month}';

  /// รวมเดือนข้อมูลกับเดือนที่เลือกไว้ เพื่อให้ dropdown ยังใช้ได้แม้รายการสุดท้ายถูกลบ
  List<DateTime> get _availableMonths {
    final months = <DateTime>{
      _month(widget.initialMonth),
      ?_selectedMonth,
      for (final transaction in widget.transactions) _month(transaction.date),
    }.toList()..sort((a, b) => b.compareTo(a));
    return months;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// ส่งรายการต้นฉบับให้ผู้เรียกเปิดฟอร์ม และปลดล็อกเมื่อกลับมาหรือเกิดข้อผิดพลาด
  Future<void> _edit(MoneyTransaction transaction) async {
    if (_busyIds.contains(transaction.id)) return;
    setState(() => _busyIds.add(transaction.id));
    try {
      await widget.onEditTransaction(transaction);
    } catch (_) {
      if (mounted) {
        _showMessage(
          'เปิดรายการเพื่อแก้ไขไม่สำเร็จ ตรวจสอบการเชื่อมต่อและสิทธิ์ แล้วลองอีกครั้ง',
        );
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(transaction.id));
    }
  }

  /// รอยืนยันจากผู้ใช้ก่อนลบ และรอผล repository ก่อนแสดงข้อความสำเร็จ
  Future<void> _delete(MoneyTransaction transaction) async {
    if (_busyIds.contains(transaction.id)) return;
    // จอง ID ก่อนเปิดกล่องยืนยัน เพื่อกันคำสั่งแก้ไขหรือลบซ้อนกันระหว่างรอ
    setState(() => _busyIds.add(transaction.id));
    final bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ยืนยันการลบรายการ'),
          content: Text(
            'ต้องการลบรายการ “${transaction.title}” จำนวน ${formatBaht(transaction.amountSatang)} หรือไม่?',
          ),
          scrollable: true,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('ลบรายการ'),
            ),
          ],
        ),
      );
      // หลัง await หน้าจออาจถูกปิดแล้ว จึงตรวจ mounted ก่อนใช้ context หรือ setState
      if (confirmed != true || !mounted) return;
      setState(() => _deletingIds.add(transaction.id));
      await widget.onDeleteTransaction(transaction);
      if (mounted) _showMessage('ลบรายการแล้ว');
    } on TimeoutException {
      // หมดเวลารอไม่ได้แปลว่าคลาวด์ยังไม่ลบ ต้องสื่อว่าผลยังไม่แน่นอน
      if (mounted) {
        _showMessage(
          'ยังยืนยันการลบไม่ได้ รายการอาจถูกลบแล้ว ตรวจสอบการเชื่อมต่อและรอข้อมูลล่าสุดก่อนลองอีกครั้ง',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'ลบรายการไม่สำเร็จ ตรวจสอบการเชื่อมต่อและสิทธิ์ แล้วลองอีกครั้ง',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyIds.remove(transaction.id);
          _deletingIds.remove(transaction.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // รายการและยอดรวมด้านบนใช้ตัวกรองชุดเดียวกัน เพื่อให้จำนวนและยอดตรงกับแถวที่เห็น
    final transactions = filterHistoryTransactions(
      widget.transactions,
      month: _selectedMonth,
      type: _selectedType,
      query: _query,
    );
    var income = 0;
    var expense = 0;
    for (final transaction in transactions) {
      if (transaction.isIncome) {
        income += transaction.amountSatang;
      } else {
        expense += transaction.amountSatang;
      }
    }
    final months = _availableMonths;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติรายการ'),
        actions: [
          IconButton.filledTonal(
            tooltip: 'เพิ่มรายการ',
            onPressed: widget.onAddTransaction,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 584),
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  // เว้นขอบเท่ากันทุกหน้าหลัก และแยกชุดตัวกรองออกจากผลรายการ
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  sliver: SliverToBoxAdapter(
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
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                widget.notice!,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // ตัวกรองเดือน ประเภท และคำค้นเปลี่ยนเฉพาะภาพที่แสดง ไม่แก้ข้อมูลจริง
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'เดือน',
                            prefixIcon: Icon(Icons.calendar_month_outlined),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              key: const Key('history-month'),
                              value: _selectedMonth == null
                                  ? 'all'
                                  : _monthKey(_selectedMonth!),
                              isExpanded: true,
                              itemHeight: null,
                              menuMaxHeight: 340,
                              items: [
                                const DropdownMenuItem(
                                  value: 'all',
                                  child: Text('ทุกเดือน'),
                                ),
                                for (final month in months)
                                  DropdownMenuItem(
                                    value: _monthKey(month),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(formatThaiMonth(month)),
                                    ),
                                  ),
                              ],
                              onChanged: (value) => setState(() {
                                _selectedMonth = value == 'all'
                                    ? null
                                    : months.firstWhere(
                                        (month) => _monthKey(month) == value,
                                      );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('ทั้งหมด'),
                              selected: _selectedType == null,
                              onSelected: (_) =>
                                  setState(() => _selectedType = null),
                            ),
                            ChoiceChip(
                              label: const Text('รายรับ'),
                              selected: _selectedType == TransactionType.income,
                              onSelected: (_) => setState(
                                () => _selectedType = TransactionType.income,
                              ),
                            ),
                            ChoiceChip(
                              label: const Text('รายจ่าย'),
                              selected:
                                  _selectedType == TransactionType.expense,
                              onSelected: (_) => setState(
                                () => _selectedType = TransactionType.expense,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const Key('history-search'),
                          decoration: const InputDecoration(
                            labelText: 'ค้นหาชื่อรายการ',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: 24),
                        // พื้นขาวและเส้นขอบบางช่วยให้ยอดรวมแยกจากเครื่องมือค้นหา
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${transactions.length} รายการ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 32,
                                runSpacing: 12,
                                children: [
                                  _HistoryTotal(
                                    label: 'รายรับ',
                                    amountSatang: income,
                                    color: AppColors.income,
                                  ),
                                  _HistoryTotal(
                                    label: 'รายจ่าย',
                                    amountSatang: expense,
                                    color: AppColors.expense,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (transactions.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.all(32),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_outlined,
                            size: 40,
                            color: AppColors.muted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'ไม่พบรายการที่ตรงกับตัวกรอง',
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'ลองเลือกเดือน ประเภท หรือคำค้นหาอื่น',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        final previous = index == 0
                            ? null
                            : transactions[index - 1];
                        // แทรกหัววันที่เฉพาะแถวแรกของวัน หลังรายการเรียงล่าสุดก่อนแล้ว
                        final startsDay =
                            previous == null ||
                            !DateUtils.isSameDay(
                              previous.date,
                              transaction.date,
                            );
                        final busy = _busyIds.contains(transaction.id);
                        return Column(
                          key: ValueKey('history-row-${transaction.id}'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (startsDay)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  4,
                                  16,
                                  4,
                                  12,
                                ),
                                child: Text(
                                  formatThaiDate(transaction.date),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TransactionTile(
                                      transaction: transaction,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PopupMenuButton<_HistoryAction>(
                                          key: ValueKey(
                                            'history-actions-${transaction.id}',
                                          ),
                                          tooltip:
                                              'จัดการ ${transaction.title}',
                                          enabled: !busy,
                                          onSelected: (action) {
                                            switch (action) {
                                              case _HistoryAction.edit:
                                                unawaited(_edit(transaction));
                                              case _HistoryAction.delete:
                                                unawaited(_delete(transaction));
                                            }
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: _HistoryAction.edit,
                                              child: Text('แก้ไข'),
                                            ),
                                            PopupMenuItem(
                                              value: _HistoryAction.delete,
                                              child: Text('ลบ'),
                                            ),
                                          ],
                                        ),
                                        if (_deletingIds.contains(
                                          transaction.id,
                                        ))
                                          const Padding(
                                            padding: EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: SizedBox.square(
                                              dimension: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                semanticsLabel:
                                                    'กำลังดำเนินการ',
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: MoneyMateNavigationBar(
        currentIndex: 1,
        onTap: widget.onDestinationSelected,
      ),
    );
  }
}

/// ป้ายยอดรวมของรายการที่ผ่านตัวกรอง แสดงจำนวนเต็มสตางค์เป็นเงินบาท
class _HistoryTotal extends StatelessWidget {
  const _HistoryTotal({
    required this.label,
    required this.amountSatang,
    required this.color,
  });

  final String label;
  final int amountSatang;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ชื่อยอดยังอ่านได้ชัดเมื่อขยายตัวอักษร โดยให้จำนวนเงินเด่นกว่าหนึ่งระดับ
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
      const SizedBox(height: 4),
      Text(
        formatBaht(amountSatang),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
    ],
  );
}
