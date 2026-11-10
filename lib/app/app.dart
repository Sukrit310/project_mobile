// ประกอบแอป กำหนดภาษา/ธีม และเลือกแหล่งข้อมูลจริงหรือแหล่งข้อมูลที่ส่งมาทดสอบ
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../screens/dashboard_screen.dart';
import '../services/budget_repository.dart';
import '../services/transaction_repository.dart';
import 'app_theme.dart';
import 'firebase_bootstrap.dart';

/// MaterialApp ดูแลการนำทางและคำแปล Material ให้ทุกหน้าจอใช้ร่วมกัน
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.repository,
    this.budgetRepository,
    this.referenceMonth,
  });

  final TransactionRepository? repository;
  final BudgetRepository? budgetRepository;
  final DateTime? referenceMonth;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MoneyMate',
    debugShowCheckedModeBanner: false,
    locale: const Locale('th'),
    supportedLocales: const [Locale('th'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: buildAppTheme(),
    home: repository == null
        ? const FirebaseBootstrap()
        : DashboardScreen(
            repository: repository!,
            budgetRepository: budgetRepository,
            referenceMonth: referenceMonth,
          ),
  );
}
