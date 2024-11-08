#include "UnityCG.cginc"

#include "atrix256.cginc"
#include "cnlohr.cginc"
#include "globals.cginc"
#include "interpolators.cginc"
#include "math.cginc"
#include "noise.cginc"
#include "oklab.cginc"
#include "pbr.cginc"
#include "poi.cginc"

#ifndef __FOG_INC
#define __FOG_INC

#if defined(_GIMMICK_FOG_00)

struct Fog00PBR {
  float4 albedo;
  float depth;
};

#define FOG_PERLIN_NOISE_SCALE 32

float3 perlin_noise_3d_tex(float3 p)
{
  // 1/256 = 0.00390625
  return _Gimmick_Fog_00_Noise.SampleLevel(trilinear_repeat_s, p.xyz * 0.00390625, 0);
}

#define FBM_OCTAVES 3

float3 perlin_noise_3d_tex_fbm(float3 p)
{
  float3 res = perlin_noise_3d_tex(p);
  float p_scale = 1;
  //float d_scale = .66666;
  float d_scale = .571428571;
  for (uint i = 1; i < FBM_OCTAVES; i++) {
    p_scale *= 2;
    d_scale *= .5;
    res += perlin_noise_3d_tex(p*p_scale)*d_scale;
  }
  return res;
}

// idea from here https://iquilezles.org/articles/warp/
float3 perlin_noise_3d_tex_warp(float3 p)
{
  p = perlin_noise_3d_tex(p);
  p = perlin_noise_3d_tex(p * 255);
  p = perlin_noise_3d_tex(p * 255);
  return p;
}

float3 light_fog00(
    float3 albedo,
    float NoL,
    float3 direct,
    float3 diffuse
    ) {
  half diffuseTerm = NoL;
  float wrappedDiffuse = saturate((diffuseTerm + _WrappingFactor) /
      (1.0f + _WrappingFactor)) * 2 / (2 * (1 + _WrappingFactor));
#if 0
  float3 direct_unlit = .01;
  direct = lerp(direct, direct_unlit, wrappedDiffuse);
#endif
  float3 diffCol = albedo * (diffuse + direct * wrappedDiffuse);
  return diffCol;
}

float map(float3 p, out float3 normal) {
#if 1
  float3 t = _Time[0] * FOG_PERLIN_NOISE_SCALE;
  t.y *= .3;
#else
  float3 t = 0;
#endif
#define RADIUS_TRANS_WIDTH 800
#define RADIUS_TRANS_WIDTH_RCP (1.0 / RADIUS_TRANS_WIDTH)
  // Try to create a smooth transition without doing any length() or other
  // transcendental ops.
  float radius2 = clamp(_Gimmick_Fog_00_Radius * _Gimmick_Fog_00_Radius - dot(p, p), 0, RADIUS_TRANS_WIDTH) * RADIUS_TRANS_WIDTH_RCP;

	float3 pp = p * _Gimmick_Fog_00_Noise_Scale * FOG_PERLIN_NOISE_SCALE;
  normal = normalize(perlin_noise_3d_tex(pp+t) * 2 - 1);
  float density = perlin_noise_3d_tex_warp(pp+t) * radius2;

  return density;
}

#if defined(_GIMMICK_FOG_00_EMITTER_TEXTURE)
// Returns weighted color
void getEmitterData(float3 p,
    float step_size,
    float3 em_loc,
    float3 em_normal,
    float2 emitter_scale,
    float2 emitter_scale_rcp,
    out float3 diffuse,
    out float3 direct)
{
  // Project onto plane
  const float3 p_to_emitter = p - em_loc;
  const float t = dot(p_to_emitter, em_normal);
  float3 p_projected = p - t * em_normal - em_loc;

  // Add some curvature to simulate scattering.
  //emitter_scale *= 1 + t*t * .002;

  bool in_range = (abs(p_projected.x) < emitter_scale.x) * (abs(p_projected.y) < emitter_scale.y) * (t > 0);

  // Go up one LOD every 5 meters
  float3 em_loc_clamp = p_projected;
  em_loc_clamp.xy = clamp(em_loc_clamp.xy, -emitter_scale, emitter_scale);
  float2 emitter_uv = em_loc_clamp.xy * emitter_scale_rcp;
  emitter_uv *= 0.5;
  emitter_uv += 0.5;

#if 0
  emitter_uv.y = FOG_PERLIN_NOISE(float3(emitter_uv*100, _Time[2]));
  emitter_uv.x = FOG_PERLIN_NOISE(p);
  emitter_uv.y = FOG_PERLIN_NOISE(float3(emitter_uv*100, _Time[2]));
#endif

  float emitter_lod = floor(abs(t) / (_Gimmick_Fog_00_Emitter_Lod_Half_Life * step_size));
  float3 em_color = _Gimmick_Fog_00_Emitter_Texture.SampleLevel(linear_clamp_s, emitter_uv, emitter_lod);
  float emitter_dist = in_range ? abs(t) : 1000;
  float emitter_falloff = min(1, rcp(emitter_dist));

  direct = in_range * emitter_falloff * em_color;

  diffuse = _Gimmick_Fog_00_Emitter_Texture.SampleLevel(linear_clamp_s, emitter_uv, 10);
  em_loc_clamp += em_loc;
#if 0
  float diffuse_falloff = min(1, 5 / dot(p - em_loc_clamp, p - em_loc_clamp));
#else
  // TODO parameterize shaping constants
  float diffuse_falloff = min(5, 4 / length(p - em_loc_clamp));
#endif
  diffuse *= diffuse_falloff;
}
#endif  // defined(_GIMMICK_FOG_00_EMITTER_TEXTURE)

#if defined(_GIMMICK_FOG_00_RAY_MARCH_0)
float fog00_map(float3 p, float rid_entropy)
{
  float sin_term = sin(rid_entropy*2*TAU+_Time[0]*2)+1.0;
  sin_term *= sin_term;
  sin_term *= 0.7;
  return length(p)+0.7-rid_entropy*2.3*
    sin_term*.2;
}
float fog00_map_dr(
    float3 p,
    float3 period,
    float3 count,
    float seed,
    out float3 which
    )
{
  p -= float3(0, period.y * floor(count.y/2) + 1, 0);
  p -= unity_ObjectToWorld._m03_m13_m23;

  which = round(p / period);
  // Direction to nearest neighboring cell.
  float3 min_d = p - period * which;
  float3 o = sign(min_d);

  float d = 1E9;
  float3 which_tmp = which;
#if 1
  for (uint xi = 0; xi < 2; xi++)
  for (uint yi = 0; yi < 2; yi++)
  for (uint zi = 0; zi < 2; zi++)
#else
  uint xi = 0;
  uint yi = 0;
  uint zi = 0;
#endif
  {
    float3 rid = which + float3(xi, yi, zi) * o;
    rid = clamp(rid, ceil(-(count)*0.5), floor((count-1)*0.5));
    float3 r = p - period * rid;
    float3 rid_entropy = float3(
        ign(rid.yz+seed),
        ign(rid.xz+seed),
        ign(rid.xy+seed));
    float3 random_dir = normalize(rid_entropy);
    r +=
      (sin(_Time[0] * 2 + (rid_entropy.x + rid_entropy.y + rid_entropy.z) * TAU * .6666) * 2 - 1.0) *
      period * 0.5 *
      random_dir *
      float3(1, 1, 1) * .3;
    float cur_d = fog00_map(r, FOG_PERLIN_NOISE((rid+seed)*100));
    which_tmp = cur_d < d ? rid : which_tmp;
    d = min(d, cur_d);
  }

  which = which_tmp;
  return d;
}
#endif

Fog00PBR getFog00(v2f i, ToonerData tdata) {
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
          SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, tdata.screen_uv),
          screen_uv) * perspective_factor;
    world_pos_depth_hit = _WorldSpaceCameraPos + eye_depth_world * world_dir;
  }

  const float3 rd = normalize(obj_pos - cam_pos);
  float3 ro = cam_pos;

  const bool inside_sphere = length(ro) < _Gimmick_Fog_00_Radius;
  bool no_intersection = false;
  float distance_to_sphere = 1E6;
  {
    float3 l = ro;
    float a = 1;
    float b = 2 * dot(rd, l);
    float c = dot(l, l) - _Gimmick_Fog_00_Radius * _Gimmick_Fog_00_Radius;
    float t0, t1;
    if (solveQuadratic(a, b, c, t0, t1)) {
      no_intersection = (t0 < 0) * (t1 < 0);
      if (inside_sphere) {
        distance_to_sphere = no_intersection ? distance_to_sphere : max(t0, t1);
        distance_to_sphere = min(distance_to_sphere, length(world_pos_depth_hit - ro));
      } else {
        distance_to_sphere = no_intersection ? distance_to_sphere : min(max(t0, 0), max(t1, 0));
        ro += distance_to_sphere * rd;
        distance_to_sphere = max(distance_to_sphere, length(world_pos_depth_hit - ro));
      }
    }
  }

  float density_ss_term = 1 / _Gimmick_Fog_00_Density;
  //density_ss_term = dclamp(density_ss_term, 0.33, 3.00, 5);
  const float step_size = _Gimmick_Fog_00_Step_Size_Factor * density_ss_term;
  const float step_size_sqrt = sqrt(step_size);
  const float step_size_sqrt_max1 = max(1, step_size_sqrt);
  //step_size = clamp(step_size, 1E-2, 1E2);
  uint2 screen_uv_round = floor(screen_uv * _ScreenParams.xy);
#if defined(_GIMMICK_FOG_00_NOISE_2D)
  const float dither_seed = _Gimmick_Fog_00_Noise_2D.SampleLevel(point_repeat_s, screen_uv_round * _Gimmick_Fog_00_Noise_2D_TexelSize.xy, 0);
#elif 1
  const float dither_seed = ign(screen_uv_round);
#else
  const float dither_seed = rand2(float2(screen_uv_round.x, screen_uv_round.y)*.001);
