// สร้าง FlutterViewController ให้หน้าต่างหลัก macOS และเชื่อมปลั๊กอิน
import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // เปลี่ยนพื้นที่เนื้อหาของหน้าต่างเป็น Flutter โดยรักษากรอบหน้าต่างเดิม
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // ให้ปลั๊กอินใช้ engine ของหน้าต่างที่เพิ่งสร้าง
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
