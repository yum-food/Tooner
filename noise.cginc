#include "math.cginc"

#ifndef __NOISE_INC
#define __NOISE_INC

float cubic_interp(float x)
{
  return x * x * (3.0 - 2.0 * x);
}

float2 cubic_interp(float2 x)
{
  return x * x * (3.0 - 2.0 * x);
}

float3 cubic_interp(float3 x)
{
  return x * x * (3.0 - 2.0 * x);
}

float quintic_interp(float x)
{
  return x * x * x * (x * (x * 6 - 15) + 10);
}

float2 quintic_interp(float2 x)
{
  return x * x * x * (x * (x * 6 - 15) + 10);
}

float perlin_noise(float2 p)
{
  float2 sq = floor(p);
  float2 sqi = frac(p);

  float r0 = rand2(sq + float2(0,0));
  float r1 = rand2(sq + float2(1,0));
  float r2 = rand2(sq + float2(0,1));
  float r3 = rand2(sq + float2(1,1));

  float2 u = cubic_interp(sqi);

  return lerp(r0, r1, u.x) +
    (r2 - r0) * u.y * (1.0 - u.x) +
    (r3 - r1) * u.x * u.y;
}

float perlin_noise_3d(float3 p)
{
  float3 sq = floor(p);
  float3 sqi = frac(p);

  float r0 = rand3(sq + float3(0,0,0));
  float r1 = rand3(sq + float3(1,0,0));
  float r2 = rand3(sq + float3(0,1,0));
  float r3 = rand3(sq + float3(1,1,0));
  float r4 = rand3(sq + float3(0,0,1));
  float r5 = rand3(sq + float3(1,0,1));
  float r6 = rand3(sq + float3(0,1,1));
  float r7 = rand3(sq + float3(1,1,1));

  float3 u = cubic_interp(sqi);

  return lerp(
      lerp(r0, r1, u.x) +
        (r2 - r0) * u.y * (1.0 - u.x) +
        (r3 - r1) * u.x * u.y,
      lerp(r4, r5, u.x) +
        (r6 - r4) * u.y * (1.0 - u.x) +
        (r7 - r5) * u.x * u.y,
      u.z);
}

float simplex_noise(float2 p)
{
  float2 sq = floor(p);
  float2 sqi = frac(p);

  float r0 = rand2(sq + float2(0,0));
  float r1 = rand2(sq + float2(1,0));
  float r2 = rand2(sq + float2(0,1));
  float r3 = rand2(sq + float2(1,1));

  float2 u = quintic_interp(sqi);

  return lerp(r0, r1, u.x) +
    (r2 - r0) * u.y * (1.0 - u.x) +
    (r3 - r1) * u.x * u.y;
}

#endif  // __NOISE_INC

