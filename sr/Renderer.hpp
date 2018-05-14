//
//  SoftwareRenderer
//

#pragma once

#include "Color.hpp"
#include "Buffer.hpp"

namespace sr
{
    class Renderer
    {
    public:
        Renderer();

        bool init(uint32_t width, uint32_t height);
        bool resize(uint32_t width, uint32_t height);

        bool clear(Color color, float depth);
        bool draw();

        const Buffer& getFrameBuffer() const { return frameBuffer; }
        const Buffer& getDepthBuffer() const { return depthBuffer; }

    private:
        Buffer frameBuffer;
        Buffer depthBuffer;
    };
}