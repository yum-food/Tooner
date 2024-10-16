#include "cnlohr.cginc"
#include "globals.cginc"
#include "interpolators.cginc"
#include "math.cginc"
#include "noise.cginc"

#ifndef __FOG_INC
#define __FOG_INC

#if defined(_GIMMICK_FOG_00)

struct Fog00PBR {
  float4 albedo;
  float3 diffuse;
  float depth;
};

#define FOG_PERLIN_NOISE_MODE 1

#if FOG_PERLIN_NOISE_MODE == 0
#define FOG_PERLIN_NOISE perlin_noise_3d
#define FOG_PERLIN_NOISE_SCALE 1
#else
#define FOG_PERLIN_NOISE perlin_noise_3d_tex
#define FOG_PERLIN_NOISE_SCALE 32
#endif

float perlin_noise_3d_tex(float3 p)
{
  // 1/256 = 0.00390625
  float r_lo = _Gimmick_Fog_00_Noise.SampleLevel(linear_repeat_s, p.xyz * 0.00390625, 0);
  return r_lo;
}

float map(float3 p, float lod) {
  float3 t = _Time[1] * .5 * FOG_PERLIN_NOISE_SCALE;
#define RADIUS_TRANS_WIDTH 100
#define RADIUS_TRANS_WIDTH_RCP (1.0 / RADIUS_TRANS_WIDTH)
  // Try to create a smooth transition without doing any length() or other
  // transcendental ops.
  float radius2 = clamp(_Gimmick_Fog_00_Radius * _Gimmick_Fog_00_Radius - dot(p, p), 0, RADIUS_TRANS_WIDTH) * RADIUS_TRANS_WIDTH_RCP;

	float3 pp = p * _Gimmick_Fog_00_Noise_Scale * FOG_PERLIN_NOISE_SCALE + t;
  float density = FOG_PERLIN_NOISE(pp) * radius2 * 0.7;

  // Exponentiate to increase contrast.
  density *= density;
  // density had an expected value of 0.5. We just calculated pow(density, 2),
  // thus the new expected value is pow(0.5, ^ 2) = 1/4. Scale it to restore
  // the original EV.
  density *= 2;
  density = saturate(density);

  // This term creates large open areas.
  // This `if` doesn't actually create any thread divergence. Since all rays
  // shoot out in lock step, they all leave this mode at the same time.
  // Also, completely disable the term at high densities since those tend to be
  // slow (more computationally expensive) anyway.
  if (lod == 0 && _Gimmick_Fog_00_Noise_Scale < 2) {
    float tmp = FOG_PERLIN_NOISE(pp * 0.167 + t/4) * radius2 - 0.5;
    // Aggressively dial down this parameter as density increases. We really
    // need to keep paths short when density is high.
    float density_performance_fix = 1 / _Gimmick_Fog_00_Density;
    density_performance_fix *= density_performance_fix;
    tmp *= 0.5 * density_performance_fix;
    density += tmp;
  }
  return saturate(density);
}

#if defined(_GIMMICK_FOG_00_EMITTER_TEXTURE)
// Returns weighted color
float3 getEmitterData(float3 p,
    float step_size,
    float3 em_loc,
    float3 em_normal,
    float2 emitter_scale,
    float2 emitter_scale_rcp)
{
  // Project onto plane
  const float3 p_to_emitter = p - em_loc;
  const float t = dot(p_to_emitter, em_normal);
  const float3 p_projected = p - t * em_normal - em_loc;

  // Add some curvature to simulate scattering.
  //emitter_scale *= 1 + t*t * .002;

  bool in_range = (abs(p_projected.x) < emitter_scale.x) * (abs(p_projected.y) < emitter_scale.y) * (t > 0);
  if (!in_range) {
    return 0;
  }

  // Go up one LOD every 5 meters
  float2 emitter_uv = clamp(p_projected.xy, -emitter_scale, emitter_scale) * emitter_scale_rcp;
  emitter_uv *= 0.5;
  emitter_uv += 0.5;
  float emitter_lod = floor(abs(t) / (_Gimmick_Fog_00_Emitter_Lod_Half_Life * step_size));
  float3 em_color = _Gimmick_Fog_00_Emitter_Texture.SampleLevel(linear_repeat_s, emitter_uv, emitter_lod);
  em_color *= _Gimmick_Fog_00_Emitter_Brightness;
  float emitter_dist = in_range ? abs(t) : 1000;
  float emitter_falloff = min(1, rcp(pow(emitter_dist, 1.4)));
  return in_range * emitter_falloff * em_color;
}
#endif  // defined(_GIMMICK_FOG_00_EMITTER_TEXTURE)

