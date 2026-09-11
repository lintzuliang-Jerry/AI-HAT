# 安裝與操作指南

## 1. 硬體

核心 Arduino Uno firmware 使用軟體 SPI 連接 SSD1322 256×64 OLED：

| OLED 訊號 | Arduino Uno pin |
|---|---:|
| Clock | 13 |
| Data | 11 |
| Chip select | 10 |
| Data/command | 9 |
| Reset | 8 |

ESP32 序列埠版本的對應 pin 為 Clock 13、Data 12、CS 14、DC 27、Reset 26。電源與邏輯電壓請以實際 OLED 模組規格為準，不要僅依訊號表接線。

## 2. Firmware

1. 安裝 Arduino IDE。
2. 透過 Library Manager 安裝 `U8g2`。
3. 開啟與控制板相符的 `.ino`：
   - `firmware/arduino_uno/AIHatDisplay/AIHatDisplay.ino`
   - `firmware/esp32_serial/AIHatEsp32Display/AIHatEsp32Display.ino`
4. 選擇控制板與序列埠後編譯、燒錄。
5. 兩個版本都以 9600 baud 接收資料。

Arduino Uno 版本保留原型的傳輸行為：連線後第一個 byte 用來設定對比，後續 UTF-8 文字以 `.` 結束。ESP32 序列版本則把數值 `0`、`80`、`255` 視為對比指令。

## 3. MATLAB GUI

1. 使用 MATLAB R2023a Update 2 或更新版本開啟 `matlab/apps/core/app_final.mlapp`。
2. 在 App Designer 的 Code View 搜尋 `COM3`，改成 Windows 裝置管理員顯示的實際序列埠。
3. 確認系統的 `F2` 可啟動語音輸入；現有 App 會模擬 `F2`、等待語音輸入，再模擬 `Enter`。
4. 執行 App，按下「開始」。
5. 可在 GUI 中選擇 OLED 對比設定，並比對語音辨識結果與 OLED 輸出。

`.mlapp` 是可編輯的主要來源。`matlab/exported/` 只供 GitHub code review 與搜尋；若修改 App，請重新從 `.mlapp` 匯出，不要讓兩份來源分歧。

## 4. 實驗版

`matlab/apps/experimental/` 的 App 建立於 MATLAB R2024a，並使用下列功能：

- Audio Toolbox：`detectSpeech`、`audioDeviceReader`
- Windows/Java AWT keyboard events
- YAMNet（喇叭聲偵測版本）

這些檔案保留了 `COM5`、`COM10` 或 `D:\voice` 等開發機路徑。執行前必須依本機環境修改；YAMNet 權重與音訊資料因容量與授權因素未納入 repository。

## 5. 已知限制

- 現有語音輸入流程依賴 Windows 快捷鍵，不是跨平台設計。
- COM port 尚未改為 GUI 設定項。
- 序列通訊以句點作為結束符，訊息本身若含句點會提早結束。
- 顯示緩衝區以 byte 計數；UTF-8 中文字數與 byte 數不同。
- Firmware 與 MATLAB App 尚無 CI 或硬體在迴路測試。
