// จุดเริ่มแอป: เตรียม Flutter แล้วส่งการตั้งค่าและการเชื่อมต่อให้ MyApp ดูแล

import 'package:flutter/material.dart';

import 'app/app.dart';

export 'app/app.dart' show MyApp;

/// เตรียม binding ก่อนให้ MyApp เริ่มแสดงผลและดูแลสถานะการเชื่อมต่อ
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
