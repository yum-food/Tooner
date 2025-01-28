#include "UnityCG.cginc"

#include "audiolink.cginc"
#include "atrix256.cginc"
#include "cnlohr.cginc"
#include "globals.cginc"
#include "interpolators.cginc"
#include "math.cginc"
#include "noise.cginc"
#include "oklab.cginc"
#include "pbr.cginc"
#include "poi.cginc"
#include "tone.cginc"

#ifndef __FOG_INC
#define __FOG_INC

#if defined(_GIMMICK_FOG_00)

struct Fog00PBR {
  float4 albedo;
  float depth;
};

#define FOG_PERLIN_NOISE_SCALE 1

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
  float3 t = float3(0, -_Time[0] * FOG_PERLIN_NOISE_SCALE, 0) * _Gimmick_Fog_00_Motion_Vector;
#else
  float3 t = 0;
#endif
#define RADIUS_TRANS_WIDTH .5
#define RADIUS_TRANS_WIDTH_RCP (1.0 / RADIUS_TRANS_WIDTH)
  // Try to create a smooth transition without doing any length() or other
  // transcendental ops.
#if 1 && defined(_GIMMICK_FOG_00_BOUNDARY_CYLINDER)
  float radius2 = clamp(_Gimmick_Fog_00_Radius * _Gimmick_Fog_00_Radius - dot(p.xz, p.xz), 0, RADIUS_TRANS_WIDTH) * RADIUS_TRANS_WIDTH_RCP;
#elif 1 && defined(_GIMMICK_FOG_00_BOUNDARY_SPHERE)
  float radius2 = clamp(_Gimmick_Fog_00_Radius * _Gimmick_Fog_00_Radius - dot(p, p), 0, RADIUS_TRANS_WIDTH) * RADIUS_TRANS_WIDTH_RCP;
#else
  float radius2 = 1;
#endif

	float3 pp = p * _Gimmick_Fog_00_Noise_Scale * FOG_PERLIN_NOISE_SCALE;
  normal = normalize(perlin_noise_3d_tex(pp+t) * 2 - 1);
  float density = perlin_noise_3d_tex_warp(pp+t) * radius2;
  //float density = perlin_noise_3d_tex(pp+t) * radius2;
  //float density = 0.5 * radius2;
  //density = pow(density, _Gimmick_Fog_00_Noise_Exponent);
  // EV is 0.5, so apply corrective factor of pow(2, _Gimmick_Fog_00_Noise_Exponent - 1)
  //density *= pow(2, _Gimmick_Fog_00_Noise_Exponent - 1);
  //density *= 8;
  density *= density * 2;

  return density;
}

