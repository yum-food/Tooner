#include "atrix256.cginc"
#include "globals.cginc"
#include "interpolators.cginc"
#include "iq_sdf.cginc"
#include "math.cginc"
#include "oklab.cginc"

#ifndef __DOWNSTAIRS_02_INC
#define __DOWNSTAIRS_02_INC

#if defined(_GIMMICK_DS2)

// All gimmicks here return this structure.
struct Gimmick_DS2_Output {
  float4 albedo;
  float3 emission;
  float3 normal;
  float3 worldPos;
  float metallic;
  float roughness;
};


float ds2_00_distance_from_sphere(float3 p, float3 c, float r)
{
  return length(p - c) - r;
}

float ds2_00_map(float3 p, out float which)
{
  float t = _Time.y;
  float theta = sin(_Time[0]) / 2;
  float2x2 rot = float2x2(
    cos(theta), -sin(theta),
    sin(theta), cos(theta));

  which = 0;
  float dist = 1000 * 1000 * 1000;
  #define Y_STEPS 5
  for (int y = 0; y < Y_STEPS; y++)
  {
    const int yy = y - Y_STEPS/2;
    #define X_STEPS 5
    for (int x = 0; x < X_STEPS; x++)
    {
      const int xx = x - X_STEPS/2;
      float2 pp = float2(xx * 2, yy * 2);
      pp = mul(rot, pp);
      float radius = cos((x + y + _Time[0]) * 3.14159) * 0.5 + 1;
      float sphere = ds2_00_distance_from_sphere(p, float3(pp.x, pp.y, 0.0), radius);
      which = lerp(which, y * Y_STEPS + x, sphere < dist);
      dist = min(dist, sphere);
      dist += sin(5.0 * pp.x) * sin(5.0 * pp.y) * 0.5;
    }
  }

  return dist;
}

float3 ds2_00_calc_normal(in float3 p)
{
  const float3 small_step = float3(1E-4, 0.0, 0.0);

  float which;
  float center = ds2_00_map(p, which);
  float gradient_x = ds2_00_map(p + small_step.xyy, which) - center;
  float gradient_y = ds2_00_map(p + small_step.yxy, which) - center;
  float gradient_z = ds2_00_map(p + small_step.yyx, which) - center;

  float3 normal = float3(gradient_x, gradient_y, gradient_z);

  return normalize(normal);
}

bool __ds2_00_march(float3 ro, float3 rd, inout float3 normal, out float which)
{
  float total_distance_traveled = 0.0;
  const float MINIMUM_HIT_DISTANCE = 0.001;
  const float MAXIMUM_TRACE_DISTANCE = 1000.0;

  #define DS2_00_MARCH_STEPS 10
  float distance_to_closest;
  float3 current_position;
  for (int i = 0; i < DS2_00_MARCH_STEPS; i++)
  {
      current_position = ro + total_distance_traveled * rd;

      distance_to_closest = ds2_00_map(current_position, which);

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
    normal = ds2_00_calc_normal(current_position);
    return true;
  }

  return false;
}

Gimmick_DS2_Output Gimmick_DS2_00(v2f i)
{
  float2 uv = i.uv0;
  uv *= 2;
  uv -= 1;
  float2 warping_speed_vector = normalize(float2(97, 101));
  for (uint ii = 0; ii < _Gimmick_DS2_00_Domain_Warping_Octaves; ii++)
  {
      float2 noise = _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, uv * _Gimmick_DS2_00_Domain_Warping_Scale + _Time[0] * _Gimmick_DS2_00_Domain_Warping_Speed * warping_speed_vector, 0);
      uv += noise * _Gimmick_DS2_00_Domain_Warping_Strength;
  }

  float3 camera_position = float3(0.0, 0.0, -5.0);
  float3 ro = camera_position;
  float3 rd = float3(uv.x, uv.y, 1.0);

  float3 normal;
  float which;
  bool hit = __ds2_00_march(ro, rd, normal, which);

  float3 shaded_color = LRGBtoOKLCH(float3(0.7, 0, 0));
  shaded_color[2] = which * TAU * 1.1 + _Time[1];
  shaded_color = OKLCHtoLRGB(shaded_color);
  
  shaded_color *= hit;

  Gimmick_DS2_Output o;
  o.albedo = float4(shaded_color * 5, 1.0);
  o.emission = shaded_color;
  o.normal = normal;
  o.metallic = 0;
  o.roughness = 1;
  o.worldPos = i.worldPos;
  return o;
}

