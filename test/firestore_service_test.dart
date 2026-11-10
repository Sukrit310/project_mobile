// ทดสอบ repository ด้วย Firestore จำลอง ทั้งข้อมูลรายผู้ใช้ เงินที่แม่นยำ และข้อมูลผิดรูปแบบ

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/services/firestore_service.dart';

/// ข้อมูลตัวอย่างสำหรับฐานข้อมูลจำลอง กำหนดวันหรือยอดต่างกันได้ตามกรณี
MoneyTransaction record(String id, {int amount = 12345, DateTime? date}) =>
    MoneyTransaction(
      id: id,
      title: 'ค่าอาหาร',
      amountSatang: amount,
      type: TransactionType.expense,
      category: TransactionCategory.food,
      date: date ?? DateTime(2026, 11, 10, 12),
    );

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  test(
    'saves exact satang and timestamp in the signed-in user collection',
    () async {
      final database = FakeFirebaseFirestore();
      final service = FirestoreService(firestore: database, userId: 'alice');
      await service.saveTransaction(record('stable-id'));

      final saved = await database
          .doc('users/alice/transactions/stable-id')
          .get();
      expect(saved.data()!['title'], 'ค่าอาหาร');
      expect(saved.data()!['amountSatang'], 12345);
      expect(saved.data()!['type'], 'expense');
      expect(saved.data()!['category'], 'food');
      expect(
        (saved.data()!['date'] as Timestamp).toDate(),
        DateTime(2026, 11, 10, 12),
      );
      expect((await database.collection('transactions').get()).docs, isEmpty);
    },
  );

  test(
    'retrying the same transaction ID does not create duplicate records',
    () async {
      final database = FakeFirebaseFirestore();
      final service = FirestoreService(firestore: database, userId: 'alice');
      await service.saveTransaction(record('same-id'));
      await service.saveTransaction(record('same-id'));
      expect(
        (await database.collection('users/alice/transactions').get()).docs,
        hasLength(1),
      );
    },
  );

  test(
    'watch reads only the current user and orders records newest first',
    () async {
      final database = FakeFirebaseFirestore();
      final alice = FirestoreService(firestore: database, userId: 'alice');
      final bob = FirestoreService(firestore: database, userId: 'bob');
      await alice.saveTransaction(record('old', date: DateTime(2026, 11, 1)));
      await bob.saveTransaction(record('private'));
      await alice.saveTransaction(record('new', date: DateTime(2026, 11, 10)));

      final feed = await alice.watchTransactions().first;
      expect(feed.transactions.map((item) => item.id), ['new', 'old']);
      expect(feed.transactions.first.amountSatang, 12345);
    },
  );

  test('empty live data stays empty without seeding demo records', () async {
    final database = FakeFirebaseFirestore();
    final service = FirestoreService(firestore: database, userId: 'alice');
    expect((await service.watchTransactions().first).transactions, isEmpty);
    expect(
      (await database.collection('users/alice/transactions').get()).docs,
      isEmpty,
    );
  });

  test(
    'invalid amounts and document paths are rejected before writing',
    () async {
      final database = FakeFirebaseFirestore();
      final service = FirestoreService(firestore: database, userId: 'alice');
      await expectLater(
        service.saveTransaction(record('zero', amount: 0)),
        throwsArgumentError,
      );
      await expectLater(
        service.saveTransaction(record('nested/path')),
        throwsArgumentError,
      );
      expect(
        () => FirestoreService(firestore: database, userId: ''),
        throwsArgumentError,
      );
      expect(
        () => FirestoreService(firestore: database, userId: 'alice/other'),
        throwsArgumentError,
      );
    },
  );

  test(
    'malformed stored data surfaces a read error rather than wrong totals',
    () async {
      final database = FakeFirebaseFirestore();
      await database.doc('users/alice/transactions/bad').set({
        'title': 'broken',
        'amountSatang': 12.5,
        'type': 'expense',
        'category': 'food',
        'date': Timestamp.fromDate(DateTime(2026, 11, 1)),
      });
      final service = FirestoreService(firestore: database, userId: 'alice');
      await expectLater(
        service.watchTransactions().first,
        throwsFormatException,
      );
    },
  );
}
