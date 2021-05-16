#include "TFT_TTGO.h"

namespace
{
    const int16_t SCREEN_WIDTH = 135;
    const int16_t SCREEN_HEIGHT = 240;
}

TFT_TTGO::TFT_TTGO()
: m_isInitialized(false)
, m_width(SCREEN_WIDTH)
, m_height(SCREEN_HEIGHT)
, m_tft(SCREEN_WIDTH, SCREEN_HEIGHT)
{
}

void TFT_TTGO::Init()
{
    if (m_isInitialized)
        return;

    m_isInitialized = true;
    m_tft.init();
    m_tft.setRotation(0);
    m_tft.fillScreen(TFT_BLACK);
}

int16_t TFT_TTGO::GetWidth()
{
    return m_width;
}

int16_t TFT_TTGO::GetHeight()
{
    return m_height;
}

void TFT_TTGO::SendImage(int16_t xStart,
                         int16_t yStart,
                         int16_t width,
                         int16_t height,
                         const uint16_t* data)
{
    m_tft.setAddrWindow(xStart, yStart, width, height);
    m_tft.pushColors(const_cast<uint16_t*>(data), width * height, /*swap = */true);
}

void TFT_TTGO::EnterSleepMode()
{
    m_tft.fillScreen(TFT_BLACK); // avoid short blink during next wake up, fill the screen now
    digitalWrite(TFT_BL, LOW); // turn backlight off
    
    m_tft.writecommand(TFT_DISPOFF);
    m_tft.writecommand(TFT_SLPIN);
}