#if defined(_GIMMICK_FOG_00_EMITTER_TEXTURE)
// Returns weighted color
void getEmitterData(float3 p,
    float dither,
    float step_size,
    float3 em_loc,
    float3 em_normal,
    float3 em_tangent,
    float3 em_normal_x_tangent,
    float2 emitter_scale,
    float2 emitter_scale_rcp,
    out float3 diffuse,
    out float3 direct)
{
  // Using identity a_parallel_to_b = (dot(a, b) / dot(b, b)) * b
  //   float3 along_tangent = dot(p - em_loc, em_tangent) * em_tangent;
  //   float3 along_normal_x_tangent = dot(p - em_loc, em_normal_x_tangent) *
  //       em_normal_x_tangent;
  // Given that em_tangent and em_normal_x_tangent are normalized, and the fact
  // that we really want uvs, we can simplify this:
  float2 uv = float2(dot(p - em_loc, em_normal_x_tangent), dot(p - em_loc, em_tangent));
  uv *= emitter_scale_rcp;
  uv *= 0.5;
  uv += 0.5;

  //uv.x += dither * .01;
  const float frame = ((float) AudioLinkData(ALPASS_GENERALVU + int2(1, 0)).x);
  //uv.x += ign_anim((dither+1000) * 1000, frame, /*speed=*/1.0) * .01;
  //uv.y += ign_anim(dither * 1000, frame, /*speed=*/1.0) * .01;

  bool in_range = uv.x < 1 && uv.y < 1 && uv.x > 0 && uv.y > 0;

#if 0
  uv.y = FOG_PERLIN_NOISE(float3(uv*100, _Time[2]));
  uv.x = FOG_PERLIN_NOISE(p);
  uv.y = FOG_PERLIN_NOISE(float3(uv*100, _Time[2]));
#endif

  const float3 p_to_emitter = p - em_loc;
  const float t = dot(p_to_emitter, em_normal);

  const float raw_noise_sample = _Gimmick_Fog_00_Noise_2D.SampleLevel(point_repeat_s, uv * 1000, 0).x;
  float emitter_lod = floor((abs(t) + dither) / ((_Gimmick_Fog_00_Emitter_Lod_Half_Life*(1+raw_noise_sample*2.5) * step_size)));
  float3 em_color = _Gimmick_Fog_00_Emitter_Texture.SampleLevel(point_clamp_s, uv, emitter_lod);
  float emitter_dist = in_range ? abs(t) : 1000;
  float emitter_falloff = min(1, rcp(emitter_dist));

  direct = in_range * emitter_falloff * em_color;

#if 1
  float e = 0.1;
  float2 uv_inv = 1.0 - uv;
  diffuse = _Gimmick_Fog_00_Emitter_Texture.SampleLevel(point_clamp_s, float2(uv.x, uv.y), 16) +
    _Gimmick_Fog_00_Emitter_Texture.SampleLevel(point_clamp_s, float2(uv.x, uv_inv.y), 16) +
    _Gimmick_Fog_00_Emitter_Texture.SampleLevel(point_clamp_s, float2(uv_inv.x, uv.y), 16);
  diffuse *= 0.3333;
  float3 em_loc_clamp = em_loc + (saturate(uv.x) *2 - 1) * em_tangent + (saturate(uv.y) * 2 - 1) * em_normal_x_tangent;
  em_loc_clamp += em_loc;
  // TODO parameterize shaping constants
  float diffuse_length = dot(p - em_loc_clamp, p - em_loc_clamp);
  diffuse /= diffuse_length;
#else
  diffuse = 0;
#endif
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

Fog00PBR __getFog00(v2f i, ToonerData tdata,
    float3 obj_pos_depth_hit,
    float2 screen_uv);

Fog00PBR getFog00(v2f i, ToonerData tdata)
{
  float3 obj_pos_depth_hit;
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
    float3 world_pos_depth_hit = _WorldSpaceCameraPos + eye_depth_world * world_dir;
    obj_pos_depth_hit = mul(unity_WorldToObject, float4(world_pos_depth_hit, 1.0)).xyz;
  }

  return __getFog00(i, tdata, obj_pos_depth_hit, screen_uv);
}

Fog00PBR __getFog00(v2f i, ToonerData tdata,
    float3 obj_pos_depth_hit,
    float2 screen_uv)
{
  float3 cam_pos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0)).xyz;
  float3 obj_pos = i.objPos;

  const float3 rd = normalize(obj_pos - cam_pos);
  float3 ro = cam_pos;

#if defined(_GIMMICK_FOG_00_BOUNDARY_CYLINDER)
  {
    // Raytrace distance to cylinder
    bool no_intersection = false;
    float distance_to_cylinder = 1E6;
    {
      float a = dot(rd.xz, rd.xz);
      float b = 2 * dot(rd.xz, ro.xz);
      float c = dot(ro.xz, ro.xz) - _Gimmick_Fog_00_Radius * _Gimmick_Fog_00_Radius;
      float t0, t1;
      if (solveQuadratic(a, b, c, t0, t1)) {
        no_intersection = (t0 < 0) * (t1 < 0);
        const bool inside_cylinder = (t0 < 0) * (t1 > 0);
        if (!inside_cylinder) {
          distance_to_cylinder = no_intersection ? distance_to_cylinder : min(max(t0, 0), max(t1, 0));
          ro += distance_to_cylinder * rd;
        }
      }
    }
    clip(no_intersection ? -1 : 1);
  }
