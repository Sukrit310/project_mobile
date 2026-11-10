// ตรวจการซ่อนยอดบนการ์ดและทางลัดที่ยังใช้งานได้เมื่อหน้าจอแคบหรือตัวอักษรใหญ่

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app_theme.dart';
import 'package:project_moneymate/data/sample_transactions.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/screens/home.dart';
import 'package:project_moneymate/widgets/balance_card.dart';

void main() {
  testWidgets('balance card offers a labeled visibility control', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const Home()),
    );

    expect(find.byTooltip('ซ่อนยอดบนการ์ด'), findsOneWidget);
    expect(find.byKey(const Key('balance-visibility')), findsOneWidget);
    expect(find.text('฿8,500.00'), findsOneWidget);
  });

  testWidgets(
    'hiding immediately removes all card amounts and their semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        var visible = true;
        final summary = DashboardSummary.fromTransactions(
          sampleTransactions,
          month: sampleReferenceMonth,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                body: BalanceCard(
                  summary: summary,
                  showBalance: visible,
                  onToggleBalanceVisibility: () =>
                      setState(() => visible = !visible),
                ),
              ),
            ),
          ),
        );

        expect(find.text('฿8,500.00'), findsOneWidget);
        expect(find.text('+฿12,000'), findsOneWidget);
        expect(find.text('-฿3,500'), findsOneWidget);

        await tester.tap(find.byKey(const Key('balance-visibility')));
        await tester.pump();

        expect(find.text('••••••'), findsNWidgets(3));
        expect(find.byTooltip('แสดงยอดบนการ์ด'), findsOneWidget);
        for (final amount in ['฿8,500.00', '+฿12,000', '-฿3,500']) {
          expect(find.text(amount), findsNothing);
          expect(
            find.bySemanticsLabel(RegExp(RegExp.escape(amount))),
            findsNothing,
          );
        }

        await tester.tap(find.byKey(const Key('balance-visibility')));
        await tester.pump();

        expect(find.text('••••••'), findsNothing);
        expect(find.text('฿8,500.00'), findsOneWidget);
        expect(find.text('+฿12,000'), findsOneWidget);
        expect(find.text('-฿3,500'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('Home forwards privacy changes and retains transaction values', (
    tester,
  ) async {
    var visible = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StatefulBuilder(
          builder: (context, setState) => Home(
            showBalance: visible,
            onToggleBalanceVisibility: () => setState(() => visible = !visible),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('balance-visibility')));
    await tester.pump();

    expect(find.text('฿8,500.00'), findsNothing);
    expect(find.text('-฿3,500'), findsNothing);
    expect(find.text('••••••'), findsNWidgets(3));
    expect(find.text('-฿80'), findsOneWidget);
    expect(find.text('+฿12,000'), findsOneWidget);
  });

  testWidgets(
    'narrow dashboard keeps privacy, wallet, and add actions usable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var visible = true;
      var additions = 0;
      int? destination;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: StatefulBuilder(
            builder: (context, setState) => Home(
              showBalance: visible,
              onToggleBalanceVisibility: () =>
                  setState(() => visible = !visible),
              onAddTransaction: () => additions++,
              onDestinationSelected: (index) => destination = index,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('กระเป๋าเงิน'));
      expect(destination, 3);
      await tester.ensureVisible(find.byKey(const Key('balance-visibility')));
      await tester.tap(find.byKey(const Key('balance-visibility')));
      await tester.pump();
      expect(find.text('••••••'), findsNWidgets(3));
      await tester.ensureVisible(find.text('เพิ่มรายการ'));
      await tester.tap(find.text('เพิ่มรายการ'));
      await tester.pump();
      expect(additions, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
