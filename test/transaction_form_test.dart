// ทดสอบฟอร์มเพิ่มและแก้ไข รวมเงินและเวลาเดิม ข้อมูลผิด การบันทึกซ้ำ และข้อผิดพลาด

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/screens/transaction_form_screen.dart';
import 'package:project_moneymate/services/transaction_repository.dart';
import 'package:project_moneymate/services/transaction_codec.dart';

const _titleKey = Key('transaction-title');
const _amountKey = Key('transaction-amount');
const _saveKey = Key('transaction-save');
const _categoryKey = Key('transaction-category');
const _dateKey = Key('transaction-date');

/// เปิดฟอร์มผ่าน Navigator จริง เพื่อทดสอบผลลัพธ์ pop และฉีดพฤติกรรมบันทึกได้
Future<void> _openForm(
  WidgetTester tester, {
  required Future<void> Function(MoneyTransaction) onSave,
  ValueChanged<bool?>? onResult,
  DateTime? initialDate,
  MoneyTransaction? initialTransaction,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => TransactionFormScreen(
                    transactionId: 'stable-transaction-id',
                    onSave: onSave,
                    initialDate:
                        initialDate ?? DateTime(2026, 11, 8, 15, 32, 10),
                    initialTransaction: initialTransaction,
                  ),
                ),
              );
              onResult?.call(result);
            },
            child: const Text('open form'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open form'));
  await tester.pumpAndSettle();
}

/// เติมค่าผ่าน validator และซ่อนคีย์บอร์ดก่อนตรวจการบันทึก
Future<void> _fillValidForm(WidgetTester tester) async {
  await tester.enterText(find.byKey(_titleKey), '  ค่าอาหารกลางวัน  ');
  await tester.enterText(find.byKey(_amountKey), '123.45');
  tester.testTextInput.hide();
  await tester.pump();
}

