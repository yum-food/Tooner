#include "atrix256.cginc"
#include "audiolink.cginc"
#include "cnlohr.cginc"
#include "globals.cginc"
#include "fog.cginc"
#include "interpolators.cginc"
#include "iq_sdf.cginc"
#include "math.cginc"
#include "noise.cginc"
#include "oklab.cginc"
#include "poi.cginc"

#ifndef __DOWNSTAIRS_02_INC
#define __DOWNSTAIRS_02_INC

#if defined(_GIMMICK_DS2)

// All gimmicks here return this structure.
struct Gimmick_DS2_Output {
  float4 albedo;
  float3 emission;
  float3 normal;
  float3 worldPos;
  float4 fog;
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
  const float t = _Time[0] * 10;
  const float warping_strength_anim = smoothstep(0, 1, sin(t*0.31));
  for (uint ii = 0; ii < _Gimmick_DS2_00_Domain_Warping_Octaves; ii++)
  {
      float2 noise = _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, uv * _Gimmick_DS2_00_Domain_Warping_Scale + _Time[0] * _Gimmick_DS2_00_Domain_Warping_Speed * warping_speed_vector, 0);
      uv += noise * _Gimmick_DS2_00_Domain_Warping_Strength * warping_strength_anim;
  }

  float3 camera_position = float3(0.0, 0.0, -5.0);
  float3 ro = camera_position;
  float3 rd = float3(uv.x, uv.y, 1.0);

  float3 normal;
  float which;
  bool hit = __ds2_00_march(ro, rd, normal, which);

  float3 shaded_color = LRGBtoOKLCH(float3(1, .05, .12));
  shaded_color[0] += smoothstep(-1, 1, sin(t*2.3 + which * TAU * 1.1)) * .5;
  shaded_color[2] += smoothstep(-1, 1, sin(t*2.9 + which * TAU * 1.1)) * .05;
  shaded_color = OKLCHtoLRGB(shaded_color);
  
  shaded_color *= hit;

  Gimmick_DS2_Output o;
  o.albedo = float4(shaded_color * 5, 1.0);
  o.emission = shaded_color;
  o.fog = 0;
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
  const float MAXIMUM_TRACE_DISTANCE = .1;
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
  color[0] += _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, ((which.xy / _Gimmick_DS2_01_Count.xy) * 1.5 + _Time[0] * .5) / 10, 0);
  color[2] = ign(which.xy + _Gimmick_DS2_01_Count.xy*2) * TAU * .1;
  color[2] += _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, ((which.xy / _Gimmick_DS2_01_Count.xy) * 1.5 + _Time[0] * .5) / 100, 0) * 5;
  color = OKLCHtoLRGB(color);
  if (hit) {
    normal = ds2_01_calc_normal(ro + total_distance_traveled * rd, 
      _Gimmick_DS2_01_Period.xyz, _Gimmick_DS2_01_Count.xyz);
    normal = UnityObjectToWorldNormal(normal);
  }

  Gimmick_DS2_Output o;
  o.albedo = hit ? float4(color, 1) : 0;
  o.emission = o.albedo;
  o.fog = 0;
  o.normal = normal;
  o.metallic = 0;
  o.roughness = 0;
  o.worldPos = i.worldPos;
  return o;
}

// which == -10 -> capped cylinder
// which == 1 -> cylinder
float ds2_10_map_repeated(float3 p, out float which)
{
  float depth = .2;
  float d0 = distance_from_capped_cylinder(abs(p) - float3(0, .45, depth * .5), .05, .02);
  float d1 = distance_from_cylinder(abs(p) - float3(0, 0, depth * .5), float3(0, 0, .015));
  which = d0 < d1 ? -10 : 1;
  return min(d0, d1);
}

float ds2_10_map_dr(
    float3 p,
    float3 period,
    float3 count,
    out float which
    )
{
  which = round(p / period);
  float3 rid = clamp(which, ceil(-(count)*0.5), floor((count-1)*0.5));
  float3 r = p - period * rid;
  return ds2_10_map_repeated(r, which);
}

