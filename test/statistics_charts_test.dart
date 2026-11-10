// ทดสอบกราฟรายจ่ายและรายรับ รวมข้อมูลว่าง สีหมวดหมู่ การเข้าถึง และตัวอักษรขนาดใหญ่

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app_theme.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/widgets/expense_chart.dart';
import 'package:project_moneymate/widgets/income_expense_chart.dart';

/// พื้นที่ทดสอบกราฟที่เลื่อนได้และกำหนดขนาดตัวอักษรเพื่อเช็กการเข้าถึง
Widget chartHost(Widget chart, {double textScale = 1}) => MaterialApp(
  theme: buildAppTheme(),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: chart),
      ),
    ),
  ),
);

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  testWidgets('empty expenses have a readable state without zero pie slices', (
    tester,
  ) async {
    await tester.pumpWidget(
      chartHost(
        const ExpenseChart(
          expensesByCategory: {
            TransactionCategory.food: 0,
            TransactionCategory.other: -1,
          },
        ),
      ),
    );
    expect(find.text('ยังไม่มีรายจ่ายในเดือนนี้'), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'expense legend retains all positive categories and exact money',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          chartHost(
            const ExpenseChart(
              expensesByCategory: {
                TransactionCategory.other: 0,
                TransactionCategory.salary: 1,
                TransactionCategory.housing: 4999,
                TransactionCategory.food: 5000,
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('อาหาร'), findsOneWidget);
        expect(find.text('เงินเดือน'), findsOneWidget);
        expect(find.text('ที่อยู่อาศัย'), findsOneWidget);
        expect(find.text('อื่น ๆ'), findsNothing);
        expect(find.text('฿0.01'), findsOneWidget);
        expect(find.text('฿49.99'), findsOneWidget);
        expect(find.text('฿50'), findsOneWidget);
        expect(find.text('<0.1%'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('เงินเดือน.*0.01.*0.1%')),
          findsOneWidget,
        );
        final data = tester.widget<PieChart>(find.byType(PieChart)).data;
        expect(data.sections.map((slice) => slice.value), [5000, 1, 4999]);
        expect(data.sections[1].showTitle, isFalse);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('expense updates preserve category colors and replace values', (
    tester,
  ) async {
    await tester.pumpWidget(
      chartHost(
        const ExpenseChart(
          expensesByCategory: {
            TransactionCategory.food: 100,
            TransactionCategory.salary: 300,
          },
        ),
      ),
    );
    final firstData = tester.widget<PieChart>(find.byType(PieChart)).data;
    final salaryColor = firstData.sections[1].color;
    await tester.pumpWidget(
      chartHost(
        const ExpenseChart(
          expensesByCategory: {TransactionCategory.salary: 555},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final updatedData = tester.widget<PieChart>(find.byType(PieChart)).data;
    expect(updatedData.sections.single.value, 555);
    expect(updatedData.sections.single.color, salaryColor);
    expect(find.text('฿5.55'), findsOneWidget);
    expect(find.text('อาหาร'), findsNothing);
    await tester.pumpWidget(
      chartHost(const ExpenseChart(expensesByCategory: {})),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PieChart), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('both-zero comparison keeps a finite scale and two zero bars', (
    tester,
  ) async {
    await tester.pumpWidget(
      chartHost(const IncomeExpenseChart(incomeSatang: 0, expenseSatang: 0)),
    );
    await tester.pumpAndSettle();
    final data = tester.widget<BarChart>(find.byType(BarChart)).data;
    expect(data.maxY.isFinite, isTrue);
    expect(data.maxY, greaterThan(0));
    expect(data.barGroups.map((group) => group.barRods.single.toY), [0, 0]);
    expect(find.text('รายรับ'), findsOneWidget);
    expect(find.text('รายจ่าย'), findsOneWidget);
    expect(find.text('฿0'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final values in [(1, 0), (0, 2), (12345, 6789)]) {
    testWidgets('comparison preserves satang for ${values.$1}/${values.$2}', (
      tester,
    ) async {
      await tester.pumpWidget(
        chartHost(
          IncomeExpenseChart(incomeSatang: values.$1, expenseSatang: values.$2),
        ),
      );
      await tester.pumpAndSettle();
      final data = tester.widget<BarChart>(find.byType(BarChart)).data;
      expect(data.minY, 0);
      expect(data.barGroups[0].barRods.single.toY, values.$1 / 100);
      expect(data.barGroups[1].barRods.single.toY, values.$2 / 100);
      expect(data.barGroups[0].barRods.single.color, AppColors.income);
      expect(data.barGroups[1].barRods.single.color, AppColors.expense);
      expect(data.maxY.isFinite, isTrue);
      expect(data.maxY, greaterThanOrEqualTo(values.$1 / 100));
      expect(data.maxY, greaterThanOrEqualTo(values.$2 / 100));
      if (values.$1 == 1) {
        expect(find.text('฿0.01'), findsOneWidget);
      } else if (values.$2 == 2) {
        expect(find.text('฿0.02'), findsOneWidget);
      } else {
        expect(find.text('฿123.45'), findsOneWidget);
        expect(find.text('฿67.89'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'comparison replaces old values when the selected month changes',
    (tester) async {
      await tester.pumpWidget(
        chartHost(
          const IncomeExpenseChart(incomeSatang: 10000, expenseSatang: 5000),
        ),
      );
      await tester.pumpWidget(
        chartHost(const IncomeExpenseChart(incomeSatang: 1, expenseSatang: 0)),
      );
      await tester.pumpAndSettle();
      final data = tester.widget<BarChart>(find.byType(BarChart)).data;
      expect(data.barGroups.map((group) => group.barRods.single.toY), [
        0.01,
        0,
      ]);
      expect(find.text('฿100'), findsNothing);
      expect(find.text('฿0.01'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all labels fit 320 pixels at double text size without clipping',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        chartHost(
          const Column(
            children: [
              ExpenseChart(
                expensesByCategory: {
                  TransactionCategory.food: 999999999999,
                  TransactionCategory.salary: 1,
                  TransactionCategory.housing: 5,
                  TransactionCategory.other: 7,
                },
              ),
              IncomeExpenseChart(incomeSatang: 999999999999, expenseSatang: 1),
            ],
          ),
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('฿9,999,999,999.99'), findsNWidgets(2));
      await tester.ensureVisible(find.text('รายจ่าย'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsOneWidget);
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        expect(text.maxLines, isNull);
        expect(text.overflow, isNot(TextOverflow.ellipsis));
      }
    },
  );
}
