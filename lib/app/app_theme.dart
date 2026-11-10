// รวมสีและธีมส่วนกลาง เพื่อให้ทุกหน้าจอใช้หน้าตาและความหมายของสีตรงกัน

import 'package:flutter/material.dart';

/// ชุดสีเดียวกันช่วยสื่อความหมายรายรับ รายจ่าย และสถานะในทุกหน้าจอ
abstract final class AppColors {
  static const primary = Color(0xFF20536B);
  static const primaryDeep = Color(0xFF173E50);
  static const surface = Colors.white;
  static const background = Color(0xFFF5F8F6);
  static const income = Color(0xFF087453);
  static const expense = Color(0xFFBE414B);
  static const muted = Color(0xFF566B70);
  static const text = Color(0xFF173B45);
  static const mintSurface = Color(0xFFDCF2E9);
  static const incomeSurface = Color(0xFFE4F3EC);
  static const expenseSurface = Color(0xFFFBEAEC);
  static const surfaceMuted = Color(0xFFEDF3F1);
  static const outline = Color(0xFFDCE6E3);
  static const controlOutline = Color(0xFF7B918B);
  static const accent = Color(0xFF92D9BC);
  static const onPrimary = Colors.white;
  static const balanceLabel = Color(0xFFDFEAF0);
  static const balanceDivider = Color(0xFF5A7F92);
  static const incomeHighlight = Color(0xFFADE3D6);
  static const expenseHighlight = Color(0xFFFFC3BD);
  static const divider = outline;
  static const noticeBackground = Color(0xFFE8F0F1);
}

/// สร้างธีม Material 3 จากสีหลักของ MoneyMate
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.income,
    secondaryContainer: AppColors.mintSurface,
    onSecondaryContainer: AppColors.primaryDeep,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.muted,
    outline: AppColors.outline,
    error: AppColors.expense,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'NotoSansThai',
  );
  final round = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.controlOutline),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    // โหลดฟอนต์จาก assets เพื่อให้อักษรไทยตรงกันบน Android/Web และใช้งานออฟไลน์ได้
    fontFamily: 'NotoSansThai',
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarThemeData(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'NotoSansThai',
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: round,
        textStyle: const TextStyle(
          fontFamily: 'NotoSansThai',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: round,
        side: const BorderSide(color: AppColors.outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(
          fontFamily: 'NotoSansThai',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorMaxLines: 4,
      helperMaxLines: 3,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.mintSurface,
      side: const BorderSide(color: AppColors.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(
        fontFamily: 'NotoSansThai',
        color: AppColors.primaryDeep,
        fontWeight: FontWeight.w500,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.primaryDeep,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: const TextStyle(
        fontFamily: 'NotoSansThai',
        color: AppColors.onPrimary,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.outline,
      thickness: 1,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.mintSurface,
      selectionHandleColor: AppColors.primary,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.outline,
    ),
  );
}