float ds2_10_map(float3 p, out float which)
{
  float depth = .2;
  which = -10;

  // Create frame for lights.
  float d0 = distance_from_box(p - float3(0, 0, depth), float3(.50, .50, depth));
  float d1 = distance_from_box(p - float3(0, 0, 0), float3(.45, .45, depth));
  float d2 = op_sub(d1, d0);

  // Create lights.
  float light_spacing = .17;
  float which_tmp;
  float d3 = ds2_10_map_dr(p, float3(light_spacing, 1, 1), float3(5, 1, 1), which_tmp);
  which = d3 < d2 ? which_tmp : which;

  return min(d2, d3);
}

float3 ds2_10_calc_normal(float3 p)
{
  float3 small_step = float3(1E-5, 0.0, 0.0);
  float which;
  float center = ds2_10_map(p, which);
  return normalize(float3(
    ds2_10_map(p + small_step.xyz, which) - center,
    ds2_10_map(p + small_step.zxy, which) - center,
    ds2_10_map(p + small_step.yzx, which) - center
  ));
}

Gimmick_DS2_Output Gimmick_DS2_10(inout v2f i)
{
  float3 camera_position = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
  float3 ro = i.objPos;
  float3 rd = normalize(i.objPos - camera_position);

  #define DS2_10_MARCH_STEPS 30
  float total_distance_traveled = 0.0;
  const float MINIMUM_HIT_DISTANCE = 1E-3;
  const float MAXIMUM_TRACE_DISTANCE = 1;
  float distance_to_closest;
  float which;
  for (uint ii = 0; ii < DS2_10_MARCH_STEPS; ii++)
  {
    float3 current_position = ro + total_distance_traveled * rd;
    distance_to_closest = ds2_10_map(current_position, which);
    total_distance_traveled += distance_to_closest;
    if (distance_to_closest < MINIMUM_HIT_DISTANCE || 
        total_distance_traveled > MAXIMUM_TRACE_DISTANCE) {
      break;
    }
  }

  float3 normal = i.normal;
  const float3 final_position = ro + total_distance_traveled * rd;
  bool hit = distance_to_closest < MINIMUM_HIT_DISTANCE;
  float3 color = (which == -10 ? 0.01 : 1.5);
  if (hit) {
    normal = ds2_10_calc_normal(final_position);
    normal = UnityObjectToWorldNormal(normal);
  }

  Gimmick_DS2_Output o;
  //o.albedo = hit ? float4(color, 1) : 0;
  o.albedo = hit ? 1 : 0;
  o.emission = color;
  o.fog = 0;
  o.normal = normal;
  o.metallic = 0;
  o.roughness = 0.3;
  o.worldPos = mul(unity_ObjectToWorld, float4(final_position, 1));
  return o;
}

float ds2_02_map(float3 p)
{
  float edge = _Gimmick_DS2_02_Edge_Length;
  float thickness = edge*10;
  return distance_from_round_box(p - float3(0, 0, thickness*.99), float3(edge, edge, thickness), edge * .1);
}

float3 ds2_02_nudge_p(float3 p, float3 which)
{
  float noise = _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, which.xy * _Gimmick_DS2_02_Period.xy * .2 + _Time[0] * .1, 0);
  return p - float3(0, 0, noise * .01);
  //return p + sin(e*TAU+_Time[0]*4) * _Gimmick_DS2_02_Edge_Length * .2 - noise;
  //return p;
}

float ds2_02_map_dr(
    float3 p,
    float3 period,
    float3 count,
    out float3 which
    )
{
  which = floor(p / period);
  // Direction to nearest neighboring cell.
  float3 min_d = p - period * which;
  float3 o = sign(min_d);

  float d = 1E9;
  float3 which_tmp = which;
  for (uint xi = 0; xi < 1; xi++)
  for (uint yi = 0; yi < 1; yi++)
  {
    float3 rid = which + float3(xi, yi, 0) * o;
    rid = clamp(rid, ceil(-(count)*0.5), floor((count-1)*0.5));
    float3 r = p - period * rid;
    r = ds2_02_nudge_p(r, rid);
    float cur_d = ds2_02_map(r);
    which_tmp = cur_d < d ? rid : which_tmp;
    d = min(d, cur_d);
  }

  which = which_tmp;
  return d;
}

