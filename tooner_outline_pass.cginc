#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"

#include "audiolink.cginc"
#include "clones.cginc"
#include "cnlohr.cginc"
#include "gerstner.cginc"
#include "globals.cginc"
#include "interpolators.cginc"
#include "math.cginc"
#include "pbr.cginc"
#include "oklab.cginc"
#include "trochoid_math.cginc"
#include "tooner_scroll.cginc"
#include "UnityCG.cginc"

#ifndef __TOONER_OUTLINE_PASS
#define __TOONER_OUTLINE_PASS

#define _OUTLINE_INTERPOLATORS

v2f vert(appdata v)
{
#if defined(_DISCARD)
  if (_Discard_Enable_Dynamic) {
    return (v2f) (0.0 / 0.0);
  }
#endif
  v2f o;

  UNITY_INITIALIZE_OUTPUT(v2f, o);
  UNITY_SETUP_INSTANCE_ID(v);
  UNITY_TRANSFER_INSTANCE_ID(v, o);
  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

#if defined(_TROCHOID)
  {
    v.vertex.xyz = cyl2_to_troch_map(cyl_to_cyl2_map(cart_to_cyl_map(v.vertex.xyz)));
  }
#endif

  float4 objPos = v.vertex;

#if defined(_OUTLINES)
#if !defined(_SCROLL) && defined(_GIMMICK_GERSTNER_WATER)
  {
    GerstnerParams p = getGerstnerParams();
    objPos.xyz = gerstner_vert(objPos.xyz, p);
    GerstnerFragResult r = gerstner_frag(objPos.xyz, p);
    v.normal = r.normal;
  }
#endif
#endif

#if defined(_OUTLINES)
  float outline_mask = _Outline_Mask.SampleLevel(linear_repeat_s, v.uv0.xy, /*lod=*/0);
  outline_mask = _Outline_Mask_Invert > 1E-9 ? 1 - outline_mask : outline_mask;

  objPos.xyz += v.normal * _Outline_Width * outline_mask * _Outline_Width_Multiplier;
#endif

#if defined(_FACE_ME_WORLD_Y)
  [branch]
  if (_FaceMeWorldY_Enable_Dynamic) {
    float3 object_center = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
    // Get forward axis of object coordinate system, i.e. the orientation of
    // the hip bone.
    // Then project it onto the xz plane.
    float3 forward_axis = mul(unity_ObjectToWorld, float3(0, 0, 1));
    forward_axis.y = 0;
    forward_axis = normalize(forward_axis);
    float4 worldPos = mul(unity_ObjectToWorld, objPos);
    float3 rd = normalize((worldPos.xyz - object_center) - getCenterCamPos());
    // We apply a factor of -1 to shift the result forward by a phase shift of pi.
    float cos_t = -dot(normalize(rd.xz), forward_axis.xz);
    // We want to get sin(t) using the identity:
    //   || a x b || = || a || || b || sin(t)
    // For normal vectors, this simplifies to:
    //   || a x b || = sin(t)
    // The issue is that the norm operator loses the sign.
    // We can estimate the sign by assuming that `rd` and `forward_axis` are on
    // the xz plane.
    // If that's the case, then the cross product is necessarily constrained to
    // the y axis.
    float sin_t_sign = sign(cross(rd, forward_axis).y);
    // Here we use the identity:
    //   sin(t) = sqrt(1 - cos(t)^2)
    // We simply apply the sign correction `sin_t_sign` to the result.
    // We then invert it, since the goal is not to amplify the rotation, but
    // to negate it.
    // Finally, we add a phase correction to make the abomination face us.
    float sin_t = -sqrt(1 - cos_t * cos_t) * sin_t_sign;
    float2x2 face_me_rot = float2x2(cos_t, -sin_t, sin_t, cos_t);
    float2x2 face_me_rot_inv = float2x2(cos_t, sin_t, -sin_t, cos_t);
    worldPos.xz = mul(face_me_rot, (worldPos.xz - object_center.xz)) + object_center.xz;
    objPos = mul(unity_WorldToObject, worldPos);
    float3 world_normal = UnityObjectToWorldNormal(v.normal);
    world_normal.xz = mul(face_me_rot_inv, world_normal.xz);
    v.normal = normalize(mul(unity_WorldToObject, world_normal));
  }
#endif

#if !defined(_SCROLL) && defined(_GIMMICK_SPHERIZE_LOCATION)
  if (_Gimmick_Spherize_Location_Enable_Dynamic) {
    float r = _Gimmick_Spherize_Location_Radius;
    float s = _Gimmick_Spherize_Location_Strength;
    float l = length(objPos.xyz);
    objPos.xyz *= lerp(1, (r / l), s);
  }
#endif
#if !defined(_SCROLL) && defined(_GIMMICK_SHEAR_LOCATION)
  if (_Gimmick_Shear_Location_Enable_Dynamic) {
     objPos = mul(float4x4(
        _Gimmick_Shear_Location_Strength.x, 0, 0, 0,
        0, _Gimmick_Shear_Location_Strength.y, 0, 0,
        0, 0, _Gimmick_Shear_Location_Strength.z, 0,
        0, 0, 0, _Gimmick_Shear_Location_Strength.w),
        objPos);
  }
#endif

  o.worldPos = mul(unity_ObjectToWorld, objPos);
  o.objPos = objPos;
  o.pos = UnityObjectToClipPos(objPos);
  o.normal = UnityObjectToWorldNormal(v.normal);
  o.uv0 = v.uv0;
#if !defined(_OPTIMIZE_INTERPOLATORS)
  o.uv1 = v.uv1;
#if defined(LIGHTMAP_ON)
  o.uv2 = v.uv2 * unity_LightmapST.xy + unity_LightmapST.zw;
  UNITY_TRANSFER_LIGHTING(o, v.uv1);
#else
  o.uv2 = v.uv2;
  o.uv3 = v.uv3;
  o.uv4 = v.uv4;
  o.uv5 = v.uv5;
  o.uv6 = v.uv6;
  o.uv7 = v.uv7;
#endif
#endif  // _OPTIMIZE_INTERPOLATORS

  o.centerCamPos = getCenterCamPos();
  return o;
}

