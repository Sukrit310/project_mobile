// รับวงจรเริ่มต้นของแอป iOS และลงทะเบียนปลั๊กอินเมื่อ Flutter engine พร้อม
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ลงทะเบียนปลั๊กอินกับ engine ที่ iOS embedding เตรียมไว้ โดยไม่สร้าง engine ซ้ำ
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