float ds2_01_map(float3 p)
{
  p.z -= _Gimmick_DS2_01_Radius;
  return distance_from_sphere(p, _Gimmick_DS2_01_Radius);
}

float3 ds2_01_nudge_p(float3 p, float3 e)
{
  return p + sin(e*TAU+_Time[0]*4) * _Gimmick_DS2_01_Radius * .5;
}

float ds2_01_map_dr(
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
  for (uint xi = 0; xi < 2; xi++)
  for (uint yi = 0; yi < 2; yi++)
  {
    float3 rid = which + float3(xi, yi, 0) * o;
    rid = clamp(rid, ceil(-(count)*0.5), floor((count-1)*0.5));
    float3 r = p - period * rid;
    float3 e = float3(
        rand3(rid / 100.0),
        rand3(rid / 100.0 + 1),
        rand3(rid / 100.0 + 2));
    r = ds2_01_nudge_p(r, e);
    float cur_d = ds2_01_map(r);
    which_tmp = cur_d < d ? rid : which_tmp;
    d = min(d, cur_d);
  }

  which = which_tmp;
  return d;
}


float3 ds2_01_calc_normal(float3 p, float3 period, float3 count)
{
  const float3 small_step = float3(1E-5, 0.0, 0.0);
  float3 which;
  float center = ds2_01_map_dr(p, period, count, which);
  return normalize(float3(
    ds2_01_map_dr(p + small_step.xyz, period, count, which) - center,
    ds2_01_map_dr(p + small_step.zxy, period, count, which) - center,
    ds2_01_map_dr(p + small_step.yzx, period, count, which) - center
  ));
}

Gimmick_DS2_Output Gimmick_DS2_01(inout v2f i)
{
  float3 camera_position = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
  float3 ro = i.objPos;
  float3 rd = normalize(i.objPos - camera_position);

  float2 warping_speed_vector = normalize(float2(97, 101));
  for (uint ii = 0; ii < _Gimmick_DS2_01_Domain_Warping_Octaves; ii++)
  {
      float2 noise = _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, ro.xy * _Gimmick_DS2_01_Domain_Warping_Scale + _Time[0] * _Gimmick_DS2_01_Domain_Warping_Speed * warping_speed_vector, 0);
      ro.xy += noise * _Gimmick_DS2_01_Domain_Warping_Strength;
  }

#define DS2_01_MARCH_STEPS 8
  float total_distance_traveled = 0.0;
  const float MINIMUM_HIT_DISTANCE = 1E-4;
  const float MAXIMUM_TRACE_DISTANCE = 30.0;
  float distance_to_closest;
  float3 which;
  for (uint ii = 0; ii < DS2_01_MARCH_STEPS; ii++)
  {
    float3 current_position = ro + total_distance_traveled * rd;
    distance_to_closest = ds2_01_map_dr(current_position, 
      _Gimmick_DS2_01_Period.xyz, _Gimmick_DS2_01_Count.xyz, which);
    total_distance_traveled += distance_to_closest;
    if (distance_to_closest < MINIMUM_HIT_DISTANCE || 
        total_distance_traveled > MAXIMUM_TRACE_DISTANCE) {
      break;
    }
  }

  float3 normal = i.normal;
  bool hit = distance_to_closest < MINIMUM_HIT_DISTANCE;
  float3 color = LRGBtoOKLCH(float3(0.7, 0, 0));
  color[0] += _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, ((which.xy / _Gimmick_DS2_01_Count.xy) + _Time[0]) / 10, 0);
  color[2] = ign(which.xy + _Gimmick_DS2_01_Count.xy) * TAU * .1;
  color[2] += _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, ((which.xy / _Gimmick_DS2_01_Count.xy) + _Time[0]) / 100, 0) * 5;
  color = OKLCHtoLRGB(color);
  if (hit) {
    normal = ds2_01_calc_normal(ro + total_distance_traveled * rd, 
      _Gimmick_DS2_01_Period.xyz, _Gimmick_DS2_01_Count.xyz);
    normal = UnityObjectToWorldNormal(normal);
  }

  Gimmick_DS2_Output o;
  o.albedo = hit ? float4(color, 1) : 0;
  o.emission = o.albedo;
  o.normal = normal;
  o.metallic = 0;
  o.roughness = 0;
  o.worldPos = i.worldPos;
  return o;
}

