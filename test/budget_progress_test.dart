// ทดสอบยอดงบประมาณและข้อความเตือนที่ผู้ใช้เห็น รวมถึงขอบเขตสตางค์จริง
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app_theme.dart';
import 'package:project_moneymate/models/budget_summary.dart';
import 'package:project_moneymate/widgets/budget_progress.dart';

// ใช้กรอบเลื่อนและธีมเดียวกับหน้าจอจริง เพื่อทดสอบตัวอักษรขนาดใหญ่ได้
Widget progressHost(Widget child, {double textScale = 1}) => MaterialApp(
  theme: buildAppTheme(),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);

void main() {
  group('BudgetSummary', () {
    test('rejects negative inputs through runtime validation', () {
      expect(
        () => BudgetSummary(limitSatang: -1, expenseSatang: 0),
        throwsArgumentError,
      );
      expect(
        () => BudgetSummary(limitSatang: 0, expenseSatang: -1),
        throwsArgumentError,
      );
    });

    test('zero limit stays unset even when the month has expenses', () {
      final empty = BudgetSummary(limitSatang: 0, expenseSatang: 0);
      expect(empty.hasBudget, isFalse);
      expect(empty.remainingSatang, 0);
      expect(empty.usedPercentage, 0);
      expect(empty.progressValue, 0);
      expect(empty.isAtLimit, isFalse);
      expect(empty.isNearLimit, isFalse);
      expect(empty.isOverBudget, isFalse);

      final spent = BudgetSummary(limitSatang: 0, expenseSatang: 1);
      expect(spent.hasBudget, isFalse);
      expect(spent.remainingSatang, -1);
      expect(spent.usedPercentage, 0);
      expect(spent.progressValue, 0);
      expect(spent.isAtLimit, isFalse);
      expect(spent.isNearLimit, isFalse);
      expect(spent.isOverBudget, isFalse);
    });

    test('one satang has distinct available, exact and exceeded states', () {
      final available = BudgetSummary(limitSatang: 1, expenseSatang: 0);
      expect(available.hasBudget, isTrue);
      expect(available.remainingSatang, 1);
      expect(available.isAtLimit, isFalse);
      expect(available.isNearLimit, isFalse);
      expect(available.isOverBudget, isFalse);

      final exact = BudgetSummary(limitSatang: 1, expenseSatang: 1);
      expect(exact.remainingSatang, 0);
      expect(exact.usedPercentage, 100);
      expect(exact.progressValue, 1);
      expect(exact.isAtLimit, isTrue);
      expect(exact.isNearLimit, isFalse);
      expect(exact.isOverBudget, isFalse);

      final exceeded = BudgetSummary(limitSatang: 1, expenseSatang: 2);
      expect(exceeded.remainingSatang, -1);
      expect(exceeded.usedPercentage, 200);
      expect(exceeded.progressValue, 1);
      expect(exceeded.isAtLimit, isFalse);
      expect(exceeded.isNearLimit, isFalse);
      expect(exceeded.isOverBudget, isTrue);
    });

    test('warning starts at exactly 80 percent and excludes full spending', () {
      expect(
        BudgetSummary(limitSatang: 10000, expenseSatang: 7999).isNearLimit,
        isFalse,
      );
      final warning = BudgetSummary(limitSatang: 10000, expenseSatang: 8000);
      expect(warning.isNearLimit, isTrue);
      expect(warning.usedPercentage, 80);
      expect(warning.progressValue, 0.8);
      expect(
        BudgetSummary(limitSatang: 10000, expenseSatang: 9999).isNearLimit,
        isTrue,
      );
      expect(
        BudgetSummary(limitSatang: 10000, expenseSatang: 10000).isNearLimit,
        isFalse,
      );
      expect(
        BudgetSummary(limitSatang: 10000, expenseSatang: 10001).isNearLimit,
        isFalse,
      );
      expect(
        BudgetSummary(limitSatang: 6, expenseSatang: 4).isNearLimit,
        isFalse,
      );
      expect(
        BudgetSummary(limitSatang: 6, expenseSatang: 5).isNearLimit,
        isTrue,
      );
    });

    test('large integer status does not use rounded ratios or overflow', () {
      const limit = 9223372036854775807;
      final nearlyFull = BudgetSummary(
        limitSatang: limit,
        expenseSatang: 9223372036854775806,
      );
      expect(nearlyFull.remainingSatang, 1);
      expect(nearlyFull.isAtLimit, isFalse);
      expect(nearlyFull.isNearLimit, isTrue);
      expect(nearlyFull.isOverBudget, isFalse);
      expect(nearlyFull.progressValue.isFinite, isTrue);
      expect(
        BudgetSummary(
          limitSatang: limit,
          expenseSatang: 7378697629483820645,
        ).isNearLimit,
        isFalse,
      );
      expect(
        BudgetSummary(
          limitSatang: limit,
          expenseSatang: 7378697629483820646,
        ).isNearLimit,
        isTrue,
      );
      final largeExpense = BudgetSummary(limitSatang: 1, expenseSatang: limit);
      expect(largeExpense.usedPercentage, greaterThan(100));
      expect(largeExpense.usedPercentage.isFinite, isTrue);
      expect(largeExpense.progressValue, 1);
      expect(largeExpense.remainingSatang, -9223372036854775806);
    });
  });

  for (final state in [
    (0, 1, 'ยังไม่ได้ตั้งงบประมาณ', 0.0),
    (10000, 7999, 'ยังอยู่ในงบ', 0.7999),
    (10000, 8000, 'ใกล้ถึงวงเงิน', 0.8),
    (1, 1, 'ใช้ครบวงเงินแล้ว', 1.0),
    (1, 2, 'เกินงบแล้ว', 1.0),
  ]) {
    testWidgets('renders Thai budget state ${state.$3}', (tester) async {
      await tester.pumpWidget(
        progressHost(
          BudgetProgress(limitSatang: state.$1, expenseSatang: state.$2),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(state.$3), findsOneWidget);
      final progress = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('budget-progress')),
      );
      expect(progress.value, state.$4);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('over-budget percentage and exact money reach accessibility', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        progressHost(
          const BudgetProgress(limitSatang: 10000, expenseSatang: 15001),
        ),
      );
      expect(find.text('ใช้ไป 150.01% ของงบประมาณ'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp('เกินงบแล้ว.*100.00.*150.01.*-.*50.01.*150.01%'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        1,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('one satang over budget never displays a rounded 100 percent', (
    tester,
  ) async {
    await tester.pumpWidget(
      progressHost(
        const BudgetProgress(limitSatang: 10000, expenseSatang: 10001),
      ),
    );
    expect(find.text('เกินงบแล้ว'), findsOneWidget);
    expect(find.text('ใช้ไป 100.01% ของงบประมาณ'), findsOneWidget);
  });

  testWidgets(
    'zero-budget semantics include spending without claiming a ratio',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          progressHost(const BudgetProgress(limitSatang: 0, expenseSatang: 1)),
        );
        expect(
          find.bySemanticsLabel(RegExp('ยังไม่ได้ตั้งงบประมาณ.*0.01')),
          findsOneWidget,
        );
        final announcement = tester
            .getSemantics(find.byType(BudgetProgress))
            .label;
        expect(announcement, contains('รายจ่าย ฿0.01'));
        expect(announcement, isNot(contains('คงเหลือ')));
        expect(announcement, isNot(contains('วงเงิน')));
        expect(find.textContaining('NaN'), findsNothing);
        expect(find.textContaining('Infinity'), findsNothing);
        expect(find.textContaining('ใช้ไป'), findsNothing);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('updates replace the old state, percentage and progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      progressHost(
        const BudgetProgress(limitSatang: 10000, expenseSatang: 1000),
      ),
    );
    expect(find.text('ยังอยู่ในงบ'), findsOneWidget);
    await tester.pumpWidget(
      progressHost(
        const BudgetProgress(limitSatang: 10000, expenseSatang: 12000),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ยังอยู่ในงบ'), findsNothing);
    expect(find.text('เกินงบแล้ว'), findsOneWidget);
    expect(find.text('ใช้ไป 120% ของงบประมาณ'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1,
    );
  });

  testWidgets('all states fit 320 pixels at double text scale', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      progressHost(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BudgetProgress(limitSatang: 0, expenseSatang: 1),
            BudgetProgress(limitSatang: 10000, expenseSatang: 1),
            BudgetProgress(limitSatang: 10000, expenseSatang: 8000),
            BudgetProgress(limitSatang: 10000, expenseSatang: 10000),
            BudgetProgress(limitSatang: 1, expenseSatang: 999999999999),
          ],
        ),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('เกินงบแล้ว'), findsOneWidget);
    await tester.ensureVisible(find.text('เกินงบแล้ว'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    }
  });
}
