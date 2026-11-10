// ค่าตั้งต้น Firebase แยกสำหรับ Android และเว็บของโปรเจกต์ MoneyMate

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Android ใช้ค่าจาก android/app/google-services.json ของ projectmoneymate
/// เว็บใช้ค่าจากแอป MoneyMate Web ที่ลงทะเบียนในโปรเจกต์เดียวกัน
class DefaultFirebaseOptions {
  /// ค่าของแอปเว็บที่ลงทะเบียนไว้ในโปรเจกต์เดียวกับ Android
  static const web = FirebaseOptions(
    apiKey: 'AIzaSyBDjPfSc82W9ZhFz-kw2YCwqRZ9IPFUIGg',
    appId: '1:756776364744:web:f6ef95a2b3bc62f71a93fd',
    messagingSenderId: '756776364744',
    projectId: 'projectmoneymate',
    authDomain: 'projectmoneymate.firebaseapp.com',
    storageBucket: 'projectmoneymate.firebasestorage.app',
    measurementId: 'G-HNC5Q1PB75',
  );

  /// ค่าของแอป Android ให้ตรงกับแพ็กเกจและไฟล์ google-services.json
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyBzjTDKrZrLzSsknV3t_x_01B0if7lLMQA',
    appId: '1:756776364744:android:f4173d6bbc16dfef1a93fd',
    messagingSenderId: '756776364744',
    projectId: 'projectmoneymate',
    storageBucket: 'projectmoneymate.firebasestorage.app',
  );

  /// ตรวจเว็บก่อน แล้วเลือก Android; แพลตฟอร์มอื่นต้องตั้งค่าเพิ่มก่อนใช้งาน
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'ตั้งค่า Firebase สำหรับแพลตฟอร์มนี้ด้วย FlutterFire ก่อน',
    );
  }
}