#elif defined(_GIMMICK_FOG_00_BOUNDARY_PLANE)
  {
    // Raytrace distance to plane
    bool no_intersection = false;
    float distance_to_plane = 1E6;
    {
      // Define the plane by normal and point
      float3 n = normalize(mul(unity_WorldToObject, float4(_Gimmick_Fog_00_Plane_Normal, 0.0)).xyz);
      float3 p0 = _Gimmick_Fog_00_Plane_Center;

      float denom = dot(n, rd);
      if (abs(denom) > 1e-6) {
        // The ray is not parallel to the plane
        float t = dot(n, (p0 - ro)) / denom;
        if (t >= 0) {
          distance_to_plane = t;
          ro += distance_to_plane * rd;
        } else {
          no_intersection = true; // Intersection is behind the ray origin
        }
      } else {
        no_intersection = true; // Ray is parallel to the plane
      }
    }
    clip(no_intersection ? -1 : 1);
  }
#elif defined(_GIMMICK_FOG_00_BOUNDARY_SPHERE)
  {
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
        const bool inside_sphere = (t0 < 0) * (t1 > 0);
        if (!inside_sphere) {
          distance_to_sphere = no_intersection ? distance_to_sphere : min(max(t0, 0), max(t1, 0));
          ro += distance_to_sphere * rd;
        }
      }
    }
    clip(no_intersection ? -1 : 1);
  }
#endif

  float density_ss_term = 1 / _Gimmick_Fog_00_Density;
  //density_ss_term = dclamp(density_ss_term, 0.33, 3.00, 5);
  const float step_size = _Gimmick_Fog_00_Step_Size_Factor * density_ss_term;
  const float step_size_sqrt = sqrt(step_size);
  const float step_size_sqrt_max1 = max(1, step_size_sqrt);
  //step_size = clamp(step_size, 1E-2, 1E2);
  uint2 screen_uv_round = floor(screen_uv * _ScreenParams.xy);
  const float frame = ((float) AudioLinkData(ALPASS_GENERALVU + int2(1, 0)).x);
#if defined(_GIMMICK_FOG_00_NOISE_2D)
  const float raw_noise_sample = _Gimmick_Fog_00_Noise_2D.SampleLevel(point_repeat_s, screen_uv * _ScreenParams.xy * _Gimmick_Fog_00_Noise_2D_TexelSize.xy, 0).x;
  const float dither_seed = frac(raw_noise_sample + frame * PHI);
#elif 1
  const float dither_seed = frac(ign_anim(screen_uv_round, frame, /*speed=*/0.000) + frame * 1.618033989);
#else
  const float dither_seed = rand2(float2(screen_uv_round.x, screen_uv_round.y)*.001);
#endif
  float dither = dither_seed * step_size * _Gimmick_Fog_00_Ray_Origin_Randomization;
  ro += rd * (_Gimmick_Fog_00_Initial_Offset + dither);

  const float depth_hit_l = length(obj_pos_depth_hit - ro);

  // Get common lighting data
  UnityLight direct_light;
  UnityIndirect indirect_light;
  direct_light.dir = getDirectLightDirection(i);
  direct_light.ndotl = 0;  // Not used
  direct_light.color = getDirectLightColor() *_Direct_Lighting_Factor;
  // TODO try per-sample baked lighting
  indirect_light.diffuse = getIndirectDiffuse(i, /*vertex_light_color=*/0) * _Indirect_Diffuse_Lighting_Factor;
  // TODO consider doing specular. At time of writing it seems pointless.
  indirect_light.specular = 0;

  float4 acc = 0;
  uint step_count = floor(min(_Gimmick_Fog_00_Max_Ray, depth_hit_l) / step_size);
  //step_count *= (1 - no_intersection);
#define FOG_MAX_LOOP 20
  step_count = min(step_count, FOG_MAX_LOOP);

