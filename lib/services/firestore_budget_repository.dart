// อ่านงบเฉพาะเจ้าของและเดือนที่เลือก โดยเก็บสถานะออฟไลน์และรอซิงก์ไว้ใน feed
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/budget_model.dart';
import 'budget_codec.dart';
import 'budget_repository.dart';

/// เก็บงบหนึ่งเอกสารต่อเดือนใน users/{uid}/budgets/{YYYY-MM}
class FirestoreBudgetRepository implements BudgetRepository {
  FirestoreBudgetRepository({required this.firestore, required String userId})
    : _userId = userId {
    if (userId.trim().isEmpty ||
        userId.contains('/') ||
        userId == '.' ||
        userId == '..') {
      throw ArgumentError.value(userId, 'userId');
    }
  }

  final FirebaseFirestore firestore;
  final String _userId;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('users').doc(_userId).collection('budgets');

  @override
  Stream<BudgetFeed> watchBudget(DateTime month) {
    final key = BudgetModel(month: month, limitSatang: 0).monthKey;
    return _collection.doc(key).snapshots(includeMetadataChanges: true).map((
      snapshot,
    ) {
      final metadata = snapshot.metadata;
      final data = snapshot.data();
      // เอกสารที่ไม่มีอยู่หมายถึงยังไม่ตั้งงบ ส่วนเอกสารเสียต้องส่งเป็นข้อผิดพลาด
      if (snapshot.exists && data == null) {
        throw const FormatException('Invalid Firestore budget');
      }
      return BudgetFeed(
        budget: !snapshot.exists
            ? null
            : BudgetCodec.decode(
                snapshot.id,
                data!,
                hasPendingWrites: metadata.hasPendingWrites,
              ),
        isFromCache: metadata.isFromCache,
        hasPendingWrites: metadata.hasPendingWrites,
      );
    });
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    // การลองบันทึกซ้ำใช้รหัสเดือนเดิม จึงไม่สร้างงบหลายฉบับเมื่อเครือข่ายช้า
    await _collection
        .doc(budget.monthKey)
        .set(BudgetCodec.encode(budget))
        .timeout(const Duration(seconds: 15));
  }
}
