import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app_theme.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/widgets/trend_chart.dart';

Widget _host(
  List<MoneyTransaction> transactions, {
  DateTime? month,
  DateTime? today,
  double scale = 1,
}) => MaterialApp(
  theme: buildAppTheme(),
  home: MediaQuery(
    data: MediaQueryData(
      textScaler: TextScaler.linear(scale),
      disableAnimations: true,
    ),
    child: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TrendChart(
            transactions: transactions,
            month: month ?? DateTime(2026, 10),
            today: today ?? DateTime(2026, 10, 8),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'empty weekly chart keeps period selection without invented bars',
    (tester) async {
      await tester.pumpWidget(_host([]));
      expect(find.byType(BarChart), findsNothing);
      expect(find.text('ยังไม่มีรายการในสัปดาห์นี้'), findsOneWidget);
      await tester.tap(find.byKey(const Key('trend-period-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('รายเดือน').last);
      await tester.pumpAndSettle();
      expect(find.text('ยังไม่มีรายการในเดือนนี้'), findsOneWidget);
    },
  );

  testWidgets(
    'real daily amounts remain accessible with large text and no motion',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final transactions = [
        MoneyTransaction(
          id: 'food',
          title: 'อาหาร',
          amountSatang: 10001,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 10, 2),
        ),
      ];
      await tester.pumpWidget(
        _host(transactions, today: DateTime(2026, 10, 2), scale: 2),
      );

      expect(find.text('฿100.01'), findsOneWidget);
      final chart = tester.widget<BarChart>(
        find.byKey(const Key('expense-trend-chart')),
      );
      expect(chart.duration, Duration.zero);
      expect(chart.data.barGroups, hasLength(7));
      expect(chart.data.barGroups[4].barRods[1].toY, 100.01);
      expect(chart.data.barGroups[0].barRods[1].toY, 0);
      await tester.ensureVisible(find.text('ดูยอดรายวัน'));
      await tester.tap(find.text('ดูยอดรายวัน'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp(r'2 ต\.ค\. 2026.*100\.01')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('period menu switches seven weekdays to monthly date bars', (
    tester,
  ) async {
    final records = [
      for (var day = 1; day <= 8; day++)
        MoneyTransaction(
          id: '$day',
          title: '$day',
          amountSatang: day * 100 + 1,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 10, day),
        ),
    ];
    await tester.pumpWidget(_host(records));
    expect(find.text('แนวโน้มรายรับรายจ่าย'), findsOneWidget);
    expect(find.text('รายสัปดาห์'), findsOneWidget);
    var chart = tester.widget<BarChart>(
      find.byKey(const Key('expense-trend-chart')),
    );
    expect(chart.data.barGroups, hasLength(7));
    expect(find.text('จ.'), findsOneWidget);
    expect(find.text('อา.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('trend-period-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('รายเดือน').last);
    await tester.pumpAndSettle();
    chart = tester.widget<BarChart>(
      find.byKey(const Key('expense-trend-chart')),
    );
    expect(chart.data.barGroups, hasLength(8));
    expect(chart.data.barGroups[7].barRods[1].toY, 8.01);
    expect(find.text('รายเดือน'), findsOneWidget);
    expect(find.byTooltip('สัปดาห์ก่อนหน้า'), findsNothing);
    await tester.tap(find.byKey(const Key('trend-period-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('รายสัปดาห์').last);
    await tester.pumpAndSettle();
    chart = tester.widget<BarChart>(
      find.byKey(const Key('expense-trend-chart')),
    );
    expect(chart.data.barGroups, hasLength(7));
    expect(chart.data.barGroups[3].barRods[1].toY, 8.01);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'weekly navigation stays selected on stream edits and resets for a new month',
    (tester) async {
      final records = [
        for (var day = 1; day <= 31; day++)
          MoneyTransaction(
            id: '$day',
            title: '$day',
            amountSatang: day * 100,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            date: DateTime(2026, 10, day),
          ),
      ];
      await tester.pumpWidget(_host(records));
      await tester.tap(find.byTooltip('สัปดาห์ก่อนหน้า'));
      await tester.pumpAndSettle();
      var chart = tester.widget<BarChart>(
        find.byKey(const Key('expense-trend-chart')),
      );
      expect(chart.data.barGroups[4].barRods[1].toY, 2);
      await tester.pumpWidget(
        _host(records.where((item) => item.date.day != 2).toList()),
      );
      await tester.pumpAndSettle();
      chart = tester.widget<BarChart>(
        find.byKey(const Key('expense-trend-chart')),
      );
      expect(chart.data.barGroups[4].barRods[1].toY, 0);
      await tester.pumpWidget(
        _host(
          [
            MoneyTransaction(
              id: 'nov',
              title: 'nov',
              amountSatang: 1001,
              type: TransactionType.expense,
              category: TransactionCategory.food,
              date: DateTime(2026, 11, 1),
            ),
          ],
          month: DateTime(2026, 11),
          today: DateTime(2026, 10, 8),
        ),
      );
      await tester.pumpAndSettle();
      chart = tester.widget<BarChart>(
        find.byKey(const Key('expense-trend-chart')),
      );
      expect(chart.data.barGroups[6].barRods[1].toY, 10.01);
      expect(tester.takeException(), isNull);
    },
  );
}
