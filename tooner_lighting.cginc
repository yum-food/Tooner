#ifndef TOONER_LIGHTING
#define TOONER_LIGHTING

#include "UnityCG.cginc"

#include "audiolink.cginc"
#include "clones.cginc"
#include "eyes.cginc"
#include "globals.cginc"
#include "interpolators.cginc"
#include "iq_sdf.cginc"
#include "math.cginc"
#include "motion.cginc"
#include "pbr.cginc"
#include "poi.cginc"
#include "rorschach.cginc"
#include "shear_math.cginc"
#include "tooner_scroll.cginc"
#include "trochoid_math.cginc"
#include "oklab.cginc"

// Hacky parameterizable whiteout blending. Probably some big mistakes but it
// passes the eyeball test.
// At w=0.5, this looks kinda like whiteout blending.
// At w=0, this returns n0.
// At w=1, this returns n1.
#define MY_BLEND_NORMALS(n0, n1, w) normalize(float3((n0.xy * (1 - w) + n1.xy * w), lerp(1, n0.z, (1-w)) * lerp(1, n1.z, w)))

void getVertexLightColor(inout v2f i)
{
  #if defined(VERTEXLIGHT_ON)
  float3 view_dir = normalize(_WorldSpaceCameraPos - i.worldPos);
  uint normals_mode = round(_Mesh_Normals_Mode);
  bool flat = (normals_mode == 0);
  float3 flat_normal = normalize(
    (1.0 / _Flatten_Mesh_Normals_Str) * i.normal +
    _Flatten_Mesh_Normals_Str * view_dir);
  i.vertexLightColor = Shade4PointLights(
    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
    unity_LightColor[0].rgb,
    unity_LightColor[1].rgb,
    unity_LightColor[2].rgb,
    unity_LightColor[3].rgb,
    unity_4LightAtten0, i.worldPos, flat ? flat_normal : i.normal
  );
  #endif
}

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

#if defined(_GIMMICK_QUANTIZE_LOCATION)
  if (_Gimmick_Quantize_Location_Enable_Dynamic) {
    float q = _Gimmick_Quantize_Location_Precision /
      _Gimmick_Quantize_Location_Multiplier;
#if defined(_GIMMICK_QUANTIZE_LOCATION_AUDIOLINK)
    // christ what a fucking variable name
    if (_Gimmick_Quantize_Location_Audiolink_Enable_Dynamic &&
        AudioLinkIsAvailable()) {
      // x is lowest frequency, w is highest
      float4 bands = AudioLinkData(ALPASS_AUDIOLINK).xyzw;

      float e = q *= 1 + (bands.x + bands.y * 0.5) *
        _Gimmick_Quantize_Location_Audiolink_Strength * 0.1;
    }
#endif
    float3 v_new0 = floor(v.vertex * q) / q;
    float3 d = v_new0 - v.vertex;
    float3 v_new1 = v.vertex - d;
    bool flip_dir = (sign(dot(d, v.normal)) !=
        sign(_Gimmick_Quantize_Location_Direction));
    float3 v_q = lerp(v_new0, v_new1, flip_dir);
    float mask = _Gimmick_Quantize_Location_Mask.SampleLevel(linear_repeat_s,
        v.uv0.xy, /*lod=*/0);
    v.vertex.xyz = lerp(v.vertex.xyz, v_q, mask);
  }
#endif

#if defined(_TROCHOID)
  {
#define PI 3.14159265
#define TAU PI * 2.0
    float theta = v.uv0.x * TAU;
    float r0 = length(v.vertex.xyz);
    v.vertex.xyz = trochoid_map(theta, r0, v.vertex.z);
  }
#endif
#if defined(_FACE_ME_WORLD_Y)
  if (_FaceMeWorldY_Enable_Dynamic) {
    // Undo object coordinate system rotation.
    float3x3 rotation = float3x3(
        normalize(unity_ObjectToWorld._m00_m10_m20),
        normalize(unity_ObjectToWorld._m01_m11_m21),
        normalize(unity_ObjectToWorld._m02_m12_m22));
    rotation = transpose(rotation);
    float3 unrotated = mul(transpose(rotation),
        v.vertex.xyz);
    float4 pos = mul(unity_ObjectToWorld,
        float4(unrotated, v.vertex.w));
    float3 unrotated_n = mul(transpose(rotation),
        v.normal);
    float3 n = UnityObjectToWorldNormal(unrotated_n);

    float3 origin = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;
    float3 view_dir = _WorldSpaceCameraPos - origin;
    // Project onto xz plane
    n.y = 0;
    view_dir.y = 0;
    // Normalize
    n = normalize(n);
    view_dir = normalize(view_dir);
    // Calculate angles and rotate
    float ct = dot(view_dir, n);
    float3 n_cross_v = cross(view_dir, n);
    float st = length(n_cross_v);
    st *= sign(n_cross_v.y);
    float2x2 rot = float2x2(
        ct, -st,
        st, ct);
    pos.xz = mul(rot, pos.xz - origin.xz) + origin.xz;

    v.vertex = mul(unity_WorldToObject, pos);
    o.normal = view_dir;
  }
#endif

#if !defined(_SCROLL) && defined(_GIMMICK_SPHERIZE_LOCATION)
  if (_Gimmick_Spherize_Location_Enable_Dynamic) {
    float3 p = v.vertex.xyz;
    float r = _Gimmick_Spherize_Location_Radius;
    float s = _Gimmick_Spherize_Location_Strength;
    float l = length(p);
    p *= lerp(1, (r / l), s);
    v.vertex.xyz = p;
  }
#endif
#if !defined(_SCROLL) && defined(_GIMMICK_SHEAR_LOCATION)
  if (_Gimmick_Shear_Location_Enable_Dynamic) {
    float3 p = v.vertex.xyz;
    float3 sc = _Gimmick_Shear_Location_Strength.xyz;
    float3x3 shear_matrix = float3x3(
          sc.x, 0, 0,
          0, sc.y, 0,
          0, 0, sc.z);
    p = mul(shear_matrix, p);
    v.vertex.xyz = p;
  }
#endif

  o.pos = UnityObjectToClipPos(v.vertex);
  o.worldPos = mul(unity_ObjectToWorld, v.vertex);
  o.objPos = v.vertex;

#if defined(SSR_ENABLED)
  o.screenPos = ComputeGrabScreenPos(o.pos);
#endif

#if defined(_FACE_ME_WORLD_Y)
  if (!_FaceMeWorldY_Enable_Dynamic) {
    o.normal = UnityObjectToWorldNormal(v.normal);
  }
#else
  o.normal = UnityObjectToWorldNormal(v.normal);
#endif

  o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
  o.uv0 = v.uv0;
  o.uv1 = v.uv1;
  o.uv2 = v.uv2;
  o.uv3 = v.uv3;
  o.uv4 = v.uv4;
  o.uv5 = v.uv5;
  o.uv6 = v.uv6;
  o.uv7 = v.uv7;
#if defined(LIGHTMAP_ON)
  o.lmuv = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
#if defined(SHADOWS_SCREEN)
  TRANSFER_SHADOW(o);
#endif

  getVertexLightColor(o);

  return o;
}

// maxvertexcount == the number of vertices we create
#if defined(_CLONES)
[maxvertexcount(45)]
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

#if defined(_EXPLODE)
  float3 n = normalize(cross(v1.worldPos - v0.worldPos, v2.worldPos - v0.worldPos));
  float3 avg_pos;

  float3 n0 = v0.normal;
  float3 n1 = v1.normal;
  float3 n2 = v2.normal;

  float phase = _Explode_Phase;
  phase = smoothstep(0, 1, phase);
  phase *= phase;
  phase *= 4;
  const float pid_rand = rand((int) pid);

  if (phase > 1E-6) {
    float3 axis = normalize(float3(
          rand((int) ((v0.uv0.x + v0.uv0.y) * 1E9)) * 2 - 1,
          rand((int) ((v1.uv0.x + v1.uv0.y) * 1E9)) * 2 - 1,
          rand((int) ((v2.uv0.x + v2.uv0.y) * 1E9)) * 2 - 1));
    float3 np = BlendNormals(n, axis * phase);

    v0.worldPos += np * phase * pid_rand;
    v1.worldPos += np * phase * pid_rand;
    v2.worldPos += np * phase * pid_rand;

    v0_objPos = mul(unity_WorldToObject, float4(v0.worldPos, 1));
    v1_objPos = mul(unity_WorldToObject, float4(v1.worldPos, 1));
    v2_objPos = mul(unity_WorldToObject, float4(v2.worldPos, 1));

    float chrono = 0;
#if defined(_AUDIOLINK)
    if (AudioLinkIsAvailable()) {
      chrono = (AudioLinkDecodeDataAsUInt( ALPASS_CHRONOTENSITY  + uint2( 2, 1 ) ) % 1000000) / 1000000.0;
    }
#endif
    v0.worldPos += n * phase * sin(_Time[2] + length(v0_objPos)*6 + chrono) * .01 + chrono * n * phase * .2;
    v1.worldPos += n * phase * sin(_Time[2] + length(v1_objPos)*6 + chrono) * .01 + chrono * n * phase * .2;
    v2.worldPos += n * phase * sin(_Time[2] + length(v2_objPos)*6 + chrono) * .01 + chrono * n * phase * .2;

    avg_pos = (v0.worldPos + v1.worldPos + v2.worldPos) / 3;
    v0.worldPos -= avg_pos;
    v1.worldPos -= avg_pos;
    v2.worldPos -= avg_pos;

    float theta = phase * 3.14159 * 4 + phase * (sin(_Time[1] * (1 + pid_rand) / 2.0 + pid_rand) + cos(_Time[1] * (1 + pid_rand) / 6.1 + pid_rand) * 2) * pid_rand * 2;
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
  add_clones(clone_verts, tri_out);
#endif  // _CLONES

  // Output transformed geometry.
  tri_out.Append(v0);
  tri_out.Append(v1);
  tri_out.Append(v2);
  tri_out.RestartStrip();
}

