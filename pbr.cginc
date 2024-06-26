#ifndef __PBR_INC
#define __PBR_INC

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

#include "globals.cginc"
#include "interpolators.cginc"
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

UnityLight CreateDirectLight(float3 normal, float ao, v2f i)
{
#if 1
  // This whole block is yoinked from AutoLight.cginc. I needed a way to
  // control shadow strength so I had to duplicate the code.
#if defined(DIRECTIONAL_COOKIE)
  DECLARE_LIGHT_COORD(i, i.worldPos);
  float shadow = UNITY_SHADOW_ATTENUATION(i, i.worldPos);
  float attenuation = tex2D(_LightTexture0, lightCoord).w;
#elif defined(POINT_COOKIE)
  DECLARE_LIGHT_COORD(i, i.worldPos);
  float shadow = UNITY_SHADOW_ATTENUATION(i, i.worldPos);
  float attenuation = tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).r *
    texCUBE(_LightTexture0, lightCoord).w;
#elif defined(DIRECTIONAL)
  float shadow = UNITY_SHADOW_ATTENUATION(i, i.worldPos);
  float attenuation = 1;
#elif defined(SPOT)
  DECLARE_LIGHT_COORD(i, i.worldPos);
  float shadow = UNITY_SHADOW_ATTENUATION(i, i.worldPos);
  float attenuation = (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);
#elif defined(POINT)
  unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(i.worldPos, 1)).xyz;
  float shadow = UNITY_SHADOW_ATTENUATION(i, i.worldPos);
  float attenuation = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).r;
#else
  float shadow = 1;
  float attenuation = 1;
#endif
  attenuation *= lerp(1, shadow, _Shadow_Strength);
#else
  UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
#endif

  UnityLight light;
  light.color = _LightColor0.rgb * attenuation * ao;
#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
  light.dir = normalize((_WorldSpaceLightPos0 - i.worldPos).xyz);
#else
  light.dir = _WorldSpaceLightPos0;
#endif

  if (round(_Confabulate_Normals)) {
    light.dir = normal;
  }
  light.ndotl = DotClamped(normal, light.dir);

  return light;
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
		UNITY_BRANCH
		if (cubemapPosition.w > 0) {
			float3 factors =
				((direction > 0 ? boxMax : boxMin) - position) / direction;
			float scalar = min(min(factors.x, factors.y), factors.z);
			direction = direction * scalar + (position - cubemapPosition);
		}
	#endif
	return direction;
}

UnityIndirect CreateIndirectLight(float4 vertexLightColor, float3 view_dir, float3 normal,
    float smoothness, float3 worldPos, float ao, float2 uv) {
  UnityIndirect indirect;
  indirect.diffuse = vertexLightColor;
  indirect.specular = 0;

#if defined(FORWARD_BASE_PASS)

#if defined(LIGHTMAP_ON)
  // Avatars are not static, don't use lightmap.
  indirect.diffuse = 0;
#else
  indirect.diffuse += max(0, ShadeSH9(float4(normal, 1)));
#endif
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
  env_data.reflUVW = BoxProjection(
      reflect_dir, worldPos,
      unity_SpecCube1_ProbePosition,
      unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax
      );
#if UNITY_SPECCUBE_BLENDING
  float interpolator = unity_SpecCube0_BoxMin.w;
  UNITY_BRANCH
    if (interpolator < 0.99999) {
      float3 probe1 = Unity_GlossyEnvironment(
          UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
          unity_SpecCube0_HDR, env_data
          );
      indirect.specular = lerp(probe1, probe0, interpolator);
    }
    else {
      indirect.specular = probe0;
    }
#else
  indirect.specular = probe0;
#endif  // UNITY_SPECCUBE_BLENDING

#if defined(_CUBEMAP)
  float roughness = GetRoughness(smoothness);
  probe0 =
    UNITY_SAMPLE_TEXCUBE_LOD(
        _Cubemap,
        reflect_dir,
        roughness * UNITY_SPECCUBE_LOD_STEPS);
#endif  // _CUBEMAP

  indirect.specular = probe0;
#endif  // FORWARD_BASE_PASS

  indirect.diffuse *= ao;

  return indirect;
}

float4 getLitColor(
    float4 vertexLightColor,
    float4 albedo,
    float3 worldPos,
    float3 normal,
    float metallic, float smoothness, float2 uv, float ao,
    v2f i)
{
  float3 specular_tint;
  float one_minus_reflectivity;
  albedo.rgb = DiffuseAndSpecularFromMetallic(
    albedo, metallic, specular_tint, one_minus_reflectivity);

  float3 view_dir = normalize(_WorldSpaceCameraPos - worldPos);

  uint normals_mode = round(_Mesh_Normals_Mode);
  bool flat = (normals_mode == 0);
  float3 flat_normal = normalize(
    (1.0 / _Flatten_Mesh_Normals_Str) * normal +
    _Flatten_Mesh_Normals_Str * view_dir);
  float3 spherical_normal = normalize(UnityObjectToWorldNormal(normalize(i.objPos)));
  normal = lerp(spherical_normal, flat_normal, flat);

	UnityIndirect indirect_light = CreateIndirectLight(vertexLightColor,
			view_dir, normal, smoothness, worldPos, ao, uv);

  UnityLight direct_light = CreateDirectLight(normal, ao, i);
  if (flat) {
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
        1.0 - smoothness,
        0);
    direct_light.color += acc.diffuse;
    direct_light.color += acc.specular;
    indirect_light.diffuse += acc.diffuse;
    indirect_light.specular += acc.specular;
  }
#endif

  direct_light.color = clamp(direct_light.color, _Min_Brightness, _Max_Brightness*.5);
  indirect_light.diffuse = clamp(indirect_light.diffuse, _Min_Brightness, _Max_Brightness);
  indirect_light.specular = clamp(indirect_light.specular, _Min_Brightness, _Max_Brightness);

  float3 pbr;
  if (round(_Confabulate_Normals)) {
    pbr = UNITY_BRDF_PBS(
        albedo,
        specular_tint,
        one_minus_reflectivity,
        smoothness,
        view_dir,
        normal,
        direct_light,
        indirect_light).xyz;
  } else {
    pbr = UNITY_BRDF_PBS(
        albedo,
        specular_tint,
        one_minus_reflectivity,
        smoothness,
        normal,
        view_dir,
        direct_light,
        indirect_light).xyz;
  }

#if defined(_LTCGI)
  pbr.rgb += (acc.specular + acc.diffuse) * metallic;
#endif

  return float4(pbr, albedo.a);
}

#endif  // __PBR_INC

