// ทดสอบหน้าสถิติร่วมกับข้อมูลสดจาก repository ทดลอง และการรักษาเดือนเมื่อข้อมูลเปลี่ยน

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/data/sample_transactions.dart';
import 'package:project_moneymate/main.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/services/demo_transaction_repository.dart';
import 'package:project_moneymate/widgets/expense_chart.dart';
import 'package:project_moneymate/widgets/income_expense_chart.dart';

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  testWidgets(
    'Statistics opens from shared navigation and shows monthly totals',
    (tester) async {
      final repository = DemoTransactionRepository(
        initialTransactions: sampleTransactions,
      );
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        MyApp(repository: repository, referenceMonth: DateTime(2026, 11)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('สถิติ'));
      await tester.pumpAndSettle();
      expect(find.text('สถิติการเงิน'), findsOneWidget);
      expect(find.byKey(const Key('statistics-month')), findsOneWidget);
      expect(find.text('พฤศจิกายน 2026'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('statistics-income'))).data,
        '฿12,000.00',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('statistics-expense'))).data,
        '฿3,500.00',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('statistics-net'))).data,
        '฿8,500.00',
      );
      expect(find.text('3 รายการในเดือนนี้'), findsOneWidget);
      await tester.tap(find.text('หน้าหลัก'));
      await tester.pumpAndSettle();
      expect(find.text('฿8,500.00'), findsOneWidget);
    },
  );

  testWidgets(
    'selected month survives live additions, edits and deleting its last records',
    (tester) async {
      final october = MoneyTransaction(
        id: 'october',
        title: 'อาหารเดือนตุลาคม',
        amountSatang: 1000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime(2026, 10, 15),
      );
      final lastYear = MoneyTransaction(
        id: 'last-year',
        title: 'ปีก่อน',
        amountSatang: 999999,
        type: TransactionType.expense,
        category: TransactionCategory.housing,
        date: DateTime(2025, 11, 15),
      );
      final repository = DemoTransactionRepository(
        initialTransactions: [...sampleTransactions, october, lastYear],
      );
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        MyApp(repository: repository, referenceMonth: DateTime(2026, 11)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('สถิติ'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('statistics-expense'))).data,
        '฿3,500.00',
      );
      await tester.tap(find.byTooltip('เดือนก่อนหน้า'));
      await tester.pumpAndSettle();
      expect(find.text('ตุลาคม 2026'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('statistics-expense'))).data,
        '฿10.00',
      );
      final added = MoneyTransaction(
        id: 'october-income',
        title: 'รายรับตุลาคม',
        amountSatang: 2000,
        type: TransactionType.income,
        category: TransactionCategory.other,
        date: DateTime(2026, 10, 16),
      );
      // เปลี่ยน repository โดยตรงเพื่อจำลอง stream สด แล้วตรวจทั้งตัวเลขและข้อมูลกราฟ
      await repository.saveTransaction(added);
      await tester.pumpAndSettle();
      expect(find.text('ตุลาคม 2026'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('statistics-net'))).data,
        '฿10.00',
      );
      expect(
        tester
            .widget<IncomeExpenseChart>(find.byType(IncomeExpenseChart))
            .incomeSatang,
        2000,
      );
      await repository.updateTransaction(
        MoneyTransaction(
          id: october.id,
          title: october.title,
          amountSatang: 1001,
          type: october.type,
          category: october.category,
          date: october.date,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('statistics-net'))).data,
        '฿9.99',
      );
      expect(
        tester
            .widget<ExpenseChart>(find.byType(ExpenseChart))
            .expensesByCategory,
        {TransactionCategory.food: 1001},
      );
      await repository.deleteTransaction(october.id);
      await repository.deleteTransaction(added.id);
      await tester.pumpAndSettle();
      expect(find.text('ตุลาคม 2026'), findsOneWidget);
      expect(find.text('ยังไม่มีรายการในเดือนนี้'), findsOneWidget);
      expect(
        tester
            .widget<ExpenseChart>(find.byType(ExpenseChart))
            .expensesByCategory,
        isEmpty,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('statistics-net'))).data,
        '฿0.00',
      );
      await tester.tap(find.byKey(const Key('statistics-month')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('พฤศจิกายน 2025').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('statistics-expense'))).data,
        '฿9,999.99',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('add form returns to Statistics with selected month intact', (
    tester,
  ) async {
    final repository = DemoTransactionRepository(
      initialTransactions: sampleTransactions,
    );
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      MyApp(repository: repository, referenceMonth: DateTime(2026, 11)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('สถิติ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('เดือนก่อนหน้า'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('เพิ่มรายการ'));
    await tester.pumpAndSettle();
    expect(find.text('เพิ่มรายการ'), findsWidgets);
    await tester.tap(find.byTooltip('กลับ'));
    await tester.pumpAndSettle();
    expect(find.text('สถิติการเงิน'), findsOneWidget);
    expect(find.text('ตุลาคม 2026'), findsOneWidget);
  });
}
