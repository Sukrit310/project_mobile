// ทดสอบว่าข้อผิดพลาดของ Firebase Auth แสดงคำแนะนำการตั้งค่าที่ตรงกับสาเหตุ

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/utils/firebase_error_message.dart';

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  test('native Android internal error with backend marker gives Auth setup guidance', () {
    final error = FirebaseAuthException(
      code: 'internal-error',
      message: 'An internal error has occurred. [ CONFIGURATION_NOT_FOUND ]',
    );
    expect(firebaseConnectionErrorMessage(error), contains('Authentication'));
    expect(firebaseConnectionErrorMessage(error), contains('Anonymous'));
  });

  test('missing Auth configuration gives setup guidance instead of a network diagnosis', () {
    final message = firebaseConnectionErrorMessage(
      FirebaseAuthException(code: 'configuration-not-found'),
    );
    expect(message, contains('Authentication'));
    expect(message, contains('Anonymous'));
    expect(message, isNot(contains('ตรวจสอบอินเทอร์เน็ต')));
  });

  test(
    'disabled anonymous provider identifies the required sign-in setting',
    () {
      expect(
        firebaseConnectionErrorMessage(
          FirebaseAuthException(code: 'operation-not-allowed'),
        ),
        contains('Anonymous'),
      );
    },
  );
}
