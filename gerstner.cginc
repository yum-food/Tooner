#include "globals.cginc"
#include "math.cginc"
#include "pema99.cginc"

#ifndef __GERSTNER_INC
#define __GERSTNER_INC

#if defined(_GIMMICK_GERSTNER_WATER)

struct GerstnerParams {
  // # of components considered
  uint M;
  // amplitudes
  float4 a;
  // phases
  float4 p;
  // wavenumbers
  float4 k_x;
  float4 k_y;
  // time factor
  float4 t_f;
#if defined(_GIMMICK_GERSTNER_WATER_COLOR_RAMP)
  float4 ramp_mask;
#endif
#if defined(_GIMMICK_GERSTNER_WATER_OCTAVE_1)
  float4 a1;
  float4 p1;
  float4 k_x1;
  float4 k_y1;
  float4 t_f1;
#if defined(_GIMMICK_GERSTNER_WATER_COLOR_RAMP)
  float4 ramp_mask1;
#endif
#endif
  // mean water depth
  float h;
  // gravity
  float g;
  float3 scale;
};

struct GerstnerFragResult {
  float4 tangent;
  float3 normal;
#if defined(_GIMMICK_GERSTNER_WATER_COLOR_RAMP)
  float3 color;
#endif
};

GerstnerParams getGerstnerParams() {
  GerstnerParams p;
  p.M = _Gimmick_Gerstner_Water_M;
  p.a = _Gimmick_Gerstner_Water_a;
  p.p = _Gimmick_Gerstner_Water_p;
  // Dumb artistic shit
  float k_x_time_distortion = _SinTime[2] * .0002;
  p.k_x = _Gimmick_Gerstner_Water_k_x + k_x_time_distortion;
  p.k_y = _Gimmick_Gerstner_Water_k_y;
  p.h = _Gimmick_Gerstner_Water_h;
  p.g = _Gimmick_Gerstner_Water_g;
  p.scale = _Gimmick_Gerstner_Water_Scale;
  p.t_f = _Gimmick_Gerstner_Water_t_f;
#if defined(_GIMMICK_GERSTNER_WATER_COLOR_RAMP)
  p.ramp_mask = _Gimmick_Gerstner_Water_Color_Ramp_Mask;
#endif
#if defined(_GIMMICK_GERSTNER_WATER_OCTAVE_1)
  p.a1 = _Gimmick_Gerstner_Water_a1;
  p.p1 = _Gimmick_Gerstner_Water_p1;
  p.k_x1 = _Gimmick_Gerstner_Water_k_x1;
  p.k_x1 += k_x_time_distortion;
  p.k_y1 = _Gimmick_Gerstner_Water_k_y1;
  p.t_f1 = _Gimmick_Gerstner_Water_t_f1;
#if defined(_GIMMICK_GERSTNER_WATER_COLOR_RAMP)
  p.ramp_mask1 = _Gimmick_Gerstner_Water_Color_Ramp_Mask1;
#endif
#endif
  return p;
}

struct GerstnerInternalResult {
  float3 world_pos;
  float color_ramp_pos;
};

