// รวมรายรับและรายจ่ายจริงเป็นแท่งรายเดือน/สัปดาห์เต็ม โดยคงจำนวนเงินเป็นสตางค์
import '../models/money_transaction.dart';

enum ExpenseTrendPeriod { monthly, weekly }

class ExpenseBarBucket {
  const ExpenseBarBucket({
    required this.date,
    required this.amountSatang,
    this.incomeSatang = 0,
  });

  final DateTime date;
  final int amountSatang;
  final int incomeSatang;

  int get expenseSatang => amountSatang;
}

class ExpenseBarSeries {
  ExpenseBarSeries({
    required this.startDate,
    required this.endDate,
    required List<ExpenseBarBucket> buckets,
  }) : buckets = List.unmodifiable(buckets);

  final DateTime startDate;
  final DateTime endDate;
  final List<ExpenseBarBucket> buckets;

  int get totalSatang =>
      buckets.fold(0, (total, bucket) => total + bucket.amountSatang);

  int get totalExpenseSatang => totalSatang;

  int get totalIncomeSatang =>
      buckets.fold(0, (total, bucket) => total + bucket.incomeSatang);

  bool get hasExpenses => totalSatang > 0;

  bool get hasActivity => hasExpenses || totalIncomeSatang > 0;
}

/// ใช้วันปฏิทินของรายการโดยไม่แปลงเขตเวลาหรือแก้ลิสต์ต้นฉบับ
/// ยอดทั้งหมดเป็น int สตางค์จนถึงขั้นวาดพิกัดกราฟ
ExpenseBarSeries calculateExpenseBarSeries(
  List<MoneyTransaction> transactions, {
  required DateTime month,
  required ExpenseTrendPeriod period,
  DateTime? weekAnchor,
  DateTime? today,
}) {
  final selected = DateTime(month.year, month.month);
  final now = today ?? DateTime.now();
  final isCurrentMonth =
      selected.year == now.year && selected.month == now.month;
  final amountsByDate = <DateTime, int>{};
  final incomeAmountsByDate = <DateTime, int>{};
  for (final transaction in transactions) {
    final date = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    final dailyAmounts = transaction.isIncome
        ? incomeAmountsByDate
        : amountsByDate;
    dailyAmounts.update(
      date,
      (amount) => amount + transaction.amountSatang,
      ifAbsent: () => transaction.amountSatang,
    );
  }

  late final DateTime startDate;
  late final DateTime endDate;
  if (period == ExpenseTrendPeriod.monthly) {
    startDate = selected;
    var lastDay = DateTime(selected.year, selected.month + 1, 0).day;
    if (isCurrentMonth) {
      lastDay = now.day;
      // Keep recorded future-dated income and expenses visible in this month.
      for (final date in amountsByDate.keys.followedBy(
        incomeAmountsByDate.keys,
      )) {
        if (date.year == selected.year &&
            date.month == selected.month &&
            date.day > lastDay) {
          lastDay = date.day;
        }
      }
    }
    endDate = DateTime(selected.year, selected.month, lastDay);
  } else {
    final anchor = weekAnchor ?? (isCurrentMonth ? now : selected);
    startDate = DateTime(
      anchor.year,
      anchor.month,
      anchor.day - (anchor.weekday - DateTime.monday),
    );
    endDate = DateTime(startDate.year, startDate.month, startDate.day + 6);
  }

  final buckets = <ExpenseBarBucket>[];
  for (
    var date = startDate;
    !date.isAfter(endDate);
    date = DateTime(date.year, date.month, date.day + 1)
  ) {
    buckets.add(
      ExpenseBarBucket(
        date: date,
        amountSatang: amountsByDate[date] ?? 0,
        incomeSatang: incomeAmountsByDate[date] ?? 0,
      ),
    );
  }
  return ExpenseBarSeries(
    startDate: startDate,
    endDate: endDate,
    buckets: buckets,
  );
}
