#ifndef OLED_SSD1351_ADAFRUIT_H_INCLUDED
#define OLED_SSD1351_ADAFRUIT_H_INCLUDED

#include "IDisplay.h"
#include <Adafruit_SSD1351.h> // available in Arduino libraries, or https://github.com/adafruit/Adafruit-SSD1351-library
#include <memory>

class OLED_SSD1351_Adafruit: public IDisplay
{
public:
    OLED_SSD1351_Adafruit();

    // prohibited
    OLED_SSD1351_Adafruit(const OLED_SSD1351_Adafruit&) = delete;
    OLED_SSD1351_Adafruit& operator=(const OLED_SSD1351_Adafruit&) = delete;
    OLED_SSD1351_Adafruit(OLED_SSD1351_Adafruit&&) = delete;
    OLED_SSD1351_Adafruit& operator=(OLED_SSD1351_Adafruit&&) = delete;

public:
    // override
    void Init() override;
    int16_t GetWidth() override;
    int16_t GetHeight() override;
    void SendImage(int16_t xStart,
                   int16_t yStart,
                   int16_t width,
                   int16_t height,
                   const uint16_t* data) override;
    void EnterSleepMode() override;

private:
    std::unique_ptr<Adafruit_SSD1351> m_driver;
    std::unique_ptr<SPIClass> m_spi;
    int16_t m_width;
    int16_t m_height;
};

#endif // OLED_SSD1351_ADAFRUIT_H_INCLUDED
