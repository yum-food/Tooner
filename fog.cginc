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
};

#define FOG_MAX_RAY 10
#define FOG_RADIUS 25
#define FOG_NOISE_SCALE 2
float map(float3 p) {
  float density = 0;
  float t = _Time[1];
  density += perlin_noise_3d(p * FOG_NOISE_SCALE * 1.0 + t) * saturate(FOG_RADIUS - length(p)) / 2.0;
  density += perlin_noise_3d(p * FOG_NOISE_SCALE * 1.7 + t) * saturate(FOG_RADIUS - length(p)) / 4.0;
  density += perlin_noise_3d(p * FOG_NOISE_SCALE * 2.9 + t) * saturate(FOG_RADIUS - length(p)) / 8.0;
  density += perlin_noise_3d(p * FOG_NOISE_SCALE * 4.3 + t) * saturate(FOG_RADIUS - length(p)) / 16.0;

  return density;
}

float3 get_normal(float3 p) {
  float3 e = float3(0.01, 0, 0);
  return normalize(float3(
      map(p + e.xyz) - map(p),
      map(p + e.yxz) - map(p),
      map(p + e.zyx) - map(p)));
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
  if (length(ro) > FOG_RADIUS) {
    float3 l = ro;
    float a = 1;
    float b = 2 * dot(rd, l);
    float c = dot(l, l) - FOG_RADIUS * FOG_RADIUS;
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
  float dither = rand2(screen_uv*10) - 0.5;
  ro += rd * (1.0 + dither);

  float world_pos_depth_hit_l = length(world_pos_depth_hit - ro);

  float4 acc = 0;
  float step_size = 0.5;
  uint step_count = floor(min(
        FOG_MAX_RAY / step_size,
        world_pos_depth_hit_l / step_size));
  step_count *= (1 - no_intersection);
  float density = 0.5;

  float3 normal_weighted_sum = 0;
  for (uint ii = 0; ii < step_count; ii++) {
    float3 p = ro + (rd * step_size) * ii;
    float4 c = float4(1, 1, 1, map(p));
#if 1
    float3 n = get_normal(p);
    normal_weighted_sum += n * c.a;
#endif
    c *= density;
    acc += c * (1.0 - acc.a);
  }

  Fog00PBR pbr;
  pbr.albedo = saturate(acc);
  pbr.albedo.rgb = saturate(pow(pbr.albedo.rgb, 3.0) * 5);

#if 0
  pbr.normal = normalize(normal_weighted_sum);
#else
  pbr.normal = i.normal;
#endif

  float4 clip_pos = mul(UNITY_MATRIX_VP, float4(ro, 1.0));
  pbr.depth = clip_pos.z / clip_pos.w;

  return pbr;
}

#endif  // _GIMMICK_FOG_00

#endif  // __FOG_INC