float ds2_02_map(float3 p, out float which)
{
  float depth = .2;
  which = 0;

  // Create frame for lights.
  float d0 = distance_from_box(p - float3(0, 0, depth), float3(.50, .50, depth));
  float d1 = distance_from_box(p - float3(0, 0, 0), float3(.45, .45, depth));
  float d2 = op_sub(d1, d0);

  // Create lights.
  float light_spacing = .12;
  float d3 = d2;
  which = -1;
  for (uint i = 0; i < 3; i++) {
    float d4 = distance_from_capped_cylinder(abs(p) - float3(i * light_spacing + light_spacing * .5, .45, depth * .5), .05, .03);
    d3 = min(d3, d4);
  }
  for (uint i = 0; i < 3; i++) {
    float d4 = distance_from_cylinder(abs(p) - float3(i * light_spacing + light_spacing * .5, 0, depth * .5), float3(0, 0, .025));
    which = d4 < d3 ? ((int) i + 1) * 2 + (sign(p.x) > 0 ? 1 : 0) : which;
    d3 = min(d3, d4);
  }

  return d3;
}

float3 ds2_02_calc_normal(float3 p)
{
  float3 small_step = float3(1E-5, 0.0, 0.0);
  float which;
  float center = ds2_02_map(p, which);
  return normalize(float3(
    ds2_02_map(p + small_step.xyz, which) - center,
    ds2_02_map(p + small_step.zxy, which) - center,
    ds2_02_map(p + small_step.yzx, which) - center
  ));
}

Gimmick_DS2_Output Gimmick_DS2_02(inout v2f i)
{
  float3 camera_position = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
  float3 ro = i.objPos;
  float3 rd = normalize(i.objPos - camera_position);

  #define DS2_02_MARCH_STEPS 30
  float total_distance_traveled = 0.0;
  const float MINIMUM_HIT_DISTANCE = 1E-3;
  const float MAXIMUM_TRACE_DISTANCE = 30.0;
  float distance_to_closest;
  float which;
  for (uint ii = 0; ii < DS2_02_MARCH_STEPS; ii++)
  {
    float3 current_position = ro + total_distance_traveled * rd;
    distance_to_closest = ds2_02_map(current_position, which);
    total_distance_traveled += distance_to_closest;
    if (distance_to_closest < MINIMUM_HIT_DISTANCE || 
        total_distance_traveled > MAXIMUM_TRACE_DISTANCE) {
      break;
    }
  }

  float3 normal = i.normal;
  bool hit = distance_to_closest < MINIMUM_HIT_DISTANCE;
  float3 color = (which == -1 ? 0.01 : 1.5);
  if (hit) {
    normal = ds2_02_calc_normal(ro + total_distance_traveled * rd);
    normal = UnityObjectToWorldNormal(normal);
  }

  Gimmick_DS2_Output o;
  o.albedo = hit ? float4(color, 1) : 0;
  o.emission = color;
  o.normal = normal;
  o.metallic = 0;
  o.roughness = 0.3;
  o.worldPos = mul(unity_ObjectToWorld, float4(ro + total_distance_traveled * rd, 1));
  return o;
}

float ds2_03_map(float3 p)
{
  float edge = _Gimmick_DS2_03_Edge_Length;
  float thickness = edge*10;
  return distance_from_round_box(p - float3(0, 0, thickness*.99), float3(edge, edge, thickness), edge * .1);
}

