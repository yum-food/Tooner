#ifndef __PBR_INC
#define __PBR_INC

#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"

#include "globals.cginc"
#include "interpolators.cginc"
#include "poi.cginc"

UNITY_DECLARE_TEXCUBE(_Cubemap);

UnityLight CreateDirectLight(float3 normal, v2f i)
{
  UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
  UnityLight light;
  light.color = _LightColor0.rgb * attenuation;
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
    float smoothness, float3 worldPos, float2 uv) {
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

  return indirect;
}

float4 getLitColor(
    float4 vertexLightColor,
    float4 albedo,
    float3 worldPos,
    float3 normal,
    float metallic, float smoothness, float2 uv, v2f i)
{
  float3 specular_tint;
  float one_minus_reflectivity;
  albedo.rgb = DiffuseAndSpecularFromMetallic(
    albedo, metallic, specular_tint, one_minus_reflectivity);

  float3 view_dir = normalize(_WorldSpaceCameraPos - worldPos);

  bool flat = round(_Flatten_Mesh_Normals) == 1.0;
	UnityIndirect indirect_light = CreateIndirectLight(vertexLightColor,
			view_dir, flat ? view_dir : normal, smoothness, worldPos, uv);

  UnityLight direct_light = CreateDirectLight(normal, i);
  if (flat) {
    float e = 0.8;
    indirect_light.diffuse += direct_light.color * e;
    direct_light.color *= (1 - e);
  }

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
        flat ? view_dir : normal,
        direct_light,
        indirect_light).xyz;
  } else {
    pbr = UNITY_BRDF_PBS(
        albedo,
        specular_tint,
        one_minus_reflectivity,
        smoothness,
        flat ? view_dir : normal,
        view_dir,
        direct_light,
        indirect_light).xyz;
  }

  return float4(pbr, albedo.a);
}

#endif  // __PBR_INC

