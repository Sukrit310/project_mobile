import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/utils/finance_insights.dart';

MoneyTransaction record(
  String id,
  int amount,
  TransactionCategory category,
  DateTime date, {
  TransactionType type = TransactionType.expense,
}) => MoneyTransaction(
  id: id,
  title: id,
  amountSatang: amount,
  type: type,
  category: category,
  date: date,
);

void main() {
  final month = DateTime(2026, 11);
  test(
    'income, empty records and other months cannot invent expense insights',
    () {
      expect(monthlyExpenseInsight([], month: month), isNull);
      expect(
        monthlyExpenseInsight([
          record(
            'income',
            999999,
            TransactionCategory.salary,
            month,
            type: TransactionType.income,
          ),
          record('old', 999999, TransactionCategory.food, DateTime(2025, 11)),
          record('next', 999999, TransactionCategory.food, DateTime(2026, 12)),
        ], month: month),
        isNull,
      );
    },
  );
  test(
    'top expense category uses exact satang and selected year and month',
    () {
      final insight = monthlyExpenseInsight([
        record('food1', 99999999999, TransactionCategory.food, month),
        record('food2', 1, TransactionCategory.food, month),
        record('housing', 99999999999, TransactionCategory.housing, month),
        record(
          'other month',
          99999999999,
          TransactionCategory.housing,
          DateTime(2026, 10),
        ),
      ], month: month)!;
      expect(insight.category, TransactionCategory.food);
      expect(insight.categorySatang, 100000000000);
      expect(insight.totalSatang, 199999999999);
      expect(insight.isTied, isFalse);
    },
  );
  test('ties are explicit and remain deterministic when records reorder', () {
    final records = [
      record('housing', 10001, TransactionCategory.housing, month),
      record('food', 10001, TransactionCategory.food, month),
    ];
    final first = monthlyExpenseInsight(records, month: month)!;
    final second = monthlyExpenseInsight(
      records.reversed.toList(),
      month: month,
    )!;
    expect(first.isTied, isTrue);
    expect(first.category, second.category);
  });
}
