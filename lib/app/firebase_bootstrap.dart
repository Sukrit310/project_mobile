// เริ่ม Firebase/Auth แล้วประกอบ repository ของ UID เดียวกัน หรือเข้าโหมดตัวอย่างโดยผู้ใช้เลือก
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../data/sample_transactions.dart';
import '../models/budget_model.dart';
import '../firebase_options.dart';
import '../screens/dashboard_screen.dart';
import '../services/auth_service.dart';
import '../services/budget_repository.dart';
import '../services/demo_budget_repository.dart';
import '../services/demo_transaction_repository.dart';
import '../services/firestore_budget_repository.dart';
import '../services/firestore_service.dart';
import '../services/transaction_repository.dart';
import '../utils/firebase_error_message.dart';
import '../widgets/status_view.dart';

/// StatefulWidget เก็บ Future การเชื่อมต่อ เพื่อไม่เริ่ม Firebase ซ้ำทุกครั้งที่ build
class FirebaseBootstrap extends StatefulWidget {
  const FirebaseBootstrap({super.key});

  @override
  State<FirebaseBootstrap> createState() => _FirebaseBootstrapState();
}

class _FirebaseBootstrapState extends State<FirebaseBootstrap> {
  late Future<_Repositories> _connection;
  DemoTransactionRepository? _demo;
  DemoBudgetRepository? _demoBudgets;

  @override
  void initState() {
    super.initState();
    _connection = _connect();
  }

  /// รอ Firebase และ Anonymous Auth ก่อนสร้างเส้นทางข้อมูลที่แยกตามเจ้าของ
  Future<_Repositories> _connect() async {
    final options = DefaultFirebaseOptions.currentPlatform;
    final app = Firebase.apps.isEmpty
        ? await Firebase.initializeApp(options: options)
              .timeout(const Duration(seconds: 15))
        : Firebase.app();
    if (app.options.projectId != 'projectmoneymate') {
      throw StateError('Firebase project does not match projectmoneymate');
    }
    final userId = await AuthService(auth: FirebaseAuth.instanceFor(app: app))
        .ensureSignedIn()
        .timeout(const Duration(seconds: 15));
    final firestore = FirebaseFirestore.instanceFor(app: app);
    return _Repositories(
      transactions: FirestoreService(firestore: firestore, userId: userId),
      budgets: FirestoreBudgetRepository(firestore: firestore, userId: userId),
    );
  }

  @override
  void dispose() {
    _demo?.dispose();
    _demoBudgets?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demo = _demo;
    if (demo != null) {
      return DashboardScreen(
        repository: demo,
        budgetRepository: _demoBudgets!,
        referenceMonth: sampleReferenceMonth,
        isDemo: true,
      );
    }
    // FutureBuilder แสดงสถานะเริ่มระบบ โดยไม่สลับไปใช้ข้อมูลปลอมอัตโนมัติเมื่อเกิดข้อผิดพลาด
    return FutureBuilder<_Repositories>(
      future: _connection,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return StatusView(
            title: 'ยังเชื่อมต่อ Firebase ไม่สำเร็จ',
            message: firebaseConnectionErrorMessage(snapshot.error),
            onRetry: () => setState(() => _connection = _connect()),
            secondaryAction: OutlinedButton(
              onPressed: () => setState(() {
                _demo = DemoTransactionRepository(
                  initialTransactions: sampleTransactions,
                );
                _demoBudgets = DemoBudgetRepository(
                  initialBudgets: [
                    BudgetModel(
                      month: sampleReferenceMonth,
                      limitSatang: 500000,
                    ),
                  ],
                );
              }),
              child: const Text('ทดลองด้วยข้อมูลตัวอย่าง'),
            ),
          );
        }
        final repository = snapshot.data;
        if (repository == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return DashboardScreen(
          repository: repository.transactions,
          budgetRepository: repository.budgets,
        );
      },
    );
  }
}

/// รวมแหล่งข้อมูลสองชนิดที่สร้างจาก Firebase app และ UID เดียวกัน
class _Repositories {
  const _Repositories({required this.transactions, required this.budgets});
  final TransactionRepository transactions;
  final BudgetRepository budgets;
}
