#ifndef __TOONER_OUTLINE_PASS
#define __TOONER_OUTLINE_PASS

#define _OUTLINE_INTERPOLATORS

#include "audiolink.cginc"
#include "clones.cginc"
#include "globals.cginc"
#include "math.cginc"
#include "pbr.cginc"
#include "tooner_scroll.cginc"
#include "UnityCG.cginc"

struct tess_data
{
  float4 vertex : INTERNALTESSPOS;
  float2 uv : TEXCOORD0;
  float3 normal : TEXCOORD2;
};

struct tess_factors {
  float edge[3] : SV_TessFactor;
  float inside: SV_InsideTessFactor;
};

v2f vert(appdata v)
{
#if defined(_OUTLINES)
  float outline_mask = _Outline_Mask.SampleLevel(linear_repeat_s, v.uv0.xy, /*lod=*/1);
  outline_mask = _Outline_Mask_Invert > 1E-6 ? 1 - outline_mask : outline_mask;

  float4 position = v.vertex;
#if !defined(_WORLD_SPACE_SCALING)
#if defined(_EXPLODE)
  if (_Explode_Phase <= 1E-6) {
    position.xyz += v.normal * _Outline_Width * .1 * outline_mask;
  }
#else
  position.xyz += v.normal * _Outline_Width * .1 * outline_mask;
#endif
#endif

  position = mul(unity_ObjectToWorld, position);
  const float3 normal = UnityObjectToWorldNormal(v.normal);

#if defined(_WORLD_SPACE_SCALING)
  // Perform scaling operation in world space so that object scale doesn't
  // affect outline width. This is handy on avatars with a bunch of different
  // gameobjects that have different scale.
#if defined(_EXPLODE)
  if (_Explode_Phase <= 1E-6) {
    position.xyz += normal * _Outline_Width * .1 * outline_mask;
  }
#else
  position.xyz += normal * _Outline_Width * .1 * outline_mask;
#endif
#endif

  // Transform back to object, then clip.
  position = mul(unity_WorldToObject, position);
  v.vertex.xyz = position.xyz;

  v2f o;
  o.worldPos = mul(unity_ObjectToWorld, v.vertex);
  o.objPos = v.vertex;
  o.pos = UnityObjectToClipPos(v.vertex);
  o.normal = normal;
  o.uv = v.uv0.xy;
  #if defined(LIGHTMAP_ON)
  o.lmuv = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw
  #endif

  return o;
#else
  v2f o;
  o.worldPos = 0;
  o.objPos = 0;
  o.pos = 0;
  o.normal = 0;
  o.uv = 0;
#if defined(LIGHTMAP_ON)
  o.lmuv = 0;
#endif
  return o;
#endif  // _OUTLINES
}

tess_data hull_vertex(appdata v)
{
#if defined(_OUTLINES)
  float outline_mask = _Outline_Mask.SampleLevel(linear_repeat_s, v.uv0.xy, /*lod=*/3);
  outline_mask = _Outline_Mask_Invert > 1E-6 ? 1 - outline_mask : outline_mask;

  float4 position = v.vertex;
  position = mul(unity_ObjectToWorld, position);
  const float3 normal = UnityObjectToWorldNormal(v.normal);

  // Perform scaling operation in world space so that object scale doesn't
  // affect outline width. This is handy on avatars with a bunch of different
  // gameobjects that have different scale.
#if defined(_EXPLODE)
  if (_Explode_Phase <= 1E-6) {
    position.xyz += normal * _Outline_Width * .1 * outline_mask;
  }
#else
  position.xyz += normal * _Outline_Width * .1 * outline_mask;
#endif

  // Transform back to object, then clip.
  position = mul(unity_WorldToObject, position);
  v.vertex.xyz = position.xyz;

  tess_data o;
  o.vertex = v.vertex;
  o.normal = normal;
  o.uv = v.uv0.xy;

  return o;
#endif  // _OUTLINES
}

