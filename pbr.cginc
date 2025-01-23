#include "atrix256.cginc"
#include "globals.cginc"
#include "ltcgi.cginc"
#include "filament_math.cginc"
#include "globals.cginc"
#include "interpolators.cginc"
#include "math.cginc"
#include "MochieStandardBRDF.cginc"
#include "poi.cginc"
#include "tone.cginc"

#ifndef __PBR_INC
#define __PBR_INC

UNITY_DECLARE_TEXCUBE(_Cubemap);
half4 _Cubemap_HDR;
float _Cubemap_Limit_To_Metallic;

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

float4 getIndirectDiffuse(v2f i, float4 vertexLightColor) {
  float4 diffuse = vertexLightColor;
#if defined(FORWARD_BASE_PASS)
#if defined(LIGHTMAP_ON)
  diffuse.xyz = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv2));
#else
  diffuse.xyz += max(0, BetterSH9(float4(0, 0, 0, 1)));
#endif
#endif
  return diffuse;
}

float4 getIndirectDiffuse(v2f i, float4 vertexLightColor, float3 normal) {
  float4 diffuse = vertexLightColor;
#if defined(FORWARD_BASE_PASS)
#if defined(LIGHTMAP_ON)
  diffuse.xyz = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv2));
#else
  if (_Mesh_Normals_Mode == 3) {  // Toon
    diffuse.xyz += max(0, BetterSH9(float4(0, 0, 0, 1)));
  } else {
    diffuse.xyz += max(0, BetterSH9(float4(normal, 1)));
  }
#endif
#endif
  return diffuse;
}

