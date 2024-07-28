#ifndef __PBR_INC
#define __PBR_INC

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

#include "globals.cginc"
#include "filament_math.cginc"
#include "globals.cginc"
#include "interpolators.cginc"
#include "MochieStandardBRDF.cginc"
#include "poi.cginc"

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
#endif  // __LTCGI

UNITY_DECLARE_TEXCUBE(_Cubemap);

float getShadowAttenuation(v2f i)
{
  float attenuation;
  // This whole block is yoinked from AutoLight.cginc. I needed a way to
  // control shadow strength so I had to duplicate the code.
#if defined(DIRECTIONAL_COOKIE)
  DECLARE_LIGHT_COORD(i, i.worldPos);
  float shadow = UNITY_SHADOW_ATTENUATION(i, i.worldPos);
  attenuation = tex2D(_LightTexture0, lightCoord).w;
#elif defined(POINT_COOKIE)
  DECLARE_LIGHT_COORD(i, i.worldPos);
  float shadow = UNITY_SHADOW_ATTENUATION(i, i.worldPos);
  attenuation = tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).r *
    texCUBE(_LightTexture0, lightCoord).w;
#elif defined(DIRECTIONAL)
  float shadow = UNITY_SHADOW_ATTENUATION(i, i.worldPos);
  attenuation = 1;
#elif defined(SPOT)
  DECLARE_LIGHT_COORD(i, i.worldPos);
  float shadow = UNITY_SHADOW_ATTENUATION(i, i.worldPos);
  attenuation = (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);
#elif defined(POINT)
  unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(i.worldPos, 1)).xyz;
  float shadow = UNITY_SHADOW_ATTENUATION(i, i.worldPos);
  attenuation = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).r;
#else
  float shadow = 1;
  attenuation = 1;
#endif
  attenuation *= lerp(1, shadow, _Shadow_Strength);
  return attenuation;
}

float3 getDirectLightDirection(v2f i) {
#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
  return normalize((_WorldSpaceLightPos0 - i.worldPos).xyz);
#else
  return _WorldSpaceLightPos0;
#endif
}

float3 getDirectLightColor()
{
  return _LightColor0.rgb;
}

float GetRoughness(float smoothness) {
  float r = 1 - smoothness;
  r *= 1.7 - 0.7 * r;
  return r;
}

float3 BoxProjection (
	float3 direction, float3 position,
	float4 cubemapPosition, float3 boxMin, float3 boxMax
) {
	#if UNITY_SPECCUBE_BOX_PROJECTION
		if (cubemapPosition.w > 0) {
			float3 factors =
				((direction > 0 ? boxMax : boxMin) - position) / direction;
			float scalar = min(min(factors.x, factors.y), factors.z);
			direction = direction * scalar + (position - cubemapPosition.xyz);
		}
	#endif
	return direction;
}

float4 getIndirectDiffuse(float4 vertexLightColor, float3 normal) {
  float4 diffuse = vertexLightColor;
  if (_Mesh_Normals_Mode == 3) {  // Toon
    diffuse.xyz += max(0, BetterSH9(float4(0, 0, 0, 1)));
  } else {
    diffuse.xyz += max(0, BetterSH9(float4(normal, 1)));
  }
  return diffuse;
}

