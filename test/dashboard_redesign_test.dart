import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app_theme.dart';
import 'package:project_moneymate/models/budget_model.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/screens/dashboard_screen.dart';
import 'package:project_moneymate/services/budget_repository.dart';
import 'package:project_moneymate/services/demo_budget_repository.dart';
import 'package:project_moneymate/services/demo_transaction_repository.dart';

class ControlledBudgets implements BudgetRepository {
  final feeds = <String, StreamController<BudgetFeed>>{};
  String key(DateTime date) => '${date.year}-${date.month}';
  StreamController<BudgetFeed> controller(DateTime date) => feeds.putIfAbsent(
    key(date),
    () => StreamController<BudgetFeed>.broadcast(),
  );
  @override
  Stream<BudgetFeed> watchBudget(DateTime month) => controller(month).stream;
  @override
  Future<void> saveBudget(BudgetModel budget) async =>
      controller(budget.month).add(BudgetFeed(budget: budget));
  Future<void> dispose() async {
    for (final controller in feeds.values) {
      await controller.close();
    }
  }
}

MoneyTransaction expense(String id, int amount, DateTime date) =>
    MoneyTransaction(
      id: id,
      title: id,
      amountSatang: amount,
      type: TransactionType.expense,
      category: TransactionCategory.food,
      date: date,
    );