/// เลื่อนถึงปุ่มแล้วเริ่มบันทึก โดยให้แต่ละกรณีเลือกว่าจะรอผลครบเมื่อใด
Future<void> _save(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(_saveKey));
  await tester.tap(find.byKey(_saveKey));
  await tester.pump();
}

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  // ข้อมูลเดิมที่ enum ยังรองรับต้องแก้ไขได้ แม้ไม่ใช่คู่ประเภท/หมวดของรายการใหม่
  for (final pair in [
    (TransactionType.income, TransactionCategory.food),
    (TransactionType.income, TransactionCategory.housing),
    (TransactionType.expense, TransactionCategory.salary),
  ]) {
    testWidgets(
      'editing preserves valid legacy ${pair.$1.name}/${pair.$2.name} category',
      (tester) async {
        final transaction = TransactionCodec.decode('legacy-record', {
          'title': 'รายการเดิม',
          'amountSatang': 10005,
          'type': pair.$1.name,
          'category': pair.$2.name,
          'date': Timestamp.fromDate(DateTime(2026, 10, 1, 12)),
        });
        MoneyTransaction? saved;
        await _openForm(
          tester,
          initialTransaction: transaction,
          onSave: (value) async => saved = value,
        );
        expect(tester.takeException(), isNull);
        await _save(tester);
        await tester.pumpAndSettle();
        expect(saved?.id, 'legacy-record');
        expect(saved?.type, pair.$1);
        expect(saved?.category, pair.$2);
        expect(saved?.amountSatang, 10005);
      },
    );
  }

  testWidgets('edit mode prefills the exact stored values and edit labels', (
    tester,
  ) async {
    await _openForm(
      tester,
      initialTransaction: MoneyTransaction(
        id: 'original-income',
        title: '  เงินพิเศษ  ',
        amountSatang: 99999999999,
        type: TransactionType.income,
        category: TransactionCategory.other,
        date: DateTime.utc(2024, 2, 29, 23, 58, 57, 456, 789),
      ),
      onSave: (_) async {},
    );

    expect(find.text('แก้ไขรายการ'), findsOneWidget);
    expect(find.text('บันทึกการแก้ไข'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byKey(_titleKey)).controller?.text,
      '  เงินพิเศษ  ',
    );
    expect(
      tester.widget<TextFormField>(find.byKey(_amountKey)).controller?.text,
      '999999999.99',
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'รายรับ'))
          .selected,
      isTrue,
    );
    expect(find.text('อื่น ๆ'), findsOneWidget);
    expect(find.text('วันที่: 29/2/2024'), findsOneWidget);
  });

  for (final amount in <(int, String)>[
    (1, '0.01'),
    (100, '1.00'),
    (99999999999, '999999999.99'),
  ]) {
    testWidgets(
      'unchanged edit preserves ${amount.$1} satang, ID and timestamp',
      (tester) async {
        MoneyTransaction? saved;
        bool? result;
        await _openForm(
          tester,
          initialTransaction: MoneyTransaction(
            id: 'existing-record',
            title: 'เงินเดือนพิเศษ',
            amountSatang: amount.$1,
            type: TransactionType.income,
            category: TransactionCategory.salary,
            date: DateTime.utc(2024, 2, 29, 23, 58, 57, 456, 789),
          ),
          onSave: (value) async => saved = value,
          onResult: (value) => result = value,
        );
        expect(find.text(amount.$2), findsOneWidget);
        await _save(tester);
        await tester.pumpAndSettle();

        expect(saved?.id, 'existing-record');
        expect(saved?.title, 'เงินเดือนพิเศษ');
        expect(saved?.amountSatang, amount.$1);
        expect(saved?.type, TransactionType.income);
        expect(saved?.category, TransactionCategory.salary);
        expect(saved?.date, DateTime.utc(2024, 2, 29, 23, 58, 57, 456, 789));
        expect(saved?.date.isUtc, isTrue);
        expect(result, isTrue);
        expect(find.byType(TransactionFormScreen), findsNothing);
      },
    );
  }

  for (final date in <DateTime>[
    DateTime.utc(2100, 7, 9, 12, 34, 56, 123, 456),
    DateTime(1800, 7, 9, 12, 34, 56, 123, 456),
  ]) {
    testWidgets(
      'cancelled date picker preserves out-of-range edit ${date.year}',
      (tester) async {
        MoneyTransaction? saved;
        await _openForm(
          tester,
          initialTransaction: MoneyTransaction(
            id: 'old-date-record',
            title: 'รายการเดิม',
            amountSatang: 12345,
            type: TransactionType.expense,
            category: TransactionCategory.housing,
            date: date,
          ),
          onSave: (value) async => saved = value,
        );
        expect(find.text('วันที่: 9/7/${date.year}'), findsOneWidget);
        await tester.tap(find.byKey(_dateKey));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final picker = tester.widget<DatePickerDialog>(
          find.byType(DatePickerDialog),
        );
        final now = DateTime.now();
        expect(
          picker.initialDate,
          date.year == 1800
              ? DateTime(1900)
              : DateTime(now.year, now.month, now.day),
        );
        await tester.tap(find.text('ยกเลิก'));
        await tester.pumpAndSettle();
        expect(find.text('วันที่: 9/7/${date.year}'), findsOneWidget);
        await _save(tester);
        await tester.pumpAndSettle();

        expect(saved?.date, date);
        expect(saved?.date.isUtc, date.isUtc);
        expect(saved?.category, TransactionCategory.housing);
      },
    );
  }

  testWidgets(
    'editing the date preserves UTC time and saves other field changes',
    (tester) async {
      MoneyTransaction? saved;
      await _openForm(
        tester,
        initialTransaction: MoneyTransaction(
          id: 'edited-record',
          title: 'ชื่อเดิม',
          amountSatang: 12345,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          date: DateTime.utc(2100, 7, 9, 12, 34, 56, 123, 456),
        ),
        onSave: (value) async => saved = value,
      );
      await tester.enterText(find.byKey(_titleKey), '  ชื่อใหม่  ');
      await tester.enterText(find.byKey(_amountKey), '987.65');
      tester.testTextInput.hide();
      await tester.pump();
      await tester.tap(find.text('รายจ่าย'));
      await tester.ensureVisible(find.byKey(_dateKey));
      await tester.tap(find.byKey(_dateKey));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(DatePickerDialog)))
          .pop(DateTime(2024, 2, 29));
      await tester.pumpAndSettle();
      await _save(tester);
      await tester.pumpAndSettle();

      expect(saved?.id, 'edited-record');
      expect(saved?.title, 'ชื่อใหม่');
      expect(saved?.amountSatang, 98765);
      expect(saved?.type, TransactionType.expense);
      expect(saved?.category, TransactionCategory.food);
      expect(saved?.date, DateTime.utc(2024, 2, 29, 12, 34, 56, 123, 456));
      expect(saved?.date.isUtc, isTrue);
    },
  );

  testWidgets(
    'missing edit retains input and offers a retry with the same ID',
    (tester) async {
      final attempted = <MoneyTransaction>[];
      await _openForm(
        tester,
        initialTransaction: MoneyTransaction(
          id: 'deleted-record',
          title: 'ชื่อเดิม',
          amountSatang: 12345,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2024, 2, 29, 12, 34, 56, 123, 456),
        ),
        onSave: (value) async {
          attempted.add(value);
          throw const TransactionNotFoundException();
        },
      );
      await tester.enterText(find.byKey(_titleKey), 'ชื่อที่แก้ไข');
      await tester.enterText(find.byKey(_amountKey), '75.01');
      tester.testTextInput.hide();
      await _save(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('ไม่พบรายการนี้แล้ว กรุณากลับไปตรวจสอบประวัติ'),
        findsOneWidget,
      );
      expect(find.byType(TransactionFormScreen), findsOneWidget);
      expect(find.text('ชื่อที่แก้ไข'), findsOneWidget);
      expect(find.text('75.01'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byKey(_saveKey)).onPressed,
        isNotNull,
      );
      await _save(tester);
      await tester.pumpAndSettle();
      expect(attempted.map((value) => value.id), [
        'deleted-record',
        'deleted-record',
      ]);
      expect(attempted.last.title, 'ชื่อที่แก้ไข');
      expect(attempted.last.amountSatang, 7501);
      expect(attempted.last.date, DateTime(2024, 2, 29, 12, 34, 56, 123, 456));
    },
  );

  testWidgets('saves normalized values and pops true after success', (
    tester,
  ) async {
    MoneyTransaction? saved;
    bool? result;
    await _openForm(
      tester,
      onSave: (transaction) async => saved = transaction,
      onResult: (value) => result = value,
    );
    await _fillValidForm(tester);
    await _save(tester);
    await tester.pumpAndSettle();

    expect(saved?.id, 'stable-transaction-id');
    expect(saved?.title, 'ค่าอาหารกลางวัน');
    expect(saved?.amountSatang, 12345);
    expect(saved?.type, TransactionType.expense);
    expect(saved?.category, TransactionCategory.food);
    expect(saved?.date, DateTime(2026, 11, 8, 15, 32, 10));
    expect(result, isTrue);
    expect(find.byType(TransactionFormScreen), findsNothing);
  });

  testWidgets('invalid values show guidance without saving', (tester) async {
    var saves = 0;
    await _openForm(tester, onSave: (_) async => saves++);
    await tester.enterText(find.byKey(_amountKey), '1e3');
    await _save(tester);

    expect(saves, 0);
    expect(find.text('กรุณากรอกชื่อรายการ'), findsOneWidget);
    expect(find.textContaining('กรอกตัวเลขบาท'), findsOneWidget);
  });

  testWidgets('type changes reset the category to a compatible choice', (
    tester,
  ) async {
    MoneyTransaction? saved;
    await _openForm(tester, onSave: (value) async => saved = value);
    await tester.tap(find.byKey(_categoryKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ที่อยู่อาศัย').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('รายรับ'));
    await tester.pumpAndSettle();
    expect(find.text('เงินเดือน'), findsOneWidget);
    expect(find.text('ที่อยู่อาศัย'), findsNothing);
    await _fillValidForm(tester);
    await _save(tester);
    await tester.pumpAndSettle();
    expect(saved?.type, TransactionType.income);
    expect(saved?.category, TransactionCategory.salary);
  });

  testWidgets(
    'saving prevents repeated taps, field edits and back navigation',
    (tester) async {
      // ????????????????????????????????? ????????????????????????
      final pending = Completer<void>();
      var saves = 0;
      await _openForm(
        tester,
        onSave: (_) {
          saves++;
          return pending.future;
        },
      );
      await _fillValidForm(tester);
      await _save(tester);
      await tester.tap(find.byKey(_saveKey));
      await tester.pump();

      expect(saves, 1);
      expect(
        tester.widget<TextFormField>(find.byKey(_titleKey)).enabled,
        isFalse,
      );
      expect(
        tester.widget<TextFormField>(find.byKey(_amountKey)).enabled,
        isFalse,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'รายรับ'))
            .onSelected,
        isNull,
      );
      expect(
        tester
            .widget<DropdownButtonFormField<TransactionCategory>>(
              find.byKey(_categoryKey),
            )
            .onChanged,
        isNull,
      );
      expect(
        tester.widget<OutlinedButton>(find.byKey(_dateKey)).onPressed,
        isNull,
      );
      final context = tester.element(find.byType(TransactionFormScreen));
      await Navigator.of(context).maybePop();
      await tester.pump();
      expect(find.byType(TransactionFormScreen), findsOneWidget);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(TransactionFormScreen), findsNothing);
    },
  );

  testWidgets('failure retains entered values and retries with the same ID', (
    tester,
  ) async {
    final saved = <MoneyTransaction>[];
    await _openForm(
      tester,
      onSave: (value) async {
        saved.add(value);
        if (saved.length == 1) throw StateError('offline');
      },
    );
    await _fillValidForm(tester);
    await _save(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('บันทึกไม่สำเร็จ'), findsOneWidget);
    expect(find.text('  ค่าอาหารกลางวัน  '), findsOneWidget);
    expect(find.text('123.45'), findsOneWidget);
    await _save(tester);
    await tester.pumpAndSettle();
    expect(saved.map((value) => value.id), [
      'stable-transaction-id',
      'stable-transaction-id',
    ]);
    expect(saved.last.amountSatang, 12345);
    expect(find.byType(TransactionFormScreen), findsNothing);
  });

  testWidgets('timeout explains uncertain saving and allows retry', (
    tester,
  ) async {
    await _openForm(
      tester,
      onSave: (_) async => throw TimeoutException('network'),
    );
    await _fillValidForm(tester);
    await _save(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('ไม่สามารถยืนยัน'), findsOneWidget);
    expect(find.textContaining('ลองอีกครั้ง'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(_saveKey)).onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'date picker prevents future dates and preserves the time of day',
    (tester) async {
      MoneyTransaction? saved;
      final initialDate = DateTime(2026, 11, 8, 15, 32, 10, 123, 456);
      await _openForm(
        tester,
        initialDate: initialDate,
        onSave: (value) async => saved = value,
      );
      await tester.tap(find.byKey(_dateKey));
      await tester.pumpAndSettle();
      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      final now = DateTime.now();
      expect(picker.lastDate, DateTime(now.year, now.month, now.day));
      Navigator.of(tester.element(find.byType(DatePickerDialog)))
          .pop(DateTime(2026, 11, 7));
      await tester.pumpAndSettle();
      await _fillValidForm(tester);
      await _save(tester);
      await tester.pumpAndSettle();

      expect(saved?.date, DateTime(2026, 11, 7, 15, 32, 10, 123, 456));
    },
  );

  testWidgets('short screen and large text remain scrollable with a keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openForm(tester, onSave: (_) async {});
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(_saveKey));
    await tester.pumpAndSettle();
    expect(find.byKey(_saveKey).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