#if defined(_GIMMICK_FOG_00_EMITTER_TEXTURE)
  const float3 em_loc = mul(unity_WorldToObject, float4(_Gimmick_Fog_00_Emitter0_Location, 1.0)).xyz;
  const float3 em_normal = normalize(mul(unity_WorldToObject, float4(_Gimmick_Fog_00_Emitter0_Normal, 0.0)).xyz);
  const float3 em_tangent = normalize(mul(unity_WorldToObject, float4(_Gimmick_Fog_00_Emitter0_Tangent, 0.0)).xyz);
  const float3 em_normal_x_tangent = normalize(cross(em_normal, em_tangent));
  const float em_scale_t   = _Gimmick_Fog_00_Emitter0_Scale_T * length(mul(unity_WorldToObject, float4(_Gimmick_Fog_00_Emitter0_Normal, 0.0)));
  const float em_scale_nxt = _Gimmick_Fog_00_Emitter0_Scale_NxT * length(mul(unity_WorldToObject, float4(cross(_Gimmick_Fog_00_Emitter0_Normal, _Gimmick_Fog_00_Emitter0_Tangent), 0.0)));
  const float2 em_scale = float2(em_scale_t, em_scale_nxt);
  const float2 em_scale_rcp = rcp(em_scale);
#endif

  const float3 ro_world = mul(unity_ObjectToWorld, float4(ro, 1.0)).xyz;
  const float3 rd_world = mul(unity_ObjectToWorld, float4(rd, 0.0)).xyz;
  const float3 rd_world_normalized = normalize(rd_world);
  const float step_size_world = step_size * length(rd_world);
  const float3 view_dir_world = normalize(_WorldSpaceCameraPos - i.worldPos);

  const float3 noise_scale_rcp = 1.0 / _Gimmick_Fog_00_Noise_Scale;
  uint ii;
  for (ii = 0; ii < step_count; ii++) {
    const float3 p = ro + rd * ii * step_size;

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
      getEmitterData(p, dither, step_size, em_loc, em_normal, em_tangent, em_normal_x_tangent, em_scale,
          em_scale_rcp, direct, diffuse);
    }
    diffuse *= _Gimmick_Fog_00_Emitter_Brightness_Diffuse;
    direct *= _Gimmick_Fog_00_Emitter_Brightness_Direct;
#else
#endif

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
    if (acc.a > _Gimmick_Fog_00_Alpha_Cutoff) {
      break;
    }
#if defined(_GIMMICK_FOG_00_BOUNDARY_SPHERE) || defined(_GIMMICK_FOG_00_BOUNDARY_CYLINDER)
    if (dot(p.xz, p.xz) > _Gimmick_Fog_00_Radius * _Gimmick_Fog_00_Radius) {
      break;
    }
#endif
#endif
  }
  if (acc.a > _Gimmick_Fog_00_Alpha_Cutoff || ii == FOG_MAX_LOOP) {
    acc /= acc.a;
  }
  acc.rgb = LRGBtoOKLAB(acc.rgb);
  acc.x = smooth_min(acc.x, _Gimmick_Fog_00_Max_Brightness * .85, _Gimmick_Fog_00_Max_Brightness);
  acc.rgb = OKLABtoLRGB(acc.rgb);

  Fog00PBR pbr;
  pbr.albedo = acc;
  pbr.albedo.a = smooth_min(pbr.albedo.a, .999, 1);

  // Add some dithering to lit color to break up banding
  //const float frame = ((float) AudioLinkData(ALPASS_GENERALVU + int2(1, 0)).x);
  //pbr.albedo.rgb += ign_anim(dither * 1000, frame, /*speed=*/1.0) * .00390625;

  // Remap onto [0, 1]
  pbr.albedo.rgb = aces_filmic(pbr.albedo.rgb);
  // Clamp so max brightness is comfortable. Do it in perceptually uniform
  // space to avoid affecting saturation.
  //pbr.albedo.rgb = LRGBtoOKLAB(pbr.albedo.rgb);
  //pbr.albedo.x = smooth_min(pbr.albedo.x, _Gimmick_Fog_00_Max_Brightness * .9, _Gimmick_Fog_00_Max_Brightness);
  //pbr.albedo.rgb = OKLABtoLRGB(pbr.albedo.rgb);

  float4 clip_pos = mul(UNITY_MATRIX_VP, float4(mul(unity_ObjectToWorld, float4(ro, 1.0))));
  pbr.depth = clip_pos.z / clip_pos.w;

