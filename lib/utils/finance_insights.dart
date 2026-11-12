// สรุปรายจ่ายจากข้อมูลจริง โดยรักษาหน่วยสตางค์ตลอดการรวมยอด
import '../models/money_transaction.dart';

class MonthlyExpenseInsight {
  const MonthlyExpenseInsight({
    required this.category,
    required this.categorySatang,
    required this.totalSatang,
    required this.isTied,
  });

  final TransactionCategory category;
  final int categorySatang;
  final int totalSatang;
  final bool isTied;
}

/// ไม่สร้างข้อสรุปเมื่อไม่มีรายจ่ายในเดือน/ปีที่เลือก และระบุกรณีหมวดสูงสุดเท่ากัน
MonthlyExpenseInsight? monthlyExpenseInsight(
  List<MoneyTransaction> transactions, {
  required DateTime month,
}) {
  final totals = <TransactionCategory, int>{};
  var total = 0;
  for (final transaction in transactions) {
    if (transaction.isIncome ||
        transaction.amountSatang == 0 ||
        transaction.date.year != month.year ||
        transaction.date.month != month.month) {
      continue;
    }
    totals.update(
      transaction.category,
      (amount) => amount + transaction.amountSatang,
      ifAbsent: () => transaction.amountSatang,
    );
    total += transaction.amountSatang;
  }
  if (totals.isEmpty) return null;
  // ใช้ลำดับหมวดคงที่เมื่อยอดเท่ากัน ไม่ให้ข้อความเปลี่ยนตามลำดับ stream
  final ranked = totals.entries.toList()
    ..sort((a, b) {
      final amount = b.value.compareTo(a.value);
      return amount != 0 ? amount : a.key.index.compareTo(b.key.index);
    });
  return MonthlyExpenseInsight(
    category: ranked.first.key,
    categorySatang: ranked.first.value,
    totalSatang: total,
    isTied: ranked.length > 1 && ranked[1].value == ranked.first.value,
  );
}
