// ทดสอบหน้าประวัติ: ตัวกรอง การยืนยันลบ การป้องกันกดซ้ำ และการแสดงผลจอแคบ

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app_theme.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/screens/history_screen.dart';

final november = DateTime(2026, 11);
final coffee = MoneyTransaction(
  id: 'coffee',
  title: 'Coffee',
  amountSatang: 8005,
  type: TransactionType.expense,
  category: TransactionCategory.food,
  date: DateTime(2026, 11, 10, 9),
);
final salary = MoneyTransaction(
  id: 'salary',
  title: 'Salary',
  amountSatang: 200000,
  type: TransactionType.income,
  category: TransactionCategory.salary,
  date: DateTime(2026, 11, 9, 12),
);
final oldCoffee = MoneyTransaction(
  id: 'old',
  title: 'Old coffee',
  amountSatang: 5000,
  type: TransactionType.expense,
  category: TransactionCategory.food,
  date: DateTime(2025, 11, 10),
);

/// ครอบหน้าประวัติด้วยธีมจริง แต่ฉีด callback จำลองเพื่อสังเกตคำสั่งแก้ไขและลบ
Widget history({
  List<MoneyTransaction>? transactions,
  Future<void> Function(MoneyTransaction)? edit,
  Future<void> Function(MoneyTransaction)? delete,
  String? notice,
}) => MaterialApp(
  theme: buildAppTheme(),
  home: HistoryScreen(
    transactions: transactions ?? [salary, oldCoffee, coffee],
    initialMonth: november,
    onEditTransaction: edit ?? (_) async {},
    onDeleteTransaction: delete ?? (_) async {},
    onAddTransaction: () {},
    onDestinationSelected: (_) {},
    notice: notice,
  ),
);

/// เลื่อนไปยังเมนูของ ID เป้าหมายก่อนเปิด เพื่อให้ทดสอบแถวที่อยู่นอกจอได้
Future<void> openActions(WidgetTester tester, String id) async {
  final actions = find.byKey(Key('history-actions-$id'));
  await tester.ensureVisible(actions);
  await tester.tap(actions);
  await tester.pumpAndSettle();
}