float3 ds2_02_calc_normal(float3 p)
{
  float3 small_step = float3(1E-5, 0.0, 0.0);
  float3 which;
  float center = ds2_02_map_dr(p, _Gimmick_DS2_02_Period.xyz, _Gimmick_DS2_02_Count.xyz, which);
  return normalize(float3(
    ds2_02_map_dr(p + small_step.xyz, _Gimmick_DS2_02_Period.xyz, _Gimmick_DS2_02_Count.xyz, which) - center,
    ds2_02_map_dr(p + small_step.zxy, _Gimmick_DS2_02_Period.xyz, _Gimmick_DS2_02_Count.xyz, which) - center,
    ds2_02_map_dr(p + small_step.yzx, _Gimmick_DS2_02_Period.xyz, _Gimmick_DS2_02_Count.xyz, which) - center
  ));
}

Gimmick_DS2_Output Gimmick_DS2_02(inout v2f i)
{
  float3 camera_position = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
  float3 ro = i.objPos;
  float3 rd = normalize(i.objPos - camera_position);

  float2 warping_speed_vector = normalize(float2(97, 101));
  for (uint ii = 0; ii < _Gimmick_DS2_02_Domain_Warping_Octaves; ii++)
  {
      float2 noise = _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, ro.xy * _Gimmick_DS2_02_Domain_Warping_Scale + _Time[0] * _Gimmick_DS2_02_Domain_Warping_Speed * warping_speed_vector, 0);
      ro.xy += noise * _Gimmick_DS2_02_Domain_Warping_Strength;
  }

  #define DS2_02_MARCH_STEPS 40
  float total_distance_traveled = 0.0;
  const float MINIMUM_HIT_DISTANCE = 1E-4;
  const float MAXIMUM_TRACE_DISTANCE = 1E-1;
  float distance_to_closest;
  float3 which;
  for (uint ii = 0; ii < DS2_02_MARCH_STEPS; ii++)
  {
    float3 current_position = ro + total_distance_traveled * rd;
    distance_to_closest = ds2_02_map_dr(current_position, _Gimmick_DS2_02_Period.xyz, _Gimmick_DS2_02_Count.xyz, which);
    total_distance_traveled += distance_to_closest;
    if (distance_to_closest < MINIMUM_HIT_DISTANCE || 
        total_distance_traveled > MAXIMUM_TRACE_DISTANCE) {
      break;
    }
  }

  bool hit = distance_to_closest < MINIMUM_HIT_DISTANCE;
  float3 final_position = ro + total_distance_traveled * rd;
  float3 normal = hit ? UnityObjectToWorldNormal(ds2_02_calc_normal(final_position)) : i.normal;

  float3 light_dir = normalize(float3(0.5, -0.5, -0.5));
  float3 light_color = float3(1, 1, 1);
  float ndotl = saturate(dot(normal, light_dir));
  float wrap_factor = 0.7;
  float4 wrapped = pow(max(1E-4, (ndotl + wrap_factor) / (1 + wrap_factor)), 1 + wrap_factor);
  float3 light_intensity = light_color * wrapped;
  float3 color = hit ? 1 : 0;
  color *= _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, which.xy * _Gimmick_DS2_02_Period.xy * .2 + _Time[0] * warping_speed_vector * .01, 0);
  // Reinterpret greyscale as OKLCH.
  //color = saturate(color * 2 - (sin(_Time[0] + 1) * .5 + .6));
  color = saturate(color * 2 - 0.4);
  float hue_noise = _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, which.xy * _Gimmick_DS2_02_Period.xy * .2 - _Time[0] * warping_speed_vector.yx * .02, 0);
  color = OKLCHtoLRGB(float3(
    color.x * 20,
    color.x * 10,
    color.x * TAU * .2 + hue_noise * 10 + _Time[0] * 10
  ));

  color = max(color, 0.005);
  color *= light_intensity;

  Gimmick_DS2_Output o;
  o.albedo = float4(color, 1);
  o.emission = o.albedo;
  o.fog = 0;
  o.normal = normal;
  o.metallic = 0;
  o.roughness = 0;
  // Depth gets all fucked up unless we use i.objPos instead of ro, which is domain warped.
  o.worldPos = mul(unity_ObjectToWorld, float4(i.objPos + rd * total_distance_traveled, 1));
  return o;
}

