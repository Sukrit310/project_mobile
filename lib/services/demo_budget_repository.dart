// เก็บงบทดลองในหน่วยความจำเท่านั้น ไม่เขียนตัวอย่างลงบัญชี Firebase ของผู้ใช้
import 'dart:async';

import '../models/budget_model.dart';
import 'budget_repository.dart';

/// จำลองงบแยกตามเดือน พร้อม stream ที่มีวงจรชีวิตเหมือนแหล่งข้อมูลจริง
class DemoBudgetRepository implements BudgetRepository {
  DemoBudgetRepository({List<BudgetModel> initialBudgets = const []})
    : _budgets = {for (final budget in initialBudgets) budget.monthKey: budget};

  final Map<String, BudgetModel> _budgets;
  final _changes = StreamController<BudgetModel>.broadcast();
  bool _isDisposed = false;

  @override
  Stream<BudgetFeed> watchBudget(DateTime month) {
    _ensureActive();
    final key = BudgetModel(month: month, limitSatang: 0).monthKey;
    return Stream.multi((controller) {
      if (_isDisposed) {
        controller.close();
        return;
      }
      // สมัครก่อนส่งค่าเริ่มต้นเพื่อไม่พลาดการแก้งบ และกรองไม่ให้เดือนอื่นรบกวน UI
      final subscription = _changes.stream
          .where((budget) => budget.monthKey == key)
          .listen(
            (budget) => controller.add(BudgetFeed(budget: budget)),
            onError: controller.addError,
            onDone: controller.close,
          );
      controller.add(BudgetFeed(budget: _budgets[key]));
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    _ensureActive();
    _budgets[budget.monthKey] = budget;
    _changes.add(budget);
  }

  // ปิด stream เมื่อแอปเลิกใช้โหมดทดลอง เพื่อคืนทรัพยากรและจบผู้ติดตามทุกเดือน
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await _changes.close();
  }

  void _ensureActive() {
    if (_isDisposed) throw StateError('Budget repository has been disposed');
  }
}
