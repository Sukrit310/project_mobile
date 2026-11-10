// สรุปการใช้งบจากจำนวนสตางค์ โดยไม่ผูกกับฐานข้อมูลหรือหน้าจอ

/// คำนวณยอดคงเหลือและสถานะงบด้วยจำนวนเต็มเพื่อรักษาความแม่นยำของเงิน
class BudgetSummary {
  BudgetSummary({required this.limitSatang, required this.expenseSatang}) {
    // ตรวจขณะทำงานจริงด้วย เพราะ assert จะไม่ทำงานในรุ่น release
    if (limitSatang < 0) {
      throw ArgumentError.value(limitSatang, 'limitSatang', 'ต้องไม่ติดลบ');
    }
    if (expenseSatang < 0) {
      throw ArgumentError.value(expenseSatang, 'expenseSatang', 'ต้องไม่ติดลบ');
    }
  }

  /// วงเงินรวมของเดือน หน่วยสตางค์; ศูนย์หมายถึงยังไม่ได้ตั้งงบ
  final int limitSatang;

  /// รายจ่ายรวมที่คำนวณจากรายการของเดือน หน่วยสตางค์
  final int expenseSatang;

  /// แยกงบที่ยังไม่ได้ตั้งออกจากงบที่ใช้จนหมด
  bool get hasBudget => limitSatang > 0;

  /// คงค่าติดลบจริงไว้ เพื่อบอกยอดที่ใช้เกินวงเงินได้ครบถ้วน
  int get remainingSatang => limitSatang - expenseSatang;

  /// อัตราที่ใช้จริงอาจเกิน 100%; งบที่ยังไม่ตั้งไม่มีอัตราส่วนให้หาร
  double get usedPercentage =>
      hasBudget ? expenseSatang / limitSatang * 100 : 0;

  /// จำกัดเฉพาะความยาวแถบให้อยู่ระหว่างศูนย์กับหนึ่ง
  double get progressValue =>
      hasBudget ? (expenseSatang / limitSatang).clamp(0.0, 1.0) : 0;

  /// เทียบสตางค์โดยตรง จึงไม่เสียความต่างหนึ่งสตางค์จากการปัดเศษ
  bool get isOverBudget => hasBudget && expenseSatang > limitSatang;

  /// แสดงสถานะใช้ครบเฉพาะวงเงินที่ตั้งไว้และใช้เท่ากันพอดี
  bool get isAtLimit => hasBudget && expenseSatang == limitSatang;

  /// เตือนตั้งแต่ 80% จนก่อนครบวงเงิน โดยหลีกเลี่ยงการคูณที่อาจล้น int
  bool get isNearLimit =>
      hasBudget &&
      expenseSatang < limitSatang &&
      expenseSatang >= limitSatang - limitSatang ~/ 5;
}
