// ควบคุมการปิดแอปและการกู้คืนสถานะหน้าต่างของ runner บน macOS
import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // ปิด process เมื่อหน้าต่างสุดท้ายปิด ตามพฤติกรรมที่ runner นี้เลือกใช้
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
