// โมเดลรายการเงินและยอดสรุปหน้าหลัก ใช้จำนวนเต็มหน่วยสตางค์ตลอดการคำนวณ

/// ประเภทใช้กำหนดว่ารายการเพิ่มหรือลดยอดคงเหลือ
enum TransactionType { income, expense }

/// หมวดหมู่สำหรับป้าย ไอคอน และการรวมกราฟรายจ่าย
enum TransactionCategory { food, salary, housing, other }

/// เก็บจำนวนเงินเป็นสตางค์ เช่น 80 บาท = 8,000 สตางค์
/// ประเภทของรายการเป็นตัวกำหนดเครื่องหมาย ไม่เก็บยอดติดลบใน amountSatang
class MoneyTransaction {
  const MoneyTransaction({
    required this.id,
    required this.title,
    required this.amountSatang,
    required this.type,
    required this.category,
    required this.date,
  }) : assert(amountSatang >= 0);

  final String id;
  final String title;
  final int amountSatang;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;

  /// ให้หน้าจอและตัวคำนวณตรวจประเภทรายรับด้วยกติกาเดียวกัน
  bool get isIncome => type == TransactionType.income;

  /// คืนยอดมีเครื่องหมายสำหรับบวกรวม โดยไม่เปลี่ยนจำนวนเงินในรายการ
  int get signedAmountSatang => isIncome ? amountSatang : -amountSatang;
}

/// คำนวณยอดจากรายการชุดเดียวกับที่แสดงบนหน้าจอ
class DashboardSummary {
  const DashboardSummary._({
    required this.balanceSatang,
    required this.incomeSatang,
    required this.expenseSatang,
    required this.recentTransactions,
  });

  /// รวมยอดสะสมทุกเดือน แต่รวมรายรับ/รายจ่ายเฉพาะปีและเดือนที่ขอ
  factory DashboardSummary.fromTransactions(
    List<MoneyTransaction> transactions, {
    required DateTime month,
  }) {
    var balance = 0;
    var income = 0;
    var expense = 0;
    for (final transaction in transactions) {
      balance += transaction.signedAmountSatang;
      if (transaction.date.year != month.year ||
          transaction.date.month != month.month) {
        continue;
      }
      if (transaction.isIncome) {
        income += transaction.amountSatang;
      } else {
        expense += transaction.amountSatang;
      }
    }
    // sort เปลี่ยนลิสต์โดยตรง จึงคัดลอกก่อนเพื่อให้หน้าประวัติและสถิติใช้ต้นฉบับต่อได้
    final sorted = List<MoneyTransaction>.of(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return DashboardSummary._(
      balanceSatang: balance,
      incomeSatang: income,
      expenseSatang: expense,
      recentTransactions: List.unmodifiable(sorted.take(2)),
    );
  }

  /// ยอดสะสมจากทุกรายการ ส่วนรายรับ/รายจ่ายเป็นยอดเฉพาะเดือน
  final int balanceSatang;
  final int incomeSatang;
  final int expenseSatang;
  final List<MoneyTransaction> recentTransactions;
}