float ds2_03_map(float3 p, float3 rid)
{
  float edge = _Gimmick_DS2_03_Edge_Length;
  float thickness = edge * .5;

  float3 pp = p - float3(0, 0, thickness*1.5);

  float wave_str = 0;
  float t = _Time[3];
  float3 noise = (_Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, rid.xy * .001 + t *.001, 0) * 2 - 1);
  wave_str += noise.x;
  float4 quat = get_quaternion(normalize(noise*2-1), wave_str * PI);
  pp = rotate_vector(pp, quat);

  return distance_from_hex_prism(pp, float2(edge, thickness));
}

float3 ds2_03_nudge_p(float3 p, float3 which)
{
  return p - float3(_Gimmick_DS2_03_Period.x * 0.65, _Gimmick_DS2_03_Period.y * 0.5, 0);
}

float ds2_03_map_dr(
    float3 p,
    float3 period,
    float3 count,
    out float3 which
    )
{
  which = floor(p / period);
  // Direction to nearest neighboring cell.
  float3 min_d = p - period * which;
  float3 o = sign(min_d);

  float d = 1E9;
  float3 which_tmp = which;
  for (uint xi = 0; xi < 1; xi++)
  {
    float3 rid = which + float3(xi, 0, 0) * o;
    rid = clamp(rid, ceil(-(count)*0.5), floor((count-1)*0.5));
    float3 r = p - period * rid;
    r = ds2_03_nudge_p(r, rid);
    float cur_d = ds2_03_map(r, rid);
    which_tmp = cur_d < d ? rid : which_tmp;
    d = min(d, cur_d);
  }

  which = which_tmp;
  return d;
}

float3 ds2_03_calc_normal(float3 p, float3 period, float3 count)
{
  float3 small_step = float3(1E-5, 0.0, 0.0);
  float3 which;
  float center = ds2_03_map_dr(p, period, count, which);
  return normalize(float3(
    ds2_03_map_dr(p + small_step.xyz, period, count, which) - center,
    ds2_03_map_dr(p + small_step.zxy, period, count, which) - center,
    ds2_03_map_dr(p + small_step.yzx, period, count, which) - center
  ));
}

