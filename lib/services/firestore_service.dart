// อ่านและเขียนรายการใน Firestore ใต้ผู้ใช้ปัจจุบัน พร้อมสถานะแคชและการรอยืนยัน

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/money_transaction.dart';
import 'transaction_codec.dart';
import 'transaction_repository.dart';

/// แยกรายการด้วยเส้นทาง users/{uid}/transactions ของผู้ใช้ที่ลงชื่อเข้า
class FirestoreService implements TransactionRepository {
  FirestoreService({required this.firestore, required String userId})
    : _userId = userId {
    if (userId.trim().isEmpty || userId.contains('/')) {
      throw ArgumentError.value(userId, 'userId');
    }
  }

  final FirebaseFirestore firestore;
  final String _userId;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('users').doc(_userId).collection('transactions');

  @override
  /// จอง ID โดยยังไม่เขียนเอกสาร ให้ฟอร์มคง ID เดิมตลอดการลองบันทึก
  String newTransactionId() => _collection.doc().id;

  @override
  /// ฟังรายการล่าสุดพร้อม metadata เพื่อแยกข้อมูลแคชและข้อมูลที่ยังรอคลาวด์ยืนยัน
  Stream<TransactionFeed> watchTransactions() => _collection
      .orderBy('date', descending: true)
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => TransactionFeed(
          transactions: snapshot.docs
              .map((doc) => TransactionCodec.decode(doc.id, doc.data()))
              .toList(),
          isFromCache: snapshot.metadata.isFromCache,
          hasPendingWrites: snapshot.metadata.hasPendingWrites,
        ),
      );

  @override
  /// เขียนทับเอกสาร ID เดิมได้; timeout หมายถึงยังยืนยันผลไม่ได้ ไม่ได้ยืนยันว่าล้มเหลว
  Future<void> saveTransaction(MoneyTransaction transaction) async {
    final data = TransactionCodec.encode(transaction);
    // ใช้ ID เดิมเมื่อกดลองอีกครั้ง จึงไม่สร้างเอกสารซ้ำหากการตอบกลับล่าช้า
    await _collection
        .doc(transaction.id)
        .set(data)
        .timeout(const Duration(seconds: 15));
  }

  @override
  /// แก้เอกสารเดิม และแปลงกรณีถูกลบแล้วเป็นข้อผิดพลาดที่ฟอร์มเข้าใจ
  Future<void> updateTransaction(MoneyTransaction transaction) async {
    final data = TransactionCodec.encode(transaction);
    try {
      // update ไม่สร้างรายการกลับขึ้นมา หากอุปกรณ์อื่นลบไปแล้ว
      await _collection
          .doc(transaction.id)
          .update(data)
          .timeout(const Duration(seconds: 15));
    } on FirebaseException catch (error) {
      if (error.code == 'not-found') throw const TransactionNotFoundException();
      rethrow;
    }
  }

  @override
  /// ลบเฉพาะเอกสารในพื้นที่ผู้ใช้นี้ โดยลองซ้ำด้วย ID เดิมได้
  Future<void> deleteTransaction(String id) async {
    TransactionCodec.validateId(id);
    await _collection.doc(id).delete().timeout(const Duration(seconds: 15));
  }
}
