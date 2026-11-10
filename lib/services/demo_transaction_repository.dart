// แหล่งข้อมูลทดลองในหน่วยความจำ มีสัญญาเดียวกับคลาวด์และแจ้งการเปลี่ยนแปลงผ่าน stream

import 'dart:async';
import 'dart:math';

import '../models/money_transaction.dart';
import 'transaction_codec.dart';
import 'transaction_repository.dart';

/// โหมดทดลองในหน่วยความจำเท่านั้น ไม่ส่งข้อมูลตัวอย่างเข้า Firebase
class DemoTransactionRepository implements TransactionRepository {
  DemoTransactionRepository({
    List<MoneyTransaction> initialTransactions = const [],
  }) : _transactions = List.of(initialTransactions);

  final List<MoneyTransaction> _transactions;
  final _changes = StreamController<TransactionFeed>.broadcast();
  final _random = Random.secure();

  TransactionFeed get _snapshot => TransactionFeed(transactions: _transactions);

  @override
  /// ส่งภาพข้อมูลปัจจุบันทันที แล้วส่งภาพใหม่ทุกครั้งที่มีการเปลี่ยนรายการ
  Stream<TransactionFeed> watchTransactions() => Stream.multi((controller) {
    final subscription = _changes.stream.listen(
      controller.add,
      onError: controller.addError,
    );
    controller.add(_snapshot);
    controller.onCancel = subscription.cancel;
  });

  @override
  /// สร้าง ID ก่อนบันทึก เพื่อให้ฟอร์มใช้ ID เดิมได้เมื่อจำเป็นต้องลองใหม่
  String newTransactionId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';

  @override
  /// แทนที่ ID เดิมก่อนเพิ่ม จึงลองบันทึกซ้ำได้โดยไม่เกิดรายการเพิ่มอีกชุด
  Future<void> saveTransaction(MoneyTransaction transaction) async {
    TransactionCodec.validate(transaction);
    _transactions.removeWhere((item) => item.id == transaction.id);
    _transactions.add(transaction);
    _changes.add(_snapshot);
  }

  @override
  /// แก้เฉพาะรายการที่ยังอยู่ ให้พฤติกรรมสอดคล้องกับ update ของ Firestore
  Future<void> updateTransaction(MoneyTransaction transaction) async {
    TransactionCodec.validate(transaction);
    final index = _transactions.indexWhere((item) => item.id == transaction.id);
    if (index == -1) throw const TransactionNotFoundException();
    _transactions[index] = transaction;
    _changes.add(_snapshot);
  }

  @override
  /// ลบ ID เดิมซ้ำได้ และแจ้ง stream เฉพาะเมื่อข้อมูลเปลี่ยนจริง
  Future<void> deleteTransaction(String id) async {
    TransactionCodec.validateId(id);
    final previousCount = _transactions.length;
    _transactions.removeWhere((item) => item.id == id);
    if (previousCount != _transactions.length) _changes.add(_snapshot);
  }

  /// ปิด stream เมื่อเลิกใช้ repository เพื่อคืนทรัพยากร
  Future<void> dispose() => _changes.close();
}
