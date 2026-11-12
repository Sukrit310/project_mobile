// ทดสอบหน้าสถิติบนจอแคบ การข้ามปี และการเลือกเดือนที่ไม่มีรายการ

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app_theme.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/screens/statistics_screen.dart';

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  /// ครอบหน้าสถิติด้วยภาษาไทยและขนาดตัวอักษรที่เลือก เพื่อทดสอบ layout โดยตรง
  Widget app({
    required List<MoneyTransaction> transactions,
    DateTime? month,
    TextScaler scaler = TextScaler.noScaling,
  }) => MaterialApp(
    theme: buildAppTheme(),
    locale: const Locale('th'),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('th'), Locale('en')],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: child!,
    ),
    home: StatisticsScreen(
      transactions: transactions,
      initialMonth: month ?? DateTime(2026, 11),
      onAddTransaction: () {},
      onDestinationSelected: (_) {},
      notice: 'แสดงข้อมูลในเครื่อง กำลังตรวจสอบกับ Firebase',
    ),
  );

  testWidgets(
    'trend and insights update from edited and deleted monthly records',
    (tester) async {
      MoneyTransaction expense(String id, int satang, DateTime date) =>
          MoneyTransaction(
            id: id,
            title: id,
            amountSatang: satang,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            date: date,
          );
      final previous = expense('previous', 10000, DateTime(2024, 9, 1));
      final current = expense('current', 15000, DateTime(2024, 10, 2));
      await tester.pumpWidget(
        app(transactions: [previous, current], month: DateTime(2024, 10)),
      );
      await tester.ensureVisible(find.text('แนวโน้มรายรับรายจ่าย'));
      expect(find.byKey(const Key('expense-trend-chart')), findsOneWidget);
      expect(find.text('หมวดอาหารมีรายจ่ายสูงที่สุด'), findsOneWidget);
      expect(find.text('รายจ่ายเพิ่มขึ้น 50.0% จากเดือนก่อน'), findsOneWidget);

      await tester.pumpWidget(
        app(
          transactions: [
            previous,
            expense('current', 5000, DateTime(2024, 10, 3)),
          ],
          month: DateTime(2024, 10),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('รายจ่ายลดลง 50.0% จากเดือนก่อน'), findsOneWidget);

      await tester.pumpWidget(
        app(transactions: [previous], month: DateTime(2024, 10)),
      );
      await tester.pumpAndSettle();
      expect(find.text('ตุลาคม 2024'), findsOneWidget);
      expect(find.byKey(const Key('expense-trend-chart')), findsNothing);
      expect(find.text('ยังไม่มีรายการในสัปดาห์นี้'), findsOneWidget);
      expect(find.text('ยังมีข้อมูลไม่พอสำหรับเปรียบเทียบ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large money and large text remain scrollable on narrow screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(
          scaler: TextScaler.linear(2),
          transactions: [
            MoneyTransaction(
              id: 'large',
              title: 'รายจ่ายสูง',
              amountSatang: 99999999999,
              type: TransactionType.expense,
              category: TransactionCategory.housing,
              date: DateTime(2026, 11, 1),
            ),
            MoneyTransaction(
              id: 'tiny',
              title: 'รายจ่ายน้อย',
              amountSatang: 1,
              type: TransactionType.expense,
              category: TransactionCategory.food,
              date: DateTime(2026, 11, 2),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('รายรับและรายจ่าย'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text('แสดงข้อมูลในเครื่อง กำลังตรวจสอบกับ Firebase'),
        findsOneWidget,
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
    },
  );

  testWidgets(
    'month arrows cross year boundaries and empty months stay selectable',
    (tester) async {
      await tester.pumpWidget(app(transactions: [], month: DateTime(2026, 1)));
      await tester.pumpAndSettle();
      expect(find.text('มกราคม 2026'), findsOneWidget);
      await tester.tap(find.byTooltip('เดือนก่อนหน้า'));
      await tester.pumpAndSettle();
      expect(find.text('ธันวาคม 2025'), findsOneWidget);
      expect(find.text('ยังไม่มีรายการในเดือนนี้'), findsOneWidget);
      await tester.tap(find.byTooltip('เดือนถัดไป'));
      await tester.pumpAndSettle();
      expect(find.text('มกราคม 2026'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('statistics-income'))).data,
        '฿0.00',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('statistics-net'))).data,
        '฿0.00',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
