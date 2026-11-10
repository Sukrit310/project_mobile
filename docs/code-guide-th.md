# คู่มืออ่านโค้ด MoneyMate

แอปใช้ Flutter แสดงหน้าจอภาษาไทย และแยกหน้าจอออกจากแหล่งข้อมูลผ่าน repository
จำนวนเงินเก็บเป็นจำนวนเต็มหน่วย **สตางค์** เช่น 10.01 บาทเท่ากับ 1,001 สตางค์
การรวมยอดและตรวจวงเงินจึงไม่พึ่งการปัดเศษของ `double`

## เริ่มอ่านจากเส้นทางเปิดแอป

1. [main.dart](../lib/main.dart) เตรียม Flutter binding แล้วเปิด `MyApp`
2. [app.dart](../lib/app/app.dart) ตั้งภาษา ธีม และเลือก repository ที่ส่งเข้ามา
   หากไม่มีการส่งแหล่งข้อมูล จะเปิด `FirebaseBootstrap`
3. [firebase_bootstrap.dart](../lib/app/firebase_bootstrap.dart) เริ่ม Firebase และ
   Anonymous Auth ก่อนสร้าง repository ของรายการและงบจาก Firebase app และ UID เดียวกัน
   หากเชื่อมต่อไม่ได้ ผู้ใช้กดเลือกโหมดตัวอย่างได้เอง ข้อมูลตัวอย่างอยู่ในหน่วยความจำ
4. [dashboard_screen.dart](../lib/screens/dashboard_screen.dart) ติดตาม stream รายการ
   ชุดเดียว แล้วส่งข้อมูลให้หน้าหลัก ประวัติ สถิติ และงบประมาณตามเมนูที่เลือก
5. หน้าจอเรียกตัวคำนวณเพื่อสร้างยอดแสดงผล และเรียก callback/repository เมื่อผู้ใช้บันทึก
   snapshot ใหม่จึงเป็นตัวกระตุ้นให้ข้อมูลบนหน้าจอเปลี่ยนตาม

## ชั้นของโค้ด Dart ที่ดูแลเอง

| ตำแหน่ง | หน้าที่และจุดที่ควรอ่าน |
| --- | --- |
| `lib/app/` | ประกอบแอป เชื่อมต่อ Firebase/Auth และเก็บสี/ธีมกลาง |
| `lib/models/` | รูปข้อมูลรายการ สถิติ และงบ รวมถึงค่าที่คำนวณจากข้อมูลเหล่านั้น |
| `lib/services/` | สัญญา repository, codec ตรวจเอกสาร, ตัวเชื่อม Firestore และแหล่งข้อมูลตัวอย่าง |
| `lib/screens/` | ดูแลสถานะหน้าจอ เดือนที่เลือก การนำทาง และการเปิดฟอร์ม |
| `lib/widgets/` | ส่วน UI ใช้ซ้ำ เช่น บัตรยอด รายการ กราฟ แถบนำทาง และความคืบหน้างบ |
| `lib/utils/` | ฟังก์ชันตรวจข้อมูล กรองรายการ รวมสถิติ และจัดรูปแบบเงิน/วันที่ |
| `lib/data/sample_transactions.dart` | ข้อมูลตัวอย่างและเดือนอ้างอิงสำหรับโหมดทดลอง |
| `lib/firebase_options.dart` | ค่าตั้งค่า Firebase แยกตามแพลตฟอร์มสำหรับการเริ่ม SDK |

[transaction_validation.dart](../lib/utils/transaction_validation.dart) แยกข้อความบาท
เป็นส่วนจำนวนเต็มและทศนิยมก่อนประกอบสตางค์ ไม่แปลงผ่าน `double`
[money_format.dart](../lib/utils/money_format.dart) จัดกลุ่มตัวเลขและทศนิยมจากจำนวนเต็ม
ส่วน [statistics_calculator.dart](../lib/utils/statistics_calculator.dart) รวมรายรับ/รายจ่าย
เฉพาะ **ปีและเดือน** ที่เลือก โดยไม่แก้ลิสต์รายการต้นทาง

ฟอร์มปิดการกดซ้ำขณะกำลังบันทึก และตรวจ `mounted` ก่อนนำผลลัพธ์ async กลับไปเปลี่ยน UI
ข้อความ cache/pending แยกจากการยืนยันของเซิร์ฟเวอร์ เพื่อให้ผู้ใช้เห็นสถานะการซิงก์ตามจริง