float3 ds2_03_nudge_p(float3 p, float3 which)
{
  float noise = _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, which.xy * _Gimmick_DS2_03_Period.xy * .2 + _Time[0] * .1, 0);
  return p - float3(0, 0, noise * .01);
  //return p + sin(e*TAU+_Time[0]*4) * _Gimmick_DS2_03_Edge_Length * .2 - noise;
  //return p;
}

float ds2_03_map_dr(
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
  for (uint xi = 0; xi < 2; xi++)
  for (uint yi = 0; yi < 2; yi++)
  {
    float3 rid = which + float3(xi, yi, 0) * o;
    rid = clamp(rid, ceil(-(count)*0.5), floor((count-1)*0.5));
    float3 r = p - period * rid;
    r = ds2_03_nudge_p(r, rid);
    float cur_d = ds2_03_map(r);
    which_tmp = cur_d < d ? rid : which_tmp;
    d = min(d, cur_d);
  }

  which = which_tmp;
  return d;
}

float3 ds2_03_calc_normal(float3 p)
{
  float3 small_step = float3(1E-5, 0.0, 0.0);
  float3 which;
  float center = ds2_03_map_dr(p, _Gimmick_DS2_03_Period.xyz, _Gimmick_DS2_03_Count.xyz, which);
  return normalize(float3(
    ds2_03_map_dr(p + small_step.xyz, _Gimmick_DS2_03_Period.xyz, _Gimmick_DS2_03_Count.xyz, which) - center,
    ds2_03_map_dr(p + small_step.zxy, _Gimmick_DS2_03_Period.xyz, _Gimmick_DS2_03_Count.xyz, which) - center,
    ds2_03_map_dr(p + small_step.yzx, _Gimmick_DS2_03_Period.xyz, _Gimmick_DS2_03_Count.xyz, which) - center
  ));
}

Gimmick_DS2_Output Gimmick_DS2_03(inout v2f i)
{
  float3 camera_position = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
  float3 ro = i.objPos;
  float3 rd = normalize(i.objPos - camera_position);

  #define DS2_03_MARCH_STEPS 30
  float total_distance_traveled = 0.0;
  const float MINIMUM_HIT_DISTANCE = 1E-3;
  const float MAXIMUM_TRACE_DISTANCE = 30.0;
  float distance_to_closest;
  float3 which;
  for (uint ii = 0; ii < DS2_03_MARCH_STEPS; ii++)
  {
    float3 current_position = ro + total_distance_traveled * rd;
    distance_to_closest = ds2_03_map_dr(current_position, _Gimmick_DS2_03_Period.xyz, _Gimmick_DS2_03_Count.xyz, which);
    total_distance_traveled += distance_to_closest;
    if (distance_to_closest < MINIMUM_HIT_DISTANCE || 
        total_distance_traveled > MAXIMUM_TRACE_DISTANCE) {
      break;
    }
  }

  bool hit = distance_to_closest < MINIMUM_HIT_DISTANCE;
  float3 normal = hit ? UnityObjectToWorldNormal(ds2_03_calc_normal(ro + total_distance_traveled * rd)) : i.normal;

  float3 light_dir = normalize(float3(0.5, -0.5, -0.5));
  float3 light_color = float3(1, 1, 1);
  float ndotl = saturate(dot(normal, light_dir));
  float wrap_factor = 0.5;
  float4 wrapped = pow(max(1E-4, (ndotl + wrap_factor) / (1 + wrap_factor)), 1 + wrap_factor);
  float3 light_intensity = light_color * wrapped;

  Gimmick_DS2_Output o;
  o.albedo = hit ? float4(light_intensity, 1) : 0;
  o.emission = o.albedo;
  o.normal = normal;
  o.metallic = 0;
  o.roughness = 0;
  o.worldPos = mul(unity_ObjectToWorld, float4(ro + total_distance_traveled * rd, 1));
  return o;
}

#endif  // _GIMMICK_DS2
#endif  // __DOWNSTAIRS_02_INC
