#include "globals.cginc"
#include "interpolators.cginc"
#include "math.cginc"
#include "noise.cginc"
#include "cnlohr.cginc"

#ifndef __FOG_INC
#define __FOG_INC

#if defined(_GIMMICK_FOG_00)

struct Fog00PBR {
  float4 albedo;
  float3 normal;
  float3 diffuse;
  float depth;
  float ao;
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

float3 get_normal(float3 p, float map_p, float lod) {
  float3 e = float3(0.001, 0, 0);
  float center = map_p;

  // Prevent NaN
  float e2 = 1E-9;
  return normalize(float3(
      map(p + e.xyz, lod) - center,
      map(p + e.yxz, lod) - center,
      map(p + e.zyx, lod) - center) + e2);
}

void getEmitterData(float3 p, float step_size,
    float3 em_loc, float3 em_normal, float2 emitter_scale,
    out float3 em_color, out float em_weight)
{
  // Project onto plane
  const float3 p_to_emitter = p - em_loc;
  const float t = dot(p_to_emitter, em_normal);
  const float3 p_projected = p - t * em_normal - em_loc;

  // Add some curvature to simulate scattering.
  //emitter_scale *= 1 + t*t * .002;

  bool in_range = (abs(p_projected.x) < emitter_scale.x) * (abs(p_projected.y) < emitter_scale.y) * (t > 0);

  // Go up one LOD every 5 meters
  // TODO make this tunable
  if (in_range) {
    float2 emitter_uv = clamp(p_projected.xy, -emitter_scale, emitter_scale) / emitter_scale;
    emitter_uv /= 2.0;
    emitter_uv += 0.5;
    float emitter_lod = floor(abs(t) / (_Gimmick_Fog_00_Emitter_Lod_Half_Life * step_size));
    em_color = _Gimmick_Fog_00_Emitter_Texture.SampleLevel(linear_repeat_s, emitter_uv, emitter_lod);
    em_color *= _Gimmick_Fog_00_Emitter_Brightness;
    float emitter_dist = in_range ? abs(t) : 1000;
    float emitter_falloff = min(1, rcp(pow(emitter_dist, 1.4)));
    em_weight = in_range * emitter_falloff;
  } else {
    em_color = 0;
    em_weight = 0;
  }
}

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

  float3 normal = i.normal;
  float ao = 0;
  for (uint ii = 0; ii < step_count; ii++) {
    const float3 p = ro + (rd * step_size) * ii;
    const float lod = floor((ii * step_size) / (_Gimmick_Fog_00_Lod_Half_Life * _Gimmick_Fog_00_Density));

    const float map_p = map(p, lod);
    float4 c = float4(0, 0, 0, map_p);
    c.a = saturate(c.a * _Gimmick_Fog_00_Density * step_size);

#if defined(_GIMMICK_FOG_00_EMITTER_TEXTURE)
    {
      const float3 em_loc = _Gimmick_Fog_00_Emitter0_Location;
      const float3 em_normal = normalize(_Gimmick_Fog_00_Emitter0_Normal);
      const float em_scale_x = _Gimmick_Fog_00_Emitter0_Scale_X;
      const float em_scale_y = _Gimmick_Fog_00_Emitter0_Scale_Y;

      float3 em_color;
      float em_weight;
      getEmitterData(p, step_size, em_loc, em_normal, float2(em_scale_x, em_scale_y), em_color, em_weight);
#if defined(_GIMMICK_FOG_00_EMITTER_1)
      const float3 em1_loc = _Gimmick_Fog_00_Emitter1_Location;
      const float3 em1_normal = normalize(_Gimmick_Fog_00_Emitter1_Normal);
      const float em1_scale_x = _Gimmick_Fog_00_Emitter1_Scale_X;
      const float em1_scale_y = _Gimmick_Fog_00_Emitter1_Scale_Y;
      float3 em1_color;
      float em1_weight;
      getEmitterData(p, step_size, em1_loc, em1_normal, float2(em1_scale_x, em1_scale_y), em1_color, em1_weight);
      em_color += em1_color;
      em_weight += em1_weight;
#endif
#if defined(_GIMMICK_FOG_00_EMITTER_2)
      const float3 em2_loc = _Gimmick_Fog_00_Emitter2_Location;
      const float3 em2_normal = normalize(_Gimmick_Fog_00_Emitter2_Normal);
      const float em2_scale_x = _Gimmick_Fog_00_Emitter2_Scale_X;
      const float em2_scale_y = _Gimmick_Fog_00_Emitter2_Scale_Y;
      float3 em2_color;
      float em2_weight;
      getEmitterData(p, step_size, em2_loc, em2_normal, float2(em2_scale_x, em2_scale_y), em2_color, em2_weight);
      em_color += em2_color;
      em_weight += em2_weight;
#endif
      c.rgb = lerp(c.rgb, em_color, em_weight);
    }
#endif

    acc += c * (1.0 - acc.a);

    // Performance hack: stop blending normals after enough accumulation.
#if 0
    if (acc.a < _Gimmick_Fog_00_Normal_Cutoff) {
      float3 n = get_normal(p, map_p);
      float n_interp = saturate(c.a * (1.0 - acc.a) * rcp(_Gimmick_Fog_00_Normal_Cutoff));
      normal = MY_BLEND_NORMALS(normal, n, n_interp);
    }
#endif
    if (acc.a > _Gimmick_Fog_00_Alpha_Cutoff) {
      acc /= acc.a;
      break;
    }
    // Performance hack: stop iterating if we go outside of the sphere.
    if (dot(p, p) > _Gimmick_Fog_00_Radius * _Gimmick_Fog_00_Radius) {
      break;
    }
  }

  Fog00PBR pbr;
  pbr.albedo.rgb = 1;
  pbr.albedo.a = saturate(acc.a);
  pbr.ao = 1;
  pbr.diffuse = acc.rgb;

#if 1
  pbr.normal = normalize(normal);
#else
  pbr.normal = i.normal;
#endif

  float4 clip_pos = mul(UNITY_MATRIX_VP, float4(ro, 1.0));
  pbr.depth = clip_pos.z / clip_pos.w;

  return pbr;
}

#endif  // _GIMMICK_FOG_00

#endif  // __FOG_INC

