// ทดสอบงบรายเดือนด้วยฐานข้อมูลจำลอง จึงไม่อ่านหรือแก้ไขข้อมูลผู้ใช้จริง
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/models/budget_model.dart';
import 'package:project_moneymate/services/budget_codec.dart';
import 'package:project_moneymate/services/demo_budget_repository.dart';
import 'package:project_moneymate/services/firestore_budget_repository.dart';

// สร้างข้อมูลเอกสารครบทุกฟิลด์เพื่อจับการยอมรับข้อมูลผิดชนิดหรือผิดเดือน
Map<String, dynamic> storedBudget({
  String monthKey = '2026-11',
  Object? limitSatang = 12345,
  Object? updatedAt,
}) => {
  'monthKey': monthKey,
  'limitSatang': limitSatang,
  'updatedAt': updatedAt ?? Timestamp.fromDate(DateTime(2026, 11, 10)),
};

void main() {
  // FieldValue จดจำ factory ครั้งแรก จึงติดตั้งของจำลองก่อนทดสอบ server timestamp
  setUpAll(() {
    FakeFirebaseFirestore();
  });

  group('BudgetModel', () {
    // วัน เวลา และเขตเวลาของรายการต้องไม่กลายเป็นส่วนหนึ่งของรหัสงบ
    test('normalizes the calendar month and pads the full month key', () {
      final budget = BudgetModel(
        month: DateTime.utc(1, 2, 28, 23, 59),
        limitSatang: 1,
      );
      expect(budget.month, DateTime(1, 2));
      expect(budget.monthKey, '0001-02');
      expect(
        BudgetModel(month: DateTime(9999, 12), limitSatang: 0).monthKey,
        '9999-12',
      );
    });

    test('accepts legacy zero and the exact maximum without rounding', () {
      expect(
        BudgetModel(month: DateTime(2026, 11), limitSatang: 0).limitSatang,
        0,
      );
      expect(
        BudgetModel(
          month: DateTime(2026, 11),
          limitSatang: 99999999999,
        ).limitSatang,
        99999999999,
      );
    });

    test('rejects out-of-range amounts and years', () {
      for (final amount in [-1, 100000000000]) {
        expect(
          () => BudgetModel(month: DateTime(2026, 11), limitSatang: amount),
          throwsArgumentError,
        );
      }
      for (final year in [0, 10000]) {
        expect(
          () => BudgetModel(month: DateTime(year, 1), limitSatang: 100),
          throwsArgumentError,
        );
      }
    });
  });

  group('BudgetCodec', () {
    test('encodes only budget fields and requests a server timestamp', () {
      final encoded = BudgetCodec.encode(
        BudgetModel(month: DateTime(2026, 11, 30), limitSatang: 12345),
      );
      expect(
        encoded.keys,
        unorderedEquals(['monthKey', 'limitSatang', 'updatedAt']),
      );
      expect(encoded['monthKey'], '2026-11');
      expect(encoded['limitSatang'], 12345);
      expect(encoded['updatedAt'], isA<FieldValue>());
    });

    test('decodes exact integer satang and a normalized calendar month', () {
      final decoded = BudgetCodec.decode('2026-11', storedBudget());
      expect(decoded.month, DateTime(2026, 11));
      expect(decoded.limitSatang, 12345);
    });

    test('rejects wrong types, amounts, missing and unexpected fields', () {
      final invalidRecords = <Map<String, dynamic>>[
        storedBudget(limitSatang: 12.5),
        storedBudget(limitSatang: 12345.0),
        storedBudget(limitSatang: '12345'),
        storedBudget(limitSatang: -1),
        storedBudget(limitSatang: 100000000000),
        storedBudget(updatedAt: 'yesterday'),
        {...storedBudget()}..remove('updatedAt'),
        {...storedBudget(), 'expenseSatang': 500},
      ];
      for (final data in invalidRecords) {
        expect(
          () => BudgetCodec.decode('2026-11', data),
          throwsFormatException,
          reason: '$data',
        );
      }
    });

    test(
      'rejects month rollover, noncanonical keys and mismatched document IDs',
      () {
        for (final key in [
          '2026-00',
          '2026-13',
          '2026-1',
          '0000-11',
          '10000-11',
          '2026-11\n',
        ]) {
          expect(
            () => BudgetCodec.decode(key, storedBudget(monthKey: key)),
            throwsFormatException,
            reason: key,
          );
        }
        expect(
          () => BudgetCodec.decode('2026-12', storedBudget()),
          throwsFormatException,
        );
        expect(
          () => BudgetCodec.decode('2026-11', {
            ...storedBudget(),
            'monthKey': 202611,
          }),
          throwsFormatException,
        );
      },
    );

    // ค่าว่างชั่วคราวของ server timestamp ยอมรับได้เฉพาะงานที่ยังรอยืนยัน
    test('allows null timestamp only for a pending local write', () {
      final pendingData = {...storedBudget(), 'updatedAt': null};
      expect(
        BudgetCodec.decode(
          '2026-11',
          pendingData,
          hasPendingWrites: true,
        ).limitSatang,
        12345,
      );
      expect(
        () => BudgetCodec.decode('2026-11', pendingData),
        throwsFormatException,
      );
      expect(
        () => BudgetCodec.decode(
          '2026-11',
          storedBudget(updatedAt: 42),
          hasPendingWrites: true,
        ),
        throwsFormatException,
      );
    });
  });

  group('FirestoreBudgetRepository', () {
    test(
      'stores only exact fields beneath the current user and month',
      () async {
        final database = FakeFirebaseFirestore();
        final repository = FirestoreBudgetRepository(
          firestore: database,
          userId: 'alice',
        );
        await repository.saveBudget(
          BudgetModel(month: DateTime(2026, 11, 30), limitSatang: 12345),
        );

        final saved = (await database.doc('users/alice/budgets/2026-11').get())
            .data()!;
        expect(
          saved.keys,
          unorderedEquals(['monthKey', 'limitSatang', 'updatedAt']),
        );
        expect(saved['monthKey'], '2026-11');
        expect(saved['limitSatang'], 12345);
        expect(saved['updatedAt'], isA<Timestamp>());
        expect((await database.collection('budgets').get()).docs, isEmpty);
        expect(
          (await database.collection('users/bob/budgets').get()).docs,
          isEmpty,
        );
      },
    );

    test('retries overwrite one document without inheriting a different month or year', () async {
      final database = FakeFirebaseFirestore();
      final alice = FirestoreBudgetRepository(
        firestore: database,
        userId: 'alice',
      );
      final bob = FirestoreBudgetRepository(firestore: database, userId: 'bob');
      await alice.saveBudget(
        BudgetModel(month: DateTime(2026, 11), limitSatang: 100),
      );
      await alice.saveBudget(
        BudgetModel(month: DateTime(2026, 11), limitSatang: 12345),
      );
      await bob.saveBudget(
        BudgetModel(month: DateTime(2026, 11), limitSatang: 999),
      );

      expect(
        (await database.collection('users/alice/budgets').get()).docs,
        hasLength(1),
      );
      expect(
        (await alice.watchBudget(DateTime(2026, 11, 15)).first)
            .budget!
            .limitSatang,
        12345,
      );
      expect(
        (await bob.watchBudget(DateTime(2026, 11)).first).budget!.limitSatang,
        999,
      );
      expect(
        (await alice.watchBudget(DateTime(2026, 12)).first).budget,
        isNull,
      );
      expect(
        (await alice.watchBudget(DateTime(2027, 11)).first).budget,
        isNull,
      );
    });

    test(
      'empty live months stay empty without seeding demonstration data',
      () async {
        final database = FakeFirebaseFirestore();
        final repository = FirestoreBudgetRepository(
          firestore: database,
          userId: 'alice',
        );
        final feed = await repository.watchBudget(DateTime(2026, 11)).first;
        expect(feed.budget, isNull);
        expect(feed.isFromCache, isFalse);
        expect(feed.hasPendingWrites, isFalse);
        expect(
          (await database.collection('users/alice/budgets').get()).docs,
          isEmpty,
        );
      },
    );

    test('rejects invalid user paths and unsupported watch years', () {
      final database = FakeFirebaseFirestore();
      for (final userId in ['', '  ', 'alice/other', '.', '..']) {
        expect(
          () => FirestoreBudgetRepository(firestore: database, userId: userId),
          throwsArgumentError,
          reason: userId,
        );
      }
      final repository = FirestoreBudgetRepository(
        firestore: database,
        userId: 'alice',
      );
      expect(
        () => repository.watchBudget(DateTime(0, 11)),
        throwsArgumentError,
      );
    });

    test(
      'malformed stored data surfaces an error instead of an empty budget',
      () async {
        final database = FakeFirebaseFirestore();
        await database
            .doc('users/alice/budgets/2026-11')
            .set(storedBudget(limitSatang: 12.5));
        final repository = FirestoreBudgetRepository(
          firestore: database,
          userId: 'alice',
        );
        await expectLater(
          repository.watchBudget(DateTime(2026, 11)).first,
          throwsFormatException,
        );
      },
    );

    // ฐานข้อมูลจำลองปกติไม่มีสถานะ pending/cache จึงแทนเฉพาะขอบเขต snapshot นี้
    test(
      'preserves cache and pending metadata then the server confirmation',
      () async {
        final database = _SnapshotFirestore([
          _BudgetSnapshot({
            ...storedBudget(),
            'updatedAt': null,
          }, const _Metadata(cache: true, pending: true)),
          _BudgetSnapshot(storedBudget(), const _Metadata()),
        ]);
        final repository = FirestoreBudgetRepository(
          firestore: database,
          userId: 'alice',
        );
        final feeds = await repository.watchBudget(DateTime(2026, 11)).toList();
        expect(database.lastSnapshotPath, 'users/alice/budgets/2026-11');
        expect(database.includeMetadataChanges, isTrue);
        expect(feeds.map((feed) => feed.budget!.limitSatang), [12345, 12345]);
        expect(feeds.first.isFromCache, isTrue);
        expect(feeds.first.hasPendingWrites, isTrue);
        expect(feeds.last.isFromCache, isFalse);
        expect(feeds.last.hasPendingWrites, isFalse);
      },
    );

    testWidgets(
      'a save that never receives confirmation times out after 15 seconds',
      (tester) async {
        final database = _SnapshotFirestore([]);
        final repository = FirestoreBudgetRepository(
          firestore: database,
          userId: 'alice',
        );
        final expected = expectLater(
          repository.saveBudget(
            BudgetModel(month: DateTime(2026, 11), limitSatang: 100),
          ),
          throwsA(isA<TimeoutException>()),
        );
        await tester.pump(const Duration(seconds: 15));
        await expected;
      },
    );
  });

  group('DemoBudgetRepository', () {
    test(
      'copies initial data and keeps month and year subscriptions isolated',
      () async {
        final initial = [
          BudgetModel(month: DateTime(2026, 11, 20), limitSatang: 100),
        ];
        final repository = DemoBudgetRepository(initialBudgets: initial);
        addTearDown(repository.dispose);
        initial.clear();

        expect(
          (await repository.watchBudget(DateTime(2026, 11)).first)
              .budget!
              .limitSatang,
          100,
        );
        expect(
          (await repository.watchBudget(DateTime(2026, 12)).first).budget,
          isNull,
        );
        expect(
          (await repository.watchBudget(DateTime(2027, 11)).first).budget,
          isNull,
        );
      },
    );

    // เก็บ feed เก่าไว้เพื่อตรวจว่าการแก้งบใหม่ไม่เปลี่ยน snapshot ที่แสดงไปแล้ว
    test(
      'emits only the selected month and leaves previous feeds unchanged',
      () async {
        final repository = DemoBudgetRepository();
        addTearDown(repository.dispose);
        final iterator = StreamIterator(
          repository.watchBudget(DateTime(2026, 11)),
        );
        expect(await iterator.moveNext(), isTrue);
        final emptyFeed = iterator.current;
        await repository.saveBudget(
          BudgetModel(month: DateTime(2026, 11), limitSatang: 100),
        );
        expect(await iterator.moveNext(), isTrue);
        final firstBudgetFeed = iterator.current;
        await repository.saveBudget(
          BudgetModel(month: DateTime(2026, 12), limitSatang: 999),
        );
        await repository.saveBudget(
          BudgetModel(month: DateTime(2026, 11), limitSatang: 12345),
        );
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current.budget!.limitSatang, 12345);
        expect(iterator.current.isFromCache, isFalse);
        expect(iterator.current.hasPendingWrites, isFalse);
        expect(emptyFeed.budget, isNull);
        expect(firstBudgetFeed.budget!.limitSatang, 100);
        await iterator.cancel();
      },
    );

    test(
      'retries replace the month and preserves zero as an unset budget',
      () async {
        final repository = DemoBudgetRepository();
        addTearDown(repository.dispose);
        final month = DateTime(2026, 11);
        await repository.saveBudget(
          BudgetModel(month: month, limitSatang: 100),
        );
        await repository.saveBudget(
          BudgetModel(month: month, limitSatang: 100),
        );
        await repository.saveBudget(BudgetModel(month: month, limitSatang: 0));
        expect(
          (await repository.watchBudget(month).first).budget!.limitSatang,
          0,
        );
      },
    );

    test(
      'dispose closes active subscriptions and prevents further writes',
      () async {
        final repository = DemoBudgetRepository();
        final iterator = StreamIterator(
          repository.watchBudget(DateTime(2026, 11)),
        );
        await iterator.moveNext();
        final completed = iterator.moveNext();
        await repository.dispose();
        expect(await completed, isFalse);
        await expectLater(
          repository.saveBudget(
            BudgetModel(month: DateTime(2026, 11), limitSatang: 100),
          ),
          throwsStateError,
        );
      },
    );
  });
}

