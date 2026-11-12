// ตรวจว่าลูกเล่นซ่อนยอดคงอยู่ระหว่างเปลี่ยนแท็บ และยอดจริงอัปเดตจาก stream โดยไม่เผยข้อมูลที่ซ่อน
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/data/sample_transactions.dart';
import 'package:project_moneymate/main.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/services/demo_transaction_repository.dart';
import 'package:project_moneymate/widgets/balance_card.dart';

void main() {
  testWidgets('zero viewport startup waits for the actual window size', (
    tester,
  ) async {
    tester.view.physicalSize = Size.zero;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = DemoTransactionRepository(
      initialTransactions: sampleTransactions,
    );
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      MyApp(repository: repository, referenceMonth: sampleReferenceMonth),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(401, 800);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('เริ่มต้นใช้งาน'));
    await tester.tap(find.text('เริ่มต้นใช้งาน'));
    await tester.pumpAndSettle();
    expect(find.text('฿8,500.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'hidden balance survives tabs and stream changes until explicitly shown',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final repository = DemoTransactionRepository(
          initialTransactions: sampleTransactions,
        );
        addTearDown(repository.dispose);
        await tester.pumpWidget(
          MyApp(repository: repository, referenceMonth: sampleReferenceMonth),
        );
        await tester.ensureVisible(find.text('เริ่มต้นใช้งาน'));
        await tester.tap(find.text('เริ่มต้นใช้งาน'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('balance-visibility')));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(BalanceCard),
            matching: find.text('฿8,500.00'),
          ),
          findsNothing,
        );
        expect(find.bySemanticsLabel('฿8,500.00'), findsNothing);
        await tester.tap(find.text('สถิติ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('หน้าหลัก'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('แสดงยอดบนการ์ด'), findsOneWidget);
        await repository.saveTransaction(
          MoneyTransaction(
            id: 'new',
            title: 'ค่าเดินทาง',
            amountSatang: 8100,
            type: TransactionType.expense,
            category: TransactionCategory.other,
            date: DateTime(2026, 11, 10),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('฿8,419.00'), findsNothing);
        await tester.tap(find.byKey(const Key('balance-visibility')));
        await tester.pumpAndSettle();
        expect(find.text('฿8,419.00'), findsOneWidget);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          0,
        );
      } finally {
        semantics.dispose();
      }
    },
  );
}
