// แถบนำทางสี่หน้า รับตำแหน่งที่เลือกและส่งการแตะกลับให้หน้าหลักจัดการ

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_theme.dart';

/// แสดงปลายทางตาม currentIndex และแจ้ง onTap โดยไม่เปลี่ยน route เอง
class MoneyMateNavigationBar extends StatelessWidget {
  const MoneyMateNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.outline)),
    ),
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 584),
        // NavigationBar ให้สถานะเลือกและพื้นที่แตะตาม Material 3 พร้อมป้ายชื่อทุกหน้า
        child: NavigationBar(
          selectedIndex: currentIndex,
          height: 76,
          elevation: 0,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.mintSurface,
          animationDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            if (index == currentIndex) return;
            // ตอบรับการแตะด้วย haptic บนอุปกรณ์ที่รองรับ โดยไม่หน่วงการเปลี่ยนหน้า
            HapticFeedback.selectionClick();
            onTap(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'หน้าหลัก',
            ),
            NavigationDestination(
              icon: Icon(Icons.format_list_bulleted),
              label: 'ประวัติ',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart_rounded),
              label: 'สถิติ',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'งบประมาณ',
            ),
          ],
        ),
      ),
    ),
  );
}
