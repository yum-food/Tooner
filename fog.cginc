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
  float depth;
  float ao;
};

float map(float3 p) {
  float density = 0;
  float t = _Time[1] * 0.5;
  float radius = saturate(_Gimmick_Fog_00_Radius - length(p));
  float tmp;
  tmp = perlin_noise_3d(p * _Gimmick_Fog_00_Noise_Scale * 3.1 + t) * radius * 0.5;
  density += tmp;
  tmp = perlin_noise_3d(p * _Gimmick_Fog_00_Noise_Scale * 1.7 + t) * radius * 0.5;
  density *= 0.5;
  density += tmp;
  tmp = perlin_noise_3d(p * _Gimmick_Fog_00_Noise_Scale * 1.0 + t) * radius * 0.5;
  density *= 0.5;
  density += tmp;

  density = pow(density, _Gimmick_Fog_00_Noise_Exponent);

  // Note: this term annihilates performance by creating large open areas. Long
  // avgerage view ray = bad perf!
  #if 1
  tmp = perlin_noise_3d(p * _Gimmick_Fog_00_Noise_Scale * 0.167 + t/4) * radius - 0.5;
  tmp *= 0.2;
  density += tmp;
  #endif

  return saturate(density);
}

float3 get_normal(float3 p, float map_p) {
  float3 e = float3(0.001, 0, 0);
  float center = map_p;

  // Prevent NaN
  float e2 = 1E-9;
  return normalize(float3(
      map(p + e.xyz) - center,
      map(p + e.yxz) - center,
      map(p + e.zyx) - center) + e2);
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
  float dither = rand2(screen_uv*10) * _Gimmick_Fog_00_Step_Size * _Gimmick_Fog_00_Ray_Origin_Randomization;
  ro += rd * (0.1 + dither);

  float world_pos_depth_hit_l = length(world_pos_depth_hit - ro);

  float4 acc = 0;
  uint step_count = floor(min(
        _Gimmick_Fog_00_Max_Ray / _Gimmick_Fog_00_Step_Size,
        world_pos_depth_hit_l / _Gimmick_Fog_00_Step_Size));
  step_count *= (1 - no_intersection);

  float3 normal = i.normal;
  float ao = 0;
  for (uint ii = 0; ii < step_count; ii++) {
    float3 p = ro + (rd * _Gimmick_Fog_00_Step_Size) * ii;

    float col_gray = 0.3;
    const float map_p = map(p);
    float4 c = float4(col_gray, col_gray, col_gray, map_p);
    c.a = saturate(c.a * _Gimmick_Fog_00_Density * _Gimmick_Fog_00_Step_Size);

#if defined(_GIMMICK_FOG_00_EMITTER_TEXTURE)
    // Project onto plane
    float3 p_to_emitter = p - _Gimmick_Fog_00_Emitter_Location;
    float3 emitter_normal = normalize(_Gimmick_Fog_00_Emitter_Normal);
    float2 emitter_scale = float2(_Gimmick_Fog_00_Emitter_Scale_X, _Gimmick_Fog_00_Emitter_Scale_Y);

    float t = dot(p_to_emitter, emitter_normal);
    float3 p_projected = p - t * emitter_normal;

    p_projected -= _Gimmick_Fog_00_Emitter_Location;
    bool in_range = (abs(p_projected.x) < emitter_scale.x) * (abs(p_projected.y) < emitter_scale.y) * (t > 0);

    float2 emitter_uv = clamp(p_projected.xy, -emitter_scale, emitter_scale) / emitter_scale;
    emitter_uv /= 2.0;
    emitter_uv += 0.5;
    float3 emitter_color = _Gimmick_Fog_00_Emitter_Texture.SampleLevel(linear_repeat_s, emitter_uv, 0);
    emitter_color *= _Gimmick_Fog_00_Emitter_Brightness;
    float emitter_dist = in_range ? abs(t) : 1000;
    // Inverse square is physically accurate, but this looks better.
    float emitter_falloff = min(1, rcp(pow(emitter_dist, 1.0)));
#if 1
    c.rgb = lerp(c.rgb, emitter_color, in_range * emitter_falloff);
#else
    c.rgb = emitter_color;
#endif
#endif

    acc += c * (1.0 - acc.a);

    const float ao_str = 0.3;
    float cur_ao = saturate(length(ro) / _Gimmick_Fog_00_Radius) * ao_str + (1.0 - ao_str);
    ao = cur_ao * (1.0 - acc.a) + acc.a * ao;

    // Performance hack: stop blending normals after enough accumulation.
    if (acc.a < _Gimmick_Fog_00_Normal_Cutoff) {
      float3 n = get_normal(p, map_p);
      float n_interp = saturate(c.a * (1.0 - acc.a) * rcp(_Gimmick_Fog_00_Normal_Cutoff));
      normal = MY_BLEND_NORMALS(normal, n, n_interp);
    }
    if (acc.a > _Gimmick_Fog_00_Albedo_Cutoff) {
      acc /= acc.a;
      break;
    }
    // Performance hack: stop iterating if we go outside of the sphere.
    if (dot(p, p) > _Gimmick_Fog_00_Radius * _Gimmick_Fog_00_Radius) {
      break;
    }
  }

  Fog00PBR pbr;
  pbr.albedo.rgb = acc.rgb;
  pbr.albedo.a = saturate(acc.a);
  pbr.ao = ao;

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

