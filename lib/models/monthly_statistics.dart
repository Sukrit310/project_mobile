// ผลรวมของเดือนที่เลือก พร้อมยอดรายจ่ายตามหมวดหมู่สำหรับสร้างกราฟ

import 'money_transaction.dart';

/// เก็บยอดเดือนปฏิทินเป็นสตางค์และหมวดรายจ่ายที่ใช้สร้างกราฟ
/// ปรับเดือนเป็นวันแรกและคัดลอกแผนที่แบบแก้ไขไม่ได้ เพื่อแยกผลลัพธ์จากต้นทาง
class MonthlyStatistics {
  MonthlyStatistics({
    required DateTime month,
    required this.incomeSatang,
    required this.expenseSatang,
    required this.transactionCount,
    required Map<TransactionCategory, int> expensesByCategory,
  }) : month = DateTime(month.year, month.month),
       expensesByCategory = Map.unmodifiable(expensesByCategory);

  final DateTime month;
  final int incomeSatang;
  final int expenseSatang;
  final int transactionCount;
  final Map<TransactionCategory, int> expensesByCategory;

  /// ยอดสุทธิของเดือนติดลบได้เมื่อรายจ่ายมากกว่ารายรับ
  int get netSatang => incomeSatang - expenseSatang;
}