tess_factors patch_constant(InputPatch<tess_data, 3> patch)
{
  tess_factors f;

#if defined(_TESSELLATION)
  float3 worldPos = mul(unity_ObjectToWorld, patch[0].vertex);
  float factor = _Tess_Factor;
  if (_Tess_Dist_Cutoff > 0 && length(_WorldSpaceCameraPos - worldPos) > _Tess_Dist_Cutoff) {
    factor = 1;
  }
#else
  float factor = 1;
#endif

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
  DOMAIN_INTERP(normal);
  //DOMAIN_INTERP(tangent);

  #if defined(VERTEXLIGHT_ON)
  DOMAIN_INTERP(vertexLightColor);
  #endif

  float4 pos =
    patch[0].vertex * baryc.x +
    patch[1].vertex * baryc.y +
    patch[2].vertex * baryc.z;
  data.pos = UnityObjectToClipPos(pos);
  data.objPos = pos;
  data.worldPos = mul(unity_ObjectToWorld, pos);

  return data;
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
#if !defined(_OUTLINES)
  return;
#endif

  v2f v0 = tri_in[0];
  v2f v1 = tri_in[1];
  v2f v2 = tri_in[2];

  float3 v0_objPos;
  float3 v1_objPos;
  float3 v2_objPos;

  float3 n = normalize(cross(v1.worldPos - v0.worldPos, v2.worldPos - v0.worldPos));
  float3 avg_pos;
#if defined(_EXPLODE)
  float3 n0 = v0.normal;
  float3 n1 = v1.normal;
  float3 n2 = v2.normal;

  float phase = _Explode_Phase;
  phase = smoothstep(0, 1, phase);
  phase *= phase;
  phase *= 4;

  if (phase > 1E-6) {
    const float pid_rand = rand((int) pid);

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

    float r = rand((int) pid);
    float theta = phase * 3.14159 * 4 + phase * (sin(_Time[1] * (1 + pid_rand) / 2.0 + r) + cos(_Time[1] * (1 + pid_rand) / 6.1 + r) * 2) * pid_rand * 2;
    float4 quat = get_quaternion(axis, theta);
    v0.worldPos = rotate_vector(v0.worldPos, quat);
    v1.worldPos = rotate_vector(v1.worldPos, quat);
    v2.worldPos = rotate_vector(v2.worldPos, quat);

    //v0.worldPos *= 1.1;
    //v1.worldPos *= 1.1;
    //v2.worldPos *= 1.1;

    v0.worldPos += avg_pos;
    v1.worldPos += avg_pos;
    v2.worldPos += avg_pos;

    float3 nn = normalize(cross(v1.worldPos - v0.worldPos, v2.worldPos - v0.worldPos));
    v0.worldPos -= nn * .0005;
    v1.worldPos -= nn * .0005;
    v2.worldPos -= nn * .0005;

    v0.normal = nn;
    v1.normal = nn;
    v2.normal = nn;

    // Omit geometry that's too close when exploded.
    /*
    if (_Explode_Phase > .05 && length(v0.worldPos - _WorldSpaceCameraPos) < .2) {
      return;
    }
    */

    // Apply transformed worldPos to other coordinate systems.
    v0_objPos = mul(unity_WorldToObject, float4(v0.worldPos, 1));
    v1_objPos = mul(unity_WorldToObject, float4(v1.worldPos, 1));
    v2_objPos = mul(unity_WorldToObject, float4(v2.worldPos, 1));

    v0.pos = UnityObjectToClipPos(v0_objPos);
    v1.pos = UnityObjectToClipPos(v1_objPos);
    v2.pos = UnityObjectToClipPos(v2_objPos);
  }
#endif
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

fixed4 frag (v2f i) : SV_Target
{
#if defined(_OUTLINES)
  float iddx = ddx(i.uv.x) / 4;
  float iddy = ddx(i.uv.y) / 4;
#if defined(_BASECOLOR_MAP)
  float4 albedo = _BaseColorTex.SampleGrad(linear_repeat_s, i.uv, iddx, iddy);
  albedo *= _BaseColor;
#else
  float4 albedo = _BaseColor;
#endif  // _BASECOLOR_MAP

#if defined(_RENDERING_CUTOUT)
  clip(albedo.a - _Alpha_Cutoff);
#endif

  // TODO FIXME the normals are fucked in pbr pass, causing flickering
  //return _Outline_Color;

  //float3 flat_normal = normalize(UnpackNormal(float4(128, 128, 255, 255)/255));
  float3 flat_normal = normalize(_WorldSpaceCameraPos - i.worldPos);
  float4 vertex_light_color = 0;
  float ao = 1;
  float4 result = getLitColor(
      vertex_light_color,
      _Outline_Color, i.worldPos, flat_normal, 0, 0, i.uv, ao, i);

  result += _Outline_Color * _Outline_Emission_Strength;

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
#else
  discard;
  return 0;
#endif  // _OUTLINES
}

#endif  // __TOONER_OUTLINE_PASS