float3 getIndirectSpecular(float3 view_dir, float3 normal,
    float smoothness, float3 worldPos, float2 uv) {
  float3 specular = 0;

#if defined(FORWARD_BASE_PASS)
  float3 reflect_dir = reflect(-view_dir, normal);
  Unity_GlossyEnvironmentData env_data;
  env_data.roughness = GetRoughness(smoothness);
  env_data.reflUVW = BoxProjection(
    reflect_dir, worldPos,
    unity_SpecCube0_ProbePosition,
    unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
  );
  float3 probe0 = Unity_GlossyEnvironment(
      UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, env_data
      );
  specular = probe0;
#if UNITY_SPECCUBE_BLENDING
  if (unity_SpecCube0_BoxMin.w < 0.99999) {
    env_data.reflUVW = BoxProjection(
        reflect_dir, worldPos,
        unity_SpecCube1_ProbePosition,
        unity_SpecCube1_BoxMin.xyz, unity_SpecCube1_BoxMax.xyz);
    float3 probe1 = Unity_GlossyEnvironment(
        UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
        unity_SpecCube1_HDR, env_data
        );
    specular = lerp(probe1, probe0, unity_SpecCube0_BoxMin.w);
  }
#endif  // UNITY_SPECCUBE_BLENDING

  // Lifted from poi toon shader (MIT).
  float horizon = min(1 + dot(reflect_dir, normal), 1);
  specular *= horizon * horizon;

#if defined(_CUBEMAP)
  float roughness = GetRoughness(smoothness);
  specular =
    UNITY_SAMPLE_TEXCUBE_LOD(
        _Cubemap,
        reflect_dir,
        roughness * UNITY_SPECCUBE_LOD_STEPS);
#endif  // _CUBEMAP

#endif  // FORWARD_BASE_PASS

  return specular;
}

