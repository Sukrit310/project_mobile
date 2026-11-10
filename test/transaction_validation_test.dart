// ทดสอบกติกาข้อมูลนำเข้า โดยเฉพาะการแปลงบาทเป็นสตางค์โดยไม่ปัดเศษ

import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/utils/transaction_validation.dart';

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  // ตัวอย่างทั้งถูกและผิดยืนยันไวยากรณ์เดียวกับฟอร์มและเพดานสตางค์ของแอป
  group('parseBahtToSatang', () {
    test('preserves satang exactly without floating point rounding', () {
      const examples = {
        '0.01': 1,
        '0.29': 29,
        '1': 100,
        '1.2': 120,
        '123456789.12': 12345678912,
        '999999999.99': 99999999999,
        ' 00012.05 ': 1205,
      };
      for (final entry in examples.entries) {
        expect(parseBahtToSatang(entry.key), entry.value, reason: entry.key);
      }
    });

    test('rejects invalid notation, nonpositive and oversized amounts', () {
      const invalid = [
        '',
        ' ',
        '0',
        '0.00',
        '-1',
        '+1',
        '.5',
        '1.',
        '1.001',
        '1,000.00',
        '1e2',
        'NaN',
        'Infinity',
        '๑๐',
        '1 00',
        '1\n2',
        '1000000000',
        '999999999.999',
        '99999999999999999999999999999999999999999999999999',
      ];
      for (final value in invalid) {
        expect(parseBahtToSatang(value), isNull, reason: value);
      }
    });
  });

  group('title validation', () {
    test('rejects empty or overlong trimmed names', () {
      expect(validateTransactionTitle(null), isNotNull);
      expect(validateTransactionTitle('  \n '), isNotNull);
      expect(validateTransactionTitle('a' * 81), isNotNull);
      expect(validateTransactionTitle('  ${'a' * 80}  '), isNull);
      expect(validateTransactionTitle('  ค่าอาหาร  '), isNull);
    });
  });

  test(
    'amount validation explains rejected inputs and accepts valid amounts',
    () {
      expect(validateTransactionAmount(null), isNotEmpty);
      expect(validateTransactionAmount('1.001'), contains('2'));
      expect(validateTransactionAmount('0'), isNotEmpty);
      expect(validateTransactionAmount('1000000000'), isNotEmpty);
      expect(validateTransactionAmount('0.01'), isNull);
    },
  );
}
