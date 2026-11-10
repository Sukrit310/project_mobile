// แยกการอ่านและบันทึกงบออกจากธุรกรรม เพื่อให้เปลี่ยนแหล่งข้อมูลได้โดยไม่ซ้ำยอดใช้จ่าย
import '../models/budget_model.dart';

/// ภาพข้อมูลของเดือนหนึ่ง พร้อมสถานะที่ UI ใช้อธิบายการซิงก์ตามจริง
class BudgetFeed {
  const BudgetFeed({
    this.budget,
    this.isFromCache = false,
    this.hasPendingWrites = false,
  });

  final BudgetModel? budget;
  final bool isFromCache;
  final bool hasPendingWrites;
}

/// สัญญาร่วมของงบจริงและโหมดทดลอง โดยผู้เรียกเลือกเดือนอย่างชัดเจน
abstract class BudgetRepository {
  Stream<BudgetFeed> watchBudget(DateTime month);
  Future<void> saveBudget(BudgetModel budget);
}