/// เปิดกล่องยืนยันเท่านั้น เพื่อให้แต่ละกรณีเลือกยืนยันหรือยกเลิกเอง
Future<void> askToDelete(WidgetTester tester, String id) async {
  await openActions(tester, id);
  await tester.tap(find.text('ลบ'));
  await tester.pumpAndSettle();
}

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  testWidgets('initial month displays ordered rows and exact filtered totals', (
    tester,
  ) async {
    await tester.pumpWidget(history(notice: 'กำลังตรวจสอบข้อมูล'));
    expect(find.text('ประวัติรายการ'), findsOneWidget);
    expect(find.text('กำลังตรวจสอบข้อมูล'), findsOneWidget);
    expect(find.text('2 รายการ'), findsOneWidget);
    expect(find.text('฿2,000'), findsOneWidget);
    expect(find.text('฿80.05'), findsOneWidget);
    expect(find.byKey(const Key('history-row-old')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('history-row-salary')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('history-row-coffee'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('history-row-salary'))).dy,
      ),
    );
    expect(find.text('10 พ.ย. 2026'), findsWidgets);
    expect(find.text('9 พ.ย. 2026'), findsWidgets);
  });

  testWidgets('month, type and title filters update totals and empty state', (
    tester,
  ) async {
    await tester.pumpWidget(history());
    await tester.tap(find.byKey(const Key('history-month')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ทุกเดือน').last);
    await tester.pumpAndSettle();
    expect(find.text('3 รายการ'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'รายจ่าย'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('history-search')),
      '  OLD COF  ',
    );
    await tester.pumpAndSettle();
    expect(find.text('1 รายการ'), findsOneWidget);
    expect(find.text('฿50'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('history-search')), 'missing');
    await tester.pumpAndSettle();
    expect(find.text('ไม่พบรายการที่ตรงกับตัวกรอง'), findsOneWidget);
    expect(find.text('0 รายการ'), findsOneWidget);
  });

  testWidgets('selected recorded month survives the last record disappearing', (
    tester,
  ) async {
    await tester.pumpWidget(history());
    await tester.tap(find.byKey(const Key('history-month')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('พฤศจิกายน 2025').last);
    await tester.pumpAndSettle();
    expect(find.text('1 รายการ'), findsOneWidget);
    await tester.pumpWidget(history(transactions: [salary, coffee]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('พฤศจิกายน 2025'), findsOneWidget);
    expect(find.text('0 รายการ'), findsOneWidget);
  });

  testWidgets(
    'edit receives the original record and cancelling delete changes nothing',
    (tester) async {
      MoneyTransaction? edited;
      var deletes = 0;
      await tester.pumpWidget(
        history(
          edit: (item) async => edited = item,
          delete: (_) async => deletes++,
        ),
      );
      await openActions(tester, 'coffee');
      await tester.tap(find.text('แก้ไข'));
      await tester.pumpAndSettle();
      expect(identical(edited, coffee), isTrue);
      await askToDelete(tester, 'coffee');
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('Coffee'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('฿80.05'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();
      expect(deletes, 0);
      expect(find.byKey(const Key('history-row-coffee')), findsOneWidget);
      expect(find.text('ลบรายการแล้ว'), findsNothing);
    },
  );

  testWidgets('delete awaits acknowledgement and blocks duplicate actions', (
    tester,
  ) async {
    // ควบคุมจังหวะตอบรับให้เห็นว่าหน้ายังไม่ประกาศลบสำเร็จระหว่างรอ
    final acknowledgement = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      history(
        delete: (item) {
          expect(identical(item, coffee), isTrue);
          calls++;
          return acknowledgement.future;
        },
      ),
    );
    await askToDelete(tester, 'coffee');
    await tester.tap(find.text('ลบรายการ'));
    await tester.pump();
    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<PopupMenuButton>(
      find.byKey(const Key('history-actions-coffee')),
    );
    expect(button.enabled, isFalse);
    expect(find.text('ลบรายการแล้ว'), findsNothing);
    acknowledgement.complete();
    await tester.pumpAndSettle();
    expect(find.text('ลบรายการแล้ว'), findsOneWidget);
    expect(find.byKey(const Key('history-row-coffee')), findsOneWidget);
  });

  testWidgets('failed deletion preserves rows and offers connection guidance', (
    tester,
  ) async {
    await tester.pumpWidget(
      history(delete: (_) async => throw StateError('denied')),
    );
    await askToDelete(tester, 'coffee');
    await tester.tap(find.text('ลบรายการ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('การเชื่อมต่อและสิทธิ์'), findsOneWidget);
    expect(find.text('ลบรายการแล้ว'), findsNothing);
    expect(find.byKey(const Key('history-row-coffee')), findsOneWidget);
  });

  testWidgets(
    'timeout describes uncertain acknowledgement and permits same-ID retry',
    (tester) async {
      final attemptedIds = <String>[];
      await tester.pumpWidget(
        history(
          delete: (item) async {
            attemptedIds.add(item.id);
            throw TimeoutException('No acknowledgement');
          },
        ),
      );
      await askToDelete(tester, 'coffee');
      await tester.tap(find.text('ลบรายการ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ยังยืนยันการลบไม่ได้'), findsOneWidget);
      expect(find.text('ลบรายการแล้ว'), findsNothing);
      await askToDelete(tester, 'coffee');
      await tester.tap(find.text('ลบรายการ'));
      await tester.pumpAndSettle();
      expect(attemptedIds, ['coffee', 'coffee']);
    },
  );

  testWidgets(
    'filters and rows remain scrollable with large text and keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
              viewInsets: EdgeInsets.only(bottom: 220),
            ),
            child: HistoryScreen(
              transactions: [coffee, salary],
              initialMonth: november,
              onEditTransaction: (_) async {},
              onDeleteTransaction: (_) async {},
              onAddTransaction: () {},
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.byKey(const Key('history-search')));
      await tester.enterText(find.byKey(const Key('history-search')), 'Coffee');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('history-row-coffee')),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('history-row-coffee')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
