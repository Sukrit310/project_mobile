import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/app/app_theme.dart';
import 'package:project_moneymate/models/money_transaction.dart';
import 'package:project_moneymate/screens/transaction_form_screen.dart';

void main() {
  Future<void> openForm(
    WidgetTester tester, {
    TransactionType initialType = TransactionType.expense,
    MoneyTransaction? initialTransaction,
    required ValueChanged<MoneyTransaction> onSave,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: TransactionFormScreen(
        transactionId: 'new-record',
        initialDate: DateTime(2026, 11, 1, 12),
        initialType: initialType,
        initialTransaction: initialTransaction,
        onSave: (value) async => onSave(value),
      ),
    ),
  );

  testWidgets(
    'income shortcut starts and saves a new income with salary category',
    (tester) async {
      MoneyTransaction? saved;
      await openForm(
        tester,
        initialType: TransactionType.income,
        onSave: (value) => saved = value,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'รายรับ'))
            .selected,
        isTrue,
      );
      await tester.enterText(
        find.byKey(const Key('transaction-title')),
        'เงินเดือน',
      );
      await tester.enterText(
        find.byKey(const Key('transaction-amount')),
        '100.01',
      );
      tester.testTextInput.hide();
      await tester.ensureVisible(find.byKey(const Key('transaction-save')));
      await tester.tap(find.byKey(const Key('transaction-save')));
      await tester.pumpAndSettle();

      expect(saved?.id, 'new-record');
      expect(saved?.type, TransactionType.income);
      expect(saved?.category, TransactionCategory.salary);
      expect(saved?.amountSatang, 10001);
    },
  );

  testWidgets(
    'editing keeps the stored type and category over shortcut defaults',
    (tester) async {
      MoneyTransaction? saved;
      final original = MoneyTransaction(
        id: 'existing-record',
        title: 'ค่าเช่า',
        amountSatang: 10005,
        type: TransactionType.expense,
        category: TransactionCategory.housing,
        date: DateTime.utc(2024, 2, 29, 10, 20, 30, 456, 789),
      );
      await openForm(
        tester,
        initialType: TransactionType.income,
        initialTransaction: original,
        onSave: (value) => saved = value,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'รายจ่าย'))
            .selected,
        isTrue,
      );
      await tester.ensureVisible(find.byKey(const Key('transaction-save')));
      await tester.tap(find.byKey(const Key('transaction-save')));
      await tester.pumpAndSettle();

      expect(saved?.id, 'existing-record');
      expect(saved?.type, TransactionType.expense);
      expect(saved?.category, TransactionCategory.housing);
      expect(saved?.date, original.date);
    },
  );
}