// maxvertexcount == the number of vertices we create
#if defined(_CLONES)
[maxvertexcount(15)]
#else
[maxvertexcount(3)]
#endif
void geom(triangle v2f tri_in[3],
  uint pid: SV_PrimitiveID,
  inout TriangleStream<v2f> tri_out)
{
  v2f v0 = tri_in[0];
  v2f v1 = tri_in[1];
  v2f v2 = tri_in[2];

  float3 v0_objPos;
  float3 v1_objPos;
  float3 v2_objPos;

  const float pid_rand = rand((int) pid);
  float explode_phase = 0;
#if defined(_EXPLODE)
  float3 n = normalize(cross(v1.worldPos - v0.worldPos, v2.worldPos - v0.worldPos));
  float3 avg_pos;

  float3 n0 = v0.normal;
  float3 n1 = v1.normal;
  float3 n2 = v2.normal;

  explode_phase = _Explode_Phase;
  explode_phase = smoothstep(0, 1, explode_phase);
  explode_phase *= explode_phase;
  explode_phase *= 4;

  if (explode_phase > 1E-6) {
    float3 axis = normalize(float3(
          rand((int) ((v0.uv0.x + v0.uv0.y) * 1E9)) * 2 - 1,
          rand((int) ((v1.uv0.x + v1.uv0.y) * 1E9)) * 2 - 1,
          rand((int) ((v2.uv0.x + v2.uv0.y) * 1E9)) * 2 - 1));
    float3 np = BlendNormals(n, axis * explode_phase);

    v0.worldPos += np * explode_phase * pid_rand;
    v1.worldPos += np * explode_phase * pid_rand;
    v2.worldPos += np * explode_phase * pid_rand;

    v0_objPos = mul(unity_WorldToObject, float4(v0.worldPos, 1));
    v1_objPos = mul(unity_WorldToObject, float4(v1.worldPos, 1));
    v2_objPos = mul(unity_WorldToObject, float4(v2.worldPos, 1));

    float chrono = 0;
#if defined(_AUDIOLINK)
    if (AudioLinkIsAvailable()) {
      chrono = (AudioLinkDecodeDataAsUInt( ALPASS_CHRONOTENSITY  + uint2( 2, 1 ) ) % 1000000) / 1000000.0;
    }
#endif
    v0.worldPos += n * explode_phase * sin(_Time[2] + length(v0_objPos)*6 + chrono) * .01 + chrono * n * explode_phase * .2;
    v1.worldPos += n * explode_phase * sin(_Time[2] + length(v1_objPos)*6 + chrono) * .01 + chrono * n * explode_phase * .2;
    v2.worldPos += n * explode_phase * sin(_Time[2] + length(v2_objPos)*6 + chrono) * .01 + chrono * n * explode_phase * .2;

    avg_pos = (v0.worldPos + v1.worldPos + v2.worldPos) / 3;
    v0.worldPos -= avg_pos;
    v1.worldPos -= avg_pos;
    v2.worldPos -= avg_pos;

    float theta = explode_phase * 3.14159 * 4 + explode_phase * (sin(_Time[1] * (1 + pid_rand) / 2.0 + pid_rand) + cos(_Time[1] * (1 + pid_rand) / 6.1 + pid_rand) * 2) * pid_rand * 2;
    float4 quat = get_quaternion(axis, theta);
    v0.worldPos = rotate_vector(v0.worldPos, quat);
    v1.worldPos = rotate_vector(v1.worldPos, quat);
    v2.worldPos = rotate_vector(v2.worldPos, quat);

    v0.worldPos += avg_pos;
    v1.worldPos += avg_pos;
    v2.worldPos += avg_pos;

    n = normalize(cross(v1.worldPos - v0.worldPos, v2.worldPos - v0.worldPos));
    v0.normal = n;
    v1.normal = n;
    v2.normal = n;

    // Omit geometry that's too close when exploded.
    /*
    if (_Explode_Phase > .05 && length(v0.worldPos - _WorldSpaceCameraPos) < .2) {
      return;
    }
    */

    v0_objPos = mul(unity_WorldToObject, float4(v0.worldPos, 1));
    v1_objPos = mul(unity_WorldToObject, float4(v1.worldPos, 1));
    v2_objPos = mul(unity_WorldToObject, float4(v2.worldPos, 1));

    // Apply transformed worldPos to other coordinate systems.
    if (_Explode_Phase > 1E-6) {
      v0.pos = UnityObjectToClipPos(v0_objPos);
      v1.pos = UnityObjectToClipPos(v1_objPos);
      v2.pos = UnityObjectToClipPos(v2_objPos);
    }
  }
#endif  // __EXPLODE
#if defined(_SCROLL)
  {
    float3 n = normalize(cross(v1.worldPos - v0.worldPos, v2.worldPos - v0.worldPos));
    float3 avg_pos = (v0.worldPos + v1.worldPos + v2.worldPos) / 3;
    v0.worldPos = applyScroll(v0.worldPos, n, avg_pos);
    v1.worldPos = applyScroll(v1.worldPos, n, avg_pos);
    v2.worldPos = applyScroll(v2.worldPos, n, avg_pos);

    float3 v0_objPos = mul(unity_WorldToObject, float4(v0.worldPos, 1));
    float3 v1_objPos = mul(unity_WorldToObject, float4(v1.worldPos, 1));
    float3 v2_objPos = mul(unity_WorldToObject, float4(v2.worldPos, 1));

#if defined(_GIMMICK_SPHERIZE_LOCATION)
  if (_Gimmick_Spherize_Location_Enable_Dynamic) {
    float r = _Gimmick_Spherize_Location_Radius;
    float s = _Gimmick_Spherize_Location_Strength;
    float l0 = length(v0_objPos);
    float l1 = length(v1_objPos);
    float l2 = length(v2_objPos);
    v0_objPos *= lerp(1, (r / l0), s);
    v1_objPos *= lerp(1, (r / l1), s);
    v2_objPos *= lerp(1, (r / l2), s);
  }
#endif
#if defined(_GIMMICK_SHEAR_LOCATION)
  if (_Gimmick_Shear_Location_Enable_Dynamic) {
    v0_objPos = mul(float3x3(
        _Gimmick_Shear_Location_Strength.x, 0, 0,
        0, _Gimmick_Shear_Location_Strength.y, 0,
        0, 0, _Gimmick_Shear_Location_Strength.z),
        v0_objPos);
    v1_objPos = mul(float3x3(
        _Gimmick_Shear_Location_Strength.x, 0, 0,
        0, _Gimmick_Shear_Location_Strength.y, 0,
        0, 0, _Gimmick_Shear_Location_Strength.z),
        v1_objPos);
    v2_objPos = mul(float3x3(
        _Gimmick_Shear_Location_Strength.x, 0, 0,
        0, _Gimmick_Shear_Location_Strength.y, 0,
        0, 0, _Gimmick_Shear_Location_Strength.z),
        v2_objPos);
  }
#endif
#if defined(_GIMMICK_SHEAR_LOCATION) || defined(_GIMMICK_SPHERIZE_LOCATION)
    v0.worldPos.xyz = mul(unity_ObjectToWorld, v0_objPos);
    v1.worldPos.xyz = mul(unity_ObjectToWorld, v1_objPos);
    v2.worldPos.xyz = mul(unity_ObjectToWorld, v2_objPos);
#endif

    v0.pos = UnityObjectToClipPos(v0_objPos);
    v1.pos = UnityObjectToClipPos(v1_objPos);
    v2.pos = UnityObjectToClipPos(v2_objPos);
  }
#endif
#if defined(_CLONES)
  v2f clone_verts[3] = {v0, v1, v2};
  add_clones(clone_verts, tri_out, pid_rand, explode_phase);
#endif  // _CLONES

  // Output transformed geometry.
  tri_out.Append(v0);
  tri_out.Append(v1);
  tri_out.Append(v2);
  tri_out.RestartStrip();
}

