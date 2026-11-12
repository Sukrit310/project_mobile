// ประกอบแอป กำหนดภาษา/ธีม และเลือกแหล่งข้อมูลจริงหรือแหล่งข้อมูลที่ส่งมาทดสอบ
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../screens/dashboard_screen.dart';
import '../screens/welcome_screen.dart';
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
    home: _WelcomeGate(
      builder: (_) => repository == null
          ? const FirebaseBootstrap()
          : DashboardScreen(
              repository: repository!,
              budgetRepository: budgetRepository,
              referenceMonth: referenceMonth,
            ),
    ),
  );
}

/// สลับเนื้อหาภายใน root route เดิม จึงไม่มี Welcome อยู่ในประวัติ Back หลังเริ่มใช้งาน
/// State อยู่เฉพาะรอบเปิดแอปนี้ และยังส่ง repository/เดือนล่าสุดเมื่อ MyApp ถูกประกอบใหม่
class _WelcomeGate extends StatefulWidget {
  const _WelcomeGate({required this.builder});
  final WidgetBuilder builder;

  @override
  State<_WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<_WelcomeGate> {
  bool _started = false;

  @override
  Widget build(BuildContext context) => _started
      ? widget.builder(context)
      : WelcomeScreen(onGetStarted: () => setState(() => _started = true));
}
