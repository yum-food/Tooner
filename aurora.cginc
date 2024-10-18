#include "globals.cginc"
#include "interpolators.cginc"
#include "math.cginc"
#include "noise.cginc"
#include "cnlohr.cginc"

#ifndef __AURORA_INC
#define __AURORA_INC

struct AuroraPBR {
  float4 albedo;
  float3 diffuse;
  float depth;
};

float2 rotate2D(float2 v, float theta) {
  return mul(float2x2(
        cos(theta), -sin(theta),
        sin(theta), cos(theta)), v);
}

AuroraPBR getAurora(v2f i) {
  AuroraPBR result;
  result.albedo.a = 1;

  // Map onto [-1, 1]
  float t = _Time[1];
  float2 uv = i.uv0;
  float c = 0;

  uv = rotate2D(uv, t * .101);
  uv *= 0.9;
  float c_term = sin(3.14159265 * uv.x * uv.x + t) - 0.25;
  c = c_term * c_term;

  uv = rotate2D(uv, -t * .67);
  c_term = (sin(-3.14159265 * uv.x * uv.x * 4 + t/4) - 0.25) * .5;
  c += c_term * c_term;

  uv = rotate2D(uv, t * .31);
  c += (sin(-3.14159265 * uv.y * uv.y * 16 + t/8) - 0.25) * .25;

  uv = rotate2D(uv, t * .15);
  c += (sin(-3.14159265 * uv.x * uv.y * 16 + t/16) - 0.25) * .125;

  c *= 0.5;

  c -= sin(3.14159265 * uv.x * uv.y * 16) * .5 + 0.5;

  const float2 uv_c = i.uv0 * 2.0 - 1;
  float center_distance_term = saturate(1.0 - dot(uv_c, uv_c));
  c *= center_distance_term * center_distance_term * center_distance_term * center_distance_term;

  result.albedo.rgb = saturate(c);

  result.diffuse = 0;

  float4 clip_pos = mul(UNITY_MATRIX_VP, float4(i.worldPos, 1.0));
  result.depth = clip_pos.z / clip_pos.w;

  return result;
}

#endif  // __AURORA_INC

