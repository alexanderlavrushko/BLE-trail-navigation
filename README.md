# Bluetooth Low Energy Bike Navigation
The application shows a GPS polyline on an external display, to help bikers follow the planned route without stops.

Prototype | ESP32
----- | ---------------
![ESP32 prototype image-1](/images/IMG-BikeNavi-prototype1-display.jpg) | ![ESP32 prototype image-2](/images/IMG-BikeNavi-prototype1-ESP32.jpg)

## How it works
The application on the phone runs in background, tracks user location, filters the part or route located nearby, converts it to graphical lines and sends to ESP32 using Bluetooth Low Energy:
* The phone acts as BLE Central
* ESP32 acts as BLE Peripheral

Only iOS application is implemented so far.

Route editing is manual and very basic:
* Every GPS point is added manually
* For now, only one GPS polyline is supported
* Points can be added/removed only one-by-one at the end of the polyline
* Route calculation not supported (and not planned)
* Route import/export is planned in future

ESP32:
* doesn't receive real GPS coordinates
* only draws graphical primitives (lines, triangles, etc.)

### Display OLED 128x128
Display: Waveshare 14747 128x128 OLED RGB ([link](https://www.waveshare.com/1.5inch-rgb-oled-module.htm))

Protocol: SSD1351

This library is required for Arduino project: [Adafruit-SSD1351-library](https://github.com/adafruit/Adafruit-SSD1351-library).

Connected this way:
ESP32 | Display WS14747
----- | ---------------
G23 | DIN
G18 | CLK
G5 | CS
G17 | DC
G16 | RST
