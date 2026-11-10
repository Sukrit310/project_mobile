// จุดเข้า Linux ที่สร้าง MyApplication และส่งการควบคุมให้วงจร GTK
#include "my_application.h"

int main(int argc, char** argv) {
  g_autoptr(MyApplication) app = my_application_new();
  // ส่งอาร์กิวเมนต์และเริ่มวงจรเหตุการณ์ที่ดูแลหน้าต่างจนแอปปิด
  return g_application_run(G_APPLICATION(app), argc, argv);
}
