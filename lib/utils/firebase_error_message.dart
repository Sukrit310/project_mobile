// แปลข้อผิดพลาดการเชื่อมต่อ Firebase เป็นข้อความแนะนำที่ผู้ใช้เข้าใจได้

import 'package:firebase_auth/firebase_auth.dart';

/// แยกปัญหาการตั้งค่าแอปหรือ Auth ออกจากข้อความตรวจการเชื่อมต่อทั่วไป
String firebaseConnectionErrorMessage(Object? error) {
  if (error is StateError || error is UnsupportedError) {
    return 'ยังตั้งค่า Firebase ของแอปนี้ไม่ครบ โปรดเชื่อมแอปกับโปรเจกต์ projectmoneymate';
  }
  if (error is FirebaseAuthException) {
    if (error.code == 'configuration-not-found' ||
        (error.message?.contains('CONFIGURATION_NOT_FOUND') ?? false)) {
      return 'โปรเจกต์นี้ยังไม่ได้ตั้งค่า Firebase Authentication โปรดเปิด Authentication และ Anonymous sign-in ใน Firebase Console';
    }
    if (error.code == 'operation-not-allowed') {
      return 'โปรเจกต์นี้ยังไม่ได้เปิด Anonymous sign-in ใน Firebase Authentication';
    }
  }
  return 'ตรวจสอบอินเทอร์เน็ตและการตั้งค่า Firebase แล้วลองอีกครั้ง';
}
