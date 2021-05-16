# Bluetooth Low Energy Bike Navigation
The application shows a GPS polyline on an external display, to help bikers follow the planned route without stops.

Prototype | ESP32
----- | ---------------
![ESP32 prototype image-1](/images/IMG-BikeNavi-prototype1-display.jpg) | ![ESP32 prototype image-2](/images/IMG-BikeNavi-prototype1-ESP32.jpg)

## How it works
The application on the phone runs in background, tracks user location, filters the part or route located nearby, converts it to graphical lines and sends to ESP32 using Bluetooth Low Energy:
* The phone acts as BLE Central
* ESP32 acts as BLE Peripheral

Application uses Apple MapKit with OpenStreetMap tiles (only iOS is supported so far).

## How to use
Route editing is manual and very basic:
* Every GPS point is added manually
* For now, only one GPS polyline is supported
* Points can be added/removed only one-by-one at the end of the polyline
* Route calculation not supported (and not planned)
* Route import/export is planned in future

ESP32:
* doesn't receive real GPS coordinates
* only draws graphical primitives (lines, triangles, etc.)

## Supported ESP32 modules
1. Regular ESP32 with external OLED display 128x128, enabled by-default - [how to connect](https://github.com/alexanderlavrushko/BLE-bike-navigation#display-oled-128x128)
1. ESP32 TTGO T-Display with embedded display 135x240 TFT - [how to enable](https://github.com/alexanderlavrushko/BLE-bike-navigation#ttgo-t-display)

### Required Arduino libraries for ESP32
* [Adafruit-GFX-Library](https://github.com/adafruit/Adafruit-GFX-Library) by Adafruit
* [Button2](https://github.com/LennartHennigs/Button2) by Lennart Hennigs
* [Adafruit-SSD1351-library](https://github.com/adafruit/Adafruit-SSD1351-library) (only for SSD1351 display)
* [TFT_eSPI adjusted by TTGO](https://github.com/Xinyuan-LilyGO/TTGO-T-Display) (only for TTGO T-Display)

### Display OLED 128x128
Display: Waveshare 14747 128x128 OLED RGB ([link](https://www.waveshare.com/1.5inch-rgb-oled-module.htm))

Connected this way:
ESP32 | Display WS14747
----- | ---------------
G23 | DIN
G18 | CLK
G5 | CS
G17 | DC
G16 | RST

### TTGO T-Display
To enable TTGO T-Display:
1. Download library [TFT_eSPI adjusted by TTGO](https://github.com/Xinyuan-LilyGO/TTGO-T-Display), copy TFT_eSPI folder to Arduino/libraries
1. Comment out the default display, uncomment TTGO display in ESP32-Arduino/BLEBikeNavi/BLEBikeNavi.ino
```
// comment out these lines 
//#include "OLED_SSD1351_Adafruit.h"
//OLED_SSD1351_Adafruit selectedDisplay;

// uncomment these lines
#include "TFT_TTGO.h"
TFT_TTGO selectedDisplay;
```
