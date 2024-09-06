#ifndef __RORSCHACH_INC
#define __RORSCHACH_INC

#if defined(_RORSCHACH)

#include "globals.cginc"
#include "interpolators.cginc"
#include "iq_sdf.cginc"
#include "pema99.cginc"

struct RorschachPBR {
  float4 albedo;
};

float map_sdf(float3 p, float2 e, float3 period)
{
  float r = 1 * min(period.x, min(period.y, period.z));
  float st = sin(_Time[1] * e.y * e.y + e.x * 3.14159265 * 2);
  r *= st;
  return distance_from_sphere(p, r);
}

float map_dr(
    float3 p,
    float3 period,
    float3 count,
    out float3 which
    )
{
  which = round(p / period);
  // Direction to nearest neighboring cell.
  float3 min_d = p - period * which;
  float3 o = sign(min_d);

  float d = 1E9;
  float3 which_tmp = which;
  for (int xi = -2; xi < 3; xi++)
  for (int yi = -2; yi < 3; yi++)
  {
    float3 rid = which + float3(xi, yi, 0) * o;
    float3 r = p - period * rid;
    float2 e = float2(
        rand3(rid),
        rand3(rid + 1));
    float cur_d = map_sdf(r, e, period);
    which_tmp = cur_d < d ? rid : which;
    d = min(d, cur_d);
  }

  which = which_tmp;
  return d;
}

RorschachPBR get_rorschach(v2f i)
{
  RorschachPBR result;
  result.albedo = float4(0, 0, 0, 1);

  float3 ro = float3(i.uv0.x - 0.5, i.uv0.y - 0.5, 0);
  float3 rd = float3(0, 0, 1);

  float3 which;
  float3 period = float3(1 / (_Rorschach_Count_X+1), 1 / (_Rorschach_Count_Y+1), 1);
  float3 count = float3(_Rorschach_Count_X, _Rorschach_Count_Y, 1);
  float d = map_dr(ro, period, count, which);
  d -= map_dr(1 - ro, period, count, which) * 4;

  d = 1 - d;
  d *= d;
  d *= d;
  d *= d;
  d = 1 - d;

  d *= 3;
  d = saturate(d);

  result.albedo.rgb = d;

  return result;
}

#endif  // _RORSCHACH
#endif  // __RORSCHACH_INC