Gimmick_DS2_Output Gimmick_DS2_03(inout v2f i)
{
  float3 camera_position = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
  float3 ro = i.objPos;
  float3 rd = normalize(i.objPos - camera_position);

  #define DS2_03_MARCH_STEPS 2
  float total_distance_traveled = 0.0;
  const float MINIMUM_HIT_DISTANCE = 2E-4;
  const float MAXIMUM_TRACE_DISTANCE = 1E-1;
  const float3 period = float3(
    _Gimmick_DS2_03_Period.x * 2,
    _Gimmick_DS2_03_Period.yz);
  const float3 count = float3(
    _Gimmick_DS2_03_Count.x * 0.5,
    _Gimmick_DS2_03_Count.yz);

  const float overstep_amount = 3;
  bool hit1;
  float total_distance_traveled1 = 0;
  float3 which1;
  {
    float distance_to_closest1;
    for (uint ii = 0; ii < DS2_03_MARCH_STEPS; ii++)
    {
      float3 current_position = ro + total_distance_traveled1 * rd;
      distance_to_closest1 = ds2_03_map_dr(current_position, period, count, which1)*overstep_amount;
      total_distance_traveled1 += distance_to_closest1;
      if (distance_to_closest1 < MINIMUM_HIT_DISTANCE || 
          total_distance_traveled1 > MAXIMUM_TRACE_DISTANCE) {
        break;
      }
    }

    hit1 = distance_to_closest1 < MINIMUM_HIT_DISTANCE;
  }

  bool hit2;
  float total_distance_traveled2 = 0;
  float3 which2;
  {
    ro.xy += period.xy * .5;
    float distance_to_closest2;
    for (uint ii = 0; ii < DS2_03_MARCH_STEPS; ii++)
    {
      float3 current_position = ro + total_distance_traveled2 * rd;
      distance_to_closest2 = ds2_03_map_dr(current_position, period, count, which2)*overstep_amount;
      total_distance_traveled2 += distance_to_closest2;
      if (distance_to_closest2 < MINIMUM_HIT_DISTANCE || 
          total_distance_traveled2 > MAXIMUM_TRACE_DISTANCE) {
        break;
      }
    }

    hit2 = distance_to_closest2 < MINIMUM_HIT_DISTANCE;
  }

  float3 final_position1 = i.objPos + total_distance_traveled1 * rd;
  float3 final_position2 = (i.objPos + float3(period.xy * .5, 0)) + total_distance_traveled2 * rd;

  float3 normal1 = hit1 ? UnityObjectToWorldNormal(ds2_03_calc_normal(final_position1, period, count)) : i.normal;
  float3 normal2 = hit2 ? UnityObjectToWorldNormal(ds2_03_calc_normal(final_position2, period, count)) : i.normal;

  float3 final_position;
  float3 normal;
  if (hit1 && hit2) {
    final_position = total_distance_traveled1 < total_distance_traveled2 ? final_position1 : final_position2;
    normal = total_distance_traveled1 < total_distance_traveled2 ? normal1 : normal2;
  } else if (hit1) {
    final_position = final_position1;
    normal = normal1;
  } else if (hit2) {
    final_position = final_position2;
    normal = normal2;
  } else {
    final_position = i.objPos;
    normal = i.normal;
  }
  bool hit = hit1 || hit2;

  float3 final_pos_world = mul(unity_ObjectToWorld, float4(final_position, 1));

  float3 light_dir = normalize(float3(0.5, -0.5, -0.5));
  float3 light_color = float3(1, 1, 1);
  float ndotl = saturate(dot(normal, light_dir));
  float wrap_factor = 0.7;
  float4 wrapped = pow(max(1E-4, (ndotl + wrap_factor) / (1 + wrap_factor)), 1 + wrap_factor);
  float3 light_intensity = light_color * wrapped;

  float3 color = hit ? light_intensity : 0;

  Gimmick_DS2_Output o;
  o.albedo = float4(color, 1);
  //o.emission = o.albedo;
  o.emission = 0;
  o.fog = 0;
  o.normal = normal;
  o.metallic = hit;
  o.roughness = 0.1;
  o.worldPos = final_pos_world;
  return o;
}

float ds2_11_height(float2 p)
{
  float sc = .4;
  float sc_rcp = 2.5;
  float2 offset = _Gimmick_DS2_11_XZ_Offset.xz * _Gimmick_DS2_11_Simulation_Scale;

  float2 pp = (p - offset) * sc_rcp;
  p /= _Gimmick_DS2_11_Simulation_Scale;
  pp /= _Gimmick_DS2_11_Simulation_Scale;
#define _GIMMICK_DS2_11_TEXTURE_NOISE
#if defined(_GIMMICK_DS2_11_TEXTURE_NOISE)
  pp *= .01;
#endif

  float h = 0;
  float hsc = _Gimmick_DS2_11_Height_Scale;
  float sc_hsc = sc * hsc;
  uint octaves = _Gimmick_DS2_11_Octaves;
  float alpha = _Gimmick_DS2_11_Alpha;
  float alpha_rcp = 1 / alpha;
  float alpha_i = 1;
  float alpha_rcp_i = 1;
  for (uint i = 0; i < octaves; i++) {
#if defined(_GIMMICK_DS2_11_TEXTURE_NOISE)
    float noise = _Gimmick_DS2_11_FBM.SampleLevel(linear_repeat_s, pp * alpha_rcp_i, 0);
#else
    float noise = perlin_noise(pp * alpha_rcp_i);
#endif
    h += noise * sc_hsc * alpha_i;
    alpha_i *= alpha;
    alpha_rcp_i *= alpha_rcp;
  }
  // The sum of the series k^-i is 1 / (1 - k^-1)
  h /= 1 / (1 - alpha);
  h *= h;

  // `scale_factor` goes from [0, 1] based on radius.
  float2 center = p;
  float scale_factor = 1 - exp(-dot(center, center) * 16);
  h *= scale_factor;
  h = ((h - (1 - scale_factor) * sc_hsc * .15) + .015) * _Gimmick_DS2_11_Simulation_Scale;

  return h;
}

