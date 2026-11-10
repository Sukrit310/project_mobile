// รวมสถิติของเดือนปฏิทินที่เลือกจากรายการ โดยไม่แก้ไขข้อมูลต้นทาง

import '../models/monthly_statistics.dart';
import '../models/money_transaction.dart';

/// รวมเฉพาะปีและเดือนตรงกันด้วย int สตางค์ โดยไม่เรียงหรือแก้ลิสต์ต้นทาง
MonthlyStatistics calculateMonthlyStatistics(
  List<MoneyTransaction> transactions,
  DateTime month,
) {
  var incomeSatang = 0;
  var expenseSatang = 0;
  var transactionCount = 0;
  final expensesByCategory = <TransactionCategory, int>{};

  for (final transaction in transactions) {
    if (transaction.date.year != month.year ||
        transaction.date.month != month.month) {
      continue;
    }

    transactionCount++;
    if (transaction.isIncome) {
      incomeSatang += transaction.amountSatang;
    } else {
      expenseSatang += transaction.amountSatang;
      // เก็บเฉพาะหมวดที่มียอดบวกสำหรับกราฟ แต่จำนวนรายการนับรวมยอดศูนย์ด้วย
      if (transaction.amountSatang > 0) {
        expensesByCategory.update(
          transaction.category,
          (amount) => amount + transaction.amountSatang,
          ifAbsent: () => transaction.amountSatang,
        );
      }
    }
  }

  return MonthlyStatistics(
    month: month,
    incomeSatang: incomeSatang,
    expenseSatang: expenseSatang,
    transactionCount: transactionCount,
    expensesByCategory: expensesByCategory,
  );
}
