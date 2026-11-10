// กติกาตรวจชื่อและจำนวนเงินของรายการ รวมถึงการแปลงข้อความบาทเป็นจำนวนเต็มสตางค์

/// เพดานเดียวกันสำหรับฟอร์มและ codec: 999,999,999.99 บาท
const maxTransactionSatang = 99999999999;

final _bahtPattern = RegExp(r'^[0-9]+(?:\.[0-9]{1,2})?$');

/// แยกส่วนบาทกับทศนิยมจากข้อความแล้วประกอบเป็น int สตางค์โดยตรง
/// ไม่ผ่าน double จึงไม่เกิดการปัดเศษ เช่น 0.29 บาทต้องได้ 29 สตางค์พอดี
int? parseBahtToSatang(String value) {
  final input = value.trim();
  if (!_bahtPattern.hasMatch(input)) return null;
  final parts = input.split('.');
  final whole = parts.first.replaceFirst(RegExp(r'^0+'), '');
  // ตรวจความยาวก่อน parse เพื่อปฏิเสธตัวเลขที่วางมายาวมากและเกินเพดาน
  if (whole.length > 9) return null;
  final baht = whole.isEmpty ? 0 : int.parse(whole);
  final fraction = parts.length == 1 ? '00' : parts[1].padRight(2, '0');
  final satang = baht * 100 + int.parse(fraction);
  if (satang <= 0 || satang > maxTransactionSatang) return null;
  return satang;
}

/// คืนข้อความผิดพลาดให้ Form หรือ null เมื่อชื่อหลังตัดช่องว่างผ่านกติกา
String? validateTransactionTitle(String? value) {
  final title = value?.trim() ?? '';
  if (title.isEmpty) return 'กรุณากรอกชื่อรายการ';
  if (title.runes.length > 80) return 'ชื่อรายการต้องไม่เกิน 80 ตัวอักษร';
  return null;
}

/// แยกข้อความแนะนำกรณีว่าง รูปแบบไม่ถูกต้อง และจำนวนเงินนอกขอบเขต
String? validateTransactionAmount(String? value) {
  if (value == null || value.trim().isEmpty) return 'กรุณากรอกจำนวนเงิน';
  if (!_bahtPattern.hasMatch(value.trim())) {
    return 'กรอกตัวเลขบาทและทศนิยมไม่เกิน 2 ตำแหน่ง โดยไม่ใส่เครื่องหมายหรือจุลภาค';
  }
  if (parseBahtToSatang(value) == null) {
    return 'จำนวนเงินต้องมากกว่า 0 และไม่เกิน 999,999,999.99 บาท';
  }
  return null;
}
