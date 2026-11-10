// แถบนำทางสี่หน้า รับตำแหน่งที่เลือกและส่งการแตะกลับให้หน้าหลักจัดการ

import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    currentIndex: currentIndex,
    backgroundColor: AppColors.background,
    selectedItemColor: AppColors.text,
    unselectedItemColor: AppColors.muted,
    selectedFontSize: 10,
    unselectedFontSize: 10,
    iconSize: 20,
    elevation: 0,
    onTap: onTap,
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: 'หน้าหลัก',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.format_list_bulleted),
        label: 'ประวัติ',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.pie_chart_outline),
        label: 'สถิติ',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.account_balance_wallet_outlined),
        label: 'งบประมาณ',
      ),
    ],
  );
}
