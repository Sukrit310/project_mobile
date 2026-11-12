// รวมรายจ่ายตามวันด้วย int สตางค์ และเปรียบเทียบเฉพาะเดือนที่สิ้นสุดแล้ว

import '../models/money_transaction.dart';

/// ทุกวันของเดือนมีช่องของตัวเอง รวมวันที่ยังไม่มีรายจ่ายเป็นศูนย์
class ExpenseTrend {
  ExpenseTrend({
    required this.month,
    required List<int> dailyExpenseSatang,
    required this.expenseCount,
    required this.previousExpenseSatang,
    required this.isCompleteMonth,
    required this.displayDayCount,
  }) : dailyExpenseSatang = List.unmodifiable(dailyExpenseSatang);

  final DateTime month;
  final List<int> dailyExpenseSatang;
  final int expenseCount;
  final int previousExpenseSatang;
  final bool isCompleteMonth;
  final int displayDayCount;

  int get totalExpenseSatang =>
      dailyExpenseSatang.fold(0, (total, amount) => total + amount);

  /// ไม่เปรียบเทียบเดือนที่ยังไม่ครบ หรือไม่มีรายจ่าย/ฐานของเดือนก่อน
  double? get changePercent {
    if (!isCompleteMonth || expenseCount == 0 || previousExpenseSatang == 0) {
      return null;
    }
    return (totalExpenseSatang - previousExpenseSatang) /
        previousExpenseSatang *
        100;
  }
}

/// เลือกด้วยปีและเดือนปฏิทินเดิมของรายการ โดยไม่แก้ไขหรือเรียงต้นฉบับ
ExpenseTrend calculateExpenseTrend(
  List<MoneyTransaction> transactions,
  DateTime month, {
  DateTime? today,
}) {
  final selected = DateTime(month.year, month.month);
  final previous = DateTime(month.year, month.month - 1);
  final daily = List<int>.filled(
    DateTime(month.year, month.month + 1, 0).day,
    0,
  );
  var expenseCount = 0;
  var previousExpenseSatang = 0;
  var latestExpenseDay = 0;
  for (final transaction in transactions) {
    if (transaction.isIncome) continue;
    final date = transaction.date;
    if (date.year == selected.year && date.month == selected.month) {
      daily[date.day - 1] += transaction.amountSatang;
      expenseCount++;
      if (date.day > latestExpenseDay) latestExpenseDay = date.day;
    } else if (date.year == previous.year && date.month == previous.month) {
      previousExpenseSatang += transaction.amountSatang;
    }
  }
  final now = today ?? DateTime.now();
  // เดือนปัจจุบันไม่ลากเส้นศูนย์ไปยังวันที่ยังไม่ถึง แต่คงรายการอนาคตเดิมไว้
  final isCurrentMonth =
      selected.year == now.year && selected.month == now.month;
  final displayDayCount = isCurrentMonth
      ? (latestExpenseDay > now.day ? latestExpenseDay : now.day)
      : daily.length;
  return ExpenseTrend(
    month: selected,
    dailyExpenseSatang: daily,
    expenseCount: expenseCount,
    previousExpenseSatang: previousExpenseSatang,
    isCompleteMonth: selected.isBefore(DateTime(now.year, now.month)),
    displayDayCount: displayDayCount,
  );
}
