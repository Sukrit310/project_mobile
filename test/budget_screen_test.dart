// ตรวจการสลับเดือน สถานะซิงก์ ฟอร์มงบ และจอแคบ โดยควบคุมเวลาเครือข่ายในหน่วยความจำ
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app_theme.dart';
import 'package:project_moneymate/data/sample_transactions.dart';
import 'package:project_moneymate/models/budget_model.dart';
import 'package:project_moneymate/screens/budget_screen.dart';
import 'package:project_moneymate/services/budget_repository.dart';
import 'package:project_moneymate/services/demo_budget_repository.dart';

/// ใช้ส่ง snapshot หรือผลบันทึกตามเหตุการณ์ แทนการหน่วงเวลาแบบสุ่มในทดสอบ
class ControlledBudgets implements BudgetRepository {
  final streams = <DateTime, StreamController<BudgetFeed>>{};
  final attempts = <BudgetModel>[];
  Future<void> Function(BudgetModel)? onSave;
  @override
  Stream<BudgetFeed> watchBudget(DateTime month) => streams
      .putIfAbsent(
        DateTime(month.year, month.month),
        () => StreamController<BudgetFeed>.broadcast(),
      )
      .stream;
  void emit(DateTime month, BudgetFeed feed) => streams[month]!.add(feed);
  @override
  Future<void> saveBudget(BudgetModel budget) async {
    attempts.add(budget);
    await onSave?.call(budget);
  }

  Future<void> dispose() async {
    for (final controller in streams.values) {
      await controller.close();
    }
  }
}

