// รวมสีและธีมส่วนกลาง เพื่อให้ทุกหน้าจอใช้หน้าตาและความหมายของสีตรงกัน

import 'package:flutter/material.dart';

/// ชุดสีเดียวกันช่วยสื่อความหมายรายรับ รายจ่าย และสถานะในทุกหน้าจอ
abstract final class AppColors {
  static const primary = Color(0xFF20536B);
  static const surface = Color(0xFFF3F3F3);
  static const background = Color(0xFFFCFCFC);
  static const income = Color(0xFF007A2D);
  static const expense = Color(0xFFD93030);
  static const muted = Color(0xFF666666);
  static const text = Colors.black87;
  static const onPrimary = Colors.white;
  static const balanceLabel = Color(0xFFDFEAF0);
  static const balanceDivider = Color(0xFF5A7F92);
  static const incomeHighlight = Color(0xFFADE3D6);
  static const expenseHighlight = Color(0xFFFFC3BD);
  static const divider = Color(0xFFE3E3E3);
  static const noticeBackground = Color(0xFFE8F0F4);
}

/// สร้างธีม Material 3 จากสีหลักของ MoneyMate
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.background,
  );
}
