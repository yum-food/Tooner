#include "texture_macros.cginc"
#include "UnityStandardUtils.cginc"

#ifndef __PBR_OVERLAY_INC
#define __PBR_OVERLAY_INC

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
  ov.ov0_mask = _PBR_Overlay0_Mask.SampleLevel(GET_SAMPLER_OV0,
  UV_SCOFF(i, _PBR_Overlay0_Mask_ST, _PBR_Overlay0_UV_Select),
      get_uv_by_channel(i, _PBR_Overlay0_UV_Select), 0);
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
  ov.ov1_mask = _PBR_Overlay1_Mask.SampleLevel(GET_SAMPLER_OV1,
      UV_SCOFF(i, _PBR_Overlay1_Mask_ST, _PBR_Overlay1_UV_Select), 0);
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
  ov.ov2_mask = _PBR_Overlay2_Mask.SampleLevel(GET_SAMPLER_OV2,
      UV_SCOFF(i, _PBR_Overlay2_Mask_ST, _PBR_Overlay2_UV_Select), 0);
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
  ov.ov3_mask = _PBR_Overlay3_Mask.SampleLevel(GET_SAMPLER_OV3,
      UV_SCOFF(i, _PBR_Overlay3_Mask_ST, _PBR_Overlay3_UV_Select), 0);
  ov.ov3_mask = ((bool) round(_PBR_Overlay3_Mask_Invert)) ? 1.0 - ov.ov3_mask : ov.ov3_mask;
#else
  ov.ov3_mask = 1;
#endif
  ov.ov3_albedo.a *= ov.ov3_mask;
#endif  // _PBR_OVERLAY3
}

void mixOverlayAlbedoRoughnessMetallic(inout float4 albedo,
    inout float roughness, inout float metallic, PbrOverlay ov,
    float mask, out float glitter_mask) {
  glitter_mask = 1;
  // Calculate alpha masks before we start mutating alpha.
#if defined(_PBR_OVERLAY0)
  float a0 = saturate(ov.ov0_albedo.a * _PBR_Overlay0_Alpha_Multiplier);
  if (_PBR_Overlay0_Constrain_By_Alpha) {
    bool in_range = (albedo.a > _PBR_Overlay0_Constrain_By_Alpha_Min) *
      (albedo.a < _PBR_Overlay0_Constrain_By_Alpha_Max);
    a0 *= in_range;
  }
  a0 *= mask;
  a0 *= ov.ov0_mask;
  glitter_mask *= 1 - a0 * _PBR_Overlay0_Mask_Glitter;
#endif
#if defined(_PBR_OVERLAY1)
  float a1 = saturate(ov.ov1_albedo.a * _PBR_Overlay1_Alpha_Multiplier);
  if (_PBR_Overlay1_Constrain_By_Alpha) {
    bool in_range = (albedo.a > _PBR_Overlay1_Constrain_By_Alpha_Min) *
      (albedo.a < _PBR_Overlay1_Constrain_By_Alpha_Max);
    a1 *= in_range;
  }
  a1 *= mask;
  a1 *= ov.ov1_mask;
  glitter_mask *= 1 - a1 * _PBR_Overlay1_Mask_Glitter;
#endif
#if defined(_PBR_OVERLAY2)
  float a2 = saturate(ov.ov2_albedo.a * _PBR_Overlay2_Alpha_Multiplier);
  if (_PBR_Overlay2_Constrain_By_Alpha) {
    bool in_range = (albedo.a > _PBR_Overlay2_Constrain_By_Alpha_Min) *
      (albedo.a < _PBR_Overlay2_Constrain_By_Alpha_Max);
    a2 *= in_range;
  }
  a2 *= mask;
  a2 *= ov.ov2_mask;
  glitter_mask *= 1 - a2 * _PBR_Overlay2_Mask_Glitter;
#endif
#if defined(_PBR_OVERLAY3)
  float a3 = saturate(ov.ov3_albedo.a * _PBR_Overlay3_Alpha_Multiplier);
  if (_PBR_Overlay3_Constrain_By_Alpha) {
    bool in_range = (albedo.a > _PBR_Overlay3_Constrain_By_Alpha_Min) *
      (albedo.a < _PBR_Overlay3_Constrain_By_Alpha_Max);
    a3 *= in_range;
  }
  a3 *= mask;
  a3 *= ov.ov3_mask;
  glitter_mask *= 1 - a3 * _PBR_Overlay3_Mask_Glitter;
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
  albedo.rgb += ov.ov0_albedo * mask * ov.ov0_mask;
#elif defined(_PBR_OVERLAY0_MIX_MIN)
  albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, ov.ov0_albedo), mask * ov.ov0_mask);
#elif defined(_PBR_OVERLAY0_MIX_MAX)
  albedo.rgb = max(albedo.rgb, ov.ov0_albedo * mask * ov.ov0_mask);
#elif defined(_PBR_OVERLAY0_MIX_MULTIPLY)
  albedo.rgb = lerp(albedo.rgb, albedo.rgb * ov.ov0_albedo, mask * ov.ov0_mask);
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
  albedo.rgb += ov.ov1_albedo * mask * ov.ov1_mask;
#elif defined(_PBR_OVERLAY1_MIX_MIN)
  albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, ov.ov1_albedo), mask * ov.ov1_mask);
#elif defined(_PBR_OVERLAY1_MIX_MAX)
  albedo.rgb = max(albedo.rgb, ov.ov1_albedo * mask * ov.ov1_mask);
#elif defined(_PBR_OVERLAY1_MIX_MULTIPLY)
  albedo.rgb = lerp(albedo.rgb, albedo.rgb * ov.ov1_albedo, mask * ov.ov1_mask);
#endif
#endif

#if defined(_PBR_OVERLAY2)
#if defined(_PBR_OVERLAY2_MIX_ALPHA_BLEND)
  albedo.rgb = lerp(albedo.rgb, ov.ov2_albedo.rgb, a2);
#if defined(_PBR_OVERLAY2_ROUGHNESS)
  roughness = lerp(roughness, ov.ov2_roughness, a2);
#endif
#if defined(_PBR_OVERLAY2_METALLIC)
  metallic = lerp(metallic, ov.ov2_metallic, a2);
#endif
  albedo.a = max(albedo.a, a2);
#elif defined(_PBR_OVERLAY2_MIX_ADD)
  albedo.rgb += ov.ov2_albedo * mask * ov.ov2_mask;
#elif defined(_PBR_OVERLAY2_MIX_MIN)
  albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, ov.ov2_albedo), mask * ov.ov2_mask);
#elif defined(_PBR_OVERLAY2_MIX_MAX)
  albedo.rgb = max(albedo.rgb, ov.ov2_albedo * mask * ov.ov2_mask);
#elif defined(_PBR_OVERLAY2_MIX_MULTIPLY)
  albedo.rgb = lerp(albedo.rgb, albedo.rgb * ov.ov2_albedo, mask * ov.ov2_mask);
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
  albedo.rgb += ov.ov3_albedo * mask * ov.ov3_mask;
#elif defined(_PBR_OVERLAY3_MIX_MIN)
  albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, ov.ov3_albedo), mask * ov.ov3_mask);
#elif defined(_PBR_OVERLAY3_MIX_MAX)
  albedo.rgb = max(albedo.rgb, ov.ov3_albedo * mask * ov.ov3_mask);
#elif defined(_PBR_OVERLAY3_MIX_MULTIPLY)
  albedo.rgb = lerp(albedo.rgb, albedo.rgb * ov.ov3_albedo, mask * ov.ov3_mask);
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

#endif  // __PBR_OVERLAY_INC

