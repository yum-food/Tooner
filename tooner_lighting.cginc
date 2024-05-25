#ifndef TOONER_LIGHTING
#define TOONER_LIGHTING

#include "audiolink.cginc"
#include "clones.cginc"
#include "globals.cginc"
#include "interpolators.cginc"
#include "iq_sdf.cginc"
#include "math.cginc"
#include "motion.cginc"
#include "pbr.cginc"
#include "poi.cginc"
#include "shadertoy.cginc"
#include "tooner_scroll.cginc"
#include "oklab.cginc"

#if defined(_LTCGI)
#include "Third_Party/at.pimaker.ltcgi/Shaders/LTCGI_structs.cginc"

struct ltcgi_acc {
  float3 diffuse;
  float3 specular;
};

void ltcgi_cb_diffuse(inout ltcgi_acc acc, in ltcgi_output output);
void ltcgi_cb_specular(inout ltcgi_acc acc, in ltcgi_output output);

#define LTCGI_V2_CUSTOM_INPUT ltcgi_acc
#define LTCGI_V2_DIFFUSE_CALLBACK ltcgi_cb_diffuse
#define LTCGI_V2_SPECULAR_CALLBACK ltcgi_cb_specular

#include "Third_Party/at.pimaker.ltcgi/Shaders/LTCGI.cginc"
void ltcgi_cb_diffuse(inout ltcgi_acc acc, in ltcgi_output output) {
	acc.diffuse += output.intensity * output.color * _LTCGI_DiffuseColor;
}
void ltcgi_cb_specular(inout ltcgi_acc acc, in ltcgi_output output) {
	acc.specular += output.intensity * output.color * _LTCGI_SpecularColor;
}
#endif

struct tess_data
{
  float4 position : INTERNALTESSPOS;
  float2 uv : TEXCOORD0;
  #if defined(LIGHTMAP_ON)
  float2 lmuv : TEXCOORD1;
  #endif
  float3 normal : TEXCOORD2;
  float4 tangent : TEXCOORD3;

  #if defined(VERTEXLIGHT_ON)
  float3 vertexLightColor : TEXCOORD4;
  #endif
};

struct tess_factors {
  float edge[3] : SV_TessFactor;
  float inside : SV_InsideTessFactor;
};

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
  v2f o;

  UNITY_INITIALIZE_OUTPUT(v2f, o);
  UNITY_SETUP_INSTANCE_ID(v);
  UNITY_TRANSFER_INSTANCE_ID(v, o);
  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

  o.clipPos = UnityObjectToClipPos(v.position);
  o.worldPos = mul(unity_ObjectToWorld, v.position);
  o.objPos = v.position;

  o.normal = UnityObjectToWorldNormal(v.normal);
  o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
  o.uv = v.uv0.xy;
  #if defined(LIGHTMAP_ON)
  o.lmuv = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
  #endif

  getVertexLightColor(o);

  return o;
}

void getVertexLightColorTess(inout tess_data i)
{
  #if defined(VERTEXLIGHT_ON)
  float3 worldPos = mul(unity_ObjectToWorld, i.position).xyz;
  float3 view_dir = normalize(_WorldSpaceCameraPos - worldPos);
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
    unity_4LightAtten0, worldPos, flat ? flat_normal : i.normal
  );
  #endif
}

tess_data hull_vertex(appdata v)
{
  tess_data o;

  UNITY_INITIALIZE_OUTPUT(tess_data, o);
  UNITY_SETUP_INSTANCE_ID(v);
  UNITY_TRANSFER_INSTANCE_ID(v, o);
  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

  o.position = v.position;
  //o.position = UnityObjectToClipPos(v.position);
  //o.worldPos = mul(unity_ObjectToWorld, v.position);
  //o.objPos = v.position;

  o.normal = UnityObjectToWorldNormal(v.normal);
  o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
  o.uv = v.uv0.xy;
  #if defined(LIGHTMAP_ON)
  o.lmuv = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
  #endif

  getVertexLightColorTess(o);

  return o;
}

