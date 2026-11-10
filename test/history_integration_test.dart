// ทดสอบประวัติร่วมกับแอปและ repository ทดลอง เพื่อให้การแก้ไขและลบสะท้อนยอดหน้าหลัก

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/data/sample_transactions.dart';
import 'package:project_moneymate/main.dart';
import 'package:project_moneymate/services/demo_transaction_repository.dart';
import 'package:project_moneymate/widgets/balance_card.dart';

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  testWidgets(
    'editing from History updates Dashboard totals with satang precision',
    (tester) async {
      final repository = DemoTransactionRepository(
        initialTransactions: sampleTransactions,
      );
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        MyApp(repository: repository, referenceMonth: DateTime(2026, 11)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ประวัติ'));
      await tester.pumpAndSettle();
      final menu = find.byKey(const Key('history-actions-food-2026-11-08'));
      await tester.ensureVisible(menu);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('แก้ไข'));
      await tester.pumpAndSettle();
      expect(find.text('แก้ไขรายการ'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('transaction-amount')),
        '50.25',
      );
      await tester.ensureVisible(find.text('บันทึกการแก้ไข'));
      await tester.tap(find.text('บันทึกการแก้ไข'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('หน้าหลัก'));
      await tester.pumpAndSettle();
      expect(find.text('฿8,529.75'), findsOneWidget);
      expect(find.text('-฿3,470.25'), findsOneWidget);
      expect(find.text('-฿50.25'), findsOneWidget);
    },
  );

  testWidgets(
    'cancelled delete keeps data; confirmed delete updates Home balance',
    (tester) async {
      final repository = DemoTransactionRepository(
        initialTransactions: sampleTransactions,
      );
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        MyApp(repository: repository, referenceMonth: DateTime(2026, 11)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ประวัติ'));
      await tester.pumpAndSettle();
      final menu = find.byKey(const Key('history-actions-food-2026-11-08'));
      await tester.ensureVisible(menu);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ลบ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('history-row-food-2026-11-08')),
        findsOneWidget,
      );
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ลบ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ลบรายการ'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('history-row-food-2026-11-08')),
        findsNothing,
      );
      await tester.tap(find.text('หน้าหลัก'));
      await tester.pumpAndSettle();
      expect(find.text('฿8,580.00'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BalanceCard),
          matching: find.text('-฿3,420'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'History navigation shows all month records and returns to Home',
    (tester) async {
      final repository = DemoTransactionRepository(
        initialTransactions: sampleTransactions,
      );
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        MyApp(repository: repository, referenceMonth: DateTime(2026, 11)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ประวัติ'));
      await tester.pumpAndSettle();
      expect(find.text('ประวัติรายการ'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('ค่าที่พัก'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('ค่าที่พัก'), findsOneWidget);
      await tester.tap(find.text('หน้าหลัก'));
      await tester.pumpAndSettle();
      expect(find.text('฿8,500.00'), findsOneWidget);
    },
  );
}
