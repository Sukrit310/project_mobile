// แสดงจำนวนสตางค์เป็นข้อความเงินบาท พร้อมเครื่องหมายและจุลภาคโดยไม่เสียเศษสตางค์

/// แสดงเงินบาทโดยไม่แปลงเป็น double เพื่อรักษาความแม่นยำของสตางค์
String formatBaht(
  int amountSatang, {
  bool decimalPlaces = false,
  bool showPlus = false,
}) {
  final absolute = amountSatang.abs();
  final baht = (absolute ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final satang = absolute % 100;
  final fraction = decimalPlaces || satang != 0
      ? '.${satang.toString().padLeft(2, '0')}'
      : '';
  final sign = amountSatang < 0
      ? '-'
      : (showPlus && amountSatang > 0 ? '+' : '');
  return '$sign฿$baht$fraction';
}