#endif
  float dither = dither_seed * step_size * _Gimmick_Fog_00_Ray_Origin_Randomization;
  ro += rd * (0.01 + dither);

  const float world_pos_depth_hit_l = length(world_pos_depth_hit - ro);

  // Get common lighting data
  UnityLight direct_light;
  UnityIndirect indirect_light;
  direct_light.dir = getDirectLightDirection(i);
  direct_light.ndotl = 0;  // Not used
  direct_light.color = getDirectLightColor();
  // TODO try per-sample baked lighting
  indirect_light.diffuse = getIndirectDiffuse(i, /*vertex_light_color=*/0);
  // TODO consider doing specular. At time of writing it seems pointless.
  indirect_light.specular = 0;

  float4 acc = 0;
  uint step_count = floor(min(
        _Gimmick_Fog_00_Max_Ray / step_size,
        world_pos_depth_hit_l / step_size));
  step_count *= (1 - no_intersection);
#define FOG_MAX_LOOP (128+16)
  step_count = min(step_count, FOG_MAX_LOOP);

#if defined(_GIMMICK_FOG_00_EMITTER_TEXTURE)
  const float3 em_loc = _Gimmick_Fog_00_Emitter0_Location;
  const float3 em_normal = normalize(_Gimmick_Fog_00_Emitter0_Normal);
  const float em_scale_x = _Gimmick_Fog_00_Emitter0_Scale_X;
  const float em_scale_y = _Gimmick_Fog_00_Emitter0_Scale_Y;
  const float2 em_scale = float2(em_scale_x, em_scale_y);
  const float2 em_scale_rcp = rcp(em_scale);
#endif

  const float noise_scale_rcp = 1.0 / _Gimmick_Fog_00_Noise_Scale;
  for (uint ii = 0; ii < step_count; ii++) {
    const float ii_step_size = ii * step_size;
    const float3 p = ro + rd * ii_step_size;

    float4 c;
    float3 c_lit = 0;
#if 1
    float3 map_normal;
    const float map_p_raw = map(p, map_normal);
    const float map_p = map_p_raw * _Gimmick_Fog_00_Density * step_size;
    c = float4(_Color.rgb, map_p);
    float3 diffuse = 0;
    float3 direct = 0;
#if defined(_GIMMICK_FOG_00_EMITTER_TEXTURE) && !defined(_GIMMICK_FOG_00_EMITTER_VARIABLE_DENSITY)
    // We put the emitter color into diffuse instead of doing a directional
    // calculation because it looks better and it's cheaper. Less accurate
    // though!
    if (_Gimmick_Fog_00_Enable_Area_Lighting) {
      // Note that I'm intentionally passing in `direct` and `diffuse`
      // backwards. It looks better if the collimated light is immune to normal
      // dimming, and if the diffuse light is not.
      getEmitterData(p, step_size, em_loc, em_normal,
          em_scale, em_scale_rcp, direct, diffuse);
    }
#endif

    diffuse *= _Gimmick_Fog_00_Emitter_Brightness;
    // Scaling brightness by sqrt(step_size) seems to look more consistent as
    // you vary density. No idea why :(
    float NoL = dot(map_normal, direct_light.dir);
    c_lit += light_fog00(
        c.rgb,
        NoL, 
        (direct_light.color + direct) * step_size_sqrt_max1,
        (indirect_light.diffuse + diffuse) * step_size_sqrt_max1);
#else
    c_lit = .05 * step_size;
    c.a = 0.1;
#endif
#if defined(_GIMMICK_FOG_00_EMITTER_TEXTURE) && defined(_GIMMICK_FOG_00_EMITTER_VARIABLE_DENSITY)
    float3 em_c = getEmitterData(p, step_size, em_loc, em_normal, em_scale, em_scale_rcp) * step_size;
    float em_NoL = saturate((map(p + dd_e * em_normal, lod) - map_p_raw) / dd_e);
    c_lit += light_fog00(
        c.rgb,
        em_NoL, 
        em_c,
        0);
#endif
    c.rgb = c_lit;

    // Intuition: add c scaled by the remaining transparent portion of acc.
    acc = acc + (1 - acc.a) * c;

#if 1
    // For performance, stop if we...
    //  1. accumulate enough alpha
    //  2. go outside of the sphere
    if (acc.a > _Gimmick_Fog_00_Alpha_Cutoff ||
        dot(p, p) > _Gimmick_Fog_00_Radius * _Gimmick_Fog_00_Radius) {
      break;
    }
#endif
  }
  if (acc.a > _Gimmick_Fog_00_Alpha_Cutoff) {
    acc /= acc.a;
  }

  Fog00PBR pbr;
  pbr.albedo = saturate(acc);

  // Add some dithering to lit color to break up banding
  pbr.albedo.rgb += ign(tdata.screen_uv_round) * .00390625;

  float4 clip_pos = mul(UNITY_MATRIX_VP, float4(ro, 1.0));
  pbr.depth = clip_pos.z / clip_pos.w;

  return pbr;
}

#endif  // _GIMMICK_FOG_00

#endif  // __FOG_INC

