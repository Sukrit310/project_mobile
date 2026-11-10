// ตรวจและแปลงข้อมูลระหว่าง MoneyTransaction กับเอกสาร Firestore

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/money_transaction.dart';
import '../utils/transaction_validation.dart';

/// แปลงเอกสาร Firestore โดยตรวจชนิดข้อมูลก่อนนำไปคำนวณยอด
class TransactionCodec {
  /// ป้องกัน ID ว่างและส่วนของเส้นทางที่ไม่ใช่ชื่อเอกสารหนึ่งรายการ
  static void validateId(String id) {
    if (id.isEmpty || id.contains('/') || id == '.' || id == '..') {
      throw ArgumentError.value(id, 'id');
    }
  }

  /// ตรวจขอบเขตข้อมูลก่อนส่งให้ทั้ง repository จริงและ repository ทดลอง
  static void validate(MoneyTransaction transaction) {
    validateId(transaction.id);
    if (validateTransactionTitle(transaction.title) != null ||
        transaction.amountSatang <= 0 ||
        transaction.amountSatang > maxTransactionSatang) {
      throw ArgumentError('Invalid transaction');
    }
  }

  /// คงจำนวนเงินเป็น int สตางค์ และแปลงวันที่เป็น Timestamp ของ Firestore
  static Map<String, dynamic> encode(MoneyTransaction transaction) {
    validate(transaction);
    return {
      'title': transaction.title.trim(),
      'amountSatang': transaction.amountSatang,
      'type': transaction.type.name,
      'category': transaction.category.name,
      'date': Timestamp.fromDate(transaction.date),
    };
  }

  /// ตรวจชนิดและค่า enum ก่อนสร้างโมเดล หากข้อมูลเสียให้เกิดข้อผิดพลาดแทนยอดผิด
  static MoneyTransaction decode(String id, Map<String, dynamic> data) {
    final title = data['title'];
    final amount = data['amountSatang'];
    final date = data['date'];
    final types = TransactionType.values.where(
      (value) => value.name == data['type'],
    );
    final categories = TransactionCategory.values.where(
      (value) => value.name == data['category'],
    );
    if (title is! String ||
        validateTransactionTitle(title) != null ||
        amount is! int ||
        amount <= 0 ||
        amount > maxTransactionSatang ||
        date is! Timestamp ||
        types.isEmpty ||
        categories.isEmpty) {
      throw const FormatException('Invalid Firestore transaction');
    }
    return MoneyTransaction(
      id: id,
      title: title.trim(),
      amountSatang: amount,
      type: types.single,
      category: categories.single,
      date: date.toDate(),
    );
  }
}
