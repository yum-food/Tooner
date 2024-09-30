#include "globals.cginc"
#include "interpolators.cginc"
#include "iq_sdf.cginc"
#include "math.cginc"

#ifndef __EYES_INC
#define __EYES_INC

#if defined(_GIMMICK_EYES_00)

float eyes00_distance_from_sphere(float3 p, float3 c, float r)
{
    return length(p - c) - r;
}

float eyes00_map(float3 p)
{
    float t = _Time.y;
    float theta = sin(_Time[0]) / 2;
    float2x2 rot = float2x2(
      cos(theta), -sin(theta),
      sin(theta), cos(theta));

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
        float sphere = eyes00_distance_from_sphere(p, float3(pp.x, pp.y, 0.0), radius);
        dist = min(dist, sphere);
        dist += sin(5.0 * pp.x) * sin(5.0 * pp.y) * 0.5;
      }
    }

    return dist;
}

float3 eyes00_calc_normal(in float3 p)
{
    const float3 small_step = float3(0.0001, 0.0, 0.0);

    float gradient_x = eyes00_map(p + small_step.xyy) - eyes00_map(p - small_step.xyy);
    float gradient_y = eyes00_map(p + small_step.yxy) - eyes00_map(p - small_step.yxy);
    float gradient_z = eyes00_map(p + small_step.yyx) - eyes00_map(p - small_step.yyx);

    float3 normal = float3(gradient_x, gradient_y, gradient_z);

    return normalize(normal);
}

float3 __eyes00_march(float3 ro, float3 rd, inout float3 normal)
{
    float total_distance_traveled = 0.0;
    const float MINIMUM_HIT_DISTANCE = 0.001;
    const float MAXIMUM_TRACE_DISTANCE = 1000.0;

    #define EYES00_MARCH_STEPS 10
    float distance_to_closest;
    float3 current_position;
    for (int i = 0; i < EYES00_MARCH_STEPS; i++)
    {
        current_position = ro + total_distance_traveled * rd;

        distance_to_closest = eyes00_map(current_position);

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
      normal = eyes00_calc_normal(current_position);
      return float3(1.0, 1.0, 1.0);
    }

    return float3(0, 0, 0);
}

float4 eyes00_march(float2 uv, inout float3 normal)
{
    uv = uv * 2.0 - 1.0;

    float3 camera_position = float3(0.0, 0.0, -5.0);
    float3 ro = camera_position;
    float3 rd = float3(uv.x, uv.y, 1.0);

    float3 shaded_color = __eyes00_march(ro, rd, normal);

    return float4(shaded_color, 1.0);
}

#endif  // _GIMMICK_EYES_00

#if defined(_GIMMICK_EYES_01)

struct Eyes01PBR {
  float4 albedo;
  float3 normal;
};

float eyes01_map(float3 p)
{
  return length(p) - .01;
}

float3 eyes01_calc_normal(in float3 p)
{
    const float3 small_step = float3(0.0001, 0.0, 0.0);

    float gradient_x = eyes01_map(p + small_step.xyy) - eyes01_map(p - small_step.xyy);
    float gradient_y = eyes01_map(p + small_step.yxy) - eyes01_map(p - small_step.yxy);
    float gradient_z = eyes01_map(p + small_step.yyx) - eyes01_map(p - small_step.yyx);

    float3 normal = float3(gradient_x, gradient_y, gradient_z);

    return normalize(normal);
}

void __eyes01_march(float3 ro, float3 rd, inout Eyes01PBR result)
{
  float total_distance_traveled = 0.0;
  const float MINIMUM_HIT_DISTANCE = 0.001;
  const float MAXIMUM_TRACE_DISTANCE = 1000.0;

#define EYES01_MARCH_STEPS 50
  float distance_to_closest;
  float3 current_position;
  for (int i = 0; i < EYES01_MARCH_STEPS; i++)
  {
    current_position = ro + total_distance_traveled * rd;

    distance_to_closest = eyes01_map(current_position);

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
    result.normal = eyes01_calc_normal(current_position);
    result.albedo = 1;
  }

  result.normal = float3(0, 0, 1);  // doesn't matter
  result.albedo = 0;
}

Eyes01PBR eyes01_march(v2f i)
{
  Eyes01PBR result;

  float3 cam_pos = _WorldSpaceCameraPos;
  float3 ro = cam_pos;
  float3 rd = normalize(i.worldPos - cam_pos);

  float r_world = _Gimmick_Eyes01_Radius;
  float3 o = -i.normal * r_world;

  ro -= o;

  __eyes01_march(ro, rd, result);

  return result;
}

#endif  // _GIMMICK_EYES_01

#if defined(_GIMMICK_EYES_02)

struct chaos_data
{
  uint n;  // degrees of symmetry
  int p;
  float a0;
  float a1;
  float a2;
  float a3;
  float a4;
  complex z;
};

