// เปลี่ยนข้อความยอดเงินอย่างนุ่มนวล โดยแสดงสตางค์จริงทันทีและไม่คำนวณเงินผ่าน double
import 'package:flutter/material.dart';

/// รับข้อความที่จัดรูปแบบแล้ว จึงไม่ปัดเศษหรือแสดงยอดระหว่างทางที่ไม่ใช่ข้อมูลจริง
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({
    super.key,
    required this.amount,
    this.style,
    this.textAlign,
    this.valueKey,
  });

  final String amount;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      amount,
      key: valueKey,
      textAlign: textAlign,
      style: (style ?? DefaultTextStyle.of(context).style).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return text;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      // เก็บเฉพาะยอดล่าสุดใน layout/semantics ไม่แสดงยอดเก่าซ้อนระหว่าง fade
      layoutBuilder: (current, previous) => current ?? const SizedBox.shrink(),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        alwaysIncludeSemantics: true,
        child: child,
      ),
      child: KeyedSubtree(key: ValueKey(amount), child: text),
    );
  }
}
