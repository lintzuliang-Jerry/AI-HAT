//BT_1

#include <Arduino.h>
#include <U8g2lib.h>
#include <BluetoothSerial.h>

BluetoothSerial SerialBT;

U8G2_SSD1322_NHD_256X64_1_4W_SW_SPI u8g2(U8G2_R0, /* clock=*/ 13, /* data=*/ 12, /* cs=*/ 14, /* dc=*/ 27, /* reset=*/ 26);

int val;
char temp;

char buffer1[96];
char buffer2[96];

int count = 0;

void setup(void) {
  u8g2.begin();
  u8g2.enableUTF8Print();
  Serial.begin(115200);

  // 初始化藍牙
  SerialBT.begin("ESP32_Display");  // 設定藍牙名稱
  Serial.println("藍牙已啟動，等待連接...");

  // 等待藍牙連接
  while (!SerialBT.connected()) {
    delay(100);  // 等待連接
  }
  Serial.println("藍牙連接成功！");

  u8g2.setContrast(0);
}


void loop(void) {
  // 檢查是否有藍牙資料傳入
  if (SerialBT.available() > 0) {
    val = SerialBT.read();

    if ((val == 0 || val == 80) || val == 255) {
      u8g2.setContrast(val);
    } else {
      temp = char(val);
      if (temp == '.') {
        do {
          u8g2.setCursor(0, 15);
          u8g2.print("-------------AI HAT-------------");
          u8g2.setCursor(0, 35);
          u8g2.print(buffer1);
          u8g2.setCursor(0, 55);
          u8g2.print(buffer2);
        } while (u8g2.nextPage());

        count = 0;
        SerialBT.end();
        SerialBT.begin("ESP32_Display");

        memset(buffer1, ' ', sizeof(buffer1));
        memset(buffer2, ' ', sizeof(buffer2));
      } else if (count <= 45) {
        buffer1[count] = temp;
      } else if (count <= 90) {
        buffer2[count - 45] = temp;
      }

      count++;
      if (count >= 91) {
        count = 0;
        SerialBT.end();
        SerialBT.begin("ESP32_Display");
        memset(buffer1, ' ', sizeof(buffer1));
        memset(buffer2, ' ', sizeof(buffer2));
      }
    }
  }
}
