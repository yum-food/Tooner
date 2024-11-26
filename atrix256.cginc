#ifndef __ATRIX256_INC
#define __ATRIX256_INC
/*
MIT License

Copyright (c) 2021 Alan Wolfe

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// Interleaved gradient noise.
// ported from this repo: https://github.com/Atrix256/IGNLDS
// blog post: https://blog.demofox.org/2017/10/31/animating-noise-for-integration-over-time
float ign(float2 screen_px) {
  return fmod(52.9829189 *
      fmod(0.06711056 * screen_px.x +
        0.00583715 * screen_px.y, 1), 1);
}

float ign_anim(float2 screen_px, float frame, float speed) {
  frame = fmod(frame * speed, 64);
  return ign(screen_px + frame * 5.588238f);
}

#endif  // __ATRIX256_INC