#if 0
  //pbr.albedo.rgb = eye_depth_world / 100;
  pbr.albedo.rgb = dither_seed;
  pbr.albedo.a = 1;
#endif

  return pbr;
}

#endif  // _GIMMICK_FOG_00

#if defined(_GIMMICK_FOG_01) || defined(_GIMMICK_DS2)

struct Fog01PBR {
  float4 albedo;
  float depth;
};

float4 apply_fog(
    float t,
    float density,
    float3 rd,
    float3 sun_dir,
    float4 sun_color,
    float sun_exponent,
    float sun_color_2_enable,
    float4 sun_color_2,
    float sun_exponent_2,
    float4 fog_color) {
  float fog_amount = 1 - exp(-t * density);
  float4 color = fog_color;
  float ndotl = dot(rd, sun_dir);
  // Wrap ndotl
  ndotl = (ndotl + 1) / (2);
  ndotl *= ndotl;
  ndotl = max(ndotl, 0);
  [branch]
  if (sun_color_2_enable) {
    float sun_amount_2 = saturate(pow(ndotl, sun_exponent_2) * fog_amount);
    color = lerp(color, sun_color_2, sun_amount_2);
  }
  float sun_amount = saturate(pow(ndotl, sun_exponent) * fog_amount);
  color = lerp(color, sun_color, sun_amount);
  //return float4(color.rgb, fog_amount * color.a);
  return float4(color.rgb, fog_amount * color.a);
}

Fog01PBR getFog01(v2f i, ToonerData tdata) {
  float3 cam_pos = _WorldSpaceCameraPos;
  float3 obj_pos = i.worldPos;

  if (_Gimmick_Fog_01_Distance_Culling_Enable) {
    float3 activation_center = _Gimmick_Fog_01_Activation_Center;
    float activation_radius = _Gimmick_Fog_01_Activation_Radius;
    float cur_radius = length(_WorldSpaceCameraPos - activation_center);
    [branch]
    if (getCenterCamPos().y > activation_center.y + activation_radius) {
      return (Fog01PBR)0;
    }
  }

  float3 world_pos_depth_hit;
  float2 screen_uv;
  float eye_depth_world;
  {
    float3 full_vec_eye_to_geometry = i.worldPos - _WorldSpaceCameraPos;
    float3 world_dir = normalize(i.worldPos - _WorldSpaceCameraPos);
    float perspective_divide = 1.0 / i.pos.w;
    float perspective_factor = length(full_vec_eye_to_geometry * perspective_divide);
    screen_uv = i.screenPos.xy * perspective_divide;
    eye_depth_world =
      GetLinearZFromZDepth_WorksWithMirrors(
          SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, tdata.screen_uv),
          screen_uv) * perspective_factor;
    world_pos_depth_hit = _WorldSpaceCameraPos + eye_depth_world * world_dir;
  }

  const float3 rd = normalize(obj_pos - cam_pos);
  float3 ro = cam_pos + rd * 1E-5;

  Fog01PBR pbr;
  pbr.albedo = apply_fog(eye_depth_world,
      _Gimmick_Fog_01_Density, rd,
      normalize(_Gimmick_Fog_01_Sun_Direction),
      _Gimmick_Fog_01_Sun_Color,
      _Gimmick_Fog_01_Sun_Exponent,
      _Gimmick_Fog_01_Sun_Color_2_Enable,
      _Gimmick_Fog_01_Sun_Color_2,
      _Gimmick_Fog_01_Sun_Exponent_2,
      _Gimmick_Fog_01_Color);
  pbr.albedo.rgb = aces_filmic(pbr.albedo.rgb);

  //pbr.albedo.rgb = eye_depth_world / 100000;
  //pbr.albedo.a = 1;

  float4 clip_pos = mul(UNITY_MATRIX_VP, float4(ro, 1));
  pbr.depth = clip_pos.z / clip_pos.w;

  return pbr;
}

#endif  // _GIMMICK_FOG_01

#endif  // __FOG_INC

