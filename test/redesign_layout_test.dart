// ตรวจองค์ประกอบ Dashboard จริงที่ขนาดโทรศัพท์/จอกว้างและตัวอักษรขยาย
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app_theme.dart';
import 'package:project_moneymate/data/sample_transactions.dart';
import 'package:project_moneymate/models/budget_model.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/screens/home.dart';
import 'package:project_moneymate/services/budget_repository.dart';

const capture = bool.fromEnvironment('CAPTURE_REDESIGN');

Future<void> saveFrame(WidgetTester tester, GlobalKey key, String name) async {
  if (!capture) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('build/$name.png').writeAsBytes(data!.buffer.asUint8List());
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
  for (final layout in [
    (size: const Size(320, 568), scale: 2.0),
    (size: const Size(401, 900), scale: 1.0),
    (size: const Size(1000, 900), scale: 1.0),
  ]) {
    testWidgets(
      'real dashboard fits ${layout.size} at ${layout.scale}x with working actions',
      (tester) async {
        tester.view.physicalSize = layout.size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final key = GlobalKey();
        TransactionType? type;
        int? destination;
        var additions = 0;
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              theme: buildAppTheme(),
              debugShowCheckedModeBanner: false,
              home: Home(
                transactions: sampleTransactions,
                referenceMonth: sampleReferenceMonth,
                budgetSnapshot: AsyncSnapshot.withData(
                  ConnectionState.active,
                  BudgetFeed(
                    budget: BudgetModel(
                      month: sampleReferenceMonth,
                      limitSatang: 500000,
                    ),
                  ),
                ),
                onAddTypedTransaction: (value) => type = value,
                onAddTransaction: () => additions++,
                onDestinationSelected: (value) => destination = value,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final suffix = '${layout.size.width.toInt()}-${layout.scale.toInt()}x';
        await saveFrame(tester, key, 'moneymate2-dashboard-top-$suffix');
        await tester.tap(find.text('เพิ่มรายการ'));
        expect(additions, 1);
        await tester.ensureVisible(find.text('เพิ่มรายรับ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('เพิ่มรายรับ'));
        expect(type, TransactionType.income);
        await tester.ensureVisible(find.text('เพิ่มรายจ่าย'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('เพิ่มรายจ่าย'));
        expect(type, TransactionType.expense);
        await tester.ensureVisible(find.text('ดูสถิติ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ดูสถิติ'));
        expect(destination, 2);
        await saveFrame(tester, key, 'moneymate2-dashboard-actions-$suffix');
        await tester.ensureVisible(find.text('ดูทั้งหมด'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ดูทั้งหมด'));
        expect(destination, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