tess_factors patch_constant(InputPatch<tess_data, 3> patch)
{
  tess_factors f;

  float3 worldPos = mul(unity_ObjectToWorld, patch[0].position);
  float factor = _Tess_Factor;
  if (_Tess_Dist_Cutoff > 0 && length(_WorldSpaceCameraPos - worldPos) > _Tess_Dist_Cutoff) {
    factor = 1;
  }

  f.edge[0] = factor;
  f.edge[1] = factor;
  f.edge[2] = factor;
  f.inside = factor;
  return f;
}

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("fractional_odd")]
[UNITY_patchconstantfunc("patch_constant")]
tess_data hull(
    InputPatch<tess_data, 3> patch,
    uint id : SV_OutputControlPointID)
{
  return patch[id];
}

[UNITY_domain("tri")]
v2f domain(
    tess_factors factors,
    OutputPatch<tess_data, 3> patch,
    float3 baryc : SV_DomainLocation)
{
  v2f data;
#define DOMAIN_INTERP(fieldName) data.fieldName = \
  patch[0].fieldName * baryc.x + \
  patch[1].fieldName * baryc.y + \
  patch[2].fieldName * baryc.z;
  DOMAIN_INTERP(uv);
  #if defined(LIGHTMAP_ON)
  DOMAIN_INTERP(lmuv);
  #endif
  DOMAIN_INTERP(normal);
  DOMAIN_INTERP(tangent);

  #if defined(VERTEXLIGHT_ON)
  DOMAIN_INTERP(vertexLightColor);
  #endif

  float4 pos =
    patch[0].position * baryc.x +
    patch[1].position * baryc.y +
    patch[2].position * baryc.z;
  data.clipPos = UnityObjectToClipPos(pos);
  data.objPos = pos;
  data.worldPos = mul(unity_ObjectToWorld, pos);

  return data;
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
          rand((int) ((v0.uv.x + v0.uv.y) * 1E9)) * 2 - 1,
          rand((int) ((v1.uv.x + v1.uv.y) * 1E9)) * 2 - 1,
          rand((int) ((v2.uv.x + v2.uv.y) * 1E9)) * 2 - 1));
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
      v0.clipPos = UnityObjectToClipPos(v0_objPos);
      v1.clipPos = UnityObjectToClipPos(v1_objPos);
      v2.clipPos = UnityObjectToClipPos(v2_objPos);
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

    v0.clipPos = UnityObjectToClipPos(v0_objPos);
    v1.clipPos = UnityObjectToClipPos(v1_objPos);
    v2.clipPos = UnityObjectToClipPos(v2_objPos);
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

