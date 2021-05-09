#ifndef TFT_TTGO_H_INCLUDED
#define TFT_TTGO_H_INCLUDED

#include "IDisplay.h"

// Copy folder TFT_eSPI to Arduino/libraries from here:
// https://github.com/Xinyuan-LilyGO/TTGO-T-Display
#include <TFT_eSPI.h>

class TFT_TTGO: public IDisplay
{
public:
    TFT_TTGO();

    // prohibited
    TFT_TTGO(const TFT_TTGO&) = delete;
    TFT_TTGO& operator=(const TFT_TTGO&) = delete;
    TFT_TTGO(TFT_TTGO&&) = delete;
    TFT_TTGO& operator=(TFT_TTGO&&) = delete;

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

private:
    bool m_isInitialized;
    TFT_eSPI m_tft;
    int16_t m_width;
    int16_t m_height;
};

#endif // TFT_TTGO_H_INCLUDED
