// สัญญากลางของแหล่งข้อมูลรายการ ช่วยให้หน้าจอสลับใช้ข้อมูลจริงหรือข้อมูลทดลองได้

import '../models/money_transaction.dart';

/// แจ้งว่ารายการที่กำลังแก้ถูกลบไปแล้ว จึงไม่ควรสร้างกลับขึ้นมาเอง
class TransactionNotFoundException implements Exception {
  const TransactionNotFoundException();
}

/// ภาพข้อมูลหนึ่งรอบจาก stream พร้อมสถานะการซิงก์สำหรับข้อความบนหน้าจอ
/// คัดลอกเป็นลิสต์แก้ไขไม่ได้ เพื่อให้ผู้รับแต่ละหน้าดูข้อมูลชุดเดียวกันอย่างปลอดภัย
class TransactionFeed {
  TransactionFeed({
    required List<MoneyTransaction> transactions,
    this.isFromCache = false,
    this.hasPendingWrites = false,
  }) : transactions = List.unmodifiable(transactions);

  final List<MoneyTransaction> transactions;

  /// true เมื่อภาพนี้มาจากแคชในเครื่อง ยังอาจไม่ใช่ข้อมูลล่าสุดบนคลาวด์
  final bool isFromCache;

  /// true เมื่อมีการเขียนในเครื่องที่ยังรอการตอบรับจาก Firestore
  final bool hasPendingWrites;
}

/// หน้าจอรู้เพียงสัญญานี้ จึงใช้แหล่งข้อมูลทดลองในการทดสอบแทนเครือข่ายจริงได้
abstract class TransactionRepository {
  /// ฟังภาพข้อมูลใหม่ต่อเนื่อง แทนการอ่านเองซ้ำในแต่ละหน้า
  Stream<TransactionFeed> watchTransactions();

  /// สร้าง ID หนึ่งครั้งก่อนเปิดฟอร์ม เพื่อรองรับการลองบันทึกซ้ำ
  String newTransactionId();

  /// บันทึกรายการด้วย ID ที่ผู้เรียกกำหนดไว้แล้ว
  Future<void> saveTransaction(MoneyTransaction transaction);

  /// แก้รายการที่มีอยู่ หรือแจ้ง TransactionNotFoundException หากหาไม่พบ
  Future<void> updateTransaction(MoneyTransaction transaction);

  /// ลบตาม ID โดยผู้เรียกต้องรอผลก่อนแสดงว่าดำเนินการสำเร็จ
  Future<void> deleteTransaction(String id);
}