void main() {
  final november = DateTime(2026, 11);
  Widget app(
    DemoTransactionRepository transactions,
    BudgetRepository budgets, {
    DateTime? month,
  }) => MaterialApp(
    theme: buildAppTheme(),
    home: DashboardScreen(
      repository: transactions,
      budgetRepository: budgets,
      referenceMonth: month ?? november,
    ),
  );

  testWidgets(
    'snapshot follows real budgets and transaction save edit delete',
    (tester) async {
      final transactions = DemoTransactionRepository(
        initialTransactions: [
          expense('food', 10001, november),
          expense('old', 999999, DateTime(2025, 11)),
        ],
      );
      final budgets = DemoBudgetRepository(
        initialBudgets: [BudgetModel(month: november, limitSatang: 50000)],
      );
      addTearDown(transactions.dispose);
      addTearDown(budgets.dispose);
      await tester.pumpWidget(app(transactions, budgets));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('dashboard-budget-spent')))
            .data,
        '฿100.01',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('dashboard-budget-remaining')))
            .data,
        '฿399.99',
      );
      await transactions.saveTransaction(expense('new', 40000, november));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('dashboard-budget-remaining')))
            .data,
        '-฿0.01',
      );
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('budget-progress')),
            )
            .value,
        1,
      );
      await transactions.updateTransaction(expense('new', 20000, november));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('dashboard-budget-spent')))
            .data,
        '฿300.01',
      );
      await transactions.deleteTransaction('new');
      await budgets.saveBudget(
        BudgetModel(month: november, limitSatang: 60000),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('dashboard-budget-remaining')))
            .data,
        '฿499.99',
      );
    },
  );

  testWidgets('missing budget offers setup that opens actual budget tab', (
    tester,
  ) async {
    final transactions = DemoTransactionRepository();
    final budgets = DemoBudgetRepository();
    addTearDown(transactions.dispose);
    addTearDown(budgets.dispose);
    await tester.pumpWidget(app(transactions, budgets));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.ensureVisible(find.text('ตั้งงบประมาณ'));
    await tester.tap(find.text('ตั้งงบประมาณ'));
    await tester.pumpAndSettle();
    expect(find.text('งบประมาณรายเดือน'), findsOneWidget);
    expect(find.text('ยังไม่ได้ตั้งงบประมาณ'), findsWidgets);
  });

  testWidgets(
    'budget loading error retry and sync metadata remain independent',
    (tester) async {
      final transactions = DemoTransactionRepository();
      final budgets = ControlledBudgets();
      addTearDown(transactions.dispose);
      addTearDown(budgets.dispose);
      await tester.pumpWidget(app(transactions, budgets));
      await tester.pump();
      expect(find.text('กำลังโหลดงบประมาณ'), findsOneWidget);
      budgets.controller(november).addError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('โหลดงบประมาณไม่สำเร็จ'), findsOneWidget);
      await tester.ensureVisible(find.text('ลองโหลดงบอีกครั้ง'));
      await tester.tap(find.text('ลองโหลดงบอีกครั้ง'));
      await tester.pump();
      budgets
          .controller(november)
          .add(
            BudgetFeed(
              budget: BudgetModel(month: november, limitSatang: 50000),
              hasPendingWrites: true,
              isFromCache: true,
            ),
          );
      await tester.pumpAndSettle();
      expect(find.text('งบประมาณกำลังรอยืนยันจาก Firebase'), findsOneWidget);
      expect(find.text('งบประมาณจากข้อมูลในเครื่อง'), findsOneWidget);
    },
  );

  testWidgets('switching month and repository immediately clears old budget', (
    tester,
  ) async {
    final transactions = DemoTransactionRepository();
    final first = ControlledBudgets();
    final second = ControlledBudgets();
    addTearDown(transactions.dispose);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(app(transactions, first));
    await tester.pump();
    await first.saveBudget(BudgetModel(month: november, limitSatang: 50000));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard-budget-limit')), findsOneWidget);
    await tester.pumpWidget(
      app(transactions, first, month: DateTime(2026, 12)),
    );
    await tester.pump();
    expect(find.byKey(const Key('dashboard-budget-limit')), findsNothing);
    expect(find.text('กำลังโหลดงบประมาณ'), findsOneWidget);
    await first.saveBudget(
      BudgetModel(month: DateTime(2026, 12), limitSatang: 60000),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('dashboard-budget-limit'))).data,
      '฿600.00',
    );
    await tester.pumpWidget(
      app(transactions, second, month: DateTime(2026, 12)),
    );
    await tester.pump();
    expect(find.byKey(const Key('dashboard-budget-limit')), findsNothing);
    second.controller(DateTime(2026, 12)).addError(StateError('denied'));
    await tester.pumpAndSettle();
    expect(find.text('โหลดงบประมาณไม่สำเร็จ'), findsOneWidget);
    expect(find.text('฿600.00'), findsNothing);
  });

  testWidgets('income shortcut opens real form and saves the selected type', (
    tester,
  ) async {
    final transactions = DemoTransactionRepository();
    final budgets = DemoBudgetRepository();
    addTearDown(transactions.dispose);
    addTearDown(budgets.dispose);
    await tester.pumpWidget(app(transactions, budgets, month: DateTime.now()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('เพิ่มรายรับ'));
    await tester.tap(find.text('เพิ่มรายรับ'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('transaction-title')),
      'รายรับจริง',
    );
    await tester.enterText(
      find.byKey(const Key('transaction-amount')),
      '90.05',
    );
    await tester.ensureVisible(find.text('บันทึกรายการ'));
    await tester.tap(find.text('บันทึกรายการ'));
    await tester.pumpAndSettle();
    final latest = await tester.runAsync(
      () => transactions.watchTransactions().first,
    );
    final records = latest!.transactions;
    expect(records.single.type, TransactionType.income);
    expect(records.single.amountSatang, 9005);
    expect(records.single.category, TransactionCategory.salary);
  });

  testWidgets('month rollover rebinds budget on a transaction stream event', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 30, 23, 59, 59);
    final transactions = DemoTransactionRepository();
    final budgets = DemoBudgetRepository(
      initialBudgets: [
        BudgetModel(month: november, limitSatang: 50000),
        BudgetModel(month: DateTime(2026, 12), limitSatang: 60000),
      ],
    );
    addTearDown(transactions.dispose);
    addTearDown(budgets.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: DashboardScreen(
          repository: transactions,
          budgetRepository: budgets,
          currentTime: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('dashboard-budget-limit'))).data,
      '฿500.00',
    );
    now = DateTime(2026, 12, 1);
    await transactions.saveTransaction(expense('december', 2000, now));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('dashboard-budget-limit'))).data,
      '฿600.00',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('dashboard-budget-spent'))).data,
      '฿20.00',
    );
    expect(find.text('ธันวาคม 2026'), findsOneWidget);
  });

  testWidgets('month rollover refreshes without incoming repository events', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 30, 23, 59, 59);
    final transactions = DemoTransactionRepository();
    final budgets = DemoBudgetRepository(
      initialBudgets: [
        BudgetModel(month: november, limitSatang: 50000),
        BudgetModel(month: DateTime(2026, 12), limitSatang: 60000),
      ],
    );
    addTearDown(transactions.dispose);
    addTearDown(budgets.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: DashboardScreen(
          repository: transactions,
          budgetRepository: budgets,
          currentTime: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    now = DateTime(2026, 12, 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('dashboard-budget-limit'))).data,
      '฿600.00',
    );
    expect(find.text('ธันวาคม 2026'), findsOneWidget);
  });

  testWidgets(
    'leaving a fixed reference month resumes automatic month refresh',
    (tester) async {
      var now = DateTime(2026, 11, 30, 23, 59, 59);
      final transactions = DemoTransactionRepository();
      final budgets = DemoBudgetRepository(
        initialBudgets: [
          BudgetModel(month: november, limitSatang: 50000),
          BudgetModel(month: DateTime(2026, 12), limitSatang: 60000),
        ],
      );
      addTearDown(transactions.dispose);
      addTearDown(budgets.dispose);
      Widget frame(DateTime? month) => MaterialApp(
        home: DashboardScreen(
          repository: transactions,
          budgetRepository: budgets,
          referenceMonth: month,
          currentTime: () => now,
        ),
      );
      await tester.pumpWidget(frame(november));
      await tester.pumpAndSettle();
      await tester.pumpWidget(frame(null));
      await tester.pumpAndSettle();
      now = DateTime(2026, 12, 1);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('dashboard-budget-limit')))
            .data,
        '฿600.00',
      );
    },
  );

  test('latest records include at most five without mutating source', () {
    final records = List.generate(
      6,
      (index) => expense('$index', 1, DateTime(2026, 11, index + 1)),
    );
    final summary = DashboardSummary.fromTransactions(records, month: november);
    expect(summary.recentTransactions.map((item) => item.id), [
      '5',
      '4',
      '3',
      '2',
      '1',
    ]);
    expect(records.first.id, '0');
  });
}
