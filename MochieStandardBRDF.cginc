#ifndef MOCHIE_STANDARD_BRDF_INCLUDED
#define MOCHIE_STANDARD_BRDF_INCLUDED

/*
 * MIT License
 *
 * Copyright (c) 2020 MochiesCode
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE
 * SOFTWARE.
 */

#include "UnityCG.cginc"
#include "UnityStandardConfig.cginc"
#include "UnityLightingCommon.cginc"
#include "MochieStandardSSR.cginc"
#include "MochieStandardSSS.cginc"

float3 get_camera_pos() {
  float3 worldCam;
  worldCam.x = unity_CameraToWorld[0][3];
  worldCam.y = unity_CameraToWorld[1][3];
  worldCam.z = unity_CameraToWorld[2][3];
  return worldCam;
}

float GSAARoughness(float3 normal, float roughness){
  float3 normalDDX = ddx(normal);
  float3 normalDDY = ddy(normal); 
  float dotX = dot(normalDDX, normalDDX);
  float dotY = dot(normalDDY, normalDDY);
  float base = saturate(max(dotX, dotY));
  return max(roughness, pow(base, 0.333)*_GSAAStrength);
}

float3 Desaturate(float3 col){
	return dot(col, float3(0.3, 0.59, 0.11));
}

float3 GetContrast(float3 col, float contrast){
    return lerp(float3(0.5,0.5,0.5), col, contrast);
}

float oetf_sRGB_scalar(float L) {
	float V = 1.055 * (pow(L, 1.0 / 2.4)) - 0.055;
	if (L <= 0.0031308)
		V = L * 12.92;
	return V;
}

float3 oetf_sRGB(float3 L) {
	return float3(oetf_sRGB_scalar(L.r), oetf_sRGB_scalar(L.g), oetf_sRGB_scalar(L.b));
}

float eotf_sRGB_scalar(float V) {
	float L = pow((V + 0.055) / 1.055, 2.4);
	if (V <= oetf_sRGB_scalar(0.0031308))
		L = V / 12.92;
	return L;
}

float3 GetHDR(float3 rgb) {
	return float3(eotf_sRGB_scalar(rgb.r), eotf_sRGB_scalar(rgb.g), eotf_sRGB_scalar(rgb.b));
}

