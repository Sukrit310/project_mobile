// ทดสอบค่าตั้งต้น Android กับไฟล์กำหนดค่าในเครื่อง และการปฏิเสธแพลตฟอร์มที่ยังไม่รองรับ

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_moneymate/firebase_options.dart';

/// ลงทะเบียนกรณีทดสอบในไฟล์นี้; แต่ละ test แยกข้อมูลและคืนทรัพยากรหลังใช้งาน
void main() {
  test('Android initializes with the registered google-services client', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    // อ่านเพียงไฟล์ตั้งค่าในเครื่อง ไม่เรียก Firebase หรือข้อมูลผู้ใช้จริง
    final config = jsonDecode(
      File('android/app/google-services.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final project = config['project_info'] as Map<String, dynamic>;
    final client = (config['client'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere(
          (item) =>
              item['client_info']['android_client_info']['package_name'] ==
              'com.example.project_moneymate',
        );
    final options = DefaultFirebaseOptions.currentPlatform;
    expect(options.projectId, project['project_id']);
    expect(options.messagingSenderId, project['project_number']);
    expect(options.appId, client['client_info']['mobilesdk_app_id']);
    expect(options.apiKey, client['api_key'][0]['current_key']);
    expect(options.storageBucket, project['storage_bucket']);
  });

  test('unregistered platforms fail before using Android options', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(
      () => DefaultFirebaseOptions.currentPlatform,
      throwsUnsupportedError,
    );
  });
}
