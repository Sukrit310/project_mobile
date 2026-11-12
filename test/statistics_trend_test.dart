import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/utils/statistics_trend.dart';

MoneyTransaction _expense(String id, int amountSatang, DateTime date) =>
    MoneyTransaction(
      id: id,
      title: id,
      amountSatang: amountSatang,
      type: TransactionType.expense,
      category: TransactionCategory.food,
      date: date,
    );

void main() {
  test('daily trend preserves satang and excludes income and other years', () {
    final records = [
      _expense('first', 101, DateTime(2024, 2, 2, 8)),
      _expense('second', 202, DateTime(2024, 2, 2, 23)),
      _expense('leap-day', 1, DateTime(2024, 2, 29)),
      _expense('other-year', 9900, DateTime(2023, 2, 2)),
      _expense('other-month', 8800, DateTime(2024, 3, 2)),
      MoneyTransaction(
        id: 'income',
        title: 'income',
        amountSatang: 70000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: DateTime(2024, 2, 2),
      ),
    ];
    final originalOrder = records.map((record) => record.id).toList();

    final trend = calculateExpenseTrend(
      records,
      DateTime(2024, 2),
      today: DateTime(2024, 4, 1),
    );

    expect(trend.dailyExpenseSatang, hasLength(29));
    expect(trend.dailyExpenseSatang[0], 0);
    expect(trend.dailyExpenseSatang[1], 303);
    expect(trend.dailyExpenseSatang[28], 1);
    expect(trend.totalExpenseSatang, 304);
    expect(trend.expenseCount, 3);
    expect(records.map((record) => record.id), originalOrder);
  });

  test(
    'completed month compares against the immediately previous year month',
    () {
      final trend = calculateExpenseTrend(
        [
          _expense('jan', 15005, DateTime(2026, 1, 10)),
          _expense('dec', 10000, DateTime(2025, 12, 31)),
          _expense('old-dec', 999999, DateTime(2024, 12, 31)),
        ],
        DateTime(2026, 1),
        today: DateTime(2026, 2, 1),
      );

      expect(trend.previousExpenseSatang, 10000);
      expect(trend.changePercent, closeTo(50.05, 0.000001));
    },
  );

  test(
    'missing expense base and incomplete months do not invent a comparison',
    () {
      final records = [
        _expense('previous', 10000, DateTime(2026, 10, 1)),
        _expense('current', 5000, DateTime(2026, 11, 1)),
      ];
      expect(
        calculateExpenseTrend(
          records,
          DateTime(2026, 11),
          today: DateTime(2026, 11, 12),
        ).changePercent,
        isNull,
      );
      expect(
        calculateExpenseTrend(
          [_expense('only-current', 5000, DateTime(2026, 10, 1))],
          DateTime(2026, 10),
          today: DateTime(2026, 11, 12),
        ).changePercent,
        isNull,
      );
      expect(
        calculateExpenseTrend(
          [_expense('only-previous', 5000, DateTime(2026, 9, 1))],
          DateTime(2026, 10),
          today: DateTime(2026, 11, 12),
        ).changePercent,
        isNull,
      );
    },
  );

  test('edits and deletes recalculate days and an empty month stays zero', () {
    final original = _expense('original', 199, DateTime(2026, 10, 2));
    final edited = _expense('original', 299, DateTime(2026, 10, 3));
    final initial = calculateExpenseTrend([original], DateTime(2026, 10));
    final updated = calculateExpenseTrend([edited], DateTime(2026, 10));
    final empty = calculateExpenseTrend([], DateTime(2026, 10));

    expect(initial.dailyExpenseSatang[1], 199);
    expect(updated.dailyExpenseSatang[1], 0);
    expect(updated.dailyExpenseSatang[2], 299);
    expect(empty.dailyExpenseSatang, List.filled(31, 0));
    expect(empty.totalExpenseSatang, 0);
    expect(empty.expenseCount, 0);
    expect(empty.changePercent, isNull);
  });

  test(
    'current chart stops today without hiding recorded future legacy data',
    () {
      final current = calculateExpenseTrend(
        [_expense('current', 100, DateTime(2026, 11, 1))],
        DateTime(2026, 11),
        today: DateTime(2026, 11, 12),
      );
      final legacy = calculateExpenseTrend(
        [_expense('future-legacy', 100, DateTime(2026, 11, 20))],
        DateTime(2026, 11),
        today: DateTime(2026, 11, 12),
      );
      final completed = calculateExpenseTrend(
        [],
        DateTime(2024, 2),
        today: DateTime(2026, 11, 12),
      );
      expect(current.displayDayCount, 12);
      expect(legacy.displayDayCount, 20);
      expect(completed.displayDayCount, 29);
    },
  );
}
