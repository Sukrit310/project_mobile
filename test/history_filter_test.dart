// ทดสอบการกรองและเรียงประวัติ โดยยืนยันว่าลิสต์รายการต้นทางไม่ถูกแก้ไข

import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/utils/history_filter.dart';

/// สร้างรายการสำหรับแยกเงื่อนไขวัน ประเภท และคำค้นโดยไม่ต้องใช้หน้าจอ
MoneyTransaction record(
  String id,
  DateTime date, {
  String title = 'Coffee',
  TransactionType type = TransactionType.expense,
}) => MoneyTransaction(
  id: id,
  title: title,
  amountSatang: 8005,
  type: type,
  category: TransactionCategory.other,
  date: date,
);

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  test('month filter compares year and sorts a new list newest first', () {
    final input = [
      record('early', DateTime(2026, 11, 1)),
      record('last-year', DateTime(2025, 11, 30)),
      record('late', DateTime(2026, 11, 30)),
      record('next-month', DateTime(2026, 12, 1)),
    ];

    final result = filterHistoryTransactions(input, month: DateTime(2026, 11));

    expect(result.map((item) => item.id), ['late', 'early']);
    expect(input.map((item) => item.id), [
      'early',
      'last-year',
      'late',
      'next-month',
    ]);
    expect(identical(result, input), isFalse);
  });

  test(
    'all-months combines type and trimmed case-insensitive title search',
    () {
      final input = [
        record('expense', DateTime(2026, 11), title: 'COFFEE beans'),
        record(
          'income',
          DateTime(2025, 1),
          title: 'Coffee refund',
          type: TransactionType.income,
        ),
        record(
          'other',
          DateTime(2026, 11),
          title: 'Salary',
          type: TransactionType.income,
        ),
      ];

      expect(
        filterHistoryTransactions(
          input,
          type: TransactionType.income,
          query: '  coFFee  ',
        ).map((item) => item.id),
        ['income'],
      );
      expect(filterHistoryTransactions(input, query: '   '), hasLength(3));
      expect(filterHistoryTransactions(input, query: 'not found'), isEmpty);
    },
  );

  test(
    'an unmodifiable source is safe and empty input returns an empty copy',
    () {
      final input = List<MoneyTransaction>.unmodifiable([
        record('a', DateTime(2026, 11)),
        record('b', DateTime(2026, 12)),
      ]);

      expect(filterHistoryTransactions(input).map((item) => item.id), [
        'b',
        'a',
      ]);
      expect(filterHistoryTransactions(const []), isEmpty);
    },
  );
}
