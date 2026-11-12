import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/utils/expense_bar_series.dart';

MoneyTransaction _expense(String id, int amountSatang, DateTime date) =>
    MoneyTransaction(
      id: id,
      title: id,
      amountSatang: amountSatang,
      type: TransactionType.expense,
      category: TransactionCategory.food,
      date: date,
    );

MoneyTransaction _income(String id, int amountSatang, DateTime date) =>
    MoneyTransaction(
      id: id,
      title: id,
      amountSatang: amountSatang,
      type: TransactionType.income,
      category: TransactionCategory.salary,
      date: date,
    );

void main() {
  test(
    'empty completed month supplies a zero bucket for every calendar day',
    () {
      final series = calculateExpenseBarSeries(
        [],
        month: DateTime(2024, 2, 12, 18),
        period: ExpenseTrendPeriod.monthly,
        today: DateTime(2026, 11, 12),
      );

      expect(series.startDate, DateTime(2024, 2, 1));
      expect(series.endDate, DateTime(2024, 2, 29));
      expect(series.buckets, hasLength(29));
      expect(series.buckets.first.date, DateTime(2024, 2, 1));
      expect(series.buckets.last.date, DateTime(2024, 2, 29));
      expect(
        series.buckets.map((bucket) => bucket.amountSatang),
        everyElement(0),
      );
      expect(
        series.buckets.map((bucket) => bucket.incomeSatang),
        everyElement(0),
      );
      expect(series.totalSatang, 0);
      expect(series.totalExpenseSatang, 0);
      expect(series.totalIncomeSatang, 0);
      expect(series.hasExpenses, isFalse);
      expect(series.hasActivity, isFalse);
    },
  );

  test(
    'monthly buckets keep income and expense satang separate by calendar day',
    () {
      final series = calculateExpenseBarSeries(
        [
          _expense('first', 101, DateTime(2024, 2, 2, 8)),
          _expense('second', 202, DateTime.utc(2024, 2, 2, 23, 59)),
          _expense('leap-day', 1, DateTime(2024, 2, 29)),
          _expense('other-year', 9900, DateTime(2023, 2, 2)),
          _expense('previous-month', 8800, DateTime(2024, 1, 31)),
          _expense('next-month', 7700, DateTime(2024, 3, 1)),
          _income('income', 70000, DateTime(2024, 2, 2)),
          _income('income-second', 203, DateTime.utc(2024, 2, 2, 23, 59)),
          _income('leap-day-income', 1, DateTime(2024, 2, 29)),
          _income('income-other-year', 9900, DateTime(2023, 2, 2)),
          _income('income-previous-month', 8800, DateTime(2024, 1, 31)),
          _income('income-next-month', 7700, DateTime(2024, 3, 1)),
        ],
        month: DateTime(2024, 2),
        period: ExpenseTrendPeriod.monthly,
        today: DateTime(2026, 11, 12),
      );

      expect(series.buckets[0].amountSatang, 0);
      expect(series.buckets[1].amountSatang, 303);
      expect(series.buckets[1].expenseSatang, 303);
      expect(series.buckets[0].incomeSatang, 0);
      expect(series.buckets[1].incomeSatang, 70203);
      expect(series.buckets[28].amountSatang, 1);
      expect(series.buckets[28].incomeSatang, 1);
      expect(series.totalSatang, 304);
      expect(series.totalExpenseSatang, 304);
      expect(series.totalIncomeSatang, 70204);
      expect(series.hasExpenses, isTrue);
      expect(series.hasActivity, isTrue);
    },
  );

  test('current month includes recorded future income in its cutoff', () {
    final series = calculateExpenseBarSeries(
      [
        _expense('current', 101, DateTime(2026, 11, 2)),
        _income('future-income', 999, DateTime(2026, 11, 29)),
        _expense('next-month', 999, DateTime(2026, 12, 30)),
        _income('next-month-income', 888, DateTime(2026, 12, 31)),
      ],
      month: DateTime(2026, 11),
      period: ExpenseTrendPeriod.monthly,
      today: DateTime(2026, 11, 12, 23, 59),
    );

    expect(series.endDate, DateTime(2026, 11, 29));
    expect(series.buckets, hasLength(29));
    expect(series.totalSatang, 101);
    expect(series.buckets.last.incomeSatang, 999);
    expect(series.totalIncomeSatang, 999);
  });

  test('current month preserves recorded future legacy expenses', () {
    final series = calculateExpenseBarSeries(
      [
        _expense('current', 101, DateTime(2026, 11, 2)),
        _expense('future-legacy', 202, DateTime(2026, 11, 20, 18)),
        _income('future-income', 999, DateTime(2026, 11, 19)),
      ],
      month: DateTime(2026, 11),
      period: ExpenseTrendPeriod.monthly,
      today: DateTime(2026, 11, 12),
    );

    expect(series.endDate, DateTime(2026, 11, 20));
    expect(series.buckets, hasLength(20));
    expect(series.buckets.last.amountSatang, 202);
    expect(series.totalSatang, 303);
    expect(series.totalIncomeSatang, 999);
  });

  test(
    'current month ends today when future activity is outside the month',
    () {
      final series = calculateExpenseBarSeries(
        [
          _expense('current', 101, DateTime(2026, 11, 2)),
          _income('current-income', 202, DateTime(2026, 11, 3)),
          _expense('next-month', 999, DateTime(2026, 12, 30)),
          _income('next-month-income', 888, DateTime(2026, 12, 31)),
          _income('other-year-income', 777, DateTime(2027, 11, 30)),
        ],
        month: DateTime(2026, 11),
        period: ExpenseTrendPeriod.monthly,
        today: DateTime(2026, 11, 12, 23, 59),
      );

      expect(series.endDate, DateTime(2026, 11, 12));
      expect(series.buckets, hasLength(12));
      expect(series.totalSatang, 101);
      expect(series.totalIncomeSatang, 202);
    },
  );

  test('income-only periods have activity without expenses', () {
    for (final period in ExpenseTrendPeriod.values) {
      final series = calculateExpenseBarSeries(
        [_income('income', 101, DateTime(2026, 11, 12))],
        month: DateTime(2026, 11),
        period: period,
        today: DateTime(2026, 11, 12),
      );

      expect(series.totalSatang, 0);
      expect(series.totalExpenseSatang, 0);
      expect(series.totalIncomeSatang, 101);
      expect(series.hasExpenses, isFalse);
      expect(series.hasActivity, isTrue);
      expect(
        series.buckets
            .singleWhere((bucket) => bucket.date.day == 12)
            .incomeSatang,
        101,
      );
    }
  });

  test('future selected month supplies the full calendar month', () {
    final series = calculateExpenseBarSeries(
      [],
      month: DateTime(2027, 1),
      period: ExpenseTrendPeriod.monthly,
      today: DateTime(2026, 11, 12),
    );

    expect(series.startDate, DateTime(2027, 1, 1));
    expect(series.endDate, DateTime(2027, 1, 31));
    expect(series.buckets, hasLength(31));
  });

  test('Sunday anchor keeps the full Monday to Sunday week across a year', () {
    final series = calculateExpenseBarSeries(
      [
        _expense('before-week', 999, DateTime(2024, 12, 29, 23, 59)),
        _expense('monday', 101, DateTime(2024, 12, 30)),
        _expense('wednesday', 202, DateTime(2025, 1, 1, 9)),
        _expense('wednesday-second', 3, DateTime.utc(2025, 1, 1, 23, 59)),
        _expense('sunday', 404, DateTime(2025, 1, 5, 23, 59)),
        _expense('after-week', 999, DateTime(2025, 1, 6)),
        _expense('other-year', 999, DateTime(2024, 1, 1)),
        _income('income-before-week', 999, DateTime(2024, 12, 29, 23, 59)),
        _income('income-monday', 10101, DateTime(2024, 12, 30)),
        _income('income', 999, DateTime(2025, 1, 1)),
        _income('income-second', 2, DateTime.utc(2025, 1, 1, 23, 59)),
        _income('income-sunday', 100, DateTime(2025, 1, 5, 23, 59)),
        _income('income-after-week', 999, DateTime(2025, 1, 6)),
        _income('income-other-year', 999, DateTime(2024, 1, 1)),
      ],
      month: DateTime(2025, 1),
      period: ExpenseTrendPeriod.weekly,
      weekAnchor: DateTime(2025, 1, 5, 20),
      today: DateTime(2025, 1, 2),
    );

    expect(series.startDate, DateTime(2024, 12, 30));
    expect(series.endDate, DateTime(2025, 1, 5));
    expect(series.buckets.map((bucket) => bucket.date), [
      DateTime(2024, 12, 30),
      DateTime(2024, 12, 31),
      DateTime(2025, 1, 1),
      DateTime(2025, 1, 2),
      DateTime(2025, 1, 3),
      DateTime(2025, 1, 4),
      DateTime(2025, 1, 5),
    ]);
    expect(series.buckets.map((bucket) => bucket.amountSatang), [
      101,
      0,
      205,
      0,
      0,
      0,
      404,
    ]);
    expect(series.totalSatang, 710);
    expect(series.buckets.map((bucket) => bucket.incomeSatang), [
      10101,
      0,
      1001,
      0,
      0,
      0,
      100,
    ]);
    expect(series.totalIncomeSatang, 11202);
    expect(series.hasExpenses, isTrue);
  });

  test('Monday anchor includes following month through Sunday', () {
    final series = calculateExpenseBarSeries(
      [
        _expense('monday', 101, DateTime(2026, 11, 30)),
        _expense('next-month', 202, DateTime(2026, 12, 6)),
        _expense('next-week', 999, DateTime(2026, 12, 7)),
        _income('income-monday', 303, DateTime(2026, 11, 30)),
        _income('income-next-month', 404, DateTime(2026, 12, 6)),
        _income('income-next-week', 999, DateTime(2026, 12, 7)),
      ],
      month: DateTime(2026, 11),
      period: ExpenseTrendPeriod.weekly,
      weekAnchor: DateTime(2026, 11, 30),
      today: DateTime(2026, 11, 12),
    );

    expect(series.startDate, DateTime(2026, 11, 30));
    expect(series.endDate, DateTime(2026, 12, 6));
    expect(series.buckets, hasLength(7));
    expect(series.buckets.first.amountSatang, 101);
    expect(series.buckets.last.amountSatang, 202);
    expect(series.totalSatang, 303);
    expect(series.buckets.first.incomeSatang, 303);
    expect(series.buckets.last.incomeSatang, 404);
    expect(series.totalIncomeSatang, 707);
  });

  test('weekly default uses today when the selected month is current', () {
    final series = calculateExpenseBarSeries(
      [],
      month: DateTime(2026, 11),
      period: ExpenseTrendPeriod.weekly,
      today: DateTime(2026, 11, 12, 18),
    );

    expect(series.startDate, DateTime(2026, 11, 9));
    expect(series.endDate, DateTime(2026, 11, 15));
    expect(series.buckets, hasLength(7));
    expect(
      series.buckets.map((bucket) => bucket.amountSatang),
      everyElement(0),
    );
    expect(series.hasExpenses, isFalse);
    expect(series.hasActivity, isFalse);
  });

  test('weekly default uses the selected first day for another month', () {
    final series = calculateExpenseBarSeries(
      [],
      month: DateTime(2026, 5, 29),
      period: ExpenseTrendPeriod.weekly,
      today: DateTime(2026, 11, 12),
    );

    expect(series.startDate, DateTime(2026, 4, 27));
    expect(series.endDate, DateTime(2026, 5, 3));
    expect(series.buckets, hasLength(7));
  });

  test('calculating both periods preserves an immutable input order', () {
    final latest = _expense('latest', 202, DateTime(2026, 11, 12, 18));
    final earliest = _expense('earliest', 101, DateTime(2026, 11, 9, 8));
    final income = _income('income', 1, DateTime(2026, 11, 11, 9));
    final records = List<MoneyTransaction>.unmodifiable([
      latest,
      earliest,
      income,
    ]);

    for (final period in ExpenseTrendPeriod.values) {
      final series = calculateExpenseBarSeries(
        records,
        month: DateTime(2026, 11),
        period: period,
        today: DateTime(2026, 11, 12),
      );

      expect(series.totalSatang, 303);
      expect(series.totalIncomeSatang, 1);
      expect(records, [same(latest), same(earliest), same(income)]);
      expect(
        () => series.buckets.add(
          ExpenseBarBucket(date: DateTime(2026, 11, 13), amountSatang: 999),
        ),
        throwsUnsupportedError,
      );
    }
  });

  test('recalculating income edits and deletes updates both periods', () {
    for (final period in ExpenseTrendPeriod.values) {
      final expense = _expense('expense', 303, DateTime(2026, 11, 12));
      final beforeEdit = calculateExpenseBarSeries(
        [expense, _income('income', 101, DateTime(2026, 11, 11))],
        month: DateTime(2026, 11),
        period: period,
        today: DateTime(2026, 11, 12),
      );
      final afterEdit = calculateExpenseBarSeries(
        [expense, _income('income', 202, DateTime(2026, 11, 12))],
        month: DateTime(2026, 11),
        period: period,
        today: DateTime(2026, 11, 12),
      );
      final afterDelete = calculateExpenseBarSeries(
        [expense],
        month: DateTime(2026, 11),
        period: period,
        today: DateTime(2026, 11, 12),
      );

      expect(beforeEdit.totalIncomeSatang, 101);
      expect(afterEdit.totalIncomeSatang, 202);
      expect(
        afterEdit.buckets
            .singleWhere((bucket) => bucket.date.day == 11)
            .incomeSatang,
        0,
      );
      expect(
        afterEdit.buckets
            .singleWhere((bucket) => bucket.date.day == 12)
            .incomeSatang,
        202,
      );
      expect(afterDelete.totalIncomeSatang, 0);
      expect(
        afterDelete.buckets.map((bucket) => bucket.incomeSatang),
        everyElement(0),
      );
      expect(beforeEdit.totalSatang, 303);
      expect(afterEdit.totalSatang, 303);
      expect(afterDelete.totalSatang, 303);
    }
  });
}