Fog00PBR getFog00(v2f i) {

  float3 cam_pos = _WorldSpaceCameraPos;
  float3 obj_pos = i.worldPos;

  float3 world_pos_depth_hit;
  float2 screen_uv;
  {
    float3 full_vec_eye_to_geometry = i.worldPos - _WorldSpaceCameraPos;
    float3 world_dir = normalize(i.worldPos - _WorldSpaceCameraPos);
    float perspective_divide = 1.0 / i.pos.w;
    float perspective_factor = length(full_vec_eye_to_geometry * perspective_divide);
    screen_uv = i.screenPos.xy * perspective_divide;
    float eye_depth_world =
      GetLinearZFromZDepth_WorksWithMirrors(
          SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screen_uv),
          screen_uv) * perspective_factor;
    world_pos_depth_hit = _WorldSpaceCameraPos + eye_depth_world * world_dir;
  }

  float3 rd = normalize(obj_pos - cam_pos);
  float3 ro = cam_pos;

  bool no_intersection = false;
  if (length(ro) > _Gimmick_Fog_00_Radius) {
    float3 l = ro;
    float a = 1;
    float b = 2 * dot(rd, l);
    float c = dot(l, l) - _Gimmick_Fog_00_Radius * _Gimmick_Fog_00_Radius;
    float t0, t1;
    if (solveQuadratic(a, b, c, t0, t1)) {
      no_intersection = (t0 < 0) * (t1 < 0);
      ro += min(max(t0, 0), max(t1, 0)) * rd;
    } else {
      no_intersection = true;
    }
  }

  // Factor of 10 on `screen_uv*10` eliminates visible striping artifact that
  // is visible with no factor.
  float step_size = rcp(_Gimmick_Fog_00_Density) * _Gimmick_Fog_00_Step_Size_Factor;
  step_size = clamp(step_size, 1E-2, 10);
  int2 screen_uv_round = floor(screen_uv * _ScreenParams.xy);
  float dither_seed = rand2(float2(screen_uv_round.x, screen_uv_round.y)*.001);
  // Smoothly vary over time. Use a triangle wave since it distributes points
  // evenly. A sin wave would bunch points up at boundaries.
  #if 1
  dither_seed = frac(dither_seed + _Time[0]*2);
  dither_seed *= 2;  // Map onto [0, 2]
  dither_seed = abs(dither_seed - 1);  // Shape into triangle wave ranging from 0 to 1
  #endif
  float dither = dither_seed * step_size * _Gimmick_Fog_00_Ray_Origin_Randomization;
  ro += rd * (0.1 + dither);

  float world_pos_depth_hit_l = length(world_pos_depth_hit - ro);

  float4 acc = 0;
  uint step_count = floor(min(
        _Gimmick_Fog_00_Max_Ray / step_size,
        world_pos_depth_hit_l / step_size));
  step_count *= (1 - no_intersection);
#define FOG_MAX_LOOP 128
  step_count = min(step_count, FOG_MAX_LOOP);

#if defined(_GIMMICK_FOG_00_EMITTER_TEXTURE)
  const float3 em_loc = _Gimmick_Fog_00_Emitter0_Location;
  const float3 em_normal = normalize(_Gimmick_Fog_00_Emitter0_Normal);
  const float em_scale_x = _Gimmick_Fog_00_Emitter0_Scale_X;
  const float em_scale_y = _Gimmick_Fog_00_Emitter0_Scale_Y;
  const float2 em_scale = float2(em_scale_x, em_scale_y);
  const float2 em_scale_rcp = rcp(em_scale);
#endif

  const float lod_denom = 1.0 /
    (_Gimmick_Fog_00_Lod_Half_Life * _Gimmick_Fog_00_Density);
  for (uint ii = 0; ii < step_count; ii++) {
    const float ii_step_size = ii * step_size;
    const float3 p = ro + rd * ii_step_size;
    const float lod = floor(ii_step_size * lod_denom);

    const float map_p =
      saturate(map(p, lod) * _Gimmick_Fog_00_Density * step_size);
    float4 c = float4(0, 0, 0, map_p);

    // Seems that this is basically free.
#if defined(_GIMMICK_FOG_00_EMITTER_TEXTURE)
    c.rgb = getEmitterData(p, step_size, em_loc, em_normal, em_scale, em_scale_rcp);
#endif

    acc += c * (1.0 - acc.a);

    // For performance, stop if we...
    //  1. accumulate enough alpha
    //  2. go outside of the sphere
    if (acc.a > _Gimmick_Fog_00_Alpha_Cutoff ||
        dot(p, p) > _Gimmick_Fog_00_Radius * _Gimmick_Fog_00_Radius) {
      break;
    }
  }
  if (acc.a > _Gimmick_Fog_00_Alpha_Cutoff) {
    acc /= acc.a;
  }

  Fog00PBR pbr;
  pbr.albedo.rgb = 1;
  pbr.albedo.a = saturate(acc.a);
  pbr.diffuse = acc.rgb;

  float4 clip_pos = mul(UNITY_MATRIX_VP, float4(ro, 1.0));
  pbr.depth = clip_pos.z / clip_pos.w;

  return pbr;
}

#endif  // _GIMMICK_FOG_00

#endif  // __FOG_INC

