#include "OLED_SSD1351_Adafruit.h"

namespace
{
    const int16_t SCREEN_WIDTH = 128;
    const int16_t SCREEN_HEIGHT = 128;
    const int16_t COLOR_BLACK = 0x0000;
    const int SCLK_PIN = 18; // this value not used because it's a default SCLK pin for VSPI
    const int MOSI_PIN = 23; // this value not used because it's a default MOSI pin for VSPI
    const int DC_PIN = 17;
    const int CS_PIN = 5;
    const int RST_PIN = 16;
}

OLED_SSD1351_Adafruit::OLED_SSD1351_Adafruit()
: m_width(SCREEN_WIDTH)
, m_height(SCREEN_HEIGHT)
{
}

void OLED_SSD1351_Adafruit::Init()
{
    if (m_driver.get() /*already initialized*/)
        return;

    m_spi.reset(new SPIClass(VSPI));
    m_spi->begin();
    m_spi->setHwCs(false);

    m_driver.reset(new Adafruit_SSD1351(m_width, m_height, m_spi.get(), CS_PIN, DC_PIN, RST_PIN));
    m_driver->begin();
    m_driver->fillScreen(COLOR_BLACK);
}

int16_t OLED_SSD1351_Adafruit::GetWidth()
{
    return m_width;
}

int16_t OLED_SSD1351_Adafruit::GetHeight()
{
    return m_height;
}

void OLED_SSD1351_Adafruit::SendImage(int16_t xStart,
                                      int16_t yStart,
                                      int16_t width,
                                      int16_t height,
                                      const uint16_t* data)
{
    // drawRGBBitmap(... const uint16_t bitmap[] ...) - uses pgm_read_word, tries to load each word from PROGMEM, which reduces performance
    // drawRGBBitmap(... uint16_t* bitmap ...) - is what we want to use
    // that's why we cast to non-const uint16_t*, to call the correct function
    uint16_t* data2 = const_cast<uint16_t*>(data);
    m_driver->drawRGBBitmap(xStart, yStart, data2, height, height);
}
