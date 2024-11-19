#ifndef __TONE_IQ_INC
#define __TONE_IQ_INC

// The MIT License
// Copyright © 2019-2024 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// https://iquilezles.org/articles/functions/
float almost_identity( float x, float m, float n )
{
  float a = 2.0*n - m;
  float b = 2.0*m - 3.0*n;
  float t = x/m;
  return lerp(
      (a*t + b)*t*t + n,
      x,
      x > m);
}
float3 almost_identity( float3 x, float3 m, float3 n )
{
  float3 a = 2.0*n - m;
  float3 b = 2.0*m - 3.0*n;
  float3 t = x/m;
  return lerp(
      (a*t + b)*t*t + n,
      x,
      x > m);
}

#endif  // __TONE_IQ_INC

