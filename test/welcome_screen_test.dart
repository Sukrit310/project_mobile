// ตรวจหน้าแรกใหม่ การเข้า flow เดิม และการจัดวางโดยไม่เปลี่ยนหน้าจออื่น
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app.dart';
import 'package:project_moneymate/app/firebase_bootstrap.dart';
import 'package:project_moneymate/models/budget_model.dart';
import 'package:project_moneymate/screens/dashboard_screen.dart';
import 'package:project_moneymate/services/demo_budget_repository.dart';
import 'package:project_moneymate/services/demo_transaction_repository.dart';
import 'package:project_moneymate/services/transaction_repository.dart';

class _CountingRepository extends DemoTransactionRepository {
  int watches = 0;
  @override
  Stream<TransactionFeed> watchTransactions() {
    watches++;
    return super.watchTransactions();
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_WELCOME')) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('build/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'NotoSansThai',
    )..addFont(rootBundle.load('assets/fonts/NotoSansThai.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets(
    'Welcome starts before either repository or Firebase is mounted',
    (tester) async {
      final repository = _CountingRepository();
      final budgets = DemoBudgetRepository(
        initialBudgets: [
          BudgetModel(month: DateTime(2026, 11), limitSatang: 43210),
        ],
      );
      addTearDown(repository.dispose);
      addTearDown(budgets.dispose);
      final month = DateTime(2026, 11, 20);
      await tester.pumpWidget(
        MyApp(
          repository: repository,
          budgetRepository: budgets,
          referenceMonth: month,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('เริ่มต้นใช้งาน'), findsOneWidget);
      expect(find.text('MoneyMate'), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
      expect(find.byType(FirebaseBootstrap), findsNothing);
      expect(repository.watches, 0);

      await tester.tap(find.text('เริ่มต้นใช้งาน'));
      await tester.pumpAndSettle();
      final dashboard = tester.widget<DashboardScreen>(
        find.byType(DashboardScreen),
      );
      expect(dashboard.repository, same(repository));
      expect(dashboard.budgetRepository, same(budgets));
      expect(dashboard.referenceMonth, month);
      expect(repository.watches, 1);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('dashboard-budget-limit')))
            .data,
        '฿432.10',
      );
      expect(find.text('เริ่มต้นใช้งาน'), findsNothing);
      for (final label in ['หน้าหลัก', 'ประวัติ', 'สถิติ', 'งบประมาณ']) {
        expect(find.text(label), findsOneWidget);
      }
    },
  );

  testWidgets(
    'starting keeps a single root route and Back cannot restore Welcome',
    (tester) async {
      final repository = _CountingRepository();
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        MyApp(repository: repository, referenceMonth: DateTime(2026, 11)),
      );
      expect(find.text('เริ่มต้นใช้งาน'), findsOneWidget);
      await tester.tap(find.text('เริ่มต้นใช้งาน'));
      await tester.pumpAndSettle();
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
      expect(await navigator.maybePop(), isFalse);
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('เริ่มต้นใช้งาน'), findsNothing);
    },
  );

  testWidgets('fresh app launch shows Welcome again without persisted state', (
    tester,
  ) async {
    final repository = _CountingRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      MyApp(repository: repository, referenceMonth: DateTime(2026, 11)),
    );
    expect(find.text('เริ่มต้นใช้งาน'), findsOneWidget);
    await tester.tap(find.text('เริ่มต้นใช้งาน'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MyApp(repository: repository, referenceMonth: DateTime(2026, 11)),
    );
    await tester.pumpAndSettle();
    expect(find.text('เริ่มต้นใช้งาน'), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
  });

  testWidgets(
    'default start preserves Firebase error retry and explicit demo entry',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();
        expect(find.text('เริ่มต้นใช้งาน'), findsOneWidget);
        expect(find.byType(FirebaseBootstrap), findsNothing);
        expect(find.text('ยังเชื่อมต่อ Firebase ไม่สำเร็จ'), findsNothing);
        await tester.tap(find.text('เริ่มต้นใช้งาน'));
        await tester.pumpAndSettle();
        expect(find.byType(FirebaseBootstrap), findsOneWidget);
        expect(find.text('ยังเชื่อมต่อ Firebase ไม่สำเร็จ'), findsOneWidget);
        expect(find.text('ลองอีกครั้ง'), findsOneWidget);
        await tester.tap(find.text('ทดลองด้วยข้อมูลตัวอย่าง'));
        await tester.pumpAndSettle();
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.textContaining('โหมดตัวอย่าง'), findsOneWidget);
        expect(find.text('เริ่มต้นใช้งาน'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  for (final layout in [
    (size: const Size(320, 568), scale: 1.0),
    (size: const Size(320, 568), scale: 2.0),
    (size: const Size(401, 900), scale: 1.0),
    (size: const Size(900, 400), scale: 1.0),
    (size: const Size(568, 320), scale: 2.0),
  ]) {
    testWidgets(
      'Welcome fits ${layout.size} at ${layout.scale}x and its button stays reachable',
      (tester) async {
        tester.view.physicalSize = layout.size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final repository = _CountingRepository();
        addTearDown(repository.dispose);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MyApp(repository: repository),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('เริ่มต้นใช้งาน'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final suffix =
            '${layout.size.width.toInt()}x${layout.size.height.toInt()}-${layout.scale.toInt()}x';
        await _capture(tester, key, 'moneymate-welcome-$suffix');
        if (layout.scale == 1 && layout.size.width < layout.size.height) {
          expect(find.text('เริ่มต้นใช้งาน').hitTestable(), findsOneWidget);
        }
        await tester.ensureVisible(find.text('เริ่มต้นใช้งาน'));
        await tester.pumpAndSettle();
        expect(find.text('เริ่มต้นใช้งาน').hitTestable(), findsOneWidget);
        expect(
          tester
              .getSize(find.widgetWithText(FilledButton, 'เริ่มต้นใช้งาน'))
              .height,
          greaterThanOrEqualTo(48),
        );
        expect(repository.watches, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
