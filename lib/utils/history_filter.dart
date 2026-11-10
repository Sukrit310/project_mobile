// กรองประวัติตามเดือน ประเภท และชื่อ โดยคืนลิสต์ใหม่เรียงจากล่าสุด

import '../models/money_transaction.dart';

/// เทียบทั้งปีและเดือน รวมตัวกรองประเภทและคำค้นชื่อที่ไม่สนตัวพิมพ์เล็กใหญ่
/// toList สร้างสำเนาก่อน sort จึงไม่เรียงสลับ stream ต้นทางที่หน้าจออื่นใช้ร่วมกัน
List<MoneyTransaction> filterHistoryTransactions(
  List<MoneyTransaction> transactions, {
  DateTime? month,
  TransactionType? type,
  String query = '',
}) {
  final search = query.trim().toLowerCase();
  return transactions.where((transaction) {
    if (month != null &&
        (transaction.date.year != month.year ||
            transaction.date.month != month.month)) {
      return false;
    }
    if (type != null && transaction.type != type) return false;
    return search.isEmpty || transaction.title.toLowerCase().contains(search);
  }).toList()..sort((a, b) => b.date.compareTo(a.date));
}
