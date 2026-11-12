// ตัวประสานเมนูทั้งสี่หน้า ใช้ stream รายการร่วมกันและเปิดฟอร์มเพิ่ม/แก้ไข
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/money_transaction.dart';
import '../services/budget_repository.dart';
import '../services/transaction_repository.dart';
import '../widgets/status_view.dart';
import '../widgets/tab_switch_transition.dart';
import '../widgets/moneymate_navigation_bar.dart';
import 'budget_screen.dart';
import 'home.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';
import 'transaction_form_screen.dart';

/// รับ stream จาก Service ส่งข้อมูลให้ Home/History/Statistics/Budget โดย Widget ย่อยไม่เรียก SDK
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.repository,
    this.budgetRepository,
    this.referenceMonth,
    this.currentTime,
    this.isDemo = false,
  });

  final TransactionRepository repository;
  final BudgetRepository? budgetRepository;
  final DateTime? referenceMonth;

  /// แหล่งเวลาเดียวสำหรับเปลี่ยนงบตามเดือน; ค่าเริ่มต้นใช้เวลาของเครื่อง
  final DateTime Function()? currentTime;
  final bool isDemo;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Stream<TransactionFeed> _feed;
  Stream<BudgetFeed>? _budgetFeed;
  BudgetRepository? _watchedBudgetRepository;
  DateTime? _budgetMonth;
  Timer? _monthTimer;
  var _selectedTab = 0;
  bool _showBalance = true;

  @override
  void initState() {
    super.initState();
    // เก็บ stream ไว้ใน state เพื่อไม่เปิด subscription ใหม่ทุกครั้งที่เปลี่ยนแท็บ
    _feed = widget.repository.watchTransactions();
    _watchBudget();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _feed = widget.repository.watchTransactions();
    }
    _watchBudget();
    // แม้เป็นเดือนเดิม การเปลี่ยนจากเดือนอ้างอิงกลับมาใช้เวลาจริงต้องเริ่มตัวจับเวลา
    _scheduleMonthRefresh();
  }

  /// เปลี่ยน stream เฉพาะเมื่อเดือนหรือแหล่งข้อมูลเปลี่ยน ไม่เปิดใหม่ทุกการแตะเมนู
  void _watchBudget({bool force = false}) {
    final reference = widget.referenceMonth ?? _now;
    final month = DateTime(reference.year, reference.month);
    if (!force &&
        _watchedBudgetRepository == widget.budgetRepository &&
        _budgetMonth == month) {
      return;
    }
    _budgetMonth = month;
    _watchedBudgetRepository = widget.budgetRepository;
    _budgetFeed = widget.budgetRepository?.watchBudget(month);
    _scheduleMonthRefresh();
  }

  void _scheduleMonthRefresh() {
    _monthTimer?.cancel();
    if (widget.referenceMonth != null) return;
    final now = _now;
    final next = now.isUtc
        ? DateTime.utc(now.year, now.month + 1)
        : DateTime(now.year, now.month + 1);
    _monthTimer = Timer(next.difference(now), () {
      if (!mounted) return;
      setState(() => _watchBudget());
      _scheduleMonthRefresh();
    });
  }

  @override
  void dispose() {
    _monthTimer?.cancel();
    super.dispose();
  }

  void _selectTab(int index) {
    FocusScope.of(context).unfocus();
    if (index >= 0 && index <= 3) {
      setState(() => _selectedTab = index);
    }
  }

  DateTime get _now => widget.currentTime?.call() ?? DateTime.now();

  /// สร้าง ID ครั้งเดียวก่อนเปิด route; ฟอร์มที่ลองบันทึกซ้ำยังใช้ ID เดิม
  Future<void> _openTransactionForm({
    MoneyTransaction? existing,
    TransactionType initialType = TransactionType.expense,
  }) async {
    final editing = existing != null;
    final transactionId = existing?.id ?? widget.repository.newTransactionId();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(
          transactionId: transactionId,
          onSave: editing
              ? widget.repository.updateTransaction
              : widget.repository.saveTransaction,
          initialTransaction: existing,
          initialType: initialType,
        ),
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          editing
              ? (widget.isDemo ? 'แก้ไขรายการตัวอย่างแล้ว' : 'แก้ไขรายการแล้ว')
              : (widget.isDemo
                    ? 'เพิ่มรายการตัวอย่างแล้ว'
                    : 'บันทึกรายการแล้ว'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Android อาจส่งขนาดศูนย์ก่อน surface พร้อม อย่าคำนวณคอลัมน์หรือวางปุ่มในเฟรมนั้น
      if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
        return const SizedBox.shrink();
      }
      return StreamBuilder<TransactionFeed>(
        key: ObjectKey(_feed),
        stream: _feed,
        builder: (context, snapshot) => TabSwitchTransition(
          index: _selectedTab,
          child: _buildDestination(context, snapshot),
        ),
      );
    },
  );

  /// คง state ซ่อนยอดไว้ที่ตัวประสานหน้า จึงยังซ่อนอยู่เมื่อกลับมาจากแท็บอื่น
  Widget _buildDestination(
    BuildContext context,
    AsyncSnapshot<TransactionFeed> snapshot,
  ) {
    // StreamBuilder สร้าง subtree เอง จึงต้องตรวจเดือนที่จุดรับ event ด้วย
    _watchBudget();
    if (snapshot.hasError) {
      return StatusView(
        title: 'โหลดรายการไม่สำเร็จ',
        message: 'ตรวจสอบการเชื่อมต่อและสิทธิ์เข้าถึงข้อมูล แล้วลองอีกครั้ง',
        onRetry: () =>
            setState(() => _feed = widget.repository.watchTransactions()),
      );
    }
    final feed = snapshot.data;
    if (feed == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // แยกข้อมูลตัวอย่าง ข้อมูล cache และคำสั่งที่ยังรอเซิร์ฟเวอร์ยืนยันให้ผู้ใช้เห็น
    final notice = widget.isDemo
        ? 'โหมดตัวอย่าง • ข้อมูลชั่วคราว ไม่บันทึกบน Firebase'
        : feed.hasPendingWrites
        ? 'กำลังรอยืนยันการบันทึกจาก Firebase'
        : feed.isFromCache
        ? 'แสดงข้อมูลในเครื่อง กำลังตรวจสอบกับ Firebase'
        : null;
    if (_selectedTab == 1) {
      return HistoryScreen(
        transactions: feed.transactions,
        initialMonth: widget.referenceMonth ?? DateTime.now(),
        onEditTransaction: (transaction) =>
            _openTransactionForm(existing: transaction),
        onDeleteTransaction: (transaction) =>
            widget.repository.deleteTransaction(transaction.id),
        onAddTransaction: () => _openTransactionForm(),
        onDestinationSelected: _selectTab,
        notice: notice,
      );
    }
    if (_selectedTab == 2) {
      return StatisticsScreen(
        transactions: feed.transactions,
        initialMonth: widget.referenceMonth ?? DateTime.now(),
        onAddTransaction: () => _openTransactionForm(),
        onDestinationSelected: _selectTab,
        notice: notice,
      );
    }
    if (_selectedTab == 3) {
      final budgets = widget.budgetRepository;
      // ใช้เฉพาะกรณีประกอบแอปทดสอบโดยไม่ได้ส่ง budget repository เข้ามา
      // ไม่สร้างงบตัวอย่างให้แหล่งข้อมูลจริงโดยเงียบ ๆ
      if (budgets == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('งบประมาณรายเดือน')),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'ยังไม่ได้เชื่อมแหล่งข้อมูลงบประมาณ',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          bottomNavigationBar: MoneyMateNavigationBar(
            currentIndex: 3,
            onTap: _selectTab,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openTransactionForm(),
            tooltip: 'เพิ่มรายการ',
            child: const Icon(Icons.add_rounded),
          ),
        );
      }
      return BudgetScreen(
        transactions: feed.transactions,
        initialMonth: widget.referenceMonth ?? DateTime.now(),
        repository: budgets,
        onAddTransaction: () => _openTransactionForm(),
        onDestinationSelected: _selectTab,
        notice: notice,
        isDemo: widget.isDemo,
      );
    }
    final budgetFeed = _budgetFeed;
    if (budgetFeed == null) return _buildHome(feed, notice, null);
    // key ใหม่ถอด snapshot เดือน/แหล่งเดิมทันที แม้ stream ใหม่ยังโหลดหรืออ่านล้มเหลว
    return StreamBuilder<BudgetFeed>(
      key: ObjectKey(budgetFeed),
      stream: budgetFeed,
      builder: (context, budgetSnapshot) =>
          _buildHome(feed, notice, budgetSnapshot),
    );
  }

  Widget _buildHome(
    TransactionFeed feed,
    String? notice,
    AsyncSnapshot<BudgetFeed>? budgetSnapshot,
  ) => Home(
    showBalance: _showBalance,
    onToggleBalanceVisibility: () =>
        setState(() => _showBalance = !_showBalance),
    transactions: feed.transactions,
    referenceMonth: _budgetMonth,
    onAddTransaction: () => _openTransactionForm(),
    onAddTypedTransaction: (type) => _openTransactionForm(initialType: type),
    budgetSnapshot: budgetSnapshot,
    onRetryBudget: _budgetFeed == null
        ? null
        : () => setState(() => _watchBudget(force: true)),
    onDestinationSelected: _selectTab,
    notice: notice,
  );
}
