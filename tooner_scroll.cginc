#ifndef __TOONER_SCROLL
#define __TOONER_SCROLL

#include "globals.cginc"
#include "math.cginc"
#include "pema99.cginc"

#if 0
float _Scroll_Toggle;
float _Scroll_Top;
float _Scroll_Bottom;
float _Scroll_Width;
float _Scroll_Strength;
float _Scroll_Speed;
#endif

float3 applyScroll(float3 p, float3 n, float3 avg_pos) {
#if defined(_SCROLL)
  float phase = glsl_mod(_Time[1] * _Scroll_Speed, 1.0);

  float z1 = _Scroll_Top;
  float z0 = _Scroll_Bottom;
  float zc = (z1 - z0) * phase + z0;

  float3 op = mul(unity_WorldToObject, float4(p, 1)).xyz;

  float offset =
    1 / (1 + pow(.5 * (zc - op.y) / _Scroll_Width, 6));

  p -= avg_pos;
  float3 axis = normalize(float3(
      rand((int) p.x * 1.0E6),
      rand((int) p.y * 1.0E6),
      rand((int) p.z * 1.0E6)));
  float theta = offset * .5;
  float4 quat = get_quaternion(axis, theta);
  p = rotate_vector(p, quat);
  p += avg_pos;

  return p + n * offset * _Scroll_Strength;
#else
  return p;
#endif  // _SCROLL
}

#endif  // __TOONER_SCROLL

