// ทดสอบแก้ไขและลบด้วย Firestore จำลองและข้อมูลทดลอง โดยรักษาขอบเขตผู้ใช้และ ID เดิม

import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/services/demo_transaction_repository.dart';
import 'package:project_moneymate/services/firestore_service.dart';
import 'package:project_moneymate/services/transaction_repository.dart';

/// สร้างรายการ ID คงที่ เพื่อยืนยันว่าการแก้ไขและลบอ้างเอกสารเดิม
MoneyTransaction entry(String id, int amount) => MoneyTransaction(
  id: id,
  title: 'ค่าอาหาร',
  amountSatang: amount,
  type: TransactionType.expense,
  category: TransactionCategory.food,
  date: DateTime(2026, 11, 8, 12, 30, 15),
);

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  test(
    'Firestore update changes the same owned record and preserves exact satang',
    () async {
      final database = FakeFirebaseFirestore();
      final alice = FirestoreService(firestore: database, userId: 'alice');
      final bob = FirestoreService(firestore: database, userId: 'bob');
      await alice.saveTransaction(entry('same-id', 8000));
      await bob.saveTransaction(entry('same-id', 9900));
      await alice.updateTransaction(entry('same-id', 5025));
      final feed = await alice.watchTransactions().first;
      expect(feed.transactions, hasLength(1));
      expect(feed.transactions.single.id, 'same-id');
      expect(feed.transactions.single.amountSatang, 5025);
      expect(feed.transactions.single.date, DateTime(2026, 11, 8, 12, 30, 15));
      expect(
        (await bob.watchTransactions().first).transactions.single.amountSatang,
        9900,
      );
    },
  );

  test(
    'Firestore update of a deleted record fails without recreating it',
    () async {
      final database = FakeFirebaseFirestore();
      final service = FirestoreService(firestore: database, userId: 'alice');
      await expectLater(
        service.updateTransaction(entry('missing', 5025)),
        throwsA(isA<TransactionNotFoundException>()),
      );
      expect(
        (await database.doc('users/alice/transactions/missing').get()).exists,
        isFalse,
      );
    },
  );

  test('Firestore deletion is user-scoped and safe to retry', () async {
    final database = FakeFirebaseFirestore();
    final alice = FirestoreService(firestore: database, userId: 'alice');
    final bob = FirestoreService(firestore: database, userId: 'bob');
    await alice.saveTransaction(entry('same-id', 8000));
    await bob.saveTransaction(entry('same-id', 9900));
    await alice.deleteTransaction('same-id');
    await alice.deleteTransaction('same-id');
    expect((await alice.watchTransactions().first).transactions, isEmpty);
    expect(
      (await bob.watchTransactions().first).transactions.single.amountSatang,
      9900,
    );
  });

  test(
    'mutation paths reject blank or nested document IDs before writes',
    () async {
      final service = FirestoreService(
        firestore: FakeFirebaseFirestore(),
        userId: 'alice',
      );
      await expectLater(service.deleteTransaction(''), throwsArgumentError);
      await expectLater(
        service.deleteTransaction('nested/id'),
        throwsArgumentError,
      );
      await expectLater(
        service.updateTransaction(entry('nested/id', 100)),
        throwsArgumentError,
      );
    },
  );

  test('demo mutations emit updated feeds and totals without changing original records', () async {
    final original = [entry('food', 8000)];
    final repository = DemoTransactionRepository(initialTransactions: original);
    addTearDown(repository.dispose);
    final iterator = StreamIterator(repository.watchTransactions());
    await iterator.moveNext();
    expect(iterator.current.transactions.single.amountSatang, 8000);
    await repository.updateTransaction(entry('food', 5025));
    await iterator.moveNext();
    expect(iterator.current.transactions.single.amountSatang, 5025);
    await repository.deleteTransaction('food');
    await iterator.moveNext();
    expect(iterator.current.transactions, isEmpty);
    await iterator.cancel();
    expect(original.single.amountSatang, 8000);
  });

  test(
    'demo update requires an existing record and delete retries stay empty',
    () async {
      final repository = DemoTransactionRepository();
      addTearDown(repository.dispose);
      await expectLater(
        repository.updateTransaction(entry('missing', 5025)),
        throwsA(isA<TransactionNotFoundException>()),
      );
      await repository.deleteTransaction('missing');
      await repository.deleteTransaction('missing');
      expect(
        (await repository.watchTransactions().first).transactions,
        isEmpty,
      );
    },
  );
}
