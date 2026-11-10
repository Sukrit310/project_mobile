// ตรวจรูปแบบเอกสารงบก่อนส่งเข้า UI และสร้าง payload ตามกติกา Firestore
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/budget_model.dart';

/// ป้องกันข้อมูลผิดเดือน ผิดชนิด หรือวงเงินที่ไม่ใช่จำนวนเต็มสตางค์
class BudgetCodec {
  static final _monthPattern = RegExp(r'^[0-9]{4}-(0[1-9]|1[0-2])$');
  static const _fields = {'monthKey', 'limitSatang', 'updatedAt'};

  static Map<String, dynamic> encode(BudgetModel budget) => {
    'monthKey': budget.monthKey,
    'limitSatang': budget.limitSatang,
    // เวลาจากเซิร์ฟเวอร์ไม่ขึ้นกับนาฬิกาของอุปกรณ์ที่ผู้ใช้แก้ไขได้
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static BudgetModel decode(
    String id,
    Map<String, dynamic> data, {
    bool hasPendingWrites = false,
  }) {
    final amount = data['limitSatang'];
    final updatedAt = data['updatedAt'];
    if (id.length != 7 ||
        !_monthPattern.hasMatch(id) ||
        id.startsWith('0000-') ||
        data.length != _fields.length ||
        !_fields.every(data.containsKey) ||
        data['monthKey'] != id ||
        amount is! int ||
        amount < 0 ||
        amount > BudgetModel.maxLimitSatang ||
        (updatedAt is! Timestamp && !(hasPendingWrites && updatedAt == null))) {
      throw const FormatException('Invalid Firestore budget');
    }

    // ตรวจเดือนด้วยรูปแบบก่อนสร้าง DateTime เพื่อไม่ให้เดือน 13 ล้นไปปีถัดไป
    return BudgetModel(
      month: DateTime(
        int.parse(id.substring(0, 4)),
        int.parse(id.substring(5)),
      ),
      limitSatang: amount,
    );
  }
}
