// กำหนดตัวเลือกหมวดหมู่ตามประเภทรายการ และชื่อภาษาไทยที่แสดงบนหน้าจอ

import '../models/money_transaction.dart';

/// ตัวเลือกสำหรับรายการใหม่: รายรับและรายจ่ายมีหมวดหมู่เริ่มต้นต่างกัน
List<TransactionCategory> categoriesForType(TransactionType type) =>
    switch (type) {
      TransactionType.income => const [
        TransactionCategory.salary,
        TransactionCategory.other,
      ],
      TransactionType.expense => const [
        TransactionCategory.food,
        TransactionCategory.housing,
        TransactionCategory.other,
      ],
    };

/// แยกชื่อที่แสดงออกจากค่า enum เพื่อไม่ผูกข้อมูลที่บันทึกกับข้อความบน UI
String transactionCategoryLabel(TransactionCategory category) =>
    switch (category) {
      TransactionCategory.food => 'อาหาร',
      TransactionCategory.salary => 'เงินเดือน',
      TransactionCategory.housing => 'ที่อยู่อาศัย',
      TransactionCategory.other => 'อื่น ๆ',
    };
