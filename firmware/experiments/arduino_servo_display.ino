#include <Arduino.h>
#include <U8g2lib.h>

#ifdef U8X8_HAVE_HW_SPI
#include <SPI.h>
#endif
#ifdef U8X8_HAVE_HW_I2C
#include <Wire.h>
#endif

#include <Servo.h> //Servo

U8G2_SSD1322_NHD_256X64_1_4W_SW_SPI u8g2(U8G2_R0, /* clock=*/ 13, /* data=*/ 11, /* cs=*/ 10, /* dc=*/ 9, /* reset=*/ 8);
Servo myservo;  // 創建伺服馬達對象

int val;
char temp;
char buffer1[47];//47
char buffer2[47];
int count = 0;

unsigned long lastInputTime = 0; // 跟踪最後一次收到數據的時間
const unsigned long timeout = 5000; // 設定超時時間為5000毫秒（5秒）

void setup(void) {
  u8g2.begin();
  u8g2.enableUTF8Print();
  Serial.begin(9600);
  Serial.setTimeout(5);
  u8g2.setContrast(0);

  myservo.attach(7); // 將伺服馬達連接到7號引腳
  // myservo.write(0); // 設置初始角度為0度

  lastInputTime = millis(); // 初始化最後接收數據的時間

}

void loop(void) {
  u8g2.setFont(u8g2_font_unifont_t_chinese2);
  u8g2.setFontDirection(0);
  u8g2.firstPage();

  if (Serial.available() > 0) {

    val = Serial.read();
    if ((val == 0 || val == 80) || val == 255) {
      u8g2.setContrast(val);
    } else {
      temp = char(val);
      if (temp == '.') {

        lastInputTime = millis(); // 更新收到數據的時間
        myservo.write(90);// 控制伺服馬達轉到90度

        do {
        u8g2.setCursor(0, 15);
        u8g2.print("-------------AI HAT-------------");
        u8g2.setCursor(0, 35);
        u8g2.print(buffer1);
        u8g2.setCursor(0, 55);
        u8g2.print(buffer2);
        } while (u8g2.nextPage());

        count = 0;
        Serial.end();
        Serial.begin(9600);

        memset(buffer1, ' ', sizeof(buffer1));
        memset(buffer2, ' ', sizeof(buffer2));
      } else if (count < 45) {

        buffer1[count] = temp;
      } else if (count < 90) {
        buffer2[count - 45] = temp;
      }

      count++;
      if (count >= 90) {
        count = 0;
        Serial.end();
        Serial.begin(9600);
        memset(buffer1, ' ', sizeof(buffer1));
        memset(buffer2, ' ', sizeof(buffer2));
      }
    }
  }
    // 檢查是否超過5秒未收到數據
  if (millis() - lastInputTime >= timeout) {
    myservo.write(0); // 轉到0度
    lastInputTime = millis(); // 重置時間，防止重複觸發
  }
}
