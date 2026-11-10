// ตรวจการแสดงเงินตรงสตางค์และการเปลี่ยนสถานะโดยไม่แสดงข้อมูลเก่าซ้อนหรือฝืนลดแอนิเมชัน
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/widgets/animated_money.dart';
import 'package:project_moneymate/widgets/tab_switch_transition.dart';

void main() {
  testWidgets('money updates expose only the latest exact text immediately', (
    tester,
  ) async {
    final amount = ValueNotifier('฿999,999,999.99');
    addTearDown(amount.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder(
          valueListenable: amount,
          builder: (_, value, child) => AnimatedMoney(
            amount: value,
            valueKey: const Key('current-money'),
          ),
        ),
      ),
    );
    amount.value = '-฿0.01';
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('current-money'))).data,
      '-฿0.01',
    );
    expect(find.text('฿999,999,999.99'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('-฿0.01'), findsOneWidget);
  });

  testWidgets('reduced motion immediately settles amounts and tab changes', (
    tester,
  ) async {
    final index = ValueNotifier(0);
    addTearDown(index.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ValueListenableBuilder(
            valueListenable: index,
            builder: (_, value, child) => TabSwitchTransition(
              index: value,
              child: AnimatedMoney(amount: value == 0 ? '฿1.00' : '฿1.01'),
            ),
          ),
        ),
      ),
    );
    index.value = 1;
    await tester.pump();
    expect(find.text('฿1.00'), findsNothing);
    expect(find.text('฿1.01'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'rapid tab changes retain a single current destination and settle',
    (tester) async {
      final index = ValueNotifier(0);
      addTearDown(index.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder(
            valueListenable: index,
            builder: (_, value, child) =>
                TabSwitchTransition(index: value, child: Text('หน้า $value')),
          ),
        ),
      );
      index.value = 1;
      await tester.pump();
      index.value = 2;
      await tester.pump();
      expect(find.text('หน้า 0'), findsNothing);
      expect(find.text('หน้า 1'), findsNothing);
      expect(find.text('หน้า 2'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
}