// จำลองเฉพาะขอบเขต Firestore ที่ส่งสถานะแคชและงานรอการยืนยันให้ repository
class _SnapshotFirestore implements FirebaseFirestore {
  _SnapshotFirestore(this.snapshots);

  final List<DocumentSnapshot<Map<String, dynamic>>> snapshots;
  String? lastSnapshotPath;
  bool? includeMetadataChanges;
  final _unconfirmedSave = Completer<void>();

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _SnapshotCollection(this, path);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ประกอบเส้นทางตามการเรียกจริงเพื่อจับกรณีอ่านผิดผู้ใช้หรือผิดเดือน
// ทดแทนขอบเขต SDK เฉพาะในเทสต์ เพราะ fake ปกติเปลี่ยน metadata ไม่ได้
// ignore: subtype_of_sealed_class
class _SnapshotCollection implements CollectionReference<Map<String, dynamic>> {
  _SnapshotCollection(this.database, this.path);
  final _SnapshotFirestore database;
  @override
  final String path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _SnapshotDocument(database, '${this.path}/$path');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// การเขียนที่ไม่จบใช้เวลาจำลองของ widget tester ทดสอบ timeout โดยไม่รอจริง
// ignore: subtype_of_sealed_class
class _SnapshotDocument implements DocumentReference<Map<String, dynamic>> {
  _SnapshotDocument(this.database, this.path);
  final _SnapshotFirestore database;
  @override
  final String path;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _SnapshotCollection(database, '$path/$collectionPath');

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    database.lastSnapshotPath = path;
    database.includeMetadataChanges = includeMetadataChanges;
    return Stream.fromIterable(database.snapshots);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) =>
      database._unconfirmedSave.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// snapshot มีข้อมูลและ metadata ครบตามที่ repository ต้องใช้จริง
// ignore: subtype_of_sealed_class
class _BudgetSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _BudgetSnapshot(this._data, this.metadata);
  final Map<String, dynamic> _data;
  @override
  final SnapshotMetadata metadata;
  @override
  String get id => '2026-11';
  @override
  bool get exists => true;
  @override
  Map<String, dynamic> data() => _data;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// แยกสถานะรอยืนยันออกจากสถานะแคช เพราะทั้งสองค่าเปลี่ยนได้อิสระ
class _Metadata implements SnapshotMetadata {
  const _Metadata({bool cache = false, bool pending = false})
    : isFromCache = cache,
      hasPendingWrites = pending;
  @override
  final bool isFromCache;
  @override
  final bool hasPendingWrites;
}