final november = DateTime(2026, 11);
final december = DateTime(2026, 12);
Widget budgetApp(BudgetRepository repository, {double scale = 1}) =>
    MaterialApp(
      theme: buildAppTheme(),
      locale: const Locale('th'),
      supportedLocales: const [Locale('th'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: BudgetScreen(
        transactions: sampleTransactions,
        initialMonth: november,
        repository: repository,
        onAddTransaction: () {},
        onDestinationSelected: (_) {},
      ),
    );
Future<void> openEditor(WidgetTester tester) async {
  final edit = find.byKey(const Key('budget-edit'));
  await tester.ensureVisible(edit);
  await tester.tap(edit);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'switch clears previous snapshot and ignores late old-month data',
    (tester) async {
      final repository = ControlledBudgets();
      addTearDown(repository.dispose);
      await tester.pumpWidget(budgetApp(repository));
      repository.emit(
        november,
        BudgetFeed(budget: BudgetModel(month: november, limitSatang: 500000)),
      );
      await tester.pumpAndSettle();
      expect(find.text('฿5,000.00'), findsOneWidget);
      await tester.tap(find.byTooltip('เดือนถัดไป'));
      await tester.pump();
      expect(find.byKey(const Key('budget-limit')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repository.emit(
        november,
        BudgetFeed(budget: BudgetModel(month: november, limitSatang: 900000)),
      );
      await tester.pump();
      expect(find.text('฿9,000.00'), findsNothing);
      repository.emit(december, const BudgetFeed());
      await tester.pumpAndSettle();
      expect(find.text('ธันวาคม 2026'), findsOneWidget);
      expect(find.text('ยังไม่ได้ตั้งงบประมาณ'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('budget-spent'))).data,
        '฿0.00',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('budget-remaining'))).data,
        '—',
      );
    },
  );
  testWidgets(
    'read errors retry and metadata does not claim cloud confirmation',
    (tester) async {
      final repository = ControlledBudgets();
      addTearDown(repository.dispose);
      await tester.pumpWidget(budgetApp(repository));
      repository.streams[november]!.addError(StateError('permission-denied'));
      await tester.pumpAndSettle();
      expect(find.text('โหลดงบประมาณไม่สำเร็จ'), findsOneWidget);
      expect(find.text('งบประมาณ'), findsOneWidget);
      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pump();
      repository.emit(
        november,
        const BudgetFeed(hasPendingWrites: true, isFromCache: true),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('กำลังรอยืนยันการบันทึกงบประมาณจาก Firebase'),
        findsOneWidget,
      );
      expect(find.text('บันทึกงบประมาณแล้ว'), findsNothing);
      repository.emit(november, const BudgetFeed(isFromCache: true));
      await tester.pumpAndSettle();
      expect(
        find.text('แสดงงบประมาณในเครื่อง กำลังตรวจสอบกับ Firebase'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'editor preserves exact cents, rejects invalid input and saves same month',
    (tester) async {
      final repository = DemoBudgetRepository(
        initialBudgets: [BudgetModel(month: november, limitSatang: 500001)],
      );
      addTearDown(repository.dispose);
      await tester.pumpWidget(budgetApp(repository));
      await tester.pumpAndSettle();
      await openEditor(tester);
      final amount = find.byKey(const Key('budget-amount'));
      expect(tester.widget<TextFormField>(amount).controller!.text, '5000.01');
      await tester.enterText(amount, '12,000');
      await tester.tap(find.byKey(const Key('budget-save')));
      await tester.pumpAndSettle();
      expect(find.textContaining('กรอกตัวเลขบาท'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('budget-limit'))).data,
        '฿5,000.01',
      );
      await tester.enterText(amount, '4000.02');
      await tester.tap(find.byKey(const Key('budget-save')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('budget-limit'))).data,
        '฿4,000.02',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('budget-remaining'))).data,
        '฿500.02',
      );
    },
  );
  testWidgets('cancel leaves budget unset then valid new budget is created', (
    tester,
  ) async {
    final repository = DemoBudgetRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(budgetApp(repository));
    await tester.pumpAndSettle();
    await openEditor(tester);
    await tester.enterText(find.byKey(const Key('budget-amount')), '5000');
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('budget-limit'))).data,
      'ยังไม่กำหนดวงเงิน',
    );
    await openEditor(tester);
    await tester.enterText(find.byKey(const Key('budget-amount')), '0.01');
    await tester.tap(find.byKey(const Key('budget-save')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('budget-limit'))).data,
      '฿0.01',
    );
    expect(find.text('เกินงบแล้ว'), findsOneWidget);
  });
  testWidgets('failed and timeout saves retain input for retry to same month', (
    tester,
  ) async {
    final repository = ControlledBudgets();
    addTearDown(repository.dispose);
    repository.onSave = (_) async => throw StateError('denied');
    await tester.pumpWidget(budgetApp(repository));
    repository.emit(november, const BudgetFeed());
    await tester.pumpAndSettle();
    await openEditor(tester);
    final amount = find.byKey(const Key('budget-amount'));
    await tester.enterText(amount, '7000.25');
    await tester.tap(find.byKey(const Key('budget-save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('บันทึกงบประมาณไม่สำเร็จ'), findsOneWidget);
    expect(tester.widget<TextFormField>(amount).controller!.text, '7000.25');
    repository.onSave = (_) async => throw TimeoutException('unconfirmed');
    await tester.tap(find.byKey(const Key('budget-save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('ยังยืนยันการบันทึกไม่ได้'), findsOneWidget);
    expect(find.text('บันทึกงบประมาณแล้ว'), findsNothing);
    repository.onSave = (_) async {};
    await tester.tap(find.byKey(const Key('budget-save')));
    await tester.pumpAndSettle();
    expect(repository.attempts.map((budget) => budget.monthKey), [
      '2026-11',
      '2026-11',
      '2026-11',
    ]);
    expect(
      repository.attempts.every((budget) => budget.limitSatang == 700025),
      isTrue,
    );
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets(
    'pending save prevents repeated submission, field edits and back',
    (tester) async {
      final repository = ControlledBudgets();
      addTearDown(repository.dispose);
      final completion = Completer<void>();
      repository.onSave = (_) => completion.future;
      await tester.pumpWidget(budgetApp(repository));
      repository.emit(november, const BudgetFeed());
      await tester.pumpAndSettle();
      await openEditor(tester);
      await tester.enterText(find.byKey(const Key('budget-amount')), '9000');
      await tester.tap(find.byKey(const Key('budget-save')));
      await tester.pump();
      expect(repository.attempts.length, 1);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('budget-amount')))
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('budget-save')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'ยกเลิก'))
            .onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      completion.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
  testWidgets('late save closes only its dialog when a newer route covers it', (
    tester,
  ) async {
    final repository = ControlledBudgets();
    addTearDown(repository.dispose);
    final completion = Completer<void>();
    repository.onSave = (_) => completion.future;
    await tester.pumpWidget(budgetApp(repository));
    repository.emit(november, const BudgetFeed());
    await tester.pumpAndSettle();
    await openEditor(tester);
    await tester.enterText(find.byKey(const Key('budget-amount')), '5000');
    await tester.tap(find.byKey(const Key('budget-save')));
    await tester.pump();
    // push ทำได้แม้ PopScope ป้องกันการย้อนกลับอยู่ จึงต้องอ้าง route ของ dialog ให้ถูกตัว
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push<void>(
        MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('หน้าที่เปิดทับ'))),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    completion.complete();
    await tester.pumpAndSettle();
    expect(find.text('หน้าที่เปิดทับ'), findsOneWidget);
    expect(find.byType(AlertDialog, skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large amounts and editor fit320px at2x with keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final repository = DemoBudgetRepository(
      initialBudgets: [BudgetModel(month: november, limitSatang: 99999999999)],
    );
    addTearDown(repository.dispose);
    await tester.pumpWidget(budgetApp(repository, scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await openEditor(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('budget-amount')));
    await tester.enterText(find.byKey(const Key('budget-amount')), '0');
    await tester.ensureVisible(find.byKey(const Key('budget-save')));
    await tester.tap(find.byKey(const Key('budget-save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('จำนวนเงินต้องมากกว่า 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