ส่วนตกแต่งใช้ `app_theme.dart` เป็นศูนย์กลางสีและฟอนต์ไทยออฟไลน์ `AnimatedMoney`
เปลี่ยนเฉพาะข้อความยอดจริง ไม่คำนวณเงินผ่านตัวเลขทศนิยมระหว่างแอนิเมชัน ส่วน
`TabSwitchTransition` วาดเฉพาะแท็บปัจจุบันและเคารพการลดแอนิเมชัน ปุ่มรูปตาบน
`BalanceCard` รับสถานะจาก `DashboardScreen` จึงยังซ่อนยอดเมื่อกลับจากแท็บอื่น
การซ่อนนี้ใช้กับการ์ดเท่านั้น รายการธุรกรรมยังแสดงยอดตามปกติ

## เส้นทางงบประมาณรายเดือน

- [BudgetModel](../lib/models/budget_model.dart) เก็บเดือนที่ปรับเป็นวันแรกและวงเงินสตางค์
  `monthKey` รูปแบบ `YYYY-MM` เป็นตัวตนของงบหนึ่งเดือน วงเงินศูนย์หมายถึงยังไม่ได้ตั้งงบ
- [BudgetRepository](../lib/services/budget_repository.dart) แยกจากรายการเงินเดิม
  `BudgetFeed` มีงบของเดือน พร้อม `isFromCache` และ `hasPendingWrites`
- [FirestoreBudgetRepository](../lib/services/firestore_budget_repository.dart) อ่าน/บันทึก
  `users/{uid}/budgets/{YYYY-MM}` และใช้รหัสเดือนเดิมเมื่อบันทึกซ้ำ
  [BudgetCodec](../lib/services/budget_codec.dart) ตรวจชนิดข้อมูล เดือน วงเงิน และเวลา
  โดยขอ `updatedAt` จากเซิร์ฟเวอร์
- [DemoBudgetRepository](../lib/services/demo_budget_repository.dart) เก็บงบแยกเดือน
  ในหน่วยความจำ และปิด stream เมื่อเลิกใช้งาน ไม่มีการนำตัวอย่างไปเขียนบน Firebase
- [BudgetScreen](../lib/screens/budget_screen.dart) เปลี่ยน stream ตามเดือนที่เลือก
  พร้อมเปลี่ยน key ของ `StreamBuilder` เพื่อไม่แสดงงบของเดือนก่อนระหว่างรอข้อมูลใหม่
  ยอดใช้ไปคำนวณจากรายการรายจ่ายของเดือน ไม่เก็บยอดซ้ำในเอกสารงบ และรายรับไม่หักลดยอดนี้
- [BudgetEditorDialog](../lib/widgets/budget_editor_dialog.dart) รับเดือนเดิมของฟอร์ม
  ตลอดการบันทึก ใช้กติกาจำนวนเงินเดียวกับรายการ และเก็บข้อความที่กรอกไว้หากบันทึกไม่สำเร็จ
- [BudgetSummary](../lib/models/budget_summary.dart) เปรียบเทียบสตางค์จริงเพื่อแยก
  ยังอยู่ในงบ ใกล้ถึงวงเงินตั้งแต่ 80% ใช้ครบพอดี และเกินวงเงิน
  คงยอดคงเหลือติดลบจริงและเปอร์เซ็นต์ที่เกิน 100% ไว้ โดยจำกัดเฉพาะความยาวแถบที่ 0–1
- [BudgetProgress](../lib/widgets/budget_progress.dart) แสดงสถานะและเปอร์เซ็นต์ภาษาไทย
  พร้อมข้อความสำหรับโปรแกรมอ่านหน้าจอที่มียอดถึงสตางค์ หากยังไม่ตั้งงบจะรายงานเฉพาะสถานะ
  และรายจ่ายจริง เพราะยังไม่มีวงเงินหรือยอดคงเหลือที่มีความหมายให้รายงาน

ไฟล์ [firestore.rules](../firestore.rules) เป็นกติกาในโครงการ การแก้ไฟล์ในเครื่อง
ไม่ได้เปลี่ยน rules ที่ใช้งานบนคลาวด์โดยอัตโนมัติ

## จุดเข้า native และการ build

| แพลตฟอร์ม | เส้นทางที่เชื่อมระบบกับ Flutter |
| --- | --- |
| Android | `AndroidManifest.xml` ประกาศ Activity/สิทธิ์ → `MainActivity.kt` ใช้ `FlutterActivity`; Gradle เชื่อม SDK และปลั๊กอิน |
| Web | `web/index.html` กำหนดข้อมูลหน้าและโหลด `flutter_bootstrap.js` ที่ได้จากเครื่องมือ Flutter |
| iOS | `AppDelegate.swift` ลงทะเบียนปลั๊กอินเมื่อ engine พร้อม; `SceneDelegate.swift` รับวงจร scene ตาม `Info.plist` |
| macOS | `AppDelegate.swift` ดูแลวงจรแอป; `MainFlutterWindow.swift` ฝัง `FlutterViewController` และลงทะเบียนปลั๊กอิน |
| Windows | `main.cpp` สร้าง `FlutterWindow` และวนรับข้อความระบบ; `win32_window.*` ดูแลหน้าต่าง/DPI; `utils.*` แปลงข้อความ UTF-16/UTF-8 |
| Linux | `main.cc` เปิด GTK application; `my_application.*` สร้างหน้าต่าง ฝัง Flutter view และแสดงเมื่อเฟรมแรกพร้อม |

