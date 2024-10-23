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
#if defined(_GIMMICK_GERSTNER_WATER_OCTAVE_1)
  float4 a1;
  float4 p1;
  float4 k_x1;
  float4 k_y1;
  float4 t_f1;
#endif
  // mean water depth
  float h;
  // gravity
  float g;
  float3 scale;
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
#if defined(_GIMMICK_GERSTNER_WATER_OCTAVE_1)
  p.a1 = _Gimmick_Gerstner_Water_a1;
  p.p1 = _Gimmick_Gerstner_Water_p1;
  p.k_x1 = _Gimmick_Gerstner_Water_k_x1;
  p.k_x1 += k_x_time_distortion;
  p.k_y1 = _Gimmick_Gerstner_Water_k_y1;
  p.t_f1 = _Gimmick_Gerstner_Water_t_f1;
#endif
  return p;
}

float3 compute_gerstner(float3 pp, GerstnerParams p)
{
  const float g_alpha = pp.x * p.scale.x;
  const float g_beta = pp.y * p.scale.y;
  float g_xi = g_alpha;
  float g_eta = g_beta;
  float g_zeta = 0;

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
          break;
        }
#endif
    }

  }

  const float3 raw_result = float3(g_xi / p.scale.x, g_eta / p.scale.y, g_zeta * p.scale.z);
  const float origin_damping_factor = 1 - pow(0.5, max(0, length(raw_result)*5000-2));

  float3 result = raw_result;
  result.z *= origin_damping_factor;
  return result;
}

float3 gerstner_vert(float3 pp, GerstnerParams p)
{
  return compute_gerstner(pp, p);
}

float3 gerstner_frag(float3 pp, GerstnerParams p)
{
  const float3 g0 = compute_gerstner(pp, p);
  const float3 e = float3(.001, 0, 0);
  const float3 g0_da = compute_gerstner(pp + e.xyz, p);
  const float3 g0_db = compute_gerstner(pp + e.yxz, p);
  const float3 ds_da = g0_da - g0;
  const float3 ds_db = g0_db - g0;

  const float3 n = normalize(cross(
        ds_da, ds_db));
  return n;
}

#endif  // _GIMMICK_GERSTNER_WATER
#endif  // __GERSTNER_INC