#if defined(_GLITTER) || defined(_RIM_LIGHTING0_GLITTER) || defined(_RIM_LIGHTING1_GLITTER) || defined(_RIM_LIGHTING2_GLITTER) || defined(_RIM_LIGHTING3_GLITTER)
float get_glitter(float2 uv, float3 worldPos,
    float3 normal, float density, float amount, float speed,
    float mask, float angle, float power)
{
  // A regular divide here causes flickering. The leading guess is that NVIDIA
  // hardware implements the divide instruction slightly differently on
  // different cores.
  precise float idensity = rcp(density);
  float glitter = rand2(floor(uv * density) * idensity);

  float thresh = 1 - amount / 100;
  glitter = lerp(0, glitter, glitter > thresh);
  glitter = (glitter - thresh) / (1 - thresh);

  float b = sin(_Time[2] * speed / 2 + glitter*100);
  b = speed > 1E-6 ? b : 1;
  glitter = max(glitter, 0)*max(b, 0);

  glitter *= mask;

  glitter = clamp(glitter, 0, 1);

  if (angle < 90) {
    float ndotl = abs(dot(normal, normalize(_WorldSpaceCameraPos.xyz - worldPos)));
    float cutoff = cos((angle / 180) * 3.14159);

    glitter *= saturate(pow(ndotl / cutoff, power));
  }

  return glitter;
}
#endif  // _GLITTER

float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) *
		(binormalSign * unity_WorldTransformParams.w);
}

float2 matcap_distortion0(float2 matcap_uv) {
  float3 qvec = float3(matcap_uv * 2 - 1, 0);
  float t = _Time[0];
  float e = .4;
  float3 qaxis = normalize(float3(sin(t * 2.3) * e, sin(t * 2.9) * e * 1.2, 1));
  float qtheta = t;
  float4 quat = get_quaternion(qaxis, qtheta);
  matcap_uv *= ((rotate_vector(qvec, quat) + 1) / 2).xy * 1.3;
  return matcap_uv;
}

float2 get_uv_by_channel(v2f i, uint which_channel) {
  switch (which_channel) {
    case 0:
      return i.uv0;
      break;
    case 1:
      return i.uv1;
      break;
    case 2:
      return i.uv2;
      break;
    case 3:
      return i.uv3;
      break;
    case 4:
      return i.uv4;
      break;
    case 5:
      return i.uv5;
      break;
    case 6:
      return i.uv6;
      break;
    case 7:
      return i.uv7;
      break;
    default:
      return 0;
      break;
  }
}

#define UV_SCOFF(i, tex_st, which_channel) get_uv_by_channel(i, round(which_channel)) * (tex_st).xy + (tex_st).zw

#if defined(_PBR_SAMPLER_REPEAT)
#define GET_SAMPLER_PBR linear_repeat_s
#elif defined(_PBR_SAMPLER_CLAMP)
#define GET_SAMPLER_PBR linear_clamp_s
#endif
#if defined(_PBR_OVERLAY0_SAMPLER_REPEAT)
#define GET_SAMPLER_OV0 linear_repeat_s
#elif defined(_PBR_OVERLAY0_SAMPLER_CLAMP)
#define GET_SAMPLER_OV0 linear_clamp_s
#endif
#if defined(_PBR_OVERLAY1_SAMPLER_REPEAT)
#define GET_SAMPLER_OV1 linear_repeat_s
#elif defined(_PBR_OVERLAY1_SAMPLER_CLAMP)
#define GET_SAMPLER_OV1 linear_clamp_s
#endif
#if defined(_PBR_OVERLAY2_SAMPLER_REPEAT)
#define GET_SAMPLER_OV2 linear_repeat_s
#elif defined(_PBR_OVERLAY2_SAMPLER_CLAMP)
#define GET_SAMPLER_OV2 linear_clamp_s
#endif
#if defined(_PBR_OVERLAY3_SAMPLER_REPEAT)
#define GET_SAMPLER_OV3 linear_repeat_s
#elif defined(_PBR_OVERLAY3_SAMPLER_CLAMP)
#define GET_SAMPLER_OV3 linear_clamp_s
#endif
#if defined(_RIM_LIGHTING0_SAMPLER_REPEAT)
#define GET_SAMPLER_RL0 linear_repeat_s
#elif defined(_RIM_LIGHTING0_SAMPLER_CLAMP)
#define GET_SAMPLER_RL0 linear_clamp_s
#endif
#if defined(_RIM_LIGHTING1_SAMPLER_REPEAT)
#define GET_SAMPLER_RL1 linear_repeat_s
#elif defined(_RIM_LIGHTING1_SAMPLER_CLAMP)
#define GET_SAMPLER_RL1 linear_clamp_s
#endif
#if defined(_RIM_LIGHTING2_SAMPLER_REPEAT)
#define GET_SAMPLER_RL2 linear_repeat_s
#elif defined(_RIM_LIGHTING2_SAMPLER_CLAMP)
#define GET_SAMPLER_RL2 linear_clamp_s
#endif
#if defined(_RIM_LIGHTING3_SAMPLER_REPEAT)
#define GET_SAMPLER_RL3 linear_repeat_s
#elif defined(_RIM_LIGHTING3_SAMPLER_CLAMP)
#define GET_SAMPLER_RL3 linear_clamp_s
#endif

struct PbrOverlay {
#if defined(_PBR_OVERLAY0)
  float4 ov0_albedo;
#if defined(_PBR_OVERLAY0_ROUGHNESS)
  float ov0_roughness;
#endif
#if defined(_PBR_OVERLAY0_METALLIC)
  float ov0_metallic;
#endif
  float ov0_mask;
#endif
#if defined(_PBR_OVERLAY1)
  float4 ov1_albedo;
#if defined(_PBR_OVERLAY1_ROUGHNESS)
  float ov1_roughness;
#endif
#if defined(_PBR_OVERLAY1_METALLIC)
  float ov1_metallic;
#endif
  float ov1_mask;
#endif
#if defined(_PBR_OVERLAY2)
  float4 ov2_albedo;
#if defined(_PBR_OVERLAY2_ROUGHNESS)
  float ov2_roughness;
#endif
#if defined(_PBR_OVERLAY2_METALLIC)
  float ov2_metallic;
#endif
  float ov2_mask;
#endif
#if defined(_PBR_OVERLAY3)
  float4 ov3_albedo;
#if defined(_PBR_OVERLAY3_ROUGHNESS)
  float ov3_roughness;
#endif
#if defined(_PBR_OVERLAY3_METALLIC)
  float ov3_metallic;
#endif
  float ov3_mask;
#endif
};

