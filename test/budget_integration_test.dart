// ตรวจการเปิดหน้างบประมาณผ่านเมนูจริงของแอป โดยใช้โหมดตัวอย่างเท่านั้น
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/main.dart';
import 'package:project_moneymate/data/sample_transactions.dart';
import 'package:project_moneymate/models/budget_model.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/services/demo_budget_repository.dart';
import 'package:project_moneymate/services/demo_transaction_repository.dart';

void main() {
  testWidgets('explicit demo opens monthly Budget with sample spending', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('ทดลองด้วยข้อมูลตัวอย่าง'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('งบประมาณ'));
    await tester.pumpAndSettle();
    expect(find.text('งบประมาณรายเดือน'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('budget-limit'))).data,
      '฿5,000.00',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('budget-spent'))).data,
      '฿3,500.00',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('budget-remaining'))).data,
      '฿1,500.00',
    );
    expect(find.textContaining('โหมดตัวอย่าง'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'Budget follows live expenses, ignores income/other years and retains month',
    (tester) async {
      final transactions = DemoTransactionRepository(
        initialTransactions: [
          ...sampleTransactions,
          MoneyTransaction(
            id: 'last-year',
            title: 'ปีก่อน',
            amountSatang: 999999,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            date: DateTime(2025, 11, 1),
          ),
        ],
      );
      final budgets = DemoBudgetRepository(
        initialBudgets: [
          BudgetModel(month: DateTime(2026, 11), limitSatang: 500000),
        ],
      );
      addTearDown(transactions.dispose);
      addTearDown(budgets.dispose);
      await tester.pumpWidget(
        MyApp(
          repository: transactions,
          budgetRepository: budgets,
          referenceMonth: DateTime(2026, 11),
        ),
      );
      await tester.pumpAndSettle();
      // ทางลัดกระเป๋าเงินบน Home เปิดแท็บงบเดียวกับเมนูล่าง
      await tester.tap(find.byTooltip('กระเป๋าเงิน'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('budget-spent'))).data,
        '฿3,500.00',
      );
      final expense = MoneyTransaction(
        id: 'extra',
        title: 'รายจ่ายเพิ่ม',
        amountSatang: 150025,
        type: TransactionType.expense,
        category: TransactionCategory.salary,
        date: DateTime(2026, 11, 10),
      );
      await transactions.saveTransaction(expense);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('budget-remaining'))).data,
        '-฿0.25',
      );
      expect(find.text('เกินงบแล้ว'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('budget-progress')),
            )
            .value,
        1,
      );
      await transactions.updateTransaction(
        MoneyTransaction(
          id: expense.id,
          title: expense.title,
          amountSatang: 1000,
          type: expense.type,
          category: expense.category,
          date: expense.date,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('budget-spent'))).data,
        '฿3,510.00',
      );
      await transactions.deleteTransaction(expense.id);
      await transactions.saveTransaction(
        MoneyTransaction(
          id: 'income',
          title: 'รายรับเพิ่ม',
          amountSatang: 500000,
          type: TransactionType.income,
          category: TransactionCategory.food,
          date: DateTime(2026, 11, 10),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('budget-spent'))).data,
        '฿3,500.00',
      );
      await tester.tap(find.byTooltip('เดือนก่อนหน้า'));
      await tester.pumpAndSettle();
      expect(find.text('ตุลาคม 2026'), findsOneWidget);
      expect(find.text('ยังไม่ได้ตั้งงบประมาณ'), findsOneWidget);
      await budgets.saveBudget(
        BudgetModel(month: DateTime(2026, 10), limitSatang: 100000),
      );
      await transactions.saveTransaction(
        MoneyTransaction(
          id: 'october',
          title: 'ตุลาคม',
          amountSatang: 10000,
          type: TransactionType.expense,
          category: TransactionCategory.housing,
          date: DateTime(2026, 10, 1),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ตุลาคม 2026'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('budget-remaining'))).data,
        '฿900.00',
      );
      await tester.tap(find.byTooltip('เดือนถัดไป'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('budget-limit'))).data,
        '฿5,000.00',
      );
      await tester.tap(find.text('ประวัติ'));
      await tester.pumpAndSettle();
      expect(find.text('ประวัติรายการ'), findsOneWidget);
      await tester.tap(find.text('สถิติ'));
      await tester.pumpAndSettle();
      expect(find.text('สถิติการเงิน'), findsOneWidget);
    },
  );
}