fixed4 frag (v2f i) : SV_Target
{
  ToonerData tdata;
  {
    float3 full_vec_eye_to_geometry = i.worldPos - _WorldSpaceCameraPos;
    float3 world_dir = normalize(i.worldPos - _WorldSpaceCameraPos);
    float perspective_divide = 1.0 / i.pos.w;
    float perspective_factor = length(full_vec_eye_to_geometry * perspective_divide);
    tdata.screen_uv = i.screenPos.xy * perspective_divide;
    tdata.screen_uv_round = floor(tdata.screen_uv * _ScreenParams.xy);
  }

  i.normal = -normalize(i.normal);

#if defined(_OUTLINES)
#if defined(_BASECOLOR_MAP)
  float4 albedo = _MainTex.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
  albedo *= _Color;
#else
  float4 albedo = _Color;
#endif  // _BASECOLOR_MAP

#if defined(_RENDERING_CUTOUT)
  clip(albedo.a - _Alpha_Cutoff);
#endif

  albedo = _Outline_Color;

#if defined(_GIMMICK_AL_CHROMA_00)
  float al_chroma_00_emission = 0;
  if (_Gimmick_AL_Chroma_00_Outline_Pass && AudioLinkIsAvailable()) {
    float3 c = AudioLinkData(ALPASS_CCSTRIP + uint2(0, 0)).rgb;
#if defined(_GIMMICK_AL_CHROMA_00_HUE_SHIFT)
    c = LRGBtoOKLCH(c);
    c[2] += _Gimmick_AL_Chroma_00_Hue_Shift_Theta * 2.0 * 3.14159265;
    c = OKLCHtoLRGB(c);
#endif
    albedo.rgb = lerp(albedo.rgb, c, _Gimmick_AL_Chroma_00_Outline_Blend);
    al_chroma_00_emission = _Gimmick_AL_Chroma_00_Outline_Emission;
  }
#endif

#if defined(_OKLAB)
  // Do hue shift in perceptually uniform color space so it doesn't look like
  // shit.
 float oklab_mask = _OKLAB_Mask.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
 if (oklab_mask > 0.01 &&
     (_OKLAB_Hue_Shift > 1E-6 ||
      abs(_OKLAB_Chroma_Shift) > 1E-6 ||
      abs(_OKLAB_Lightness_Shift) > 1E-6)) {
   float3 c = albedo.rgb;
   c = LRGBtoOKLCH(c);
   c.x += _OKLAB_Lightness_Shift;
   c.y += _OKLAB_Chroma_Shift;
   c.z += _OKLAB_Hue_Shift;
   c = OKLCHtoLRGB(c);
   albedo.rgb = c;
 }
#endif

  float4 vertex_light_color = 0;
  float ao = 1;
  float4 result = getLitColor(
      vertex_light_color,
      albedo, i.worldPos, i.normal,
      /*metallic=*/0, /*smoothness=*/0,
      i.uv0, ao, /*enable_direct=*/false,
      /*diffuse_contrib=*/0, i, tdata);

  result += albedo * _Outline_Emission_Strength;
#if defined(_GIMMICK_AL_CHROMA_00)
  result += albedo * al_chroma_00_emission;
#endif

#if defined(_EXPLODE) && defined(_AUDIOLINK)
  if (AudioLinkIsAvailable() && _Explode_Phase > 1E-6) {
    float4 al_color =
      AudioLinkData(
          ALPASS_CCLIGHTS +
          uint2(uint(i.uv0.x * 8) + uint(i.uv0.y * 16) * 8, 0 )).rgba;
    result = lerp(result, al_color, _Explode_Phase * _Explode_Phase);
  }
#endif

  return result;
#else
  discard;
  return 0;
#endif  // _OUTLINES
}

#endif  // __TOONER_OUTLINE_PASS

