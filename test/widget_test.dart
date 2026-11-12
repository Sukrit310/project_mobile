// ทดสอบหน้าหลักตัวอย่าง ยอด รายการล่าสุด การเชื่อม callback และขนาดหน้าจอ

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app_theme.dart';
import 'package:project_moneymate/screens/home.dart';

/// เปิด Home แบบตัวอย่างเดี่ยว จึงทดสอบข้อความทางลัดแยกจากเส้นทาง MyApp จริง
Widget dashboard({VoidCallback? onAdd, ValueChanged<int>? onNavigate}) =>
    MaterialApp(
      theme: buildAppTheme(),
      home: Home(onAddTransaction: onAdd, onDestinationSelected: onNavigate),
    );

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  testWidgets(
    'shows consistent demo totals and up to five newest transactions',
    (tester) async {
      await tester.pumpWidget(dashboard());

      expect(find.text('MoneyMate'), findsOneWidget);
      expect(find.text('฿8,500.00'), findsOneWidget);
      expect(find.text('+฿12,000'), findsNWidgets(2));
      expect(find.text('-฿3,500'), findsOneWidget);
      expect(find.text('-฿80'), findsOneWidget);
      expect(find.text('พฤศจิกายน 2026'), findsOneWidget);
      expect(find.text('8 พ.ย. 2026'), findsOneWidget);
      expect(find.text('1 พ.ย. 2026'), findsNWidgets(2));
      expect(
        tester.getTopLeft(find.text('ค่าอาหาร')).dy,
        lessThan(tester.getTopLeft(find.text('เงินเดือน')).dy),
      );
      expect(find.text('ค่าที่พัก'), findsOneWidget);
    },
  );

  testWidgets('add button forwards its real callback', (tester) async {
    var additions = 0;
    await tester.pumpWidget(dashboard(onAdd: () => additions++));
    await tester.ensureVisible(find.text('เพิ่มรายการ'));
    await tester.tap(find.text('เพิ่มรายการ'));
    await tester.pump();

    expect(additions, 1);
  });

  testWidgets('standalone Home hides actions without working callbacks', (
    tester,
  ) async {
    await tester.pumpWidget(dashboard());
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('เพิ่มรายการ'), findsNothing);
    expect(find.text('เพิ่มรายรับ'), findsNothing);
    expect(find.text('ตั้งงบประมาณ'), findsNothing);
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

      await tester.pumpWidget(dashboard(onAdd: () {}, onNavigate: (_) {}));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('เพิ่มรายการ'));
      await tester.pump();
      expect(find.text('เพิ่มรายการ').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