half4 BRDF1_Mochie_PBS (
    half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
    half3 normal, half3 viewDir, half3 worldPos, half2 screenUVs, half4 screenPos,
    half metallic, half thickness, half3 ssColor, half atten, float2 lightmapUV, float3 vertexColor,
    UnityLight light, UnityIndirect gi, float reflection_strength, float ssr_mask)
{

  half perceptualRoughness = SmoothnessToPerceptualRoughness(smoothness);
  if (_GSAA == 1){
    perceptualRoughness = GSAARoughness(normal, perceptualRoughness);
  }
  half3 halfDir = Unity_SafeNormalize (half3(light.dir) + viewDir);
  half nv = abs(dot(normal, viewDir));
  half nl = saturate(dot(normal, light.dir));
  half nh = saturate(dot(normal, halfDir));
  half lv = saturate(dot(light.dir, viewDir));
  half lh = saturate(dot(light.dir, halfDir));

  // Diffuse term
  half diffuseTerm = DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;
  float wrappedDiffuse = saturate((diffuseTerm + _WrappingFactor) /
      (1.0f + _WrappingFactor)) * 2 / (2 * (1 + _WrappingFactor));

  // Specular term
  half roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
#if UNITY_BRDF_GGX
  roughness = max(roughness, 0.002);
  half V = SmithJointGGXVisibilityTerm (nl, nv, roughness);
  half D = GGXTerm(nh, roughness);
#else
  half V = SmithBeckmannVisibilityTerm (nl, nv, roughness);
  half D = NDFBlinnPhongNormalizedTerm (nh, PerceptualRoughnessToSpecPower(perceptualRoughness));
#endif

#if defined(_SPECULARHIGHLIGHTS_OFF)
  half specularTerm = 0.0;
#else
  half specularTerm = V*D * UNITY_PI;
#ifdef UNITY_COLORSPACE_GAMMA
  specularTerm = sqrt(max(1e-4h, specularTerm));
#endif
  specularTerm = max(0, specularTerm * nl);
#endif
  half surfaceReduction;
#ifdef UNITY_COLORSPACE_GAMMA
  surfaceReduction = 1.0-0.28*roughness*perceptualRoughness;
#else
  surfaceReduction = 1.0 / (roughness*roughness + 1.0);
#endif

  half grazingTerm = saturate(smoothness + (1-oneMinusReflectivity));

  half3 diffCol = 0;
  diffCol = diffColor * (gi.diffuse + light.color * lerp(diffuseTerm, wrappedDiffuse, thickness));

  // TODO this should probably use its own version of _WrappingFactor
  specularTerm = saturate((specularTerm + _WrappingFactor) /
      (1.0f + _WrappingFactor)) * 2 / (2 * (1 + _WrappingFactor));

  half3 specCol = specularTerm * light.color * FresnelTerm (specColor, lh) * _SpecularStrength;

  half3 reflCol = surfaceReduction * gi.specular * FresnelLerp (specColor, grazingTerm, lerp(1, nv, _FresnelStrength*_UseFresnel)) * reflection_strength;
#if SSR_ENABLED
  half4 ssrCol = GetSSR(worldPos, viewDir, reflect(-viewDir, normal), normal, smoothness, diffColor, metallic, screenUVs, screenPos);
  ssrCol.rgb *= _SSRStrength;
  if (_EdgeFade == 0)
    ssrCol.a = ssrCol.a > 0 ? 1 : 0;
  reflCol = lerp(reflCol, ssrCol.rgb, ssrCol.a * saturate(_SSRStrength * ssr_mask));
  specCol *= 1 - ssrCol.a * ssr_mask;
#endif

  half3 subsurfaceCol = 0;
  if (_Subsurface == 1){
    subsurfaceCol = GetSubsurfaceLight(
        light.color, 
        light.dir, 
        normal, 
        viewDir, 
        atten, 
        thickness, 
        gi.diffuse, 
        ssColor
        );
  }

#ifdef LTCGI
  if (_LTCGIStrength > 0){
    half3 diffLight = 0;
    LTCGI_Contribution(
        worldPos, 
        normal, 
        viewDir, 
        perceptualRoughness,
        (lightmapUV - unity_LightmapST.zw) / unity_LightmapST.xy,
        diffLight
#ifndef _GLOSSYREFLECTIONS_OFF
        , reflCol
#endif
        );
    diffCol += (diffColor * diffLight) * _LTCGIStrength;
  }
#endif

#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
  if (_ReflShadows == 1){
    float3 lightmap = Desaturate(DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, lightmapUV)));
    lightmap = GetContrast(lightmap, _ContrastReflShad);
    lightmap = lerp(lightmap, GetHDR(lightmap), _HDRReflShad);
    lightmap *= _BrightnessReflShad;
    lightmap *= _TintReflShad;
    shadowedReflections = saturate(lerp(1, lightmap, _ReflShadowStrength));
    reflCol *= shadowedReflections;
    specCol *= shadowedReflections;
  }
#else
  shadowedReflections = lerp(1, lerp(1, atten, 0.9), _ReflShadows*_ReflShadowStrength);
  reflCol *= shadowedReflections;
#endif

  // #ifdef FULL_VERSION
  // 	reflCol *= lerp(1, vertexColor, _ReflVertexColor*_ReflVertexColorStrength);
  // #endif

diffCol = 0;
  return half4(diffCol + specCol + reflCol + subsurfaceCol, 1);
}

#endif // MOCHIE_STANDARD_BRDF_INCLUDED
