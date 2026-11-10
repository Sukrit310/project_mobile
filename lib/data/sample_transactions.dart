// รายการและเดือนอ้างอิงสำหรับโหมดตัวอย่าง โดยไม่เขียนข้อมูลเหล่านี้ขึ้นคลาวด์

import '../models/money_transaction.dart';

// ตรึงเดือนของข้อมูลตัวอย่างให้ตรงกับภาพ แม้เปิดแอปในเดือนอื่น
final sampleReferenceMonth = DateTime(2026, 11);

/// ลิสต์แก้ไขไม่ได้ เพื่อไม่ให้การทดลองหน้าจอเปลี่ยนข้อมูลตั้งต้นส่วนกลาง
final sampleTransactions = List<MoneyTransaction>.unmodifiable([
  MoneyTransaction(
    id: 'food-2026-11-08',
    title: 'ค่าอาหาร',
    amountSatang: 8000,
    type: TransactionType.expense,
    category: TransactionCategory.food,
    date: DateTime(2026, 11, 8, 12),
  ),
  MoneyTransaction(
    id: 'salary-2026-11-01',
    title: 'เงินเดือน',
    amountSatang: 1200000,
    type: TransactionType.income,
    category: TransactionCategory.salary,
    date: DateTime(2026, 11, 1, 9),
  ),
  // รายการเก่าช่วยให้รายจ่ายรวมเป็น 3,500 และยอดสุทธิเป็น 8,500 บาท
  MoneyTransaction(
    id: 'housing-2026-11-01',
    title: 'ค่าที่พัก',
    amountSatang: 342000,
    type: TransactionType.expense,
    category: TransactionCategory.housing,
    date: DateTime(2026, 11, 1, 8),
  ),
]);