float3 getIndirectSpecular(v2f i, float3 view_dir, float3 normal,
    float smoothness, float metallic, float3 worldPos) {
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

#if defined(_CUBEMAP)
#if 0
  float3 specular_tmp =
    UNITY_SAMPLE_TEXCUBE_LOD(
        _Cubemap,
        reflect_dir,
        roughness * UNITY_SPECCUBE_LOD_STEPS);
#else
  env_data.reflUVW = BoxProjection(
    reflect_dir, worldPos,
    unity_SpecCube0_ProbePosition,
    unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
  );
  float3 specular_tmp = Unity_GlossyEnvironment(
      UNITY_PASS_TEXCUBE(_Cubemap), _Cubemap_HDR, env_data);
#endif
  if (_Cubemap_Limit_To_Metallic) {
    specular = lerp(specular, specular_tmp, metallic);
  } else {
    specular = specular_tmp;
  }
#endif  // _CUBEMAP

  // Lifted from poi toon shader (MIT).
  float horizon = min(1 + dot(reflect_dir, normal), 1);
  specular *= horizon * horizon;

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
    float3 diffuse_contrib,
    v2f i,
    ToonerData tdata)
{
  float3 specular_tint;
  float one_minus_reflectivity;
  albedo.rgb = DiffuseAndSpecularFromMetallic(
    albedo, metallic, specular_tint, one_minus_reflectivity);

  const float3 view_dir = normalize(_WorldSpaceCameraPos - worldPos);
  uint normals_mode = round(_Mesh_Normals_Mode);
  switch (normals_mode) {
    case 0:
      {
        float3 flat_normal = normalize(
            (1.0 / _Flatten_Mesh_Normals_Str) * normal +
            _Flatten_Mesh_Normals_Str * view_dir);
        normal = flat_normal;
      }
      break;
    case 1:
      {
        float3 spherical_normal = normalize(UnityObjectToWorldNormal(normalize(i.objPos)));
        normal = spherical_normal;
      }
      break;
    default:
      break;
  }

	UnityIndirect indirect_light;
  vertexLightColor *= _Vertex_Lighting_Factor;


#if defined(LIGHTMAP_ON)
  UNITY_LIGHT_ATTENUATION(shadow_attenuation, i, i.worldPos);
#else
  float shadow_attenuation = getShadowAttenuation(i);
#endif

  UnityLight direct_light;
  direct_light.color = 0;
  {
    direct_light.dir = getDirectLightDirection(i);
    direct_light.ndotl = DotClamped(normal, direct_light.dir);
//#define POI_LIGHTING
#if defined(POI_LIGHTING)
    direct_light.color = getPoiLightingDirect(normal);
#else
    direct_light.color = getDirectLightColor();
#endif
    indirect_light.diffuse = getIndirectDiffuse(i, vertexLightColor, normal) + diffuse_contrib;
    indirect_light.specular = getIndirectSpecular(i, view_dir, normal,
        smoothness, metallic, worldPos);
  }

  if (normals_mode == 0) {
    float e = 0.8;
    indirect_light.diffuse += direct_light.color * e;
    direct_light.color *= (1 - e);
  }

#if defined(_LTCGI)
#if !defined(LIGHTMAP_ON) && !defined(_FORCE_WORLD_LIGHTING)
  ltcgi_acc acc = (ltcgi_acc) 0;
  if (_LTCGI_Enabled_Dynamic) {
    LTCGI_Contribution(
        acc,
        i.worldPos,
        normal,
        view_dir,
        GetRoughness(smoothness),
        i.uv2);
    indirect_light.diffuse += acc.diffuse * _LTCGI_Strength;
    indirect_light.specular += acc.specular * _LTCGI_Strength;
  }
#endif
#endif

#if defined(_BRIGHTNESS_CLAMP) || defined(_PROXIMITY_DIMMING)
  direct_light.color = RGBtoHSV(direct_light.color);
  indirect_light.specular = RGBtoHSV(indirect_light.specular);
  indirect_light.diffuse = RGBtoHSV(indirect_light.diffuse);

  if (_Reflection_Probe_Saturation < 1.0) {
    direct_light.color[1] *= _Reflection_Probe_Saturation;
    indirect_light.specular[1] *= _Reflection_Probe_Saturation;
    indirect_light.diffuse[1] *= _Reflection_Probe_Saturation;
  }

  float2 brightnesses = float2(
      direct_light.color[2],
      indirect_light.diffuse[2]);
  // Do this to avoid division by 0. If both light sources are black,
  // sum_brightness could be 0;
  const float min_brightness = max(_Min_Brightness, 1E-6);
#if defined(_BRIGHTNESS_CLAMP)
  //brightnesses = smooth_max(brightnesses, _Min_Brightness);
  brightnesses = max(brightnesses, min_brightness);

  float sum_brightness = max(brightnesses[0] + brightnesses[1], min_brightness);
  float2 brightness_proportions = brightnesses / sum_brightness;

  sum_brightness = smooth_clamp(sum_brightness, min_brightness, _Max_Brightness);

  direct_light.color[2] = sum_brightness * brightness_proportions[0];
  indirect_light.diffuse[2] = sum_brightness * brightness_proportions[1];
#endif

#if defined(_PROXIMITY_DIMMING)
  {
    float cam_dist = length(i.centerCamPos - worldPos);
    // Map onto [min, max]
    cam_dist = clamp(cam_dist, _Proximity_Dimming_Min_Dist,
        _Proximity_Dimming_Max_Dist);
    // Map onto [0, max - min]
    cam_dist -= _Proximity_Dimming_Min_Dist;
    // Map onto [0, 1]
    cam_dist /= _Proximity_Dimming_Max_Dist - _Proximity_Dimming_Min_Dist;
    float dim_factor = lerp(_Proximity_Dimming_Factor, 1, cam_dist);
    direct_light.color[2] *= dim_factor;
    indirect_light.diffuse[2] *= dim_factor;
    indirect_light.specular[2] *= dim_factor;
  }
#endif

  // Specular has to be clamped separately to avoid artifacting.
#if defined(_BRIGHTNESS_CLAMP)
  indirect_light.specular[2] = smooth_clamp(indirect_light.specular[2], min_brightness, _Max_Brightness);
#endif

  direct_light.color = HSVtoRGB(direct_light.color);
  indirect_light.specular = HSVtoRGB(indirect_light.specular);
  indirect_light.diffuse = HSVtoRGB(indirect_light.diffuse);
#endif
  // _BRIGHTNESS_CLAMP || _PROXIMITY_DIMMING
  direct_light.color *= _Lighting_Factor * _Direct_Lighting_Factor * enable_direct;
  indirect_light.specular *= _Lighting_Factor * _Indirect_Specular_Lighting_Factor * _Indirect_Specular_Lighting_Factor2;
  indirect_light.diffuse *= _Lighting_Factor * _Indirect_Diffuse_Lighting_Factor;

  // Apply AO
  indirect_light.diffuse *= ao;
  float3 direct_color = direct_light.color;
  direct_light.color *= ao;

  direct_light.color *= shadow_attenuation;

  float2 screenUVs = 0;
  float4 screenPos = 0;
  #if SSR_ENABLED
    float perspective_divide = rcp(i.pos.w+0.0000000001);
    screenUVs = i.screenPos.xy * perspective_divide;
    #if UNITY_SINGLE_PASS_STEREO || defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED        )
      screenUVs.x *= 2;
    #endif
    screenPos = float4(i.screenPos, 0, i.pos.w);
  #endif

#if 1
  float reflection_strength = _ReflectionStrength;
#if defined(_REFLECTION_STRENGTH_TEX)
  reflection_strength *= _ReflectionStrengthTex.SampleLevel(linear_repeat_s, i.uv0, 0);
#endif
#if defined(SSR_MASK)
  float ssr_mask = _SSR_Mask.SampleLevel(linear_repeat_s, i.uv0, 0);
#else
  float ssr_mask = 1;
#endif
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
      i.uv2,
      vertexLightColor,
      direct_light,
      indirect_light,
      reflection_strength,
      ssr_mask);
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


