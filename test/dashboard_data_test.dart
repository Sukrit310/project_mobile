// ทดสอบยอดสรุปหน้าหลัก การเรียงรายการล่าสุด และรูปแบบเงินบาทที่รักษาสตางค์

import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/utils/money_format.dart';

/// สร้างข้อมูลขนาดเล็กที่กำหนดเงิน ประเภท และวันได้ชัดเจนในแต่ละกรณี
MoneyTransaction transaction(
  String id,
  int satang,
  TransactionType type,
  DateTime date,
) => MoneyTransaction(
  id: id,
  title: id,
  amountSatang: satang,
  type: type,
  category: TransactionCategory.other,
  date: date,
);

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  test(
    'monthly totals filter both year and month; balance includes all records',
    () {
      final summary = DashboardSummary.fromTransactions([
        transaction(
          'salary',
          1200000,
          TransactionType.income,
          DateTime(2026, 11, 1),
        ),
        transaction(
          'food',
          8000,
          TransactionType.expense,
          DateTime(2026, 11, 8),
        ),
        transaction(
          'rent',
          342000,
          TransactionType.expense,
          DateTime(2026, 11, 1),
        ),
        transaction(
          'october',
          50000,
          TransactionType.income,
          DateTime(2026, 10, 31),
        ),
        transaction(
          'last-year',
          20000,
          TransactionType.expense,
          DateTime(2025, 11, 1),
        ),
        transaction(
          'december',
          10000,
          TransactionType.expense,
          DateTime(2026, 12, 1),
        ),
      ], month: DateTime(2026, 11));

      expect(summary.incomeSatang, 1200000);
      expect(summary.expenseSatang, 350000);
      expect(summary.balanceSatang, 870000);
    },
  );

  test(
    'recent transactions are sorted newest first without changing input',
    () {
      final records = [
        transaction(
          'old',
          10000,
          TransactionType.expense,
          DateTime(2026, 11, 1, 8),
        ),
        transaction(
          'newest',
          1000,
          TransactionType.expense,
          DateTime(2026, 11, 8),
        ),
        transaction(
          'salary',
          1200000,
          TransactionType.income,
          DateTime(2026, 11, 1, 9),
        ),
      ];
      final summary = DashboardSummary.fromTransactions(
        records,
        month: DateTime(2026, 11),
      );

      expect(summary.recentTransactions.map((entry) => entry.id), [
        'newest',
        'salary',
        'old',
      ]);
      expect(records.map((entry) => entry.id), ['old', 'newest', 'salary']);
    },
  );

  test('empty records produce zero totals and no recent transactions', () {
    final summary = DashboardSummary.fromTransactions(
      [],
      month: DateTime(2026, 11),
    );
    expect(summary.incomeSatang, 0);
    expect(summary.expenseSatang, 0);
    expect(summary.balanceSatang, 0);
    expect(summary.recentTransactions, isEmpty);
  });

  test('expense-only records produce a negative balance with exact satang', () {
    final summary = DashboardSummary.fromTransactions([
      transaction(
        'expense',
        10005,
        TransactionType.expense,
        DateTime(2026, 11, 1),
      ),
    ], month: DateTime(2026, 11));
    expect(summary.balanceSatang, -10005);
    expect(formatBaht(summary.balanceSatang, decimalPlaces: true), '-฿100.05');
  });

  test('baht formatting groups thousands and preserves signs and satang', () {
    expect(formatBaht(850000, decimalPlaces: true), '฿8,500.00');
    expect(formatBaht(1200000, showPlus: true), '+฿12,000');
    expect(formatBaht(-350000), '-฿3,500');
    expect(formatBaht(105), '฿1.05');
    expect(formatBaht(-5), '-฿0.05');
    expect(formatBaht(0, showPlus: true), '฿0');
  });
}