void iterate0(inout struct chaos_data d)
{
  complex z_conj = cconjugate(d.z);
  complex z_conj_n_1 = cpow(z_conj, d.n);
  complex z_n = cpow(d.z, d.n);

  complex next =
    cmul((
          complex(d.a0, 0) +
          d.a1 * cmul(d.z, cconjugate(d.z)) +
          complex(d.a2 * creal(z_n), 0) +
          complex(0, d.a3)
         ),
        d.z) +
    d.a4 * z_conj_n_1;

  d.z = next;
}

void iterate1(inout struct chaos_data d)
{
  complex z_conj = cconjugate(d.z);
  complex z_conj_n_1 = cpow(z_conj, d.n - 1);
  complex z_n = cpow(d.z, d.n);

  complex next =
    (d.a0 +
     d.a1 * (d.z.x * d.z.x - d.z.y * d.z.y) +
     d.a2 * creal(z_n) +
     d.a3 * creal(cmul(cpow((cdiv(d.z, abs(d.z))), d.n * d.p), abs(d.z)))) *
    d.z +
    d.a4 * (z_conj_n_1);

  d.z = next;
}

// Return a number on (0, inf)
float get_chaos(in float2 uv, inout chaos_data d)
{
  complex z = uv;
  // Remap onto [-1, 1]
  float scale = 2.0;
  z = z * scale * 2 - scale;
  d.z = z;

  for (int i = 0; i < 6; i++) {
    iterate0(d);
  }

  float l = d.z.x * d.z.x - d.z.y * d.z.y;
  if (l < 1) {
    float b = .1;
    return b/l;
  } else {
    return 0;
  }
}

float3 get_chaos_normal(in float2 uv, inout chaos_data d)
{
  float2 small_step = float2(.0001, 0);
  float dx = get_chaos(uv + small_step.xy, d) - get_chaos(uv, d);
  float dz = get_chaos(uv + small_step.yx, d) - get_chaos(uv, d);
  float dy = small_step.x;

  float3 normal = float3(dx, dy, dz);
  return UnityObjectToWorldNormal(normalize(normal));
}

bool eyes02_march(float2 uv, inout float3 normal)
{
  float2 uv_scale = _Gimmick_Eyes02_UV_Adjust.xy;
  float2 uv_center = _Gimmick_Eyes02_UV_Adjust.zw;
  uv -= 0.5;

  if (_Gimmick_Eyes02_UV_X_Symmetry) {
    uv.x = abs(uv.x);
  }

  uv -= (uv_center - 0.5);
  uv /= uv_scale;

  uv += 0.5;

  float t20 = _Time[0] * _Gimmick_Eyes02_Animate_Speed;
  float t = _Time[1] * _Gimmick_Eyes02_Animate_Speed;

  struct chaos_data d;
  d.n = _Gimmick_Eyes02_N;
  d.p = _Gimmick_Eyes02_N;
  d.a0 = _Gimmick_Eyes02_A0;
  d.a1 = _Gimmick_Eyes02_A1;
  d.a2 = _Gimmick_Eyes02_A2;
  d.a3 = _Gimmick_Eyes02_A3;
  d.a4 = _Gimmick_Eyes02_A4;

  if (_Gimmick_Eyes02_Animate) {
    float effect = 1;
    float e = _Gimmick_Eyes02_Animate_Strength;
    if (round(effect) == 0) {
      d.a0 += (sin(t * 1.1) * .01 + sin(t20 * 1.1) * .75) * e;
      d.a1 += (sin(t * 1.3) * .01 + sin(t20 * 1.3) * .75) * e;
      d.a2 += (sin(t * 1.7) * .01 + sin(t20 * 1.7) * 1) * e;
      d.a3 += (sin(t * 1.9) * .01 + sin(t20 * 1.9) * .75) * e;
      d.a4 += (sin(t * 2.3) * .02 + sin(t20 * 2.3) * .4) * e;
    } else if (round(effect) == 1) {
      d.a0 += (sin(t * 1.1) * .01 + sin(t20 * 1.1) * .75) * e;
      d.a1 += (sin(t * 1.3) * .01 + sin(t20 * 1.3) * .75) * e;
      d.a2 += (sin(t * 1.7) * .01 + sin(t20 * 1.7) * 1) * e;
      d.a3 += (sin(t * 1.9) * .0005 + sin(t20 * 1.9) * .05) * e;
      d.a4 += (sin(t * 2.3) * .02 + sin(t20 * 2.3) * 1) * e;
    }
  }

  float c = get_chaos(uv, d);
  c = exp(-c);

  if (c < 1) {
    normal = get_chaos_normal(uv, d);
  }
  bool is_ray_hit = (c < 1);
  return is_ray_hit;
}

#endif  // _GIMMICK_EYES_02

#endif  // __EYES_INC