GerstnerInternalResult compute_gerstner(float3 pp, GerstnerParams p)
{
  const float g_alpha = pp.x * p.scale.x;
  const float g_beta = pp.y * p.scale.y;
  float g_xi = g_alpha;
  float g_eta = g_beta;
  float g_zeta = 0;
  float g_zeta_color_ramp = 0;

  for (uint i = 0; i < p.M; i++) {
    uint i_mod_4 = glsl_mod(i, 4);
    switch (floor(i/4)) {
      case 0:
        {
          const float g_t = _Time[1] * p.t_f[i];
          // wavenumber
          const float g_k = length(float2(p.k_x[i], p.k_y[i]));
          // angular frequency
          const float g_w = sqrt(p.g * g_k * tanh(g_k * p.h));
          // angular frequency
          const float g_theta = p.k_x[i] * g_alpha + p.k_y[i] * g_beta - g_w * g_t - p.p[i];

          g_xi  -= (p.k_x[i] / g_k) * (p.a[i] / tanh(g_k * p.h)) * sin(g_theta);
          g_eta -= (p.k_y[i] / g_k) * (p.a[i] / tanh(g_k * p.h)) * sin(g_theta);
          g_zeta += p.a[i] * cos(g_theta);
#if defined(_GIMMICK_GERSTNER_WATER_COLOR_RAMP)
          g_zeta_color_ramp += p.a[i] * cos(g_theta) * p.ramp_mask[i];
#endif
          break;
        }
#if defined(_GIMMICK_GERSTNER_WATER_OCTAVE_1)
      case 1:
        {
          const float g_t = _Time[1] * p.t_f1[i_mod_4];
          // wavenumber
          const float g_k = length(float2(p.k_x1[i_mod_4], p.k_y1[i_mod_4]));
          // angular frequency
          const float g_w = sqrt(p.g * g_k * tanh(g_k * p.h));
          const float g_theta = p.k_x1[i_mod_4] * g_alpha + p.k_y1[i_mod_4] * g_beta - g_w * g_t - p.p1[i_mod_4];

          g_xi  -= (p.k_x1[i_mod_4] / g_k) * (p.a1[i_mod_4] / tanh(g_k * p.h)) * sin(g_theta);
          g_eta -= (p.k_y1[i_mod_4] / g_k) * (p.a1[i_mod_4] / tanh(g_k * p.h)) * sin(g_theta);
          g_zeta += p.a1[i_mod_4] * cos(g_theta);
#if defined(_GIMMICK_GERSTNER_WATER_COLOR_RAMP)
          g_zeta_color_ramp += p.a1[i_mod_4] * cos(g_theta) * p.ramp_mask1[i_mod_4];
#endif
          break;
        }
#endif
    }
  }

  const float3 raw_result = float3(g_xi / p.scale.x, g_eta / p.scale.y, g_zeta * p.scale.z);
  g_zeta_color_ramp *= p.scale.z;
  const float3 raw_result_world = mul(unity_ObjectToWorld, float4(raw_result, 1)).xyz;
  float3 result_world = raw_result_world;

  if (_Gimmick_Gerstner_Water_Origin_Damping_Direction > 0) {
    result_world.y = dmax(_Gimmick_Gerstner_Water_Origin_Damping_Direction, result_world.y, 1);
  } else {
    result_world.y = dmin(_Gimmick_Gerstner_Water_Origin_Damping_Direction, result_world.y, 1);
  }

  float3 result_obj = mul(unity_WorldToObject, float4(result_world, 1)).xyz;

  result_obj = lerp(result_obj, raw_result,
      // If within cylindrical distance, apply damping.
      // TODO parameterize this!
      dsaturate((length(raw_result_world.xz) - 15), 1) *
      // Only enable if mesh is on the wrong side of the damping vector.
      // TODO make this differentiable. As is, there's a visible seam.
      dsaturate(-(raw_result_world.y - _Gimmick_Gerstner_Water_Origin_Damping_Direction) * sign(_Gimmick_Gerstner_Water_Origin_Damping_Direction), 1));

  GerstnerInternalResult r;
  r.world_pos = result_obj;
  r.color_ramp_pos = g_zeta_color_ramp;
  return r;
}

float3 gerstner_vert(float3 pp, GerstnerParams p)
{
  return compute_gerstner(pp, p).world_pos;
}

GerstnerFragResult gerstner_frag(float3 pp, GerstnerParams p)
{
  const GerstnerInternalResult r0 = compute_gerstner(pp, p);
  const float3 g0 = r0.world_pos;
  const float3 e = float3(1E-7, 0, 0);
  const float3 g0_da = compute_gerstner(pp + e.xyz, p).world_pos;
  const float3 g0_db = compute_gerstner(pp + e.yxz, p).world_pos;
  const float3 ds_da = g0_da - g0;
  const float3 ds_db = g0_db - g0;

  GerstnerFragResult r;
  r.normal = normalize(cross(
        ds_da, ds_db));
  r.tangent = float4(normalize(ds_da), 1);

#if defined(_GIMMICK_GERSTNER_WATER_COLOR_RAMP)
  float ramp_phase = r0.color_ramp_pos;
  ramp_phase *= _Gimmick_Gerstner_Water_Color_Ramp_Scale;
  ramp_phase += _Gimmick_Gerstner_Water_Color_Ramp_Offset;
  float3 ramp_color = _Gimmick_Gerstner_Water_Color_Ramp.Sample(linear_clamp_s, float2(ramp_phase, 0.5));

  r.color = ramp_color;
#endif

  return r;
}

#endif  // _GIMMICK_GERSTNER_WATER
#endif  // __GERSTNER_INC

