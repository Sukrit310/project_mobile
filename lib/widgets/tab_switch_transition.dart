// ให้ข้อมูลหน้าที่เลือกปรากฏทันที พร้อมจังหวะเปลี่ยนหน้าสั้น ๆ ที่เคารพการลดแอนิเมชัน
import 'package:flutter/material.dart';

/// วาดเฉพาะหน้าปัจจุบัน จึงไม่สร้างเมนูหรือฟอร์มซ้อนกันระหว่างเปลี่ยนแท็บ
class TabSwitchTransition extends StatefulWidget {
  const TabSwitchTransition({
    super.key,
    required this.index,
    required this.child,
  });
  final int index;
  final Widget child;

  @override
  State<TabSwitchTransition> createState() => _TabSwitchTransitionState();
}

class _TabSwitchTransitionState extends State<TabSwitchTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _opacity = Tween(
    begin: 0.75,
    end: 1.0,
  ).animate(_curve);
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant TabSwitchTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index && !_reduceMotion) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    alwaysIncludeSemantics: true,
    child: widget.child,
  );
}
