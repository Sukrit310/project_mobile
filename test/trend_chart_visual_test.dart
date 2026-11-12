// ตรวจกราฟด้วยฟอนต์จริงทั้งสองช่วงเวลา และสร้างภาพตรวจได้โดยไม่ใช้ข้อมูล Firebase
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app_theme.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/widgets/trend_chart.dart';

const _capture = bool.fromEnvironment('CAPTURE_TREND');

Future<void> _save(WidgetTester tester, GlobalKey key, String name) async {
  if (!_capture) return;
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
    (width: 401.0, scale: 1.0),
    (width: 320.0, scale: 2.0),
  ]) {
    testWidgets(
      'bar periods render with real Thai fonts at ${layout.width}/${layout.scale}x',
      (tester) async {
        tester.view.physicalSize = Size(layout.width, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final records = [
          for (var index = 0; index < 7; index++)
            MoneyTransaction(
              id: '$index',
              title: 'ทดสอบ $index',
              amountSatang: [
                25000,
                45000,
                33000,
                75000,
                65000,
                40000,
                50000,
              ][index],
              type: TransactionType.expense,
              category: TransactionCategory.food,
              date: DateTime(2026, 10, 26 + index),
            ),
          for (var index = 0; index < 7; index++)
            MoneyTransaction(
              id: 'income-$index',
              title: 'รายรับทดสอบ $index',
              amountSatang: [
                50000,
                65000,
                42000,
                88000,
                70000,
                54000,
                35000,
              ][index],
              type: TransactionType.income,
              category: TransactionCategory.salary,
              date: DateTime(2026, 10, 26 + index),
            ),
        ];
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: RepaintBoundary(
                  key: key,
                  child: TrendChart(
                    transactions: records,
                    month: DateTime(2026, 10),
                    today: DateTime(2026, 10, 31),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        var chart = tester.widget<BarChart>(
          find.byKey(const Key('expense-trend-chart')),
        );
        expect(chart.data.barGroups[3].barRods[1].color, AppColors.primary);
        expect(
          chart.data.barGroups[0].barRods[0].color,
          isNot(AppColors.primary),
        );
        await _save(
          tester,
          key,
          'moneymate-weekly-trend-${layout.width.toInt()}',
        );
        await tester.tap(find.byKey(const Key('trend-period-selector')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('รายเดือน').last);
        await tester.pumpAndSettle();
        chart = tester.widget<BarChart>(
          find.byKey(const Key('expense-trend-chart')),
        );
        expect(chart.data.barGroups, hasLength(31));
        expect(find.text('30'), findsNothing);
        expect(find.text('31'), findsOneWidget);
        if (layout.scale == 2) expect(find.text('5'), findsNothing);
        expect(
          chart.data.barGroups.every((group) => group.barRods.length == 2),
          isTrue,
        );
        expect(chart.data.barGroups[28].barRods[0].toY, 880);
        expect(chart.data.barGroups[28].barRods[1].toY, 750);
        expect(tester.takeException(), isNull);
        await _save(
          tester,
          key,
          'moneymate-monthly-trend-${layout.width.toInt()}',
        );
      },
    );
  }
}
