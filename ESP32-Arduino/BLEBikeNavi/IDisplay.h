#ifndef IDISPLAY_H_INCLUDED
#define IDISPLAY_H_INCLUDED

#include <stdint.h>

class IDisplay
{
public:
    virtual ~IDisplay() = default;

    virtual void Init() = 0;
    virtual int16_t GetWidth() = 0;
    virtual int16_t GetHeight() = 0;
    virtual void SendImage(int16_t xStart,
                           int16_t yStart,
                           int16_t width,
                           int16_t height,
                           const uint16_t* data) = 0;
};

#endif // IDISPLAY_H_INCLUDED