#if defined(_LTCGI)
#if defined(LIGHTMAP_ON) || defined(_FORCE_WORLD_LIGHTING)
  ltcgi_acc acc = (ltcgi_acc) 0;
  if (_LTCGI_Enabled_Dynamic) {
    LTCGI_Contribution(
        acc,
        i.worldPos,
        normal,
        view_dir,
        1.0 - smoothness,
        i.uv2);
    pbr.rgb += (acc.diffuse * pbr.rgb + acc.specular) * albedo.a;
  }
#endif
#endif

  // TODO formalize with parameters
  // Break up color banding by adding some dithering to shaded color.
  //float screen_dither = ign(tdata.screen_uv_round) * .00390625;
  //pbr += screen_dither;

#if defined(_CLEARCOAT)
    // Direct lighting
    // TODO add keywords to optimize away mask samples when not used
    float cc_mask = 1;
#if defined(_CLEARCOAT_MASK)
    float cc_mask_tmp = _Clearcoat_Mask.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
    if (_Clearcoat_Mask_Invert) {
      cc_mask_tmp = 1 - cc_mask_tmp;
    }
    cc_mask *= cc_mask_tmp;
#endif
#if defined(_CLEARCOAT_MASK2)
    float cc_mask2_tmp = _Clearcoat_Mask2.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
    if (_Clearcoat_Mask_Invert) {
      cc_mask2_tmp = 1 - cc_mask2_tmp;
    }
    cc_mask *= cc_mask2_tmp;
#endif
    const float3 cc_normal = _Clearcoat_Use_Texture_Normals ? normal : i.normal;
    // Diffuse specular
    const float cc_roughness = max(1E-4, _Clearcoat_Roughness);
    const float3 cc_indirect_specular = getIndirectSpecular(
        i, view_dir,
        cc_normal,
        /*smoothness=*/1 - cc_roughness,
        /*metallic=*/0,
        worldPos);
    // Indirect specular
    {
      // TODO fold this into the full BRDF and apply the brightness corrections
      // described in the filament whitepaper:
      // https://google.github.io/filament/Filament.html
      const float3 l = reflect(-view_dir, cc_normal);
      const float3 h = normalize(l + view_dir);
      const float NoH = dot(cc_normal, h);
      const float LoH = dot(l, h);

      float Fc;
      float cc_term = FilamentClearcoat(
          cc_roughness,
          _Clearcoat_Strength,
          NoH,
          LoH,
          h,
          Fc);
      pbr.rgb += cc_term * (indirect_light.specular + indirect_light.diffuse) * cc_mask;
    }
    // Direct
    {
      const float3 l = direct_light.dir;
      const float3 h = normalize(l + view_dir);
      const float NoH = dot(cc_normal, h);
      const float LoH = dot(direct_light.dir, h);

      float Fc;
      float cc_term = FilamentClearcoat(
          cc_roughness,
          _Clearcoat_Strength,
          NoH,
          LoH,
          h,
          Fc);
      pbr.rgb += cc_term * direct_light.color * cc_mask;
    }
#endif

#if defined(_UNITY_FOG)
  UNITY_APPLY_FOG(i.fogCoord, pbr.rgb);
#endif

  return float4(pbr.rgb, albedo.a);
}

#endif  // __PBR_INC

