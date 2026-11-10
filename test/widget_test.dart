// ทดสอบหน้าหลักตัวอย่างแบบเดี่ยว ทั้งยอด รายการล่าสุด ข้อความทางลัด และขนาดหน้าจอ

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app_theme.dart';
import 'package:project_moneymate/screens/home.dart';

/// เปิด Home แบบตัวอย่างเดี่ยว จึงทดสอบข้อความทางลัดแยกจากเส้นทาง MyApp จริง
Widget dashboard() => MaterialApp(theme: buildAppTheme(), home: const Home());

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  testWidgets('shows consistent demo totals and the two newest transactions', (
    tester,
  ) async {
    await tester.pumpWidget(dashboard());

    expect(find.text('MoneyMate'), findsOneWidget);
    expect(find.text('฿8,500.00'), findsOneWidget);
    expect(find.text('+฿12,000'), findsNWidgets(2));
    expect(find.text('-฿3,500'), findsOneWidget);
    expect(find.text('-฿80'), findsOneWidget);
    expect(find.text('พฤศจิกายน 2026'), findsOneWidget);
    expect(find.text('8 พ.ย. 2026'), findsOneWidget);
    expect(find.text('1 พ.ย. 2026'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('ค่าอาหาร')).dy,
      lessThan(tester.getTopLeft(find.text('เงินเดือน')).dy),
    );
    expect(find.text('ค่าที่พัก'), findsNothing);
  });

  testWidgets('add button explains that the form is the next step', (
    tester,
  ) async {
    await tester.pumpWidget(dashboard());
    await tester.ensureVisible(find.text('เพิ่มรายการ'));
    await tester.tap(find.text('เพิ่มรายการ'));
    await tester.pump();

    expect(find.text('ฟอร์มเพิ่มรายการจะพร้อมในขั้นตอนถัดไป'), findsOneWidget);
  });

  testWidgets('future navigation explains its status and keeps Home selected', (
    tester,
  ) async {
    await tester.pumpWidget(dashboard());
    await tester.tap(find.text('ประวัติ'));
    await tester.pump();

    expect(find.text('หน้าประวัติจะพร้อมในขั้นตอนถัดไป'), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      0,
    );
  });

  for (final size in [const Size(401, 577), const Size(320, 568)]) {
    testWidgets('Dashboard fits $size with large text and scrolls to actions', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(dashboard());
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('เพิ่มรายการ'));
      await tester.pump();
      expect(find.text('เพิ่มรายการ').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