#if defined(_GLITTER)
float get_glitter(float2 uv, float iddx, float iddy, float3 worldPos, float3 normal)
{
  float pixellate = _Glitter_Density;
  float glitter = rand2(round(uv * pixellate) / pixellate + _Glitter_Seed);

  float thresh = 1 - _Glitter_Amount / 100;
  glitter = lerp(0, glitter, glitter > thresh);
  glitter = (glitter - thresh) / (1 - thresh);

  float b = sin(_Time[2] * _Glitter_Speed / 2 + glitter*100);
  glitter = max(glitter, 0)*max(b, 0);

  float mask = _Glitter_Mask.SampleGrad(linear_repeat_s, uv, iddx, iddy);
  glitter *= mask;

  glitter = clamp(glitter, 0, 1);
  glitter *= _Glitter_Brightness;

  if (_Glitter_Angle < 90) {
    float ndotl = abs(dot(normal, normalize(_WorldSpaceCameraPos.xyz - worldPos)));
    float cutoff = cos((_Glitter_Angle / 180) * 3.14159);

    glitter *= saturate(pow(ndotl / cutoff, _Glitter_Power));

    //glitter = ndotl > cutoff ? glitter : 0;
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

#define UV_SCOFF(uv, tex_st) (uv) * (tex_st).xy + (tex_st).zw

float4 effect(inout v2f i)
{
  float iddx = ddx(i.uv.x) / 4;
  float iddy = ddx(i.uv.y) / 4;
  const float3 view_dir = normalize(_WorldSpaceCameraPos - i.worldPos);

#if defined(_UVSCROLL)
  float2 orig_uv = i.uv;
  float uv_scroll_mask = round(_UVScroll_Mask.SampleGrad(linear_repeat_s, i.uv, iddx, iddy));
  i.uv += _Time[0] * float2(_UVScroll_U_Speed, _UVScroll_V_Speed) * uv_scroll_mask;
#endif

#if defined(_BASECOLOR_MAP)
  float4 albedo = _BaseColorTex.SampleGrad(linear_repeat_s, UV_SCOFF(i.uv, _BaseColorTex_ST), iddx, iddy);
  albedo *= _BaseColor;
#else
  float4 albedo = _BaseColor;
#endif  // _BASECOLOR_MAP

#if defined(_UVSCROLL)
  if (uv_scroll_mask) {
    float uv_scroll_alpha = _UVScroll_Alpha.SampleGrad(linear_repeat_s, orig_uv, iddx, iddy);
    albedo.a *= uv_scroll_alpha;
  }
#endif

#if defined(_RENDERING_CUTOUT)
#if defined(_RENDERING_CUTOUT_STOCHASTIC)
  float ar = rand2(i.uv);
  clip(albedo.a - ar);
#else
  clip(albedo.a - _Alpha_Cutoff);
#endif
  albedo.a = 1;
#endif

#if defined(_PBR_OVERLAY)
#if defined(_PBR_OVERLAY_BASECOLOR_MAP)
  float4 ov_albedo = _PBR_Overlay_BaseColorTex.SampleGrad(linear_repeat_s, UV_SCOFF(i.uv, _PBR_Overlay_BaseColorTex_ST), iddx, iddy);
  ov_albedo *= _PBR_Overlay_BaseColor;
#else
  float4 ov_albedo = _BaseColor;
#endif  // _PBR_OVERLAY_BASECOLOR_MAP

#if defined(_PBR_OVERLAY_MASK)
  float ov_mask = _PBR_Overlay_Mask.SampleGrad(linear_repeat_s, i.uv, iddx, iddy);
#else
  float ov_mask = 1;
#endif
  ov_albedo.a *= ov_mask;

#endif  // _PBR_OVERLAY

#if defined(_NORMAL_MAP)
  // Use UVs to smoothly blend between fully detailed normals when close up and
  // flat normals when far away. If we don't do this, then we see moire effects
  // on e.g. striped normal maps.
  float fw = clamp(fwidth(i.uv), .001, 1) * 1200;
  float3 raw_normal = UnpackScaleNormal(_NormalTex.SampleGrad(linear_repeat_s, UV_SCOFF(i.uv, _NormalTex_ST), iddx/2, iddy/2), _Tex_NormalStr);
  raw_normal = normalize(raw_normal);

  raw_normal = BlendNormals(
      (1/fw) * raw_normal,
      fw * float3(0, 0, 1));

#if defined(_PBR_OVERLAY) && defined(_PBR_OVERLAY_NORMAL_MAP)
  {
    // Use UVs to smoothly blend between fully detailed normals when close up and
    // flat normals when far away. If we don't do this, then we see moire effects
    // on e.g. striped normal maps.
    //float3 raw_normal = UnpackScaleNormal(_PBR_Overlay_NormalTex.SampleGrad(linear_repeat_s, i.uv, iddx/2, iddy/2), _PBR_Overlay_Tex_NormalStr);
    float3 raw_normal_2 = UnpackScaleNormal(_PBR_Overlay_NormalTex.SampleGrad(linear_repeat_s, UV_SCOFF(i.uv, _PBR_Overlay_NormalTex_ST), iddx/2, iddy/2), _PBR_Overlay_Tex_NormalStr * ov_albedo.a);

    raw_normal = BlendNormals(
        raw_normal,
        raw_normal_2);
  }
#endif  // _PBR_OVERLAY && _PBR_OVERLAY_NORMAL_MAP

  float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
	float3 normal = normalize(
		raw_normal.x * i.tangent +
		raw_normal.y * binormal +
		raw_normal.z * i.normal
	);
#else  // !_NORMAL_MAP
  float3 normal = i.normal;
#endif  // _NORMAL_MAP

#if defined(_METALLIC_MAP)
  float metallic = _MetallicTex.SampleGrad(linear_repeat_s, UV_SCOFF(i.uv, _MetallicTex_ST), iddx, iddy);
#else
  float metallic = _Metallic;
#endif
#if defined(_ROUGHNESS_MAP)
  float roughness = _RoughnessTex.SampleGrad(linear_repeat_s, UV_SCOFF(i.uv, _RoughnessTex_ST), iddx, iddy);
#else
  float roughness = _Roughness;
#endif
#if defined(VERTEXLIGHT_ON)
  float4 vertex_light_color = float4(i.vertexLightColor, 1);
#else
  float4 vertex_light_color = 0;
#endif

#if defined(_PBR_OVERLAY)
  albedo.rgb = lerp(albedo.rgb, ov_albedo.rgb, ov_albedo.a);
#endif  // _PBR_OVERLAY

#if defined(_MATCAP0) || defined(_MATCAP1) || defined(_RIM_LIGHTING0) || defined(_RIM_LIGHTING1)
  float3 matcap_emission = 0;
#endif

#if defined(_MATCAP0) || defined(_MATCAP1)
  {
    const float3 cam_normal = normalize(mul(UNITY_MATRIX_V, float4(normal, 0)));
    const float3 cam_view_dir = normalize(mul(UNITY_MATRIX_V, float4(view_dir, 0)));
    const float3 refl = -reflect(cam_view_dir, cam_normal);
    float m = 2.0 * sqrt(
        refl.x * refl.x +
        refl.y * refl.y +
        (refl.z + 1) * (refl.z + 1));
    float2 matcap_uv = refl.xy / m + 0.5;
    float iddx = ddx(i.uv.x);
    float iddy = ddy(i.uv.y);
    {
#if defined(_MATCAP0)
#if defined(_MATCAP0_DISTORTION0)
      float2 distort_uv = matcap_distortion0(matcap_uv);
      float2 matcap_uv = distort_uv;
#endif
      float3 matcap = _Matcap0.SampleGrad(linear_repeat_s, matcap_uv, iddx, iddy) * _Matcap0Str;

#if defined(_MATCAP0_MASK)
      float4 matcap_mask_raw = _Matcap0_Mask.SampleGrad(linear_repeat_s, i.uv.xy, iddx, iddy);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Matcap0_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif

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
#endif
    }
    {
#if defined(_MATCAP1)
#if defined(_MATCAP1_DISTORTION0)
      float2 distort_uv = matcap_distortion0(matcap_uv);
      float2 matcap_uv = distort_uv;
#endif
      float3 matcap = _Matcap1.SampleGrad(linear_repeat_s, matcap_uv, iddx, iddy) * _Matcap1Str;

#if defined(_MATCAP1_MASK)
      float4 matcap_mask_raw = _Matcap1_Mask.SampleGrad(linear_repeat_s, i.uv.xy, iddx, iddy);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Matcap1_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif

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
#endif  // _MATCAP1
    }
  }
#endif  // _MATCAP0 || _MATCAP1
#if defined(_RIM_LIGHTING0) || defined(_RIM_LIGHTING1)
  {
    // identity: (a, b, c) and (c, c, -(a +b)) are perpendicular to each other
    float theta = atan2(length(cross(view_dir, normal)), dot(view_dir, normal));
#define PI 3.14159265

#if defined(_RIM_LIGHTING0)
    {
      float rl = abs(theta) / PI;  // on [0, 1]
      rl = pow(2, -_Rim_Lighting0_Power * abs(rl - _Rim_Lighting0_Center));
      float3 matcap = rl * _Rim_Lighting0_Color * _Rim_Lighting0_Strength;
#if defined(_RIM_LIGHTING0_MASK)
      float4 matcap_mask_raw = _Rim_Lighting0_Mask.SampleGrad(linear_repeat_s, i.uv.xy, iddx, iddy);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Rim_Lighting0_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif
      int mode = round(_Rim_Lighting0_Mode);
      switch (mode) {
        case 0:
          albedo.rgb += lerp(0, matcap, matcap_mask);
          matcap_emission += lerp(0, matcap, matcap_mask) * _Rim_Lighting0_Emission;
          break;
        case 1:
          matcap_emission = albedo.rgb * lerp(1, matcap, matcap_mask) * _Rim_Lighting0_Emission;
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
      float3 matcap = rl * _Rim_Lighting1_Color * _Rim_Lighting1_Strength;
#if defined(_RIM_LIGHTING1_MASK)
      float4 matcap_mask_raw = _Rim_Lighting1_Mask.SampleGrad(linear_repeat_s, i.uv.xy, iddx, iddy);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Rim_Lighting1_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif
      int mode = round(_Rim_Lighting1_Mode);
      switch (mode) {
        case 0:
          albedo.rgb += lerp(0, matcap, matcap_mask);
          matcap_emission += lerp(0, matcap, matcap_mask) * _Rim_Lighting1_Emission;
          break;
        case 1:
          matcap_emission = albedo.rgb * lerp(1, matcap, matcap_mask) * _Rim_Lighting1_Emission;
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
  }
#endif  // _RIM_LIGHTING0 || _RIM_LIGHTING1

#if defined(_OKLAB)
  // Do hue shift in perceptually uniform color space so it doesn't look like
  // shit.
 float oklab_mask = _OKLAB_Mask.SampleGrad(linear_repeat_s, i.uv, iddx, iddy);
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

  float4 lit = getLitColor(vertex_light_color, albedo, i.worldPos, normal,
      metallic, 1.0 - roughness, i.uv, i);

  float4 result = lit;
#if defined(_MATCAP0) || defined(_MATCAP1) || defined(_RIM_LIGHTING0) || defined(_RIM_LIGHTING1)
  result.rgb += matcap_emission;
#endif
#if defined(_LTCGI)
  if ((bool) round(_LTCGI_Enabled)) {
    ltcgi_acc acc = (ltcgi_acc) 0;
    LTCGI_Contribution(
        acc,
        i.worldPos,
        normal,
        view_dir,
        roughness,
        0);
    float3 ltcgi_emission = 0;
    ltcgi_emission += clamp(acc.diffuse * albedo.rgb, 0, 2);
    result.rgb += ltcgi_emission;
  }
#endif
#if defined(_GLITTER)
  float glitter = get_glitter(i.uv, iddx, iddy, i.worldPos, normal);
  result.rgb += glitter;
#endif
#if defined(_EMISSION)
  float emission = _EmissionTex.SampleGrad(linear_repeat_s, i.uv, iddx, iddy);
  result.rgb += albedo.rgb * emission * _EmissionStrength;
#endif
#if defined(_EXPLODE) && defined(_AUDIOLINK)
  if (AudioLinkIsAvailable() && _Explode_Phase > 1E-6) {
    float4 al_color =
      AudioLinkData(
          ALPASS_CCLIGHTS +
          uint2(uint(i.uv.x * 8) + uint(i.uv.y * 16) * 8, 0 )).rgba;
    result = lerp(result, al_color, _Explode_Phase * _Explode_Phase);
  }
#endif

  return result;
}

fixed4 frag(v2f i) : SV_Target
{
  return effect(i);
}

#endif  // TOONER_LIGHTING