float4 getLitColor(
    float4 vertexLightColor,
    float4 albedo,
    float3 worldPos,
    float3 normal,
    float metallic,
    float smoothness,
    float2 uv,
    float ao,
    // hack while i figure out view-dependent flickering in outlines
    bool enable_direct,
    v2f i)
{
  float3 specular_tint;
  float one_minus_reflectivity;
  albedo.rgb = DiffuseAndSpecularFromMetallic(
    albedo, metallic, specular_tint, one_minus_reflectivity);

  float3 view_dir = normalize(_WorldSpaceCameraPos - worldPos);

  uint normals_mode = round(_Mesh_Normals_Mode);
  float3 flat_normal = normalize(
    (1.0 / _Flatten_Mesh_Normals_Str) * normal +
    _Flatten_Mesh_Normals_Str * view_dir);
  float3 spherical_normal = normalize(UnityObjectToWorldNormal(normalize(i.objPos)));
  normal = lerp(normal, flat_normal, normals_mode == 0);
  normal = lerp(normal, spherical_normal, normals_mode == 1);

	UnityIndirect indirect_light;
  vertexLightColor *= _Vertex_Lighting_Factor;
  indirect_light.diffuse = getIndirectDiffuse(vertexLightColor, normal);
  indirect_light.specular = getIndirectSpecular(view_dir, normal, smoothness,
      worldPos, uv);

  float attenuation;
  UnityLight direct_light;
  direct_light.dir = getDirectLightDirection(i);
  direct_light.ndotl = DotClamped(normal, direct_light.dir);
  float shadow_attenuation = getShadowAttenuation(i);
#define POI_LIGHTING
#if defined(POI_LIGHTING)
  direct_light.color = getPoiLightingDirect(normal) * shadow_attenuation;
#else
  direct_light.color = getDirectLightColor() * shadow_attenuation;
#endif

  if (normals_mode == 0) {
    float e = 0.8;
    indirect_light.diffuse += direct_light.color * e;
    direct_light.color *= (1 - e);
  }

#if defined(_LTCGI)
  ltcgi_acc acc = (ltcgi_acc) 0;
  if ((bool) round(_LTCGI_Enabled)) {
    LTCGI_Contribution(
        acc,
        i.worldPos,
        normal,
        view_dir,
        GetRoughness(smoothness),
        0);
    indirect_light.diffuse += acc.diffuse;
    indirect_light.specular += acc.specular;
  }
#endif

  if (_Reflection_Probe_Saturation < 1.0) {
    direct_light.color = RGBtoHSV(direct_light.color);
    direct_light.color[1] *= _Reflection_Probe_Saturation;
    direct_light.color = HSVtoRGB(direct_light.color);
    indirect_light.specular = RGBtoHSV(indirect_light.specular);
    indirect_light.specular[1] *= _Reflection_Probe_Saturation;
    indirect_light.specular = HSVtoRGB(indirect_light.specular);
    indirect_light.diffuse = RGBtoHSV(indirect_light.diffuse);
    indirect_light.diffuse[1] *= _Reflection_Probe_Saturation;
    indirect_light.diffuse = HSVtoRGB(indirect_light.diffuse);
  }

  direct_light.color = clamp(direct_light.color, _Min_Brightness, _Max_Brightness);
  indirect_light.diffuse = clamp(indirect_light.diffuse, _Min_Brightness, _Max_Brightness);
  indirect_light.specular = clamp(indirect_light.specular, _Min_Brightness, _Max_Brightness);

  // TODO move back before clamping
  direct_light.color *= _Lighting_Factor * _Direct_Lighting_Factor * enable_direct;
  indirect_light.specular *= _Lighting_Factor * _Indirect_Specular_Lighting_Factor;
  indirect_light.diffuse *= _Lighting_Factor * _Indirect_Diffuse_Lighting_Factor;

  // Apply AO
  indirect_light.diffuse *= ao;
  float3 direct_color = direct_light.color;
  direct_light.color *= ao;

  float2 screenUVs = 0;
  float4 screenPos = 0;
#if 1
  float4 pbr = BRDF1_Mochie_PBS(
      albedo,
      specular_tint,
      one_minus_reflectivity,
      smoothness,
      normal,
      view_dir,
      i.worldPos,
      screenUVs,
      screenPos,
      metallic,
      /*thickness=*/1,
      /*ssColor=*/0,
      shadow_attenuation,
      /*lightmapUV=*/0,
      vertexLightColor,
      direct_light,
      indirect_light);
#else
    float3 pbr = UNITY_BRDF_PBS(
        albedo,
        specular_tint,
        one_minus_reflectivity,
        smoothness,
        normal,
        view_dir,
        direct_light,
        indirect_light).xyz;
#endif

#if defined(_CLEARCOAT)
    // Direct lighting
    float cc_mask = _Clearcoat_Mask.SampleGrad(linear_repeat_s, i.uv, ddx(i.uv.x), ddy(i.uv.y));
    {
      float3 cc_L = direct_light.dir;
      half3 cc_H = Unity_SafeNormalize(cc_L + view_dir);
      half cc_LoH = saturate(dot(direct_light.dir, cc_H));
      float3 cc_N = normalize(i.normal);
      half cc_NoH = saturate(dot(i.normal, cc_H));
      float clearcoat = FilamentClearcoat(
          _Clearcoat_Roughness,
          _Clearcoat_Strength,
          cc_NoH,
          cc_LoH,
          cc_H);
      pbr.rgb += clearcoat * saturate(dot(i.normal, cc_L)) *
        cc_mask * direct_color * _Direct_Lighting_Factor;
    }
    // Indirect specular lighting
#if 1
    {
      float3 in_L = normalize(reflect(-view_dir, i.normal));
      half3 in_H = i.normal;
      half in_LoH = saturate(dot(in_L, in_H));
      half in_NoH = 1;
      float clearcoat = FilamentClearcoat(
          _Clearcoat_Roughness,
          _Clearcoat_Strength,
          in_NoH,
          in_LoH,
          in_H);
      pbr.rgb += clearcoat * saturate(dot(i.normal, in_L)) *
        cc_mask * indirect_light.specular * _Indirect_Specular_Lighting_Factor;
    }
#endif
#if defined(VERTEXLIGHT_ON)
    // Vertex lights
    for (uint ii = 0; ii < 4; ii++) {
      float3 vpos = float3(unity_4LightPosX0[ii], unity_4LightPosY0[ii],
          unity_4LightPosZ0[ii]);
      float3 vl = normalize(vpos - i.worldPos);
      float3 c = unity_LightColor[0].rgb;

      half3 vhalf = Unity_SafeNormalize(half3(vl) + view_dir);
      half vlh = saturate(dot(vl, vhalf));
      half cc_vnh = saturate(dot(i.normal, vhalf));

      float clearcoat = FilamentClearcoat(
          _Clearcoat_Roughness,
          _Clearcoat_Strength,
          cc_vnh,
          vlh,
          vhalf);
      pbr.rgb += clearcoat * saturate(dot(i.normal, vl)) *
        cc_mask * c * _Vertex_Lighting_Factor;
    }
#endif
#endif

  return float4(pbr.rgb, albedo.a);
}

#endif  // __PBR_INC

