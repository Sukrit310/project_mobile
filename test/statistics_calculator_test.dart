// ทดสอบสถิติรายเดือน ทั้งขอบเขตปี สตางค์ หมวดหมู่เดิม และการไม่แก้ข้อมูลต้นทาง

import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/models/monthly_statistics.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/utils/statistics_calculator.dart';

/// สร้างรายการที่ปรับประเภทและหมวดได้ รวมข้อมูลเดิมที่ฟอร์มใหม่อาจไม่ได้เสนอ
MoneyTransaction record(
  String id,
  int amountSatang,
  DateTime date, {
  TransactionType type = TransactionType.expense,
  TransactionCategory category = TransactionCategory.other,
}) => MoneyTransaction(
  id: id,
  title: id,
  amountSatang: amountSatang,
  type: type,
  category: category,
  date: date,
);

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  test('selects both year and month including the first and final instant', () {
    final summary = calculateMonthlyStatistics([
      record('previous-year', 500, DateTime(2025, 11, 10)),
      record('previous-month', 600, DateTime(2026, 10, 31, 23, 59, 59, 999)),
      record(
        'first-instant',
        10001,
        DateTime(2026, 11),
        type: TransactionType.income,
      ),
      record(
        'final-instant',
        202,
        DateTime(2026, 11, 30, 23, 59, 59, 999, 999),
      ),
      record('next-month', 700, DateTime(2026, 12)),
      record('next-year', 800, DateTime(2027, 11, 10)),
    ], DateTime(2026, 11, 19, 12, 34));

    expect(summary.month, DateTime(2026, 11));
    expect(summary.incomeSatang, 10001);
    expect(summary.expenseSatang, 202);
    expect(summary.netSatang, 9799);
    expect(summary.transactionCount, 2);
    expect(summary.expensesByCategory, {TransactionCategory.other: 202});
  });

  test('December and January remain separate across the year boundary', () {
    final transactions = [
      record('december', 105, DateTime(2026, 12, 31, 23, 59)),
      record('january', 206, DateTime(2027, 1, 1)),
    ];

    final december = calculateMonthlyStatistics(
      transactions,
      DateTime(2026, 12),
    );
    final january = calculateMonthlyStatistics(transactions, DateTime(2027, 1));

    expect(december.expenseSatang, 105);
    expect(december.transactionCount, 1);
    expect(january.expenseSatang, 206);
    expect(january.transactionCount, 1);
  });

  test('adds exact integer satang and counts zero amount records', () {
    final summary = calculateMonthlyStatistics([
      record('one-satang', 1, DateTime(2026, 11)),
      record('ten-satang', 10, DateTime(2026, 11)),
      record('twenty-satang', 20, DateTime(2026, 11)),
      record('zero', 0, DateTime(2026, 11)),
      record('income', 30, DateTime(2026, 11), type: TransactionType.income),
    ], DateTime(2026, 11));

    expect(summary.incomeSatang, 30);
    expect(summary.expenseSatang, 31);
    expect(summary.netSatang, -1);
    expect(summary.transactionCount, 5);
    expect(summary.expensesByCategory, {TransactionCategory.other: 31});
  });

  test('groups every expense category including legacy salary expenses', () {
    final summary = calculateMonthlyStatistics([
      record(
        'food',
        101,
        DateTime(2026, 11),
        category: TransactionCategory.food,
      ),
      record(
        'salary-expense',
        202,
        DateTime(2026, 11),
        category: TransactionCategory.salary,
      ),
      record(
        'housing',
        303,
        DateTime(2026, 11),
        category: TransactionCategory.housing,
      ),
      record('other', 404, DateTime(2026, 11)),
      record(
        'more-food',
        505,
        DateTime(2026, 11),
        category: TransactionCategory.food,
      ),
      record(
        'legacy-food-income',
        909,
        DateTime(2026, 11),
        type: TransactionType.income,
        category: TransactionCategory.food,
      ),
    ], DateTime(2026, 11));

    expect(summary.expenseSatang, 1515);
    expect(summary.incomeSatang, 909);
    expect(summary.transactionCount, 6);
    expect(summary.expensesByCategory, {
      TransactionCategory.food: 606,
      TransactionCategory.salary: 202,
      TransactionCategory.housing: 303,
      TransactionCategory.other: 404,
    });
  });

  test('empty and income-only months have no category slices', () {
    final empty = calculateMonthlyStatistics(const [], DateTime(2026, 11));
    final incomeOnly = calculateMonthlyStatistics([
      record(
        'zero-expense',
        0,
        DateTime(2026, 11),
        category: TransactionCategory.food,
      ),
      record('outside-month', 999, DateTime(2026, 10)),
      record('income', 12345, DateTime(2026, 11), type: TransactionType.income),
    ], DateTime(2026, 11));

    expect(empty.incomeSatang, 0);
    expect(empty.expenseSatang, 0);
    expect(empty.netSatang, 0);
    expect(empty.transactionCount, 0);
    expect(empty.expensesByCategory, isEmpty);
    expect(incomeOnly.incomeSatang, 12345);
    expect(incomeOnly.expenseSatang, 0);
    expect(incomeOnly.netSatang, 12345);
    expect(incomeOnly.transactionCount, 2);
    expect(incomeOnly.expensesByCategory, isEmpty);
  });

  test('calculation preserves input order, records, and list mutability', () {
    final transactions = [
      record('latest', 123, DateTime(2026, 11, 20)),
      record('outside-month', 456, DateTime(2025, 11)),
      record('earliest', 789, DateTime(2026, 11, 1)),
    ];
    final originalRecords = List<MoneyTransaction>.of(transactions);

    final summary = calculateMonthlyStatistics(
      transactions,
      DateTime(2026, 11),
    );
    final immutableSource = List<MoneyTransaction>.unmodifiable(transactions);
    final immutableResult = calculateMonthlyStatistics(
      immutableSource,
      DateTime(2026, 11),
    );

    expect(summary.expenseSatang, 912);
    expect(immutableResult.expenseSatang, 912);
    expect(transactions, orderedEquals(originalRecords));
    for (var index = 0; index < transactions.length; index++) {
      expect(identical(transactions[index], originalRecords[index]), isTrue);
    }
    transactions.add(record('later-addition', 500, DateTime(2026, 11)));
    expect(summary.expenseSatang, 912);
    expect(summary.transactionCount, 2);
  });

  test(
    'monthly summary normalizes month and owns an immutable category copy',
    () {
      final categories = {TransactionCategory.food: 500};
      final summary = MonthlyStatistics(
        month: DateTime(2026, 11, 19, 16, 45),
        incomeSatang: 1000,
        expenseSatang: 500,
        transactionCount: 2,
        expensesByCategory: categories,
      );

      categories[TransactionCategory.food] = 999;
      categories[TransactionCategory.salary] = 200;

      expect(summary.month, DateTime(2026, 11));
      expect(summary.netSatang, 500);
      expect(summary.expensesByCategory, {TransactionCategory.food: 500});
      expect(
        () => summary.expensesByCategory[TransactionCategory.food] = 1,
        throwsUnsupportedError,
      );
      expect(() => summary.expensesByCategory.clear(), throwsUnsupportedError);
    },
  );
}