`CMakeLists.txt` ระดับโครงการและ runner ของ Windows/Linux ระบุซอร์ส ไลบรารี และไฟล์
ที่รวมเป็นชุดแจกจ่าย ส่วน `Runner.rc`/`resource.h` ระบุไอคอนและรุ่นบน Windows
ไฟล์ `*.xcconfig`, `Info.plist`, entitlements และ Android XML กำหนดค่าที่ native runner
ต้องใช้ คอมเมนต์ภาษาไทยอธิบายหน้าที่และจุดส่งต่อหลัก โดยคงค่าตั้งค่าและโค้ดเดิมไว้

## อ่านการทดสอบตามพฤติกรรม

`test/` แบ่งตามเรื่องที่ผู้ใช้ทำและกติกาข้อมูล เช่น การตรวจจำนวนเงิน การเพิ่ม/แก้ไข/ลบ
ประวัติ สถิติ กราฟ และการไหลของข้อมูลจาก repository ไปหน้าจอ
ชุดทดสอบงบตรวจ codec/repository การคำนวณสถานะ ความแม่นยำหนึ่งสตางค์ การเปลี่ยนเดือน
ผลการบันทึก และ UI ที่จอแคบ/ตัวอักษรใหญ่ โดยใช้แหล่งข้อมูลจำลองในการทดสอบ

`ios/RunnerTests/RunnerTests.swift` และ `macos/RunnerTests/RunnerTests.swift`
เป็นโครง XCTest เริ่มต้นที่ยังไม่มีกรณีทดสอบ native จริง
ผลตรวจล่าสุดและวิธีรันแอปให้ดู [README](../README.md) และรายงานการตรวจของงานนั้น

## ไฟล์ที่อธิบายในคู่มือแทนการแทรกคอมเมนต์

- **JSON** เช่น `android/app/google-services.json`, `web/manifest.json` และ
  `Assets.xcassets/**/Contents.json` เป็นค่าตั้งค่า Firebase, เว็บแอป และรายการทรัพยากร
  ตามลำดับ รูปแบบ JSON ไม่รองรับคอมเมนต์ การแทรกข้อความจะทำให้เครื่องมืออ่านไม่ได้
- **ไฟล์สร้างอัตโนมัติ** เช่น `GeneratedPluginRegistrant.*`,
  `generated_plugin_registrant.*`, `generated_plugins.cmake`, `Generated.xcconfig`,
  `Flutter-Generated.xcconfig` และ `flutter_export_environment.sh` เชื่อมปลั๊กอิน/SDK
  และค่าของเครื่องที่ build เครื่องมืออาจเขียนทับไฟล์เหล่านี้ จึงไม่แก้คำอธิบายลงไฟล์
- **ส่วนที่ Flutter ดูแล** ได้แก่ `windows/flutter/CMakeLists.txt` และ
  `linux/flutter/CMakeLists.txt` ซึ่งระบุว่าไม่ควรแก้ รวมถึง `ephemeral/`, `.dart_tool/`,
  `build/`, cache และผล build เป็นขั้นตอน/ผลลัพธ์ของเครื่องมือ ไม่ใช่จุดแก้ตรรกะธุรกิจ
- **ข้อมูล IDE และ wrapper** เช่น `.xcodeproj`, `.xcworkspace`, `.iml`, storyboard/XIB,
  `gradlew*` และ Gradle wrapper JAR เป็นโครง/ข้อมูลที่เครื่องมือดูแล ส่วน
  `local.properties` ผูกกับ SDK บนเครื่อง จึงไม่แก้เพื่อใส่คำอธิบาย
- **รูปภาพ ไอคอน และไฟล์ไบนารี** เป็นทรัพยากรที่แอปหรือเครื่องมือเปิดใช้งานโดยตรง
  จึงอธิบายบทบาทผ่านคู่มือนี้แทนการแก้เนื้อหาไฟล์

แผนและเหตุผลการตัดสินใจของแต่ละส่วนอยู่ใน `docs/superpowers/specs/` และ
`docs/superpowers/plans/` ใช้อ่านประกอบเมื่อจะเปลี่ยนพฤติกรรมหรือขยายงานต่อ
