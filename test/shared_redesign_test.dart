// ตรวจลำดับข้อมูลของการ์ดและรายการร่วมกันบนจอแคบพร้อมตัวอักษรขยาย
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app_theme.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/utils/date_formatter.dart';
import 'package:project_moneymate/widgets/balance_card.dart';
import 'package:project_moneymate/widgets/moneymate_navigation_bar.dart';
import 'package:project_moneymate/widgets/transaction_tile.dart';

void main() {
  testWidgets(
    'balance explains its accumulated scope with exact large amounts',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final summary = DashboardSummary.fromTransactions([
        MoneyTransaction(
          id: 'large-income',
          title: 'รายรับเดือนก่อน',
          amountSatang: 99999999999,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          date: DateTime(2026, 10, 1),
        ),
      ], month: DateTime(2026, 11));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: BalanceCard(summary: summary),
            ),
          ),
        ),
      );

      expect(find.text('สะสมจากทุกรายการ'), findsOneWidget);
      expect(find.text('฿999,999,999.99'), findsOneWidget);
      expect(find.text('รายรับเดือนนี้'), findsOneWidget);
      expect(find.text('รายจ่ายเดือนนี้'), findsOneWidget);
      expect(find.text('฿0'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('transaction retains category date and exact amount at 2x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final transaction = MoneyTransaction(
      id: 'long-expense',
      title: 'รายการอาหารสำหรับครอบครัวในวันหยุด',
      amountSatang: 99999999999,
      type: TransactionType.expense,
      category: TransactionCategory.food,
      date: DateTime(2026, 11, 12),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: TransactionTile(transaction: transaction),
          ),
        ),
      ),
    );

    expect(find.text(transaction.title), findsOneWidget);
    expect(find.text('อาหาร'), findsOneWidget);
    expect(find.text(formatThaiDate(transaction.date)), findsOneWidget);
    expect(find.text('-฿999,999,999.99'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('transaction avoids repeating a category used as its title', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: TransactionTile(
            transaction: MoneyTransaction(
              id: 'salary',
              title: 'เงินเดือน',
              amountSatang: 1200000,
              type: TransactionType.income,
              category: TransactionCategory.salary,
              date: DateTime(2026, 11, 1),
            ),
          ),
        ),
      ),
    );

    expect(find.text('เงินเดือน'), findsOneWidget);
    expect(find.text('1 พ.ย. 2026'), findsOneWidget);
  });

  testWidgets(
    'four labeled destinations retain tap and reduced motion behavior',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final selected = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: Scaffold(
              bottomNavigationBar: MoneyMateNavigationBar(
                currentIndex: 0,
                onTap: selected.add,
              ),
            ),
          ),
        ),
      );

      for (final label in ['หน้าหลัก', 'ประวัติ', 'สถิติ', 'งบประมาณ']) {
        expect(find.text(label).hitTestable(), findsOneWidget);
        await tester.tap(find.text(label));
        await tester.pump();
      }
      expect(selected, [1, 2, 3]);
      expect(
        tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .animationDuration,
        Duration.zero,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