void getOverlayAlbedoRoughnessMetallic(inout PbrOverlay ov,
    v2f i)
{
#if defined(_PBR_OVERLAY0)
#if defined(_PBR_OVERLAY0_BASECOLOR_MAP)
  ov.ov0_albedo = _PBR_Overlay0_BaseColorTex.SampleBias(GET_SAMPLER_OV0,
      UV_SCOFF(i, _PBR_Overlay0_BaseColorTex_ST, _PBR_Overlay0_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay0_Mip_Bias);
  ov.ov0_albedo *= _PBR_Overlay0_BaseColor;
#else
  ov.ov0_albedo = _PBR_Overlay0_BaseColor;
#endif  // _PBR_OVERLAY0_BASECOLOR_MAP

#if defined(_PBR_OVERLAY0_ROUGHNESS)
#if defined(_PBR_OVERLAY0_ROUGHNESS_MAP)
  ov.ov0_roughness = _PBR_Overlay0_RoughnessTex.SampleBias(GET_SAMPLER_OV0,
      UV_SCOFF(i, _PBR_Overlay0_RoughnessTex_ST, _PBR_Overlay0_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay0_Mip_Bias);
  ov.ov0_roughness *= _PBR_Overlay0_Roughness;
#else
  ov.ov0_roughness = _PBR_Overlay0_Roughness;
#endif  // _PBR_OVERLAY0_ROUGHNESS_MAP
#endif

#if defined(_PBR_OVERLAY0_METALLIC)
#if defined(_PBR_OVERLAY0_METALLIC_MAP)
  ov.ov0_metallic = _PBR_Overlay0_MetallicTex.SampleBias(GET_SAMPLER_OV0,
      UV_SCOFF(i, _PBR_Overlay0_MetallicTex_ST, _PBR_Overlay0_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay0_Mip_Bias);
  ov.ov0_metallic *= _PBR_Overlay0_Metallic;
#else
  ov.ov0_metallic = _PBR_Overlay0_Metallic;
#endif  // _PBR_OVERLAY0_METALLIC_MAP
#endif

#if defined(_PBR_OVERLAY0_MASK)
  ov.ov0_mask = _PBR_Overlay0_Mask.SampleBias(GET_SAMPLER_OV0,
      get_uv_by_channel(i, _PBR_Overlay0_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay0_Mip_Bias);
  ov.ov0_mask = ((bool) round(_PBR_Overlay0_Mask_Invert)) ? 1.0 - ov.ov0_mask : ov.ov0_mask;
#else
  ov.ov0_mask = 1;
#endif
  ov.ov0_albedo.a *= ov.ov0_mask;
#endif  // _PBR_OVERLAY0

#if defined(_PBR_OVERLAY1)
#if defined(_PBR_OVERLAY1_BASECOLOR_MAP)
  ov.ov1_albedo = _PBR_Overlay1_BaseColorTex.SampleBias(GET_SAMPLER_OV1,
      UV_SCOFF(i, _PBR_Overlay1_BaseColorTex_ST, _PBR_Overlay1_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay1_Mip_Bias);
  ov.ov1_albedo *= _PBR_Overlay1_BaseColor;
#else
  ov.ov1_albedo = _PBR_Overlay1_BaseColor;
#endif  // _PBR_OVERLAY1_BASECOLOR_MAP

#if defined(_PBR_OVERLAY1_ROUGHNESS)
#if defined(_PBR_OVERLAY1_ROUGHNESS_MAP)
  ov.ov1_roughness = _PBR_Overlay1_RoughnessTex.SampleBias(GET_SAMPLER_OV1,
      UV_SCOFF(i, _PBR_Overlay1_RoughnessTex_ST, _PBR_Overlay1_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay1_Mip_Bias);
  ov.ov1_roughness *= _PBR_Overlay1_Roughness;
#else
  ov.ov1_roughness = _PBR_Overlay1_Roughness;
#endif  // _PBR_OVERLAY1_ROUGHNESS_MAP
#endif

#if defined(_PBR_OVERLAY1_METALLIC)
#if defined(_PBR_OVERLAY1_METALLIC_MAP)
  ov.ov1_metallic = _PBR_Overlay1_MetallicTex.SampleBias(GET_SAMPLER_OV1,
      UV_SCOFF(i, _PBR_Overlay1_MetallicTex_ST, _PBR_Overlay1_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay1_Mip_Bias);
  ov.ov1_metallic *= _PBR_Overlay1_Metallic;
#else
  ov.ov1_metallic = _PBR_Overlay1_Metallic;
#endif  // _PBR_OVERLAY1_METALLIC_MAP
#endif

#if defined(_PBR_OVERLAY1_MASK)
  ov.ov1_mask = _PBR_Overlay1_Mask.SampleBias(GET_SAMPLER_OV1,
      get_uv_by_channel(i, _PBR_Overlay1_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay1_Mip_Bias);
  ov.ov1_mask = ((bool) round(_PBR_Overlay1_Mask_Invert)) ? 1.0 - ov.ov1_mask : ov.ov1_mask;
#else
  ov.ov1_mask = 1;
#endif
  ov.ov1_albedo.a *= ov.ov1_mask;
#endif  // _PBR_OVERLAY1

#if defined(_PBR_OVERLAY2)
#if defined(_PBR_OVERLAY2_BASECOLOR_MAP)
  ov.ov2_albedo = _PBR_Overlay2_BaseColorTex.SampleBias(GET_SAMPLER_OV2,
      UV_SCOFF(i, _PBR_Overlay2_BaseColorTex_ST, _PBR_Overlay2_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay2_Mip_Bias);
  ov.ov2_albedo *= _PBR_Overlay2_BaseColor;
#else
  ov.ov2_albedo = _PBR_Overlay2_BaseColor;
#endif  // _PBR_OVERLAY2_BASECOLOR_MAP

#if defined(_PBR_OVERLAY2_ROUGHNESS)
#if defined(_PBR_OVERLAY2_ROUGHNESS_MAP)
  ov.ov2_roughness = _PBR_Overlay2_RoughnessTex.SampleBias(GET_SAMPLER_OV2,
      UV_SCOFF(i, _PBR_Overlay2_RoughnessTex_ST, _PBR_Overlay2_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay2_Mip_Bias);
  ov.ov2_roughness *= _PBR_Overlay2_Roughness;
#else
  ov.ov2_roughness = _PBR_Overlay2_Roughness;
#endif  // _PBR_OVERLAY2_ROUGHNESS_MAP
#endif

#if defined(_PBR_OVERLAY2_METALLIC)
#if defined(_PBR_OVERLAY2_METALLIC_MAP)
  ov.ov2_metallic = _PBR_Overlay2_MetallicTex.SampleBias(GET_SAMPLER_OV2,
      UV_SCOFF(i, _PBR_Overlay2_MetallicTex_ST, _PBR_Overlay2_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay2_Mip_Bias);
  ov.ov2_metallic *= _PBR_Overlay2_Metallic;
#else
  ov.ov2_metallic = _PBR_Overlay2_Metallic;
#endif  // _PBR_OVERLAY2_METALLIC_MAP
#endif

#if defined(_PBR_OVERLAY2_MASK)
  ov.ov2_mask = _PBR_Overlay2_Mask.SampleBias(GET_SAMPLER_OV2,
      get_uv_by_channel(i, _PBR_Overlay2_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay2_Mip_Bias);
  ov.ov2_mask = ((bool) round(_PBR_Overlay2_Mask_Invert)) ? 1.0 - ov.ov2_mask : ov.ov2_mask;
#else
  ov.ov2_mask = 1;
#endif
  ov.ov2_albedo.a *= ov.ov2_mask;
#endif  // _PBR_OVERLAY2

#if defined(_PBR_OVERLAY3)
#if defined(_PBR_OVERLAY3_BASECOLOR_MAP)
  ov.ov3_albedo = _PBR_Overlay3_BaseColorTex.SampleBias(GET_SAMPLER_OV3,
      UV_SCOFF(i, _PBR_Overlay3_BaseColorTex_ST, _PBR_Overlay3_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay3_Mip_Bias);
  ov.ov3_albedo *= _PBR_Overlay3_BaseColor;
#else
  ov.ov3_albedo = _PBR_Overlay3_BaseColor;
#endif  // _PBR_OVERLAY3_BASECOLOR_MAP

#if defined(_PBR_OVERLAY3_ROUGHNESS)
#if defined(_PBR_OVERLAY3_ROUGHNESS_MAP)
  ov.ov3_roughness = _PBR_Overlay3_RoughnessTex.SampleBias(GET_SAMPLER_OV3,
      UV_SCOFF(i, _PBR_Overlay3_RoughnessTex_ST, _PBR_Overlay3_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay3_Mip_Bias);
  ov.ov3_roughness *= _PBR_Overlay3_Roughness;
#else
  ov.ov3_roughness = _PBR_Overlay3_Roughness;
#endif  // _PBR_OVERLAY3_ROUGHNESS_MAP
#endif

#if defined(_PBR_OVERLAY3_METALLIC)
#if defined(_PBR_OVERLAY3_METALLIC_MAP)
  ov.ov3_metallic = _PBR_Overlay3_MetallicTex.SampleBias(GET_SAMPLER_OV3,
      UV_SCOFF(i, _PBR_Overlay3_MetallicTex_ST, _PBR_Overlay3_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay3_Mip_Bias);
  ov.ov3_metallic *= _PBR_Overlay3_Metallic;
#else
  ov.ov3_metallic = _PBR_Overlay3_Metallic;
#endif  // _PBR_OVERLAY3_METALLIC_MAP
#endif

#if defined(_PBR_OVERLAY3_MASK)
  ov.ov3_mask = _PBR_Overlay3_Mask.SampleBias(GET_SAMPLER_OV3,
      get_uv_by_channel(i, _PBR_Overlay3_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay3_Mip_Bias);
  ov.ov3_mask = ((bool) round(_PBR_Overlay3_Mask_Invert)) ? 1.0 - ov.ov3_mask : ov.ov3_mask;
#else
  ov.ov3_mask = 1;
#endif
  ov.ov3_albedo.a *= ov.ov3_mask;
#endif  // _PBR_OVERLAY3
}

void applyDecalImpl(
    inout float4 albedo,
    inout float3 decal_emission,
    inout float roughness,
    inout float metallic,
    v2f i,
    texture2D tex,
    float4 tex_st,
    texture2D roughness_tex,
    texture2D metallic_tex,
    float emission_strength,
    float angle,
    bool do_roughness,
    bool do_metallic,
    float which_uv)
{
  float2 d0_uv = ((get_uv_by_channel(i, which_uv) - 0.5) - tex_st.zw) * tex_st.xy + 0.5;

  if (abs(angle) > 1E-6) {
    float theta = angle * 2.0 * 3.14159265;
    float2x2 rot = float2x2(
        cos(theta), -sin(theta),
        sin(theta), cos(theta));
    d0_uv = mul(rot, d0_uv - 0.5) + 0.5;
  }

  float4 d0_c = tex.SampleBias(linear_clamp_s, saturate(d0_uv), _Global_Sample_Bias);

  float d0_in_range = 1;
  d0_in_range *= d0_uv.x > 0;
  d0_in_range *= d0_uv.x < 1;
  d0_in_range *= d0_uv.y > 0;
  d0_in_range *= d0_uv.y < 1;
  d0_c *= d0_in_range;

  albedo.rgb = lerp(albedo.rgb, d0_c.rgb, d0_c.a);
  albedo.a = max(albedo.a, d0_c.a);
  decal_emission += d0_c.rgb * emission_strength;

  if (do_roughness) {
    float4 d0_r = roughness_tex.SampleBias(linear_clamp_s, saturate(d0_uv), _Global_Sample_Bias);
    d0_r *= d0_in_range;
    roughness = lerp(roughness, d0_r, d0_r.a);
  }
  if (do_metallic) {
    float4 d0_m = metallic_tex.SampleBias(linear_clamp_s, saturate(d0_uv), _Global_Sample_Bias);
    d0_m *= d0_in_range;
    metallic = lerp(metallic, d0_m, d0_m.a);
  }
}

void applyDecal(inout float4 albedo,
    inout float roughness,
    inout float metallic,
    inout float3 decal_emission,
    v2f i)
{
#if defined(_DECAL0)
#if defined(_DECAL0_ROUGHNESS)
  bool d0_do_roughness = true;
#else
  bool d0_do_roughness = false;
#endif
#if defined(_DECAL0_METALLIC)
  bool d0_do_metallic = true;
#else
  bool d0_do_metallic = false;
#endif
  applyDecalImpl(albedo, decal_emission, roughness, metallic, i,
      _Decal0_BaseColor,
      _Decal0_BaseColor_ST,
      _Decal0_Roughness,
      _Decal0_Metallic,
      _Decal0_Emission_Strength,
      _Decal0_Angle,
      d0_do_roughness,
      d0_do_metallic,
      _Decal0_UV_Select);
#endif  // _DECAL0
#if defined(_DECAL1)
#if defined(_DECAL1_ROUGHNESS)
  bool d1_do_roughness = true;
#else
  bool d1_do_roughness = false;
#endif
#if defined(_DECAL1_METALLIC)
  bool d1_do_metallic = true;
#else
  bool d1_do_metallic = false;
#endif
  applyDecalImpl(albedo, decal_emission, roughness, metallic, i,
      _Decal1_BaseColor,
      _Decal1_BaseColor_ST,
      _Decal1_Roughness,
      _Decal1_Metallic,
      _Decal1_Emission_Strength,
      _Decal1_Angle,
      d1_do_roughness,
      d1_do_metallic,
      _Decal1_UV_Select);
#endif  // _DECAL1
#if defined(_DECAL2)
#if defined(_DECAL2_ROUGHNESS)
  bool d2_do_roughness = true;
#else
  bool d2_do_roughness = false;
#endif
#if defined(_DECAL2_METALLIC)
  bool d2_do_metallic = true;
#else
  bool d2_do_metallic = false;
#endif
  applyDecalImpl(albedo, decal_emission, roughness, metallic, i,
      _Decal2_BaseColor,
      _Decal2_BaseColor_ST,
      _Decal2_Roughness,
      _Decal2_Metallic,
      _Decal2_Emission_Strength,
      _Decal2_Angle,
      d2_do_roughness,
      d2_do_metallic,
      _Decal2_UV_Select);
#endif  // _DECAL2
#if defined(_DECAL3)
#if defined(_DECAL3_ROUGHNESS)
  bool d3_do_roughness = true;
#else
  bool d3_do_roughness = false;
#endif
#if defined(_DECAL3_METALLIC)
  bool d3_do_metallic = true;
#else
  bool d3_do_metallic = false;
#endif
  applyDecalImpl(albedo, decal_emission, roughness, metallic, i,
      _Decal3_BaseColor,
      _Decal3_BaseColor_ST,
      _Decal3_Roughness,
      _Decal3_Metallic,
      _Decal3_Emission_Strength,
      _Decal3_Angle,
      d3_do_roughness,
      d3_do_metallic,
      _Decal3_UV_Select);
#endif  // _DECAL3
}

void mixOverlayAlbedoRoughnessMetallic(inout float4 albedo,
    inout float roughness, inout float metallic, PbrOverlay ov,
    float mask) {
  // Calculate alpha masks before we start mutating alpha.
#if defined(_PBR_OVERLAY0)
  float a0 = saturate(ov.ov0_albedo.a * _PBR_Overlay0_Alpha_Multiplier);
  if (_PBR_Overlay0_Constrain_By_Alpha) {
    bool in_range = (albedo.a > _PBR_Overlay0_Constrain_By_Alpha_Min) *
      (albedo.a < _PBR_Overlay0_Constrain_By_Alpha_Max);
    a0 *= in_range;
  }
  a0 *= mask;
#endif
#if defined(_PBR_OVERLAY1)
  float a1 = saturate(ov.ov1_albedo.a * _PBR_Overlay1_Alpha_Multiplier);
  if (_PBR_Overlay1_Constrain_By_Alpha) {
    bool in_range = (albedo.a > _PBR_Overlay1_Constrain_By_Alpha_Min) *
      (albedo.a < _PBR_Overlay1_Constrain_By_Alpha_Max);
    a1 *= in_range;
  }
  a1 *= mask;
#endif
#if defined(_PBR_OVERLAY2)
  float a2 = saturate(ov.ov2_albedo.a * _PBR_Overlay2_Alpha_Multiplier);
  if (_PBR_Overlay2_Constrain_By_Alpha) {
    bool in_range = (albedo.a > _PBR_Overlay2_Constrain_By_Alpha_Min) *
      (albedo.a < _PBR_Overlay2_Constrain_By_Alpha_Max);
    a2 *= in_range;
  }
  a2 *= mask;
#endif
#if defined(_PBR_OVERLAY3)
  float a3 = saturate(ov.ov3_albedo.a * _PBR_Overlay3_Alpha_Multiplier);
  if (_PBR_Overlay3_Constrain_By_Alpha) {
    bool in_range = (albedo.a > _PBR_Overlay3_Constrain_By_Alpha_Min) *
      (albedo.a < _PBR_Overlay3_Constrain_By_Alpha_Max);
    a3 *= in_range;
  }
  a3 *= mask;
#endif

#if defined(_PBR_OVERLAY0)
#if defined(_PBR_OVERLAY0_MIX_ALPHA_BLEND)
  albedo.rgb = lerp(albedo.rgb, ov.ov0_albedo.rgb, a0);
#if defined(_PBR_OVERLAY0_ROUGHNESS)
  roughness = lerp(roughness, ov.ov0_roughness, a0);
#endif
#if defined(_PBR_OVERLAY0_METALLIC)
  metallic = lerp(metallic, ov.ov0_metallic, a0);
#endif
  albedo.a = max(albedo.a, a0);
#elif defined(_PBR_OVERLAY0_MIX_ADD)
  albedo.rgb += ov.ov0_albedo;
#elif defined(_PBR_OVERLAY0_MIX_MIN)
  albedo.rgb = min(albedo.rgb, ov.ov0_albedo);
#elif defined(_PBR_OVERLAY0_MIX_MAX)
  albedo.rgb = max(albedo.rgb, ov.ov0_albedo);
#endif
#endif

#if defined(_PBR_OVERLAY1)
#if defined(_PBR_OVERLAY1_MIX_ALPHA_BLEND)
  albedo.rgb = lerp(albedo.rgb, ov.ov1_albedo.rgb, a1);
#if defined(_PBR_OVERLAY1_ROUGHNESS)
  roughness = lerp(roughness, ov.ov1_roughness, a1);
#endif
#if defined(_PBR_OVERLAY1_METALLIC)
  metallic = lerp(metallic, ov.ov1_metallic, a1);
#endif
  albedo.a = max(albedo.a, a1);
#elif defined(_PBR_OVERLAY1_MIX_ADD)
  albedo.rgb += ov.ov1_albedo;
#elif defined(_PBR_OVERLAY1_MIX_MIN)
  albedo.rgb = min(albedo.rgb, ov.ov1_albedo);
#elif defined(_PBR_OVERLAY1_MIX_MAX)
  albedo.rgb = max(albedo.rgb, ov.ov1_albedo);
#endif
#endif

#if defined(_PBR_OVERLAY2)
#if defined(_PBR_OVERLAY2_MIX_ALPHA_BLEND)
  albedo.rgb = lerp(albedo.rgb, ov.ov2_albedo.rgb, ov.ov2_albedo.a);
#if defined(_PBR_OVERLAY2_ROUGHNESS)
  roughness = lerp(roughness, ov.ov2_roughness, a2);
#endif
#if defined(_PBR_OVERLAY2_METALLIC)
  metallic = lerp(metallic, ov.ov2_metallic, a2);
#endif
  albedo.a = max(albedo.a, a2);
#elif defined(_PBR_OVERLAY2_MIX_ADD)
  albedo.rgb += ov.ov2_albedo;
#elif defined(_PBR_OVERLAY2_MIX_MIN)
  albedo.rgb = min(albedo.rgb, ov.ov2_albedo);
#elif defined(_PBR_OVERLAY2_MIX_MAX)
  albedo.rgb = max(albedo.rgb, ov.ov2_albedo);
#endif
#endif

#if defined(_PBR_OVERLAY3)
#if defined(_PBR_OVERLAY3_MIX_ALPHA_BLEND)
  albedo.rgb = lerp(albedo.rgb, ov.ov3_albedo.rgb, a3);
#if defined(_PBR_OVERLAY3_ROUGHNESS)
  roughness = lerp(roughness, ov.ov3_roughness, a3);
#endif
#if defined(_PBR_OVERLAY3_METALLIC)
  metallic = lerp(metallic, ov.ov3_metallic, a3);
#endif
  albedo.a = max(albedo.a, a3);
#elif defined(_PBR_OVERLAY3_MIX_ADD)
  albedo.rgb += ov.ov3_albedo;
#elif defined(_PBR_OVERLAY3_MIX_MIN)
  albedo.rgb = min(albedo.rgb, ov.ov3_albedo);
#elif defined(_PBR_OVERLAY3_MIX_MAX)
  albedo.rgb = max(albedo.rgb, ov.ov3_albedo);
#endif
#endif
}

void applyOverlayNormal(inout float3 raw_normal, float4 albedo, PbrOverlay ov, v2f i)
{
  float3 raw_normal_2;
#if defined(_PBR_OVERLAY0) && defined(_PBR_OVERLAY0_NORMAL_MAP)
  float a0 = 1;
  if (_PBR_Overlay0_Constrain_By_Alpha) {
    bool in_range = (albedo.a > _PBR_Overlay0_Constrain_By_Alpha_Min) *
      (albedo.a < _PBR_Overlay0_Constrain_By_Alpha_Max);
    a0 *= in_range;
  }
  // Use UVs to smoothly blend between fully detailed normals when close up and
  // flat normals when far away. If we don't do this, then we see moire effects
  // on e.g. striped normal maps.
  raw_normal_2 = UnpackScaleNormal(_PBR_Overlay0_NormalTex.SampleBias(GET_SAMPLER_OV0,
        UV_SCOFF(i, _PBR_Overlay0_NormalTex_ST, _PBR_Overlay0_UV_Select),
        _Global_Sample_Bias + _PBR_Overlay0_Mip_Bias),
      _PBR_Overlay0_Tex_NormalStr * ov.ov0_mask * a0);

  raw_normal = BlendNormals(
      raw_normal,
      raw_normal_2);
#endif  // _PBR_OVERLAY0 && _PBR_OVERLAY0_NORMAL_MAP
#if defined(_PBR_OVERLAY1) && defined(_PBR_OVERLAY1_NORMAL_MAP)
  float a1 = 1;
  if (_PBR_Overlay1_Constrain_By_Alpha) {
    bool in_range = (albedo.a > _PBR_Overlay1_Constrain_By_Alpha_Min) *
      (albedo.a < _PBR_Overlay1_Constrain_By_Alpha_Max);
    a1 *= in_range;
  }
  raw_normal_2 = UnpackScaleNormal(_PBR_Overlay1_NormalTex.SampleBias(GET_SAMPLER_OV1,
        UV_SCOFF(i, _PBR_Overlay1_NormalTex_ST, _PBR_Overlay1_UV_Select),
        _Global_Sample_Bias + _PBR_Overlay1_Mip_Bias),
      _PBR_Overlay1_Tex_NormalStr * ov.ov1_mask * a1);

  raw_normal = BlendNormals(
      raw_normal,
      raw_normal_2);
#endif  // _PBR_OVERLAY1 && _PBR_OVERLAY1_NORMAL_MAP
#if defined(_PBR_OVERLAY2) && defined(_PBR_OVERLAY2_NORMAL_MAP)
  float a2 = 1;
  if (_PBR_Overlay2_Constrain_By_Alpha) {
    bool in_range = (albedo.a > _PBR_Overlay2_Constrain_By_Alpha_Min) *
      (albedo.a < _PBR_Overlay2_Constrain_By_Alpha_Max);
    a2 *= in_range;
  }
  raw_normal_2 = UnpackScaleNormal(_PBR_Overlay2_NormalTex.SampleBias(GET_SAMPLER_OV2,
        UV_SCOFF(i, _PBR_Overlay2_NormalTex_ST, _PBR_Overlay2_UV_Select),
        _Global_Sample_Bias + _PBR_Overlay2_Mip_Bias),
      _PBR_Overlay2_Tex_NormalStr * ov.ov2_mask * a2);

  raw_normal = BlendNormals(
      raw_normal,
      raw_normal_2);
#endif  // _PBR_OVERLAY2 && _PBR_OVERLAY2_NORMAL_MAP
#if defined(_PBR_OVERLAY3) && defined(_PBR_OVERLAY3_NORMAL_MAP)
  float a3 = 1;
  if (_PBR_Overlay3_Constrain_By_Alpha) {
    bool in_range = (albedo.a > _PBR_Overlay3_Constrain_By_Alpha_Min) *
      (albedo.a < _PBR_Overlay3_Constrain_By_Alpha_Max);
    a3 *= in_range;
  }
  raw_normal_2 = UnpackScaleNormal(_PBR_Overlay3_NormalTex.SampleBias(GET_SAMPLER_OV3,
        UV_SCOFF(i, _PBR_Overlay3_NormalTex_ST, _PBR_Overlay3_UV_Select),
        _Global_Sample_Bias + _PBR_Overlay3_Mip_Bias),
      _PBR_Overlay3_Tex_NormalStr * ov.ov3_mask * a3);

  raw_normal = BlendNormals(
      raw_normal,
      raw_normal_2);
#endif  // _PBR_OVERLAY3 && _PBR_OVERLAY3_NORMAL_MAP
}

float3 getOverlayEmission(PbrOverlay ov, v2f i)
{
  float3 em = 0;
#if defined(_PBR_OVERLAY0_EMISSION_MAP)
  em += _PBR_Overlay0_EmissionTex.SampleBias(GET_SAMPLER_OV0,
      UV_SCOFF(i, _PBR_Overlay0_EmissionTex_ST, _PBR_Overlay0_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay0_Mip_Bias) *
    _PBR_Overlay0_Emission * ov.ov0_mask;
#endif

#if defined(_PBR_OVERLAY1_EMISSION_MAP)
  em += _PBR_Overlay1_EmissionTex.SampleBias(GET_SAMPLER_OV1,
      UV_SCOFF(i, _PBR_Overlay1_EmissionTex_ST, _PBR_Overlay1_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay1_Mip_Bias) *
    _PBR_Overlay1_Emission * ov.ov1_mask;
#endif

#if defined(_PBR_OVERLAY2_EMISSION_MAP)
  em += _PBR_Overlay2_EmissionTex.SampleBias(GET_SAMPLER_OV2,
      UV_SCOFF(i, _PBR_Overlay2_EmissionTex_ST, _PBR_Overlay2_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay2_Mip_Bias) *
    _PBR_Overlay2_Emission * ov.ov2_mask;
#endif

#if defined(_PBR_OVERLAY3_EMISSION_MAP)
  em += _PBR_Overlay3_EmissionTex.SampleBias(GET_SAMPLER_OV3,
      UV_SCOFF(i, _PBR_Overlay3_EmissionTex_ST, _PBR_Overlay3_UV_Select),
      _Global_Sample_Bias + _PBR_Overlay3_Mip_Bias) *
    _PBR_Overlay3_Emission * ov.ov3_mask;
#endif
  return em;
}

#if defined(_PIXELLATE)
float2 pixellate_uv(int2 px_res, float2 uv)
{
  return floor(uv * px_res) / px_res;
}

float4 pixellate_color(int2 px_res, float2 uv, float4 c)
{
  float2 px_intra_uv = fmod(uv * px_res, 1.0);
  float2 px_extra_uv = floor(uv * px_res) / px_res;

  float2 px_uv = floor(uv * px_res) / px_res;
  if (px_intra_uv.y > 0.1 && px_intra_uv.y < 0.9) {
    if (px_intra_uv.x < 0.333) {
      c.xyz = float3(1, 0, 0);
    } else if (px_intra_uv.x < 0.666) {
      c.yxz = float3(1, 0, 0);
    } else {
      c.zxy = float3(1, 0, 0);
    }
    c *= 3;
  } else {
    c = 0;
  }

  return c;
}
#endif

float4 effect(inout v2f i)
{
  const float3 view_dir = normalize(_WorldSpaceCameraPos - i.worldPos);
  // Not necessarily normalized after interpolation.
  i.normal = normalize(i.normal);
  i.tangent.xyz = normalize(i.tangent.xyz);

#if defined(_TROCHOID)
  {
    i.normal = trochoid_normal(i.objPos.xyz, i.uv0);

    float theta = i.uv0.x * TAU;
    float r0 = length(i.objPos.xyz);
    float z = i.objPos.z;
    i.objPos.xyz = trochoid_map(theta, r0, z);
  }
#endif

#if defined(_UVSCROLL)
  float2 orig_uv = i.uv0;
  float uv_scroll_mask = round(_UVScroll_Mask.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias));
  i.uv0 += _Time[0] * float2(_UVScroll_U_Speed, _UVScroll_V_Speed) * uv_scroll_mask;
#endif

#if defined(_BASECOLOR_MAP)
  float4 albedo = _MainTex.SampleBias(GET_SAMPLER_PBR, UV_SCOFF(i, _MainTex_ST, 0), _Global_Sample_Bias);
  albedo *= _Color;
#else
  float4 albedo = _Color;
#endif  // _BASECOLOR_MAP

#if defined(_UVSCROLL)
  if (uv_scroll_mask) {
    float uv_scroll_alpha = _UVScroll_Alpha.SampleBias(linear_repeat_s, orig_uv, _Global_Sample_Bias);
    albedo.a *= uv_scroll_alpha;
  }
#endif

#if defined(_PIXELLATE)
  {
    const int2 px_res = int2(
        _Gimmick_Pixellate_Resolution_U,
        _Gimmick_Pixellate_Resolution_V);

    float2 uv = pixellate_uv(px_res, i.uv0);
    const float2 duv = float2(ddx(i.uv0.x), ddy(i.uv0.y)) / 16;
    float4 color = _Gimmick_Pixellate_Effect_Mask.SampleGrad(linear_clamp_s, uv, duv.x, duv.y);
    float2 fw = float2(fwidth(i.uv0.x), fwidth(i.uv0.y));
    float fwm = max(fw.x, fw.y);
    color.rgb *= albedo;
    float4 px_color = pixellate_color(px_res, i.uv0, color);
    albedo = lerp(albedo, px_color, pow(0.9, fwm * 100));
  }
#endif

#if defined(_RORSCHACH)
  if (_Rorschach_Enable_Dynamic) {
    albedo = get_rorschach(i).albedo;
  }
#endif

#if defined(_RENDERING_CUTOUT)
#if defined(_RENDERING_CUTOUT_STOCHASTIC)
  float ar = rand2(i.uv0);
  clip(albedo.a - ar);
#else
  clip(albedo.a - _Alpha_Cutoff);
#endif
  albedo.a = 1;
#endif

  PbrOverlay ov;
  getOverlayAlbedoRoughnessMetallic(ov, i);

#if defined(_NORMAL_MAP)
  // Use UVs to smoothly blend between fully detailed normals when close up and
  // flat normals when far away. If we don't do this, then we see moire effects
  // on e.g. striped normal maps.
  float3 raw_normal = UnpackScaleNormal(_NormalTex.SampleBias(GET_SAMPLER_PBR,
        UV_SCOFF(i, _NormalTex_ST, 0), _Global_Sample_Bias),
      _Tex_NormalStr);
#else
  float3 raw_normal = UnpackNormal(float4(0.5, 0.5, 1, 1));
#endif  // _NORMAL_MAP

  applyOverlayNormal(raw_normal, albedo, ov, i);

  float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
  // normalize is not necessary; result is already normalized
	float3 normal = float3(
		raw_normal.x * i.tangent +
		raw_normal.y * binormal +
		raw_normal.z * i.normal
	);

#if defined(_METALLIC_MAP)
  float metallic = _MetallicTex.SampleBias(GET_SAMPLER_PBR,
      UV_SCOFF(i, _MetallicTex_ST, 0), _Global_Sample_Bias);
#else
  float metallic = _Metallic;
#endif
#if defined(_ROUGHNESS_MAP)
  float roughness = _RoughnessTex.SampleBias(GET_SAMPLER_PBR, UV_SCOFF(i, _RoughnessTex_ST, 0), _Global_Sample_Bias);
  if (_Roughness_Invert) {
    roughness = 1 - roughness;
  }
  roughness *= _Roughness;
#else
  float roughness = _Roughness;
#endif
#if defined(VERTEXLIGHT_ON)
  float4 vertex_light_color = float4(i.vertexLightColor, 1);
#else
  float4 vertex_light_color = float4(0, 0, 0, 1);
#endif

#if defined(_GIMMICK_EYES_00)
  {
    float3 eyes00_normal = 0;
    float3 eyes00_albedo = eyes00_march(i.uv0, eyes00_normal).rgb;
    bool is_ray_hit = (eyes00_albedo.r > 0 || eyes00_albedo.g > 0 || eyes00_albedo.b > 0);
    if (is_ray_hit) {
      float mask = _Gimmick_Eyes00_Effect_Mask.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
      albedo.rgb = lerp(eyes00_albedo * 1.5, albedo.rgb * 20.0, mask);
      normal = eyes00_normal;
    }
  }
#endif

#if defined(_MATCAP0) || defined(_MATCAP1) || defined(_RIM_LIGHTING0) || defined(_RIM_LIGHTING1) || defined(_RIM_LIGHTING2) || defined(_RIM_LIGHTING3)
  float3 matcap_emission = 0;
  float2 matcap_uv;
  float matcap_theta;
  float matcap_radius;
  {
    const float3 cam_normal = normalize(mul(UNITY_MATRIX_V, float4(normal, 0)));
    const float3 cam_view_dir = normalize(mul(UNITY_MATRIX_V, float4(view_dir, 0)));
    const float3 cam_refl = -reflect(cam_view_dir, cam_normal);
    float m = 2.0 * sqrt(
        cam_refl.x * cam_refl.x +
        cam_refl.y * cam_refl.y +
        (cam_refl.z + 1) * (cam_refl.z + 1));
    matcap_uv = cam_refl.xy / m + 0.5;
    matcap_radius = length(matcap_uv - 0.5);
    matcap_theta = atan2(matcap_uv.y - 0.5, matcap_uv.x - 0.5);
  }
#endif
  float4 matcap_overwrite_mask = 0;
#if defined(_MATCAP0) || defined(_MATCAP1)
  {
#if defined(_MATCAP0)
    {
#if defined(_MATCAP0_MASK)
      float4 matcap_mask_raw = _Matcap0_Mask.SampleLevel(linear_repeat_s,
          get_uv_by_channel(i, _Matcap0_Mask_UV_Select), 0);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Matcap0_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif
#if defined(_MATCAP0_MASK2)
      {
        float4 matcap_mask2_raw = _Matcap0_Mask2.SampleLevel(linear_repeat_s,
            get_uv_by_channel(i, _Matcap0_Mask2_UV_Select), 0);
        float matcap_mask2 = matcap_mask2_raw.r;
        matcap_mask2 = (bool) round(_Matcap0_Mask2_Invert) ? 1 - matcap_mask2 : matcap_mask2;
        matcap_mask2 *= matcap_mask2_raw.a;
        matcap_mask *= matcap_mask2;
      }
#endif
#if defined(_MATCAP0_NORMAL)
      float3 matcap_normal = UnpackScaleNormal(
          _Matcap0Normal.SampleBias(linear_repeat_s,
            UV_SCOFF(i, _Matcap0Normal_ST, _Matcap0Normal_UV_Select),
            _Global_Sample_Bias + _Matcap0Normal_Mip_Bias),
          _Matcap0Normal_Str * _Matcap0MixFactor);
      raw_normal = MY_BLEND_NORMALS(raw_normal, matcap_normal, matcap_mask * _Matcap0MixFactor);
      normal = float3(
          raw_normal.x * i.tangent +
          raw_normal.y * binormal +
          raw_normal.z * i.normal
          );
  {
    const float3 cam_normal = normalize(mul(UNITY_MATRIX_V, float4(normal, 0)));
    const float3 cam_view_dir = normalize(mul(UNITY_MATRIX_V, float4(view_dir, 0)));
    const float3 cam_refl = -reflect(cam_view_dir, cam_normal);
    float m = 2.0 * sqrt(
        cam_refl.x * cam_refl.x +
        cam_refl.y * cam_refl.y +
        (cam_refl.z + 1) * (cam_refl.z + 1));
    matcap_uv = cam_refl.xy / m + 0.5;
    matcap_radius = length(matcap_uv - 0.5);
    matcap_theta = atan2(matcap_uv.y - 0.5, matcap_uv.x - 0.5);
  }
#endif

#if defined(_MATCAP0_DISTORTION0)
      float2 distort_uv = matcap_distortion0(matcap_uv);
      float2 matcap_uv = distort_uv;
#endif
      float3 matcap = _Matcap0.SampleBias(linear_repeat_s, matcap_uv, _Global_Sample_Bias) * _Matcap0Str;

      float q = _Matcap0Quantization;
      if (q > 0) {
        matcap = ceil(matcap * q) / q;
      }

      int mode = round(_Matcap0Mode);
      switch (mode) {
        case 0:
          albedo.rgb += lerp(0, matcap, matcap_mask);
          matcap_emission += lerp(0, matcap, matcap_mask) * _Matcap0Emission;
          break;
        case 1:
          matcap_emission = lerp(1, matcap, matcap_mask) * _Matcap0Emission;
          albedo.rgb *= lerp(1, matcap, matcap_mask);
          break;
        case 2:
          matcap_overwrite_mask[0] = max(matcap_mask, matcap_overwrite_mask[0]);
          albedo.rgb = lerp(albedo.rgb, matcap, matcap_mask);
          matcap_emission = lerp(albedo.rgb, matcap, matcap_mask) * _Matcap0Emission;
          break;
        case 3:
          albedo.rgb -= lerp(0, matcap, matcap_mask);
          matcap_emission -= lerp(0, matcap, matcap_mask) * _Matcap0Emission;
          break;
        case 4:
          albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask) * _Matcap0Emission;
          break;
        case 5:
          albedo.rgb = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask) * _Matcap0Emission;
          break;
        default:
          break;
      }
    }
#endif  // _MATCAP0
#if defined(_MATCAP1)
    {
#if defined(_MATCAP1_MASK)
      float4 matcap_mask_raw = _Matcap1_Mask.SampleLevel(linear_repeat_s,
          get_uv_by_channel(i, _Matcap1_Mask_UV_Select), 0);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Matcap1_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif
#if defined(_MATCAP1_MASK2)
      {
        float4 matcap_mask2_raw = _Matcap1_Mask2.SampleLevel(linear_repeat_s,
            get_uv_by_channel(i, _Matcap1_Mask2_UV_Select), 0);
        float matcap_mask2 = matcap_mask2_raw.r;
        matcap_mask2 = (bool) round(_Matcap1_Mask2_Invert) ? 1 - matcap_mask2 : matcap_mask2;
        matcap_mask2 *= matcap_mask2_raw.a;
        matcap_mask *= matcap_mask2;
      }
#endif
#if defined(_MATCAP1_NORMAL)
      float3 matcap_normal = UnpackScaleNormal(
          _Matcap1Normal.SampleBias(linear_repeat_s,
            UV_SCOFF(i, _Matcap1Normal_ST, _Matcap1Normal_UV_Select),
            _Global_Sample_Bias + _Matcap1Normal_Mip_Bias),
          _Matcap1Normal_Str * _Matcap1MixFactor);
      raw_normal = MY_BLEND_NORMALS(raw_normal, matcap_normal, matcap_mask * _Matcap1MixFactor);
      normal = float3(
          raw_normal.x * i.tangent +
          raw_normal.y * binormal +
          raw_normal.z * i.normal
          );
  {
    const float3 cam_normal = normalize(mul(UNITY_MATRIX_V, float4(normal, 0)));
    const float3 cam_view_dir = normalize(mul(UNITY_MATRIX_V, float4(view_dir, 0)));
    const float3 cam_refl = -reflect(cam_view_dir, cam_normal);
    float m = 2.0 * sqrt(
        cam_refl.x * cam_refl.x +
        cam_refl.y * cam_refl.y +
        (cam_refl.z + 1) * (cam_refl.z + 1));
    matcap_uv = cam_refl.xy / m + 0.5;
    matcap_radius = length(matcap_uv - 0.5);
    matcap_theta = atan2(matcap_uv.y - 0.5, matcap_uv.x - 0.5);
  }
#endif
#if defined(_MATCAP1_DISTORTION0)
      float2 distort_uv = matcap_distortion0(matcap_uv);
      float2 matcap_uv = distort_uv;
#endif
      float3 matcap = _Matcap1.SampleBias(linear_repeat_s, matcap_uv, _Global_Sample_Bias) * _Matcap1Str;

      float q = _Matcap1Quantization;
      if (q > 0) {
        matcap = ceil(matcap * q) / q;
      }

      matcap_mask *= _Matcap1MixFactor;

      int mode = round(_Matcap1Mode);
      switch (mode) {
        case 0:
          albedo.rgb += lerp(0, matcap, matcap_mask);
          matcap_emission += lerp(0, matcap, matcap_mask) * _Matcap1Emission;
          break;
        case 1:
          matcap_emission = lerp(1, matcap, matcap_mask) * _Matcap1Emission;
          albedo.rgb *= lerp(1, matcap, matcap_mask);
          break;
        case 2:
          matcap_overwrite_mask[1] = max(matcap_mask, matcap_overwrite_mask[1]);
          albedo.rgb = lerp(albedo.rgb, matcap, matcap_mask);
          matcap_emission = lerp(albedo.rgb, matcap, matcap_mask) * _Matcap1Emission;
          break;
        case 3:
          albedo.rgb -= lerp(0, matcap, matcap_mask);
          matcap_emission -= lerp(0, matcap, matcap_mask) * _Matcap1Emission;
          break;
        case 4:
          albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask) * _Matcap1Emission;
          break;
        case 5:
          albedo.rgb = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask) * _Matcap1Emission;
          break;
        default:
          break;
      }
    }
#endif  // _MATCAP1
  }
#endif  // _MATCAP0 || _MATCAP1
  matcap_overwrite_mask = 1 - matcap_overwrite_mask;

  // TODO get rid of the pow. It's a hack to make matcap replace mode look
  // better with overlay tattoos.
  mixOverlayAlbedoRoughnessMetallic(albedo, roughness, metallic, ov,
      1 - pow((1 - min(matcap_overwrite_mask[0], matcap_overwrite_mask[1])), 8));
#if defined(_DECAL0) || defined(_DECAL1) || defined(_DECAL2) || defined(_DECAL3)
  float3 decal_emission = 0;
  applyDecal(albedo, roughness, metallic, decal_emission, i);
#endif

#if defined(_RIM_LIGHTING0) || defined(_RIM_LIGHTING1) || defined(_RIM_LIGHTING2) || defined(_RIM_LIGHTING3)
  {
    // identity: (a, b, c) and (c, c, -(a +b)) are perpendicular to each other
    float theta = atan2(length(cross(view_dir, normal)), dot(view_dir, normal));
#define PI 3.14159265

#if defined(_RIM_LIGHTING0)
    {
      float rl = abs(theta) / PI;  // on [0, 1]
      rl = pow(2, -_Rim_Lighting0_Power * abs(rl - _Rim_Lighting0_Center));
      float q = _Rim_Lighting0_Quantization;
      if (q > -1) {
        rl = floor(rl * q) / q;
      }
      float3 matcap = rl * _Rim_Lighting0_Color * _Rim_Lighting0_Strength;

#if defined(_RIM_LIGHTING0_MASK)
      float4 matcap_mask_raw = _Rim_Lighting0_Mask.SampleBias(GET_SAMPLER_RL0,
          get_uv_by_channel(i, _Rim_Lighting0_Mask_UV_Select), _Global_Sample_Bias);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Rim_Lighting0_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif
#if defined(_MATCAP0)
        if (_Matcap0_Overwrite_Rim_Lighting_0) {
          matcap_mask *= matcap_overwrite_mask[0];
        }
#endif
#if defined(_MATCAP1)
        if (_Matcap1_Overwrite_Rim_Lighting_0) {
          matcap_mask *= matcap_overwrite_mask[1];
        }
#endif
#if defined(_RIM_LIGHTING0_POLAR_MASK)
      if (_Rim_Lighting0_PolarMask_Enabled) {
        float pmask_theta = _Rim_Lighting0_PolarMask_Theta;
        float pmask_pow = _Rim_Lighting0_PolarMask_Power;
        matcap_mask *= abs(1.0 / (1.0 + pow(abs(matcap_theta - pmask_theta), pmask_pow)));;
      }
#endif
#if defined(_RIM_LIGHTING0_GLITTER)
      float rl_glitter = get_glitter(
          get_uv_by_channel(i, round(_Rim_Lighting0_Glitter_UV_Select)),
          i.worldPos, normal,
          _Rim_Lighting0_Glitter_Density,
          _Rim_Lighting0_Glitter_Amount, _Rim_Lighting0_Glitter_Speed,
          /*mask=*/1, /*angle=*/91, /*power=*/1);
      rl_glitter = floor(rl_glitter * _Rim_Lighting0_Glitter_Quantization) / _Rim_Lighting0_Glitter_Quantization;
      matcap_mask *= rl_glitter;
#endif
      int mode = round(_Rim_Lighting0_Mode);
      switch (mode) {
        case 0:
          albedo.rgb += lerp(0, matcap, matcap_mask);
          matcap_emission += lerp(0, matcap, matcap_mask) * _Rim_Lighting0_Emission;
          break;
        case 1:
          matcap_emission = albedo.rgb * lerp(0, matcap, matcap_mask) * _Rim_Lighting0_Emission;
          albedo.rgb *= lerp(1, matcap, matcap_mask);
          break;
        case 2:
          albedo.rgb = lerp(albedo.rgb, matcap, matcap_mask);
          matcap_emission = lerp(albedo.rgb, matcap, matcap_mask) * _Rim_Lighting0_Emission;
          break;
        case 3:
          albedo.rgb -= lerp(0, matcap, matcap_mask);
          matcap_emission -= lerp(0, matcap, matcap_mask) * _Rim_Lighting0_Emission;
          break;
        case 4:
          albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting0_Emission;
          break;
        case 5:
          albedo.rgb = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting0_Emission;
          break;
        default:
          break;
      }
    }
#endif  // _RIM_LIGHTING0
#if defined(_RIM_LIGHTING1)
    {
      float rl = abs(theta) / PI;  // on [0, 1]
      rl = pow(2, -_Rim_Lighting1_Power * abs(rl - _Rim_Lighting1_Center));
      float q = _Rim_Lighting1_Quantization;
      if (q > 0) {
        rl = floor(rl * q) / q;
      }
      float3 matcap = rl * _Rim_Lighting1_Color * _Rim_Lighting1_Strength;
#if defined(_RIM_LIGHTING1_MASK)
      float4 matcap_mask_raw = _Rim_Lighting1_Mask.SampleBias(GET_SAMPLER_RL1,
          get_uv_by_channel(i, _Rim_Lighting1_Mask_UV_Select), _Global_Sample_Bias);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Rim_Lighting1_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif
#if defined(_MATCAP0)
        if (_Matcap0_Overwrite_Rim_Lighting_1) {
          matcap_mask *= matcap_overwrite_mask[0];
        }
#endif
#if defined(_MATCAP1)
        if (_Matcap1_Overwrite_Rim_Lighting_1) {
          matcap_mask *= matcap_overwrite_mask[1];
        }
#endif
#if defined(_RIM_LIGHTING1_POLAR_MASK)
      if (_Rim_Lighting1_PolarMask_Enabled) {
        float pmask_theta = _Rim_Lighting1_PolarMask_Theta;
        float pmask_pow = _Rim_Lighting1_PolarMask_Power;
        float filter = abs(1.0 / (1.0 + pow(abs(matcap_theta - pmask_theta), pmask_pow)));;
        if (q > 0) {
          filter = floor(filter * q) / q;
        }
        matcap_mask *= filter;
      }
#endif
#if defined(_RIM_LIGHTING1_GLITTER)
      float rl_glitter = get_glitter(
          get_uv_by_channel(i, round(_Rim_Lighting1_Glitter_UV_Select)),
          i.worldPos, normal,
          _Rim_Lighting1_Glitter_Density,
          _Rim_Lighting1_Glitter_Amount, _Rim_Lighting1_Glitter_Speed,
          /*mask=*/1, /*angle=*/91, /*power=*/1);
      rl_glitter = floor(rl_glitter * _Rim_Lighting1_Glitter_Quantization) / _Rim_Lighting1_Glitter_Quantization;
      matcap_mask *= rl_glitter;
#endif
      int mode = round(_Rim_Lighting1_Mode);
      switch (mode) {
        case 0:
          albedo.rgb += lerp(0, matcap, matcap_mask);
          matcap_emission += lerp(0, matcap, matcap_mask) * _Rim_Lighting1_Emission;
          break;
        case 1:
          matcap_emission = albedo.rgb * lerp(0, matcap, matcap_mask) * _Rim_Lighting1_Emission;
          albedo.rgb *= lerp(1, matcap, matcap_mask);
          break;
        case 2:
          albedo.rgb = lerp(albedo.rgb, matcap, matcap_mask);
          matcap_emission = lerp(albedo.rgb, matcap, matcap_mask) * _Rim_Lighting1_Emission;
          break;
        case 3:
          albedo.rgb -= lerp(0, matcap, matcap_mask);
          matcap_emission -= lerp(0, matcap, matcap_mask) * _Rim_Lighting1_Emission;
          break;
        case 4:
          albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting1_Emission;
          break;
        case 5:
          albedo.rgb = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting1_Emission;
          break;
        default:
          break;
      }
    }
#endif  // _RIM_LIGHTING1
#if defined(_RIM_LIGHTING2)
    {
      float rl = abs(theta) / PI;  // on [0, 1]
      rl = pow(2, -_Rim_Lighting2_Power * abs(rl - _Rim_Lighting2_Center));
      float q = _Rim_Lighting2_Quantization;
      if (q > 0) {
        rl = floor(rl * q) / q;
      }
      float3 matcap = rl * _Rim_Lighting2_Color * _Rim_Lighting2_Strength;
#if defined(_RIM_LIGHTING2_MASK)
      float4 matcap_mask_raw = _Rim_Lighting2_Mask.SampleBias(GET_SAMPLER_RL2,
          get_uv_by_channel(i, _Rim_Lighting2_Mask_UV_Select), _Global_Sample_Bias);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Rim_Lighting2_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif
#if defined(_MATCAP0)
        if (_Matcap0_Overwrite_Rim_Lighting_2) {
          matcap_mask *= matcap_overwrite_mask[0];
        }
#endif
#if defined(_MATCAP1)
        if (_Matcap1_Overwrite_Rim_Lighting_2) {
          matcap_mask *= matcap_overwrite_mask[1];
        }
#endif
#if defined(_RIM_LIGHTING2_POLAR_MASK)
      if (_Rim_Lighting2_PolarMask_Enabled) {
        float pmask_theta = _Rim_Lighting2_PolarMask_Theta;
        float pmask_pow = _Rim_Lighting2_PolarMask_Power;
        float filter = abs(1.0 / (1.0 + pow(abs(matcap_theta - pmask_theta), pmask_pow)));;
        if (q > 0) {
          filter = floor(filter * q) / q;
        }
        matcap_mask *= filter;
      }
#endif
#if defined(_RIM_LIGHTING2_GLITTER)
      float rl_glitter = get_glitter(
          get_uv_by_channel(i, round(_Rim_Lighting2_Glitter_UV_Select)),
          i.worldPos, normal,
          _Rim_Lighting2_Glitter_Density,
          _Rim_Lighting2_Glitter_Amount, _Rim_Lighting2_Glitter_Speed,
          /*mask=*/1, /*angle=*/91, /*power=*/1);
      rl_glitter = floor(rl_glitter * _Rim_Lighting2_Glitter_Quantization) / _Rim_Lighting2_Glitter_Quantization;
      matcap_mask *= rl_glitter;
#endif
      int mode = round(_Rim_Lighting2_Mode);
      switch (mode) {
        case 0:
          albedo.rgb += lerp(0, matcap, matcap_mask);
          matcap_emission += lerp(0, matcap, matcap_mask) * _Rim_Lighting2_Emission;
          break;
        case 1:
          matcap_emission = albedo.rgb * lerp(0, matcap, matcap_mask) * _Rim_Lighting2_Emission;
          albedo.rgb *= lerp(1, matcap, matcap_mask);
          break;
        case 2:
          albedo.rgb = lerp(albedo.rgb, matcap, matcap_mask);
          matcap_emission = lerp(albedo.rgb, matcap, matcap_mask) * _Rim_Lighting2_Emission;
          break;
        case 3:
          albedo.rgb -= lerp(0, matcap, matcap_mask);
          matcap_emission -= lerp(0, matcap, matcap_mask) * _Rim_Lighting2_Emission;
          break;
        case 4:
          albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting2_Emission;
          break;
        case 5:
          albedo.rgb = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting2_Emission;
          break;
        default:
          break;
      }
    }
#endif  // _RIM_LIGHTING2
#if defined(_RIM_LIGHTING3)
    {
      float rl = abs(theta) / PI;  // on [0, 1]
      rl = pow(2, -_Rim_Lighting3_Power * abs(rl - _Rim_Lighting3_Center));
      float q = _Rim_Lighting3_Quantization;
      if (q > 0) {
        rl = floor(rl * q) / q;
      }
      float3 matcap = rl * _Rim_Lighting3_Color * _Rim_Lighting3_Strength;
#if defined(_RIM_LIGHTING3_MASK)
      float4 matcap_mask_raw = _Rim_Lighting3_Mask.SampleBias(GET_SAMPLER_RL3,
          get_uv_by_channel(i, _Rim_Lighting3_Mask_UV_Select), _Global_Sample_Bias);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Rim_Lighting3_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif
#if defined(_MATCAP0)
        if (_Matcap0_Overwrite_Rim_Lighting_3) {
          matcap_mask *= matcap_overwrite_mask[0];
        }
#endif
#if defined(_MATCAP1)
        if (_Matcap1_Overwrite_Rim_Lighting_3) {
          matcap_mask *= matcap_overwrite_mask[1];
        }
#endif
#if defined(_RIM_LIGHTING3_POLAR_MASK)
      if (_Rim_Lighting3_PolarMask_Enabled) {
        float pmask_theta = _Rim_Lighting3_PolarMask_Theta;
        float pmask_pow = _Rim_Lighting3_PolarMask_Power;
        float filter = abs(1.0 / (1.0 + pow(abs(matcap_theta - pmask_theta), pmask_pow)));;
        if (q > 0) {
          filter = floor(filter * q) / q;
        }
        matcap_mask *= filter;
      }
#endif
#if defined(_RIM_LIGHTING3_GLITTER)
      float rl_glitter = get_glitter(
          get_uv_by_channel(i, round(_Rim_Lighting3_Glitter_UV_Select)),
          i.worldPos, normal,
          _Rim_Lighting3_Glitter_Density,
          _Rim_Lighting3_Glitter_Amount, _Rim_Lighting3_Glitter_Speed,
          /*mask=*/1, /*angle=*/91, /*power=*/1);
      rl_glitter = floor(rl_glitter * _Rim_Lighting3_Glitter_Quantization) / _Rim_Lighting3_Glitter_Quantization;
      matcap_mask *= rl_glitter;
#endif
      int mode = round(_Rim_Lighting3_Mode);
      switch (mode) {
        case 0:
          albedo.rgb += lerp(0, matcap, matcap_mask);
          matcap_emission += lerp(0, matcap, matcap_mask) * _Rim_Lighting3_Emission;
          break;
        case 1:
          matcap_emission = albedo.rgb * lerp(0, matcap, matcap_mask) * _Rim_Lighting3_Emission;
          albedo.rgb *= lerp(1, matcap, matcap_mask);
          break;
        case 2:
          albedo.rgb = lerp(albedo.rgb, matcap, matcap_mask);
          matcap_emission = lerp(albedo.rgb, matcap, matcap_mask) * _Rim_Lighting3_Emission;
          break;
        case 3:
          albedo.rgb -= lerp(0, matcap, matcap_mask);
          matcap_emission -= lerp(0, matcap, matcap_mask) * _Rim_Lighting3_Emission;
          break;
        case 4:
          albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting3_Emission;
          break;
        case 5:
          albedo.rgb = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting3_Emission;
          break;
        default:
          break;
      }
    }
#endif  // _RIM_LIGHTING3
  }
#endif  // _RIM_LIGHTING0 || _RIM_LIGHTING1 || _RIM_LIGHTING2 || _RIM_LIGHTING3

#if defined(_OKLAB)
  // Do hue shift in perceptually uniform color space so it doesn't look like
  // shit.
 float oklab_mask = _OKLAB_Mask.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
 if (_OKLAB_Mask_Invert) {
   oklab_mask = 1 - oklab_mask;
 }
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

#if defined(_HSV0)
 {
   float hsv_mask = _HSV0_Mask.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
   if (_HSV0_Mask_Invert) {
     hsv_mask = 1 - hsv_mask;
   }
   if (hsv_mask > 0.01 &&
       (_HSV0_Hue_Shift > 1E-6 ||
        abs(_HSV0_Sat_Shift) > 1E-6 ||
        abs(_HSV0_Val_Shift) > 1E-6)) {
     float3 c = albedo.rgb;
     c = RGBtoHSV(c);
     c += float3(_HSV0_Hue_Shift, _HSV0_Sat_Shift, _HSV0_Val_Shift);
     c.x = glsl_mod(c.x, 1.0);
     c.yz = saturate(c.yz);
     c = HSVtoRGB(c);
     albedo.rgb = c;
   }
 }
#endif

#if defined(_HSV1)
 {
   float hsv_mask = _HSV1_Mask.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
   if (_HSV1_Mask_Invert) {
     hsv_mask = 1 - hsv_mask;
   }
   if (hsv_mask > 0.01 &&
       (_HSV1_Hue_Shift > 1E-6 ||
        abs(_HSV1_Sat_Shift) > 1E-6 ||
        abs(_HSV1_Val_Shift) > 1E-6)) {
     float3 c = albedo.rgb;
     c = RGBtoHSV(c);
     c += float3(_HSV1_Hue_Shift, _HSV1_Sat_Shift, _HSV1_Val_Shift);
     c.x = glsl_mod(c.x, 1.0);
     c.yz = saturate(c.yz);
     c = HSVtoRGB(c);
     albedo.rgb = c;
   }
 }
#endif

#if defined(_AMBIENT_OCCLUSION)
  float ao = _Ambient_Occlusion.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
  ao = 1 - (1 - ao) * _Ambient_Occlusion_Strength;
#else
  float ao = 1;
#endif

#if defined(_GIMMICK_FLAT_COLOR)
  if (round(_Gimmick_Flat_Color_Enable_Dynamic)) {
    albedo = _Gimmick_Flat_Color_Color;
    normal = i.normal;
  }
#endif
#if defined(_GLITTER)
  float3 glitter_color_unlit;
  {
    float glitter_mask = _Glitter_Mask.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
    glitter_mask *= min(matcap_overwrite_mask[0], matcap_overwrite_mask[1]);
    float glitter = get_glitter(
        get_uv_by_channel(i, round(_Glitter_UV_Select)),
        i.worldPos, normal,
        _Glitter_Density, _Glitter_Amount, _Glitter_Speed,
        glitter_mask, _Glitter_Angle, _Glitter_Power);
        glitter_color_unlit = glitter * _Glitter_Color;
  }
  albedo.rgb += glitter_color_unlit * _Glitter_Brightness_Lit;
#endif

  float4 lit = getLitColor(vertex_light_color, albedo, i.worldPos, normal,
      metallic, 1.0 - roughness, i.uv0, ao, /*enable_direct=*/true, i);

#if defined(_GIMMICK_FLAT_COLOR)
  if (round(_Gimmick_Flat_Color_Enable_Dynamic)) {
#if defined(_RENDERING_CUTOUT)
#if defined(_RENDERING_CUTOUT_STOCHASTIC)
    float ar = rand2(i.uv0);
    clip(albedo.a - ar);
#else
    clip(albedo.a - _Alpha_Cutoff);
#endif
    albedo.a = 1;
#endif

    return float4(lit.rgb + _Gimmick_Flat_Color_Emission * _Global_Emission_Factor, albedo.a);
  }
#endif

  float4 result = lit;
#if defined(_MATCAP0) || defined(_MATCAP1) || defined(_RIM_LIGHTING0) || defined(_RIM_LIGHTING1)
  result.rgb += matcap_emission * _Global_Emission_Factor;
#endif
#if defined(_DECAL0) || defined(_DECAL1) || defined(_DECAL2) || defined(_DECAL3)
  result.rgb += decal_emission * _Global_Emission_Factor;
#endif
#if defined(_GLITTER)
  result.rgb += glitter_color_unlit * _Glitter_Brightness;
#endif
#if defined(_EMISSION0)
  {
    float emission = _Emission0Tex.SampleBias(linear_repeat_s, get_uv_by_channel(i, round(_Emission0_UV_Select)), _Global_Sample_Bias);
    result.rgb += albedo.rgb * emission * _Emission0Strength *
      _Global_Emission_Factor * _Emission0Multiplier;
  }
#endif
#if defined(_EMISSION1)
  {
    float emission = _Emission1Tex.SampleBias(linear_repeat_s, get_uv_by_channel(i, round(_Emission1_UV_Select)), _Global_Sample_Bias);
    result.rgb += albedo.rgb * emission * _Emission1Strength *
      _Global_Emission_Factor * _Emission1Multiplier;
  }
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
#if defined(_RENDERING_TRANSPARENT) || defined(_RENDERING_TRANSCLIPPING)
  result.rgb *= result.a;
#endif
  result.rgb += getOverlayEmission(ov, i) * _Global_Emission_Factor;

  return result;
}

fixed4 frag(v2f i) : SV_Target
{
  UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
  return effect(i);
}

#endif  // TOONER_LIGHTING

