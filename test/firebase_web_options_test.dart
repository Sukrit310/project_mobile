// ทดสอบการเลือกค่าของแอป Firebase บนเบราว์เซอร์ โดยไม่เปิดการเชื่อมต่อจริง

@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/firebase_options.dart';

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  test('Chrome uses the registered Web app without dart-define flags', () {
    final options = DefaultFirebaseOptions.currentPlatform;
    expect(options.projectId, 'projectmoneymate');
    expect(options.appId, '1:756776364744:web:f6ef95a2b3bc62f71a93fd');
    expect(options.authDomain, 'projectmoneymate.firebaseapp.com');
    expect(options.storageBucket, 'projectmoneymate.firebasestorage.app');
    expect(options.messagingSenderId, '756776364744');
  });
}
