#include <Arduino.h>
#include <U8g2lib.h>

#ifdef U8X8_HAVE_HW_SPI
#include <SPI.h>
#endif
#ifdef U8X8_HAVE_HW_I2C
#include <Wire.h>
#endif

U8G2_SSD1322_NHD_256X64_1_4W_SW_SPI u8g2(U8G2_R0, /* clock=*/ 13, /* data=*/ 11, /* cs=*/ 10, /* dc=*/ 9, /* reset=*/ 8); // Enable U8G2_16BIT in u8g2.h

int val,x; //----------------------
String str1; //----------------------
char temp, buffer0[30], buffer1[32], buffer2[32]; //-------------
int count = 0,light;
int init_flag=1;

void setup(void) {

  u8g2.begin();
  u8g2.enableUTF8Print();   // enable UTF8 support for the Arduino print() function
  Serial.begin(9600); //-----------------
  Serial.setTimeout(5); //---------------



}

void loop(void)
{
  u8g2.setFont(u8g2_font_unifont_t_chinese2);  // use chinese2 for all the glyphs of "你好世界"

  u8g2.setFontDirection(0);
  u8g2.firstPage();

  if (Serial.available()>0)
  {
      val=Serial.read();       //-------------------
    if(init_flag==1)
    {light=val;
     u8g2.setContrast(light);
     init_flag=0;

    }

    else
    {

      //Serial.print(val);
      temp = char(val);
      if(temp=='.')
      {delay(1000);
        count=0;
       Serial.end();
       Serial.begin(9600);
       for(int i=0;i<=31;i++)
           {buffer1[i]=' ';
            buffer2[i]=' ';
           }


      }
      if (count <=31)
      { if(temp!='.')
          buffer1[count] = temp;
      }
      else
      {
        if(temp!='.')
          buffer2[count-32] = temp;
      }

       count++;
      if(count>=64)
        {count=0;
         Serial.end();
         Serial.begin(9600);
         for(int i=0;i<=31;i++)
           {buffer1[i]=' ';
            buffer2[i]=' ';
           }
         }
    }

  }

  //sprintf(buffer,"%s",val);

    do {
    u8g2.setCursor(0, 15);
    u8g2.print("-------------AI HAT-------------");

    u8g2.setCursor(0, 35); //-----------------------
    u8g2.print(String(buffer1)); //------------------
   // u8g2.print(buffer);
    u8g2.setCursor(0, 55);
    u8g2.print(String(buffer2));
    //u8g2.setContrast(light);
//    u8g2.setCursor(60, 55);
//    u8g2.print(String(buffer2[8]));
//    u8g2.print("Hello World!");


  } while ( u8g2.nextPage() );


   //delay(1000);
}
