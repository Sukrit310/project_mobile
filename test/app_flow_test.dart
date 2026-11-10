// ทดสอบเส้นทางหลักของแอปด้วย repository จำลอง รวมการบันทึก สถานะโหลด และการรอยืนยัน

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/main.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/services/demo_transaction_repository.dart';
import 'package:project_moneymate/services/transaction_repository.dart';

/// ควบคุม stream จากการทดสอบ เพื่อจำลองกำลังโหลด ข้อผิดพลาด และ pending writes
class ControlledRepository implements TransactionRepository {
  final controller = StreamController<TransactionFeed>.broadcast();
  @override
  Stream<TransactionFeed> watchTransactions() => controller.stream;
  @override
  String newTransactionId() => 'test-id';
  @override
  Future<void> saveTransaction(MoneyTransaction transaction) async {}
  @override
  Future<void> updateTransaction(MoneyTransaction transaction) async {}
  @override
  Future<void> deleteTransaction(String id) async {}
}

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  testWidgets(
    'unsupported Firebase platform offers explicit demo rather than fake cloud data',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.text('ยังเชื่อมต่อ Firebase ไม่สำเร็จ'), findsOneWidget);
      expect(find.text('฿8,500.00'), findsNothing);
      await tester.tap(find.text('ทดลองด้วยข้อมูลตัวอย่าง'));
      await tester.pumpAndSettle();
      expect(find.textContaining('โหมดตัวอย่าง'), findsOneWidget);
      expect(find.text('฿8,500.00'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('saving a form updates the Dashboard with exact satang', (
    tester,
  ) async {
    final repository = DemoTransactionRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      MyApp(repository: repository, referenceMonth: DateTime(2026, 11)),
    );
    await tester.pumpAndSettle();
    expect(find.text('฿0.00'), findsOneWidget);
    expect(find.text('ยังไม่มีรายการในตอนนี้'), findsOneWidget);
    await tester.ensureVisible(find.text('เพิ่มรายการ'));
    await tester.tap(find.text('เพิ่มรายการ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('transaction-title')), 'กาแฟ');
    await tester.enterText(
      find.byKey(const Key('transaction-amount')),
      '80.05',
    );
    await tester.ensureVisible(find.text('บันทึกรายการ'));
    await tester.tap(find.text('บันทึกรายการ'));
    await tester.pumpAndSettle();
    expect(find.text('กาแฟ'), findsOneWidget);
    expect(find.text('-฿80.05'), findsNWidgets(3));
    expect(find.text('บันทึกรายการ'), findsNothing);
  });

  testWidgets('live loading, error and retry states are visible', (
    tester,
  ) async {
    final repository = ControlledRepository();
    addTearDown(repository.controller.close);
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.controller.addError(StateError('read failed'));
    await tester.pumpAndSettle();
    expect(find.text('โหลดรายการไม่สำเร็จ'), findsOneWidget);
    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pump();
    repository.controller.add(TransactionFeed(transactions: []));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีรายการในตอนนี้'), findsOneWidget);
    expect(find.text('฿8,500.00'), findsNothing);
  });

  testWidgets(
    'pending writes are labelled instead of claiming cloud confirmation',
    (tester) async {
      final repository = ControlledRepository();
      addTearDown(repository.controller.close);
      await tester.pumpWidget(MyApp(repository: repository));
      await tester.pump();
      repository.controller.add(
        TransactionFeed(transactions: [], hasPendingWrites: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('กำลังรอยืนยันการบันทึกจาก Firebase'), findsOneWidget);
    },
  );
}
