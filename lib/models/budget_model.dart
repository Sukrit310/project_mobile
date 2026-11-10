// เก็บวงเงินรวมรายเดือนเป็นสตางค์ เพื่อไม่ให้การปัดเศษทศนิยมเปลี่ยนงบ

/// งบที่แก้ไขค่าไม่ได้ โดยใช้วันแรกของเดือนและรหัสปีเดือนเดียวกันเสมอ
final class BudgetModel {
  BudgetModel({required DateTime month, required this.limitSatang})
    : month = _normalizeMonth(month) {
    if (limitSatang < 0 || limitSatang > maxLimitSatang) {
      throw ArgumentError.value(limitSatang, 'limitSatang');
    }
  }

  static const maxLimitSatang = 99999999999;

  final DateTime month;
  final int limitSatang;

  String get monthKey =>
      '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

  // จำกัดปีให้ตรงกับรหัสเอกสารสี่หลัก และตัดวันเวลาออกจากตัวตนของงบ
  static DateTime _normalizeMonth(DateTime month) {
    if (month.year < 1 || month.year > 9999) {
      throw ArgumentError.value(month, 'month');
    }
    return DateTime(month.year, month.month);
  }
}
