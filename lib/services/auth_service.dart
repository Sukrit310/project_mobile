// จัดการตัวตน Firebase แบบไม่ระบุชื่อ เพื่อให้ข้อมูลแยกตาม UID ของผู้ใช้

import 'package:firebase_auth/firebase_auth.dart';

/// ใช้ผู้ใช้ที่ลงชื่อเข้าอยู่แล้ว หรือขอ UID ใหม่ผ่าน Anonymous Authentication
class AuthService {
  AuthService({required this.auth});

  final FirebaseAuth auth;

  /// คืน UID ที่ repository ใช้สร้างเส้นทางข้อมูลเฉพาะเจ้าของ
  Future<String> ensureSignedIn() async {
    final existing = auth.currentUser;
    if (existing != null) return existing.uid;
    final result = await auth.signInAnonymously();
    final user = result.user;
    if (user == null) throw StateError('Firebase did not return a user');
    return user.uid;
  }
}