float3 ds2_11_calc_normal(float3 p)
{
#if 0
  // 4-point anti aliasing in an X shape with full central differences. 16 taps.
  float epsilon = 1E-3;
  float3 result = 0;
  for (uint i = 0; i < 4; i++) {
    float2 pp = p.xz + epsilon * (float2(i % 2, (i/2) % 2) - .5) * 2;
    result += float3(
      ds2_11_height(pp - float2(epsilon, 0)) - ds2_11_height(pp + float2(epsilon, 0)),
      2 * epsilon,
      ds2_11_height(pp - float2(0, epsilon)) - ds2_11_height(pp + float2(0, epsilon))
    );
  }
  return normalize(result);
#elif 0
  // Full central differences. 4 taps.
  float epsilon = 1E-3;
  return normalize(float3(
    ds2_11_height(p.xz - float2(epsilon, 0)) - ds2_11_height(p.xz + float2(epsilon, 0)),
    2 * epsilon,
    ds2_11_height(p.xz - float2(0, epsilon)) - ds2_11_height(p.xz + float2(0, epsilon))
  ));
#elif 0
  // Abridged central differences along stochastic diagonal. 6 taps.
  float epsilon = 1E-3;
  float noise = _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, p.xz * 1000, 0) * TAU;
  float2 axis = float2(cos(noise), sin(noise));
  float2 p0 = p.xz + (epsilon * axis);
  float2 p1 = p.xz - (epsilon * axis);
  float c0 = ds2_11_height(p0);
  float c1 = ds2_11_height(p1);
  float3 n0 = float3(
    ds2_11_height(p0 - float2(epsilon, 0)) - c0,
    epsilon,
    ds2_11_height(p0 - float2(0, epsilon)) - c0
  );
  float3 n1 = float3(
    ds2_11_height(p1 - float2(epsilon, 0)) - c1,
    epsilon,
    ds2_11_height(p1 - float2(0, epsilon)) - c1
  );
  return normalize(n0 + n1);
#elif 1
  // Full central differences rotated a random amount about the original point. 4 taps.
  float epsilon = 8E-4;
  float3 pp = p * 64;
  float noise = _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, pp.xz, 0) * TAU;
  float2 axis = float2(cos(noise), sin(noise));
  float2 p0 = p.xz + (epsilon * axis) * 1.20710678;
  float3 n0 = float3(
    ds2_11_height(p0 - float2(epsilon, 0)) - ds2_11_height(p0 + float2(epsilon, 0)),
    2 * epsilon,
    ds2_11_height(p0 - float2(0, epsilon)) - ds2_11_height(p0 + float2(0, epsilon))
  );
  return normalize(n0);
#elif 1
  // Abridged central differences along diagonal oriented tangent to circle centered at the origin. 6 taps.
  float epsilon = 1E-3;
  float2 n2 = normalize(p.xz);
  float2 ortho = float2(-n2.y, n2.x);
  float2 p0 = p.xz + (epsilon * .7071 * ortho);
  float2 p1 = p.xz - (epsilon * .7071 * ortho);
  float c0 = ds2_11_height(p0);
  float c1 = ds2_11_height(p1);
  float3 n0 = float3(
    ds2_11_height(p0 - float2(epsilon, 0)) - c0,
    epsilon,
    ds2_11_height(p0 - float2(0, epsilon)) - c0
  );
  float3 n1 = float3(
    ds2_11_height(p1 - float2(epsilon, 0)) - c1,
    epsilon,
    ds2_11_height(p1 - float2(0, epsilon)) - c1
  );
  return normalize(n0 + n1);
