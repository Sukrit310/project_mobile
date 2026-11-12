// ตรวจแท่งรายรับ/รายจ่ายคู่กัน รวมยอดและรายละเอียดตามช่วงวันที่เดียวกัน
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app_theme.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/widgets/trend_chart.dart';

MoneyTransaction _record(
  String id,
  int satang,
  TransactionType type,
  int day,
) => MoneyTransaction(
  id: id,
  title: id,
  amountSatang: satang,
  type: type,
  category: TransactionCategory.other,
  date: DateTime(2026, 10, day),
);

Widget _app(List<MoneyTransaction> records, {double scale = 1}) => MaterialApp(
  theme: buildAppTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: TrendChart(
        transactions: records,
        month: DateTime(2026, 10),
        today: DateTime(2026, 10, 8),
      ),
    ),
  ),
);

void main() {
  final records = [
    _record('income-a', 10001, TransactionType.income, 5),
    _record('income-b', 1000, TransactionType.income, 5),
    _record('expense', 3001, TransactionType.expense, 5),
    _record('income-only-day', 20002, TransactionType.income, 6),
  ];
  testWidgets('each day has separate income and expense rods and totals', (
    tester,
  ) async {
    await tester.pumpWidget(_app(records));
    final chart = tester.widget<BarChart>(
      find.byKey(const Key('expense-trend-chart')),
    );
    expect(find.text('แนวโน้มรายรับรายจ่าย'), findsOneWidget);
    expect(chart.data.barGroups, hasLength(7));
    expect(
      chart.data.barGroups.every((group) => group.barRods.length == 2),
      isTrue,
    );
    expect(chart.data.barGroups[0].barRods[0].toY, 110.01);
    expect(chart.data.barGroups[0].barRods[1].toY, 30.01);
    expect(chart.data.barGroups[1].barRods[0].toY, 200.02);
    expect(chart.data.barGroups[1].barRods[1].toY, 0);
    expect(
      chart.data.barGroups[0].barRods[0].color,
      isNot(chart.data.barGroups[0].barRods[1].color),
    );
    expect(find.text('รวมรายรับ'), findsOneWidget);
    expect(find.text('รวมรายจ่าย'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('statistics-trend-income-total')))
          .data,
      '฿310.03',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('statistics-trend-total'))).data,
      '฿30.01',
    );
    expect(chart.data.maxY, greaterThan(200.02));
  });

  testWidgets(
    'income-only period renders and preserves monthly selection after edits',
    (tester) async {
      await tester.pumpWidget(
        _app([_record('income', 12345, TransactionType.income, 5)]),
      );
      expect(find.byKey(const Key('expense-trend-chart')), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('statistics-trend-income-total')),
            )
            .data,
        '฿123.45',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('statistics-trend-total')))
            .data,
        '฿0.00',
      );
      await tester.tap(find.byKey(const Key('trend-period-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('รายเดือน').last);
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _app([_record('income', 99999, TransactionType.income, 6)]),
      );
      await tester.pumpAndSettle();
      expect(find.text('รายเดือน'), findsOneWidget);
      final chart = tester.widget<BarChart>(
        find.byKey(const Key('expense-trend-chart')),
      );
      expect(chart.data.barGroups, hasLength(8));
      expect(chart.data.barGroups[4].barRods[0].toY, 0);
      expect(chart.data.barGroups[5].barRods[0].toY, 999.99);
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('statistics-trend-income-total')),
            )
            .data,
        '฿999.99',
      );
      await tester.pumpWidget(_app([]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expense-trend-chart')), findsNothing);
      expect(find.text('ยังไม่มีรายการในเดือนนี้'), findsOneWidget);
    },
  );

  testWidgets(
    'tooltips and accessible daily details identify both transaction types',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_app(records));
        final chart = tester.widget<BarChart>(
          find.byKey(const Key('expense-trend-chart')),
        );
        final group = chart.data.barGroups.first;
        final tooltip = chart.data.barTouchData.touchTooltipData.getTooltipItem;
        expect(
          tooltip(group, 0, group.barRods[0], 0)!.text,
          contains('รายรับ ฿110.01'),
        );
        expect(
          tooltip(group, 0, group.barRods[1], 1)!.text,
          contains('รายจ่าย ฿30.01'),
        );
        await tester.ensureVisible(find.text('ดูยอดรายวัน'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ดูยอดรายวัน'));
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(
            RegExp(r'5 ต\.ค\. 2026.*รายรับ.*110\.01.*รายจ่าย.*30\.01'),
          ),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'paired bars and large totals fit 320 pixels at double text scale',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app([
          _record('large-income', 99999999999, TransactionType.income, 5),
          _record('tiny-expense', 1, TransactionType.expense, 5),
        ], scale: 2),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final chart = tester.widget<BarChart>(
        find.byKey(const Key('expense-trend-chart')),
      );
      expect(chart.data.maxY, greaterThan(999999999.99));
      expect(chart.data.barGroups.first.barRods[1].toY, 0.01);
      await tester.ensureVisible(
        find.byKey(const Key('statistics-trend-income-total')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
