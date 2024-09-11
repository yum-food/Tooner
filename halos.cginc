#ifndef __HALOS_INC
#define __HALOS_INC

#include "globals.cginc"
#include "interpolators.cginc"
#include "math.cginc"

#if defined(_GIMMICK_HALO_00)
struct Halo00Params {
  float3 period;
  float3 count;
  float2 uv;
};
struct Halo00PBR {
  float4 albedo;
  float3 normal;
};

float halo00_map(float3 p, float2 e)
{
  return length(p) - 0.1;
}

float halo00_map_dr(
    float3 p,
    Halo00Params params,
    out float3 which
    )
{
  which = round(p / params.period);
  // Direction to nearest neighboring cell.
  float3 min_d = p - params.period * which;
  float3 o = sign(min_d);

  float d = 1E9;
  float3 which_tmp = which;
  for (int xi = 0; xi < 1; xi++)
  for (int yi = 0; yi < 1; yi++)
  {
    float3 rid = which + float3(xi, yi, 0) * o;
    rid = clamp(rid, ceil(-(params.count)*0.5), floor((params.count-1)*0.5));
    float3 r = p - params.period * rid;
    float2 e = 0;
    /*
    float2 e = float2(
        rand3(rid / 100.0),
        rand3(rid / 100.0 + 1));
    */
    float cur_d = halo00_map(r, e);
    which_tmp = 
        (cur_d < d ? rid : which_tmp);
    d = min(d, cur_d);
  }

  which = which_tmp;
  return d;
}

float3 halo00_calc_normal(float3 p, Halo00Params params)
{
    const float3 small_step = float3(0.0001, 0.0, 0.0);

    // TODO do we need full central differences?
    float3 which;
    float gradient_x = halo00_map_dr(p + small_step.xyy, params, which) -
      halo00_map_dr(p - small_step.xyy, params, which);
    float gradient_y = halo00_map_dr(p + small_step.yxy, params, which) -
      halo00_map_dr(p - small_step.yxy, params, which);
    float gradient_z = halo00_map_dr(p + small_step.yyx, params, which) -
      halo00_map_dr(p - small_step.yyx, params, which);

    float3 normal = float3(gradient_x, gradient_y, gradient_z);

    return normalize(normal);
}

void __halo00_march(float3 ro, float3 rd, Halo00Params params, out Halo00PBR result)
{
  float total_distance_traveled = 0.0;
  const float MINIMUM_HIT_DISTANCE = 0.001;
  const float MAXIMUM_TRACE_DISTANCE = 10.0;
  
  ro -= (1 - (params.count % 2)) * params.period * 0.5;

#define HALO00_MARCH_STEPS 30
  float distance_to_closest;
  float3 current_position;
  float3 which;
  for (int i = 0; i < HALO00_MARCH_STEPS; i++)
  {
    current_position = ro + total_distance_traveled * rd;

    distance_to_closest = halo00_map_dr(current_position, params, which);

    if (distance_to_closest < MINIMUM_HIT_DISTANCE) 
    {
      break;
    }

    if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE)
    {
      break;
    }
    total_distance_traveled += distance_to_closest;
  }

  if (distance_to_closest < MINIMUM_HIT_DISTANCE) {
    result.albedo = 1;
    result.normal = halo00_calc_normal(current_position, params);
    return;
  }

  result.albedo = 0;
  result.normal = 0;
  return;
}

Halo00PBR halo00_march(float3 worldPos, float2 uv)
{
  Halo00PBR result;
  Halo00Params params;
  params.period = 0.2;
  params.count = 5;
  params.uv = uv;

  float3 camera_position = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1));
  float3 ro = camera_position;
  float3 rd = normalize(mul(unity_WorldToObject, float4(worldPos - _WorldSpaceCameraPos.xyz, 1)));

  __halo00_march(ro, rd, params, result);

  return result;
}

#endif  // _GIMMICK_HALO_00

#endif  // _HALOS_INC