#elif 0
  // Abridged central differences along diagonal oriented normal to circle centered at the origin. 6 taps.
  float epsilon = 1E-3;
  float2 n2 = normalize(p.xz);
  float2 p0 = p.xz + (epsilon * .5 * n2);
  float2 p1 = p.xz - (epsilon * .5 * n2);
  float c0 = ds2_11_height(p0);
  float c1 = ds2_11_height(p1);
  float3 n0 = normalize(float3(
    c0 - ds2_11_height(p0 - float2(epsilon, 0)),
    epsilon,
    c0 - ds2_11_height(p0 - float2(0, epsilon))
  ));
  float3 n1 = normalize(float3(
    c1 - ds2_11_height(p1 - float2(epsilon, 0)),
    epsilon,
    c1 - ds2_11_height(p1 - float2(0, epsilon))
  ));
  return normalize(n0 + n1);
#else
  // Abridged central differences. 3 taps.
  float epsilon = 1E-3;
  float center = ds2_11_height(p.xz);
  return normalize(float3(
    ds2_11_height(p.xz - float2(epsilon, 0)) - center,
    2 * epsilon,
    ds2_11_height(p.xz - float2(0, epsilon)) - center
  ));
#endif
}

Gimmick_DS2_Output Gimmick_DS2_11(inout v2f i, ToonerData tdata)
{
  float3 camera_position = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
  float3 rd = normalize(i.objPos - camera_position);
  float3 ro = camera_position;

  // Raytrace to intersection with sphere of radius _Gimmick_DS2_11_March_Initial_Offset centered at the object space origin.
  {
    float r = _Gimmick_DS2_11_March_Initial_Offset * _Gimmick_DS2_11_Simulation_Scale;
    float3 L = ro; // Sphere center is at the origin
    float b = 2.0 * dot(rd, L);
    float c = dot(L, L) - r * r;
    float discriminant = b * b - 4.0 * c;

    // If discriminant is negative, the ray does not intersect the sphere
    if (discriminant > 0.0)
    {
      // Compute the two points of intersection
      float sqrt_discriminant = sqrt(discriminant);
      float t0 = (-b - sqrt_discriminant) * 0.5;
      float t1 = (-b + sqrt_discriminant) * 0.5;

      // Choose the nearest positive t
      float t_sphere = (t0 > 0.0) ? t0 : ((t1 > 0.0) ? t1 : -1.0);

      // If both t0 and t1 are negative, the sphere is behind the ray origin
      if (t_sphere > 0.0)
      {
          ro += rd * t_sphere;
      }
    }
  }

  // 180 degrees is pi radians
  // (d/180)*pi
  [branch]
  if (dot(rd, UnityObjectToWorldNormal(float3(0, 1, 0))) > _Gimmick_DS2_11_Early_Exit_Cutoff_Cos_Theta) {
    return (Gimmick_DS2_Output)0;
  }

  [branch]
  if (_Gimmick_DS2_11_Distance_Culling_Enable) {
    float activation_y = _Gimmick_DS2_11_Activation_Y;
    [branch]
    if (getCenterCamPos().y > activation_y) {
      return (Gimmick_DS2_Output)0;
    }
  }

  float perspective_divide = 1.0 / i.pos.w;
  float2 screen_uv = i.screenPos.xy * perspective_divide * _ScreenParams.xy * _Gimmick_DS2_Noise_TexelSize.xy;
  const float noise = _Gimmick_DS2_Noise.SampleLevel(point_repeat_s, screen_uv, 0);
  const float frame = ((float) AudioLinkData(ALPASS_GENERALVU + int2(1, 0)).x);
  const float tnoise = frac(noise + frame * PHI);

  float t = 0.0;
  float dt0 = _Gimmick_DS2_11_March_Initial_Step_Size * _Gimmick_DS2_11_Simulation_Scale;
  float dt = dt0;
  // last height, last y
  float lh = 0;
  float ly = 0;

  // https://iquilezles.org/articles/terrainmarching/
  bool hit = false;
  float3 p;
  float h;
  for (uint ii = 0; ii < _Gimmick_DS2_11_March_Steps; ii++) {
    p = ro + rd * t;
    h = ds2_11_height(p.xz);
    if (p.y < h) {
      break;
    }
    t += dt;
    dt = dt0 * (ii+1);
    lh = h;
    ly = p.y;
  }
  [branch]
  if (p.y < h) {
    hit = true;
    t = t - dt + dt * (lh - ly) / (p.y - ly - h + lh);

    // Backtrack to find a closer intersection point using binary search
    float t0 = t;
    //p = ro + rd * t;
    //float t1 = t + dt * sign(h - ds2_11_height(p.xz));
    float t1 = t + dt * .5;
    for (uint j = 0; j < _Gimmick_DS2_11_March_Backtrack_Steps; j++) {
      float tm = (t0 + t1) * 0.5;
      float3 pm = ro + rd * tm;
      float hm = ds2_11_height(pm.xz);
      t1 = (pm.y < hm) ? tm : t1;
      t0 = (pm.y < hm) ? t0 : tm;
    }
    t = t1;  // Refined intersection time
    p = ro + rd * t;
  }

  float3 final_pos = ro + t * rd + (1 - hit) * rd * 1E2;
  float3 normal = UnityObjectToWorldNormal(ds2_11_calc_normal(final_pos));
  float3 final_pos_world = mul(unity_ObjectToWorld, float4(final_pos, 1));
  float4 final_color = 1;

  float snowline_noise = 0;
  float alpha = 0.3;
  float alpha_rcp = 1 / alpha;
  for (uint ii = 0; ii < _Gimmick_DS2_11_Snowline_Octaves; ii++) {
    snowline_noise += _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, final_pos.xz * _Gimmick_DS2_11_Snowline_Noise_Scale * pow(alpha_rcp, ii), 0) * pow(alpha, ii);
  }
  float snowline = (snowline_noise - _Gimmick_DS2_11_Snowline) * _Gimmick_DS2_11_Snowline_Width;
  float rockline_noise = 0;
  for (uint ii = 0; ii < _Gimmick_DS2_11_Rockline_Octaves; ii++) {
    rockline_noise += _Gimmick_DS2_Noise.SampleLevel(linear_repeat_s, final_pos.xz * _Gimmick_DS2_11_Rockline_Noise_Scale * pow(alpha_rcp, ii), 0) * pow(alpha, ii);
  }
  float rockline = (rockline_noise - _Gimmick_DS2_11_Rockline) * _Gimmick_DS2_11_Rockline_Width;

  final_color.rgb = lerp(
    _Gimmick_DS2_11_Grass_Color,
    _Gimmick_DS2_11_Rock_Color,
    saturate(final_pos_world.y - rockline));

  final_color.rgb = lerp(
    final_color.rgb,
    _Gimmick_DS2_11_Snow_Color,
    saturate(final_pos_world.y - snowline));

  final_color *= hit;

  float4 fog = 0;
  [branch]
  if (_Gimmick_DS2_11_Fog_Enable) {
    fog = apply_fog(
        length(final_pos_world.xyz - _WorldSpaceCameraPos.xyz),
        _Gimmick_DS2_11_Fog_Density,
        UnityObjectToWorldNormal(rd),
        normalize(_Gimmick_DS2_11_Fog_Sun_Direction),
        _Gimmick_DS2_11_Fog_Sun_Color,
        _Gimmick_DS2_11_Fog_Sun_Exponent,
        _Gimmick_DS2_11_Fog_Sun_Color_2_Enable,
        _Gimmick_DS2_11_Fog_Sun_Color_2,
        _Gimmick_DS2_11_Fog_Sun_Exponent_2,
        _Gimmick_DS2_11_Fog_Color) * hit;
  }

  Gimmick_DS2_Output o;
  o.albedo = final_color;
  o.emission = 0;
  o.fog = fog;
  o.normal = normal;
  o.metallic = 0;
  o.roughness = 1;
  o.worldPos = final_pos_world;
  return o;
}

#endif  // _GIMMICK_DS2
#endif  // __DOWNSTAIRS_02_INC
