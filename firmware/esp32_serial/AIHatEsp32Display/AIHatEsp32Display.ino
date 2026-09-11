#include <Arduino.h>
#include <U8g2lib.h>

#ifdef U8X8_HAVE_HW_SPI
#include <SPI.h>
#endif
#ifdef U8X8_HAVE_HW_I2C
#include <Wire.h>
#endif

U8G2_SSD1322_NHD_256X64_1_4W_SW_SPI u8g2(U8G2_R0, /* clock=*/ 13, /* data=*/ 12, /* cs=*/ 14, /* dc=*/ 27, /* reset=*/ 26);	// Enable U8G2_16BIT in u8g2.h

int val;
char temp;

char buffer1[96];
char buffer2[96];

int count = 0;

void setup(void) {
  u8g2.begin();
  u8g2.enableUTF8Print();
  Serial.begin(9600);
  Serial.setTimeout(5);
  u8g2.setContrast(0);
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
      } else if (count <= 45) {
        buffer1[count] = temp;
      } else if (count <= 90) {
        buffer2[count - 45] = temp;
      }

      count++;
      if (count >= 91) {//192
        count = 0;
        Serial.end();
        Serial.begin(9600);
        memset(buffer1, ' ', sizeof(buffer1));
        memset(buffer2, ' ', sizeof(buffer2));
      }
    }
  }
}
