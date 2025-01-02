#include "AutoLight.cginc"
#include "macros.cginc"

#ifndef __GLOBALS_INC
#define __GLOBALS_INC

struct ToonerData
{
  float2 screen_uv;
  uint2 screen_uv_round;
};

UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

SamplerState point_clamp_s;
SamplerState point_repeat_s;
SamplerState linear_repeat_s;
SamplerState linear_clamp_s;
SamplerState bilinear_repeat_s;
SamplerState bilinear_clamp_s;
SamplerState trilinear_repeat_s;
SamplerState trilinear_clamp_s;

float4 _Color;
float _Metallic;
float _Roughness;
float _Roughness_Invert;
float _Tex_NormalStr;
float _NormalStr;

float _Lighting_Factor;
float _Direct_Lighting_Factor;
float _Vertex_Lighting_Factor;
float _Indirect_Specular_Lighting_Factor;
float _Indirect_Specular_Lighting_Factor2;
float _Indirect_Diffuse_Lighting_Factor;
float _Reflection_Probe_Saturation;
float _Min_Brightness;
float _Max_Brightness;

float _Frame_Counter;
float _Rendering_Cutout_Noise_Scale;

float _Mesh_Normals_Mode;
float _Flatten_Mesh_Normals_Str;
float _Confabulate_Normals;

float _Shadow_Strength;
float _Global_Sample_Bias;

float _ScatterDist;
float _ScatterPow;
float _ScatterIntensity;
float _ScatterAmbient;
float _GSAA;
float _GSAAStrength;
float _WrappingFactor;
float _Subsurface;
float _SpecularStrength;
float _FresnelStrength;
float _UseFresnel;
float _ReflectionStrength;
#if defined(_REFLECTION_STRENGTH_TEX)
texture2D _ReflectionStrengthTex;
#endif
float3 shadowedReflections;
int _ReflShadows;
float _ReflShadowStrength;
float			_BrightnessReflShad;
float			_ContrastReflShad;
float			_HDRReflShad;
float3			_TintReflShad;

float _VRChatMirrorMode;
float3 _VRChatMirrorCameraPos;

#if defined(_DISCARD)
float _Discard_Enable_Dynamic;
#endif

#if defined(_PROXIMITY_DIMMING)
float _Proximity_Dimming_Min_Dist;
float _Proximity_Dimming_Max_Dist;
float _Proximity_Dimming_Factor;
#endif

#if defined(_CLEARCOAT)
float _Clearcoat_Enabled;
float _Clearcoat_Strength;
float _Clearcoat_Roughness;
#if defined(_CLEARCOAT_MASK)
texture2D _Clearcoat_Mask;
float _Clearcoat_Mask_Invert;
#endif
#if defined(_CLEARCOAT_MASK2)
texture2D _Clearcoat_Mask2;
float _Clearcoat_Mask2_Invert;
#endif
#endif

#if defined(SSR_ENABLED)
sampler2D _GrabTexture; 
sampler2D _NoiseTexSSR;
float4 _GrabTexture_TexelSize;
float4 _NoiseTexSSR_TexelSize;
float _EdgeFade;
float _Enable_SSR;
float _SSRStrength;
float _SSRHeight;
#if defined(SSR_MASK)
texture2D _SSR_Mask;
#endif
#endif


#if defined(_BASECOLOR_MAP)
texture2D _MainTex;
float4 _MainTex_ST;
#endif
texture2D _BumpMap;
float4 _BumpMap_ST;
texture2D _MetallicTex;
float _MetallicTexChannel;
float4 _MetallicTex_ST;
texture2D _RoughnessTex;
float _RoughnessTexChannel;
float4 _RoughnessTex_ST;

#if defined(_PBR_OVERLAY0)
float4 _PBR_Overlay0_BaseColor;
#if defined(_PBR_OVERLAY0_METALLIC)
float _PBR_Overlay0_Metallic;
texture2D _PBR_Overlay0_MetallicTex;
float4 _PBR_Overlay0_MetallicTex_ST;
#endif
#if defined(_PBR_OVERLAY0_ROUGHNESS)
float _PBR_Overlay0_Roughness;
texture2D _PBR_Overlay0_RoughnessTex;
float4 _PBR_Overlay0_RoughnessTex_ST;
#endif
texture2D _PBR_Overlay0_BaseColorTex;
float4 _PBR_Overlay0_BaseColorTex_ST;
float4 _PBR_Overlay0_Emission;
texture2D _PBR_Overlay0_EmissionTex;
float4 _PBR_Overlay0_EmissionTex_ST;
texture2D _PBR_Overlay0_NormalTex;
float4 _PBR_Overlay0_NormalTex_ST;
float _PBR_Overlay0_Tex_NormalStr;
texture2D _PBR_Overlay0_Mask;
float4 _PBR_Overlay0_Mask_ST;
float _PBR_Overlay0_Mask_Invert;
float _PBR_Overlay0_Constrain_By_Alpha;
float _PBR_Overlay0_Constrain_By_Alpha_Min;
float _PBR_Overlay0_Constrain_By_Alpha_Max;
float _PBR_Overlay0_Alpha_Multiplier;
float _PBR_Overlay0_UV_Select;
float _PBR_Overlay0_Sampler_Mode;
float _PBR_Overlay0_Mip_Bias;
float _PBR_Overlay0_Mask_Glitter;
#endif

#if defined(_PBR_OVERLAY1)
float4 _PBR_Overlay1_BaseColor;
#if defined(_PBR_OVERLAY1_METALLIC)
float _PBR_Overlay1_Metallic;
texture2D _PBR_Overlay1_MetallicTex;
float4 _PBR_Overlay1_MetallicTex_ST;
#endif
#if defined(_PBR_OVERLAY1_ROUGHNESS)
float _PBR_Overlay1_Roughness;
texture2D _PBR_Overlay1_RoughnessTex;
float4 _PBR_Overlay1_RoughnessTex_ST;
#endif
texture2D _PBR_Overlay1_BaseColorTex;
float4 _PBR_Overlay1_BaseColorTex_ST;
float4 _PBR_Overlay1_Emission;
texture2D _PBR_Overlay1_EmissionTex;
float4 _PBR_Overlay1_EmissionTex_ST;
texture2D _PBR_Overlay1_NormalTex;
float4 _PBR_Overlay1_NormalTex_ST;
float _PBR_Overlay1_Tex_NormalStr;
texture2D _PBR_Overlay1_Mask;
float4 _PBR_Overlay1_Mask_ST;
float _PBR_Overlay1_Mask_Invert;
float _PBR_Overlay1_Constrain_By_Alpha;
float _PBR_Overlay1_Constrain_By_Alpha_Min;
float _PBR_Overlay1_Constrain_By_Alpha_Max;
float _PBR_Overlay1_Alpha_Multiplier;
float _PBR_Overlay1_UV_Select;
float _PBR_Overlay1_Sampler_Mode;
float _PBR_Overlay1_Mip_Bias;
float _PBR_Overlay1_Mask_Glitter;
#endif

#if defined(_PBR_OVERLAY2)
float4 _PBR_Overlay2_BaseColor;
#if defined(_PBR_OVERLAY2_METALLIC)
float _PBR_Overlay2_Metallic;
texture2D _PBR_Overlay2_MetallicTex;
float4 _PBR_Overlay2_MetallicTex_ST;
#endif
#if defined(_PBR_OVERLAY2_ROUGHNESS)
float _PBR_Overlay2_Roughness;
texture2D _PBR_Overlay2_RoughnessTex;
float4 _PBR_Overlay2_RoughnessTex_ST;
#endif
texture2D _PBR_Overlay2_BaseColorTex;
float4 _PBR_Overlay2_BaseColorTex_ST;
float4 _PBR_Overlay2_Emission;
texture2D _PBR_Overlay2_EmissionTex;
float4 _PBR_Overlay2_EmissionTex_ST;
texture2D _PBR_Overlay2_NormalTex;
float4 _PBR_Overlay2_NormalTex_ST;
float _PBR_Overlay2_Tex_NormalStr;
texture2D _PBR_Overlay2_Mask;
float4 _PBR_Overlay2_Mask_ST;
float _PBR_Overlay2_Mask_Invert;
float _PBR_Overlay2_Constrain_By_Alpha;
float _PBR_Overlay2_Constrain_By_Alpha_Min;
float _PBR_Overlay2_Constrain_By_Alpha_Max;
float _PBR_Overlay2_Alpha_Multiplier;
float _PBR_Overlay2_UV_Select;
float _PBR_Overlay2_Sampler_Mode;
float _PBR_Overlay2_Mip_Bias;
float _PBR_Overlay2_Mask_Glitter;
#endif

#if defined(_PBR_OVERLAY3)
float4 _PBR_Overlay3_BaseColor;
#if defined(_PBR_OVERLAY3_METALLIC)
float _PBR_Overlay3_Metallic;
texture2D _PBR_Overlay3_MetallicTex;
float4 _PBR_Overlay3_MetallicTex_ST;
#endif
#if defined(_PBR_OVERLAY3_ROUGHNESS)
float _PBR_Overlay3_Roughness;
texture2D _PBR_Overlay3_RoughnessTex;
float4 _PBR_Overlay3_RoughnessTex_ST;
#endif
texture2D _PBR_Overlay3_BaseColorTex;
float4 _PBR_Overlay3_BaseColorTex_ST;
float4 _PBR_Overlay3_Emission;
texture2D _PBR_Overlay3_EmissionTex;
float4 _PBR_Overlay3_EmissionTex_ST;
texture2D _PBR_Overlay3_NormalTex;
float4 _PBR_Overlay3_NormalTex_ST;
float _PBR_Overlay3_Tex_NormalStr;
texture2D _PBR_Overlay3_Mask;
float4 _PBR_Overlay3_Mask_ST;
float _PBR_Overlay3_Mask_Invert;
float _PBR_Overlay3_Constrain_By_Alpha;
float _PBR_Overlay3_Constrain_By_Alpha_Min;
float _PBR_Overlay3_Constrain_By_Alpha_Max;
float _PBR_Overlay3_Alpha_Multiplier;
float _PBR_Overlay3_UV_Select;
float _PBR_Overlay3_Sampler_Mode;
float _PBR_Overlay3_Mip_Bias;
float _PBR_Overlay3_Mask_Glitter;
#endif

#define DECAL_PROPERTIES(n) \
float4 MERGE(_Decal,n,_Color); \
texture2D MERGE(_Decal,n,_BaseColor); \
float4 MERGE(_Decal,n,_BaseColor_TexelSize); \
float4 MERGE(_Decal,n,_BaseColor_ST); \
float MERGE(_Decal,n,_BaseColor_Mode); \
texture2D MERGE(_Decal,n,_Roughness); \
texture2D MERGE(_Decal,n,_Metallic); \
float MERGE(_Decal,n,_Emission_Strength); \
float MERGE(_Decal,n,_Angle); \
float MERGE(_Decal,n,_Alpha_Multiplier); \
float MERGE(_Decal,n,_Round_Alpha_Multiplier); \
float MERGE(_Decal,n,_SDF_Threshold); \
float MERGE(_Decal,n,_SDF_Softness); \
float MERGE(_Decal,n,_SDF_Px_Range); \
float MERGE(_Decal,n,_Tiling_Mode); \
float MERGE(_Decal,n,_UV_Select); \
float MERGE(_Decal,n,_Domain_Warping_Enable_Static); \
texture2D MERGE(_Decal,n,_Domain_Warping_Noise); \
float MERGE(_Decal,n,_Domain_Warping_Strength); \
float MERGE(_Decal,n,_Domain_Warping_Speed); \
float MERGE(_Decal,n,_Domain_Warping_Octaves); \
float MERGE(_Decal,n,_Domain_Warping_Scale);

#define DECAL_MASK_PROPERTIES(n) \
texture2D MERGE(_Decal,n,_Mask); \
float MERGE(_Decal,n,_Mask_Invert);

#if defined(_DECAL0)
DECAL_PROPERTIES(0)
#if defined(_DECAL0_MASK)
DECAL_MASK_PROPERTIES(0)
#endif

#endif
#if defined(_DECAL1)
DECAL_PROPERTIES(1)
#if defined(_DECAL1_MASK)
DECAL_MASK_PROPERTIES(1)
#endif
#endif

#if defined(_DECAL2)
DECAL_PROPERTIES(2)
#if defined(_DECAL2_MASK)
DECAL_MASK_PROPERTIES(2)
#endif
#endif

#if defined(_DECAL3)
DECAL_PROPERTIES(3)
#if defined(_DECAL3_MASK)
DECAL_MASK_PROPERTIES(3)
#endif
#endif

#if defined(_DECAL4)
DECAL_PROPERTIES(4)
#if defined(_DECAL4_MASK)
DECAL_MASK_PROPERTIES(4)
#endif
#endif

#if defined(_DECAL5)
DECAL_PROPERTIES(5)
#if defined(_DECAL5_MASK)
DECAL_MASK_PROPERTIES(5)
#endif
#endif

#if defined(_DECAL6)
DECAL_PROPERTIES(6)
#if defined(_DECAL6_MASK)
DECAL_MASK_PROPERTIES(6)
#endif
#endif

#if defined(_DECAL7)
DECAL_PROPERTIES(7)
#if defined(_DECAL7_MASK)
DECAL_MASK_PROPERTIES(7)
#endif
#endif

#if defined(_DECAL8)
DECAL_PROPERTIES(8)
#if defined(_DECAL8_MASK)
DECAL_MASK_PROPERTIES(8)
#endif
#endif

#if defined(_DECAL9)
DECAL_PROPERTIES(9)
#if defined(_DECAL9_MASK)
DECAL_MASK_PROPERTIES(9)
#endif
#endif

#if defined(_EMISSION)
texture2D _EmissionMap;
float3 _EmissionColor;
#endif
#if defined(_EMISSION0)
texture2D _Emission0Tex;
float3 _Emission0Color;
float _Emission0Multiplier;
float _Emission0_UV_Select;
#endif
#if defined(_EMISSION1)
texture2D _Emission1Tex;
float3 _Emission1Color;
float _Emission1Multiplier;
float _Emission1_UV_Select;
#endif
float _Global_Emission_Factor;
float _Global_Emission_Additive_Factor;

#if defined(_AMBIENT_OCCLUSION)
texture2D _Ambient_Occlusion;
float4 _Ambient_Occlusion_ST;
float _Ambient_Occlusion_Strength;
#endif

#if defined(_RENDERING_CUTOUT)
float _Alpha_Cutoff;
#if defined(_RENDERING_CUTOUT_IGN)
float _Rendering_Cutout_Ign_Seed;
float _Rendering_Cutout_Ign_Speed;
#endif
#endif

#if defined(_OUTLINES)
float _Outline_Width;
float4 _Outline_Color;
float _Outline_Emission_Strength;
texture2D _Outline_Mask;
float _Outline_Mask_Invert;
float _Outline_Width_Multiplier;
#endif

#if defined(_GLITTER)
texture2D _Glitter_Mask;
float3 _Glitter_Color;
float _Glitter_Density;
float _Glitter_Amount;
float _Glitter_Speed;
float _Glitter_Brightness;
float _Glitter_Brightness_Lit;
float _Glitter_Angle;
float _Glitter_Power;
float _Glitter_UV_Select;
#endif

#if defined(_EXPLODE)
float _Explode_Phase;
#endif

#if defined(_SCROLL)
float _Scroll_Toggle;
float _Scroll_Top;
float _Scroll_Bottom;
float _Scroll_Width;
float _Scroll_Strength;
float _Scroll_Speed;
#endif

#if defined(_TESSELLATION)
float _Tess_Factor;
float _Tess_Dist_Cutoff;
#endif

#if defined(_MATCAP0)
float _Enable_Matcap0;
texture2D _Matcap0;
texture2D _Matcap0_Mask;
float _Matcap0_Mask_Invert;
float _Matcap0_Mask_UV_Select;
float _Matcap0_Center_Eye_Fix;
texture2D _Matcap0_Mask2;
float _Matcap0_Mask2_Invert_Colors;
float _Matcap0_Mask2_Invert_Alpha;
float _Matcap0_Mask2_UV_Select;
float _Matcap0Str;
float _Matcap0MixFactor;
float _Matcap0Quantization;
float _Matcap0Mode;
float _Matcap0Emission;
#if defined(_MATCAP0_NORMAL)
texture2D _Matcap0Normal;
float4 _Matcap0Normal_ST;
float _Matcap0Normal_Mip_Bias;
float _Matcap0Normal_Str;
float _Matcap0Normal_UV_Select;
#endif
float _Matcap0_Overwrite_Rim_Lighting_0;
float _Matcap0_Overwrite_Rim_Lighting_1;
float _Matcap0_Overwrite_Rim_Lighting_2;
float _Matcap0_Overwrite_Rim_Lighting_3;
#endif

#if defined(_MATCAP1)
float _Enable_Matcap1;
texture2D _Matcap1;
texture2D _Matcap1_Mask;
float _Matcap1_Mask_Invert;
float _Matcap1_Mask_UV_Select;
float _Matcap1_Center_Eye_Fix;
texture2D _Matcap1_Mask2;
float _Matcap1_Mask2_Invert_Colors;
float _Matcap1_Mask2_Invert_Alpha;
float _Matcap1_Mask2_UV_Select;
float _Matcap1Str;
float _Matcap1MixFactor;
float _Matcap1Quantization;
float _Matcap1Mode;
float _Matcap1Emission;
#if defined(_MATCAP1_NORMAL)
texture2D _Matcap1Normal;
float4 _Matcap1Normal_ST;
float _Matcap1Normal_Mip_Bias;
float _Matcap1Normal_Str;
float _Matcap1Normal_UV_Select;
#endif
float _Matcap1_Overwrite_Rim_Lighting_0;
float _Matcap1_Overwrite_Rim_Lighting_1;
float _Matcap1_Overwrite_Rim_Lighting_2;
float _Matcap1_Overwrite_Rim_Lighting_3;
#endif

#if defined(_RIM_LIGHTING0)
float _Rim_Lighting0_Enabled;
float _Rim_Lighting0_Mode;
float3 _Rim_Lighting0_Color;
texture2D _Rim_Lighting0_Mask;
float _Rim_Lighting0_Mask_Invert;
float _Rim_Lighting0_Mask_UV_Select;
float _Rim_Lighting0_Mask_Sampler_Mode;
texture2D _Rim_Lighting0_Mask2;
float _Rim_Lighting0_Mask2_Invert_Colors;
float _Rim_Lighting0_Mask2_Invert_Alpha;
float _Rim_Lighting0_Mask2_UV_Select;
float _Rim_Lighting0_Center_Eye_Fix;
float _Rim_Lighting0_Center;
float _Rim_Lighting0_Power;
float _Rim_Lighting0_Strength;
float _Rim_Lighting0_Emission;
float _Rim_Lighting0_Quantization;
#if defined(_RIM_LIGHTING0_GLITTER)
float _Rim_Lighting0_Glitter_Enabled;
float _Rim_Lighting0_Glitter_Density;
float _Rim_Lighting0_Glitter_Amount;
float _Rim_Lighting0_Glitter_Speed;
float _Rim_Lighting0_Glitter_Quantization;
float _Rim_Lighting0_Glitter_UV_Select;
#endif
#if defined(_RIM_LIGHTING0_POLAR_MASK)
float _Rim_Lighting0_PolarMask_Enabled;
float _Rim_Lighting0_PolarMask_Theta;
float _Rim_Lighting0_PolarMask_Power;
#endif
#if defined(_RIM_LIGHTING0_CUSTOM_VIEW_VECTOR)
float4 _Rim_Lighting0_Custom_View_Vector;
#endif
#endif

#if defined(_RIM_LIGHTING1)
float _Rim_Lighting1_Enabled;
float _Rim_Lighting1_Mode;
float3 _Rim_Lighting1_Color;
texture2D _Rim_Lighting1_Mask;
float _Rim_Lighting1_Mask_Invert;
float _Rim_Lighting1_Mask_UV_Select;
float _Rim_Lighting1_Mask_Sampler_Mode;
texture2D _Rim_Lighting1_Mask2;
float _Rim_Lighting1_Mask2_Invert_Colors;
float _Rim_Lighting1_Mask2_Invert_Alpha;
float _Rim_Lighting1_Mask2_UV_Select;
float _Rim_Lighting1_Center_Eye_Fix;
float _Rim_Lighting1_Center;
float _Rim_Lighting1_Power;
float _Rim_Lighting1_Strength;
float _Rim_Lighting1_Emission;
float _Rim_Lighting1_Quantization;
#if defined(_RIM_LIGHTING1_GLITTER)
float _Rim_Lighting1_Glitter_Enabled;
float _Rim_Lighting1_Glitter_Density;
float _Rim_Lighting1_Glitter_Amount;
float _Rim_Lighting1_Glitter_Speed;
float _Rim_Lighting1_Glitter_Quantization;
float _Rim_Lighting1_Glitter_UV_Select;
#endif
#if defined(_RIM_LIGHTING1_POLAR_MASK)
float _Rim_Lighting1_PolarMask_Enabled;
float _Rim_Lighting1_PolarMask_Theta;
float _Rim_Lighting1_PolarMask_Power;
#endif
#if defined(_RIM_LIGHTING1_CUSTOM_VIEW_VECTOR)
float4 _Rim_Lighting1_Custom_View_Vector;
#endif
#endif

#if defined(_RIM_LIGHTING2)
float _Rim_Lighting2_Enabled;
float _Rim_Lighting2_Mode;
float3 _Rim_Lighting2_Color;
texture2D _Rim_Lighting2_Mask;
float _Rim_Lighting2_Mask_Invert;
float _Rim_Lighting2_Mask_UV_Select;
float _Rim_Lighting2_Mask_Sampler_Mode;
texture2D _Rim_Lighting2_Mask2;
float _Rim_Lighting2_Mask2_Invert_Colors;
float _Rim_Lighting2_Mask2_Invert_Alpha;
float _Rim_Lighting2_Mask2_UV_Select;
float _Rim_Lighting2_Center_Eye_Fix;
float _Rim_Lighting2_Center;
float _Rim_Lighting2_Power;
float _Rim_Lighting2_Strength;
float _Rim_Lighting2_Emission;
float _Rim_Lighting2_Quantization;
#if defined(_RIM_LIGHTING2_GLITTER)
float _Rim_Lighting2_Glitter_Enabled;
float _Rim_Lighting2_Glitter_Density;
float _Rim_Lighting2_Glitter_Amount;
float _Rim_Lighting2_Glitter_Speed;
float _Rim_Lighting2_Glitter_Quantization;
float _Rim_Lighting2_Glitter_UV_Select;
#endif
#if defined(_RIM_LIGHTING2_POLAR_MASK)
float _Rim_Lighting2_PolarMask_Enabled;
float _Rim_Lighting2_PolarMask_Theta;
float _Rim_Lighting2_PolarMask_Power;
#endif
#if defined(_RIM_LIGHTING2_CUSTOM_VIEW_VECTOR)
float4 _Rim_Lighting2_Custom_View_Vector;
#endif
#endif

#if defined(_RIM_LIGHTING3)
float _Rim_Lighting3_Enabled;
float _Rim_Lighting3_Mode;
float3 _Rim_Lighting3_Color;
texture2D _Rim_Lighting3_Mask;
float _Rim_Lighting3_Mask_Invert;
float _Rim_Lighting3_Mask_UV_Select;
float _Rim_Lighting3_Mask_Sampler_Mode;
texture2D _Rim_Lighting3_Mask2;
float _Rim_Lighting3_Mask2_Invert_Colors;
float _Rim_Lighting3_Mask2_Invert_Alpha;
float _Rim_Lighting3_Mask2_UV_Select;
float _Rim_Lighting3_Center_Eye_Fix;
float _Rim_Lighting3_Center;
float _Rim_Lighting3_Power;
float _Rim_Lighting3_Strength;
float _Rim_Lighting3_Emission;
float _Rim_Lighting3_Quantization;
#if defined(_RIM_LIGHTING3_GLITTER)
float _Rim_Lighting3_Glitter_Enabled;
float _Rim_Lighting3_Glitter_Density;
float _Rim_Lighting3_Glitter_Amount;
float _Rim_Lighting3_Glitter_Speed;
float _Rim_Lighting3_Glitter_Quantization;
float _Rim_Lighting3_Glitter_UV_Select;
#endif
#if defined(_RIM_LIGHTING3_POLAR_MASK)
float _Rim_Lighting3_PolarMask_Enabled;
float _Rim_Lighting3_PolarMask_Theta;
float _Rim_Lighting3_PolarMask_Power;
#endif
#if defined(_RIM_LIGHTING3_CUSTOM_VIEW_VECTOR)
float4 _Rim_Lighting3_Custom_View_Vector;
#endif
#endif

#if defined(_OKLAB)
float _OKLAB_Enabled;
texture2D _OKLAB_Mask;
float _OKLAB_Mask_Invert;
float _OKLAB_Lightness_Shift;
float _OKLAB_Chroma_Shift;
float _OKLAB_Hue_Shift;
#endif

#if defined(_HSV0)
float _HSV0_Enabled;
texture2D _HSV0_Mask;
float _HSV0_Mask_Invert;
float _HSV0_Hue_Shift;
float _HSV0_Sat_Shift;
float _HSV0_Val_Shift;
#endif

#if defined(_HSV1)
float _HSV1_Enabled;
texture2D _HSV1_Mask;
float _HSV1_Mask_Invert;
float _HSV1_Hue_Shift;
float _HSV1_Sat_Shift;
float _HSV1_Val_Shift;
#endif

#if defined(_HSV2)
float _HSV2_Enabled;
texture2D _HSV2_Mask;
float _HSV2_Mask_Invert;
float _HSV2_Hue_Shift;
float _HSV2_Sat_Shift;
float _HSV2_Val_Shift;
#endif

#if defined(_CLONES)
float _Clones_Enabled;
float _Clones_Count;
float _Clones_dx;
float _Clones_dy;
float _Clones_dz;
float3 _Clones_Scale;
float _Clones_Dist_Cutoff;
#endif

#if defined(_UVSCROLL)
float _UVScroll_Enabled;
texture2D _UVScroll_Mask;
float _UVScroll_U_Speed;
float _UVScroll_V_Speed;
texture2D _UVScroll_Alpha;
#endif

#if defined(_LTCGI)
float _LTCGI_Enabled_Dynamic;
float4 _LTCGI_SpecularColor;
float4 _LTCGI_DiffuseColor;
#endif

#if defined(_GIMMICK_FLAT_COLOR)
float _Gimmick_Flat_Color_Enable_Static;
float _Gimmick_Flat_Color_Enable_Dynamic;
float4 _Gimmick_Flat_Color_Color;
float3 _Gimmick_Flat_Color_Emission;
#endif

#if defined(_GIMMICK_QUANTIZE_LOCATION)
float _Gimmick_Quantize_Location_Enable_Static;
float _Gimmick_Quantize_Location_Enable_Dynamic;
float _Gimmick_Quantize_Location_Precision;
float _Gimmick_Quantize_Location_Direction;
float _Gimmick_Quantize_Location_Multiplier;
texture2D _Gimmick_Quantize_Location_Mask;
#if defined(_GIMMICK_QUANTIZE_LOCATION)
float _Gimmick_Quantize_Location_Audiolink_Enable_Static;
float _Gimmick_Quantize_Location_Audiolink_Enable_Dynamic;
float _Gimmick_Quantize_Location_Audiolink_Strength;
#endif
#endif

#if defined(_GIMMICK_SHEAR_LOCATION)
float _Gimmick_Shear_Location_Enable_Static;
float _Gimmick_Shear_Location_Enable_Dynamic;
float4 _Gimmick_Shear_Location_Strength;
float _Gimmick_Shear_Location_Mesh_Renderer_Fix;
float4 _Gimmick_Shear_Location_Mesh_Renderer_Offset;
float4 _Gimmick_Shear_Location_Mesh_Renderer_Rotation;
float4 _Gimmick_Shear_Location_Mesh_Renderer_Scale;
#endif

#if defined(_GIMMICK_SPHERIZE_LOCATION)
float _Gimmick_Spherize_Location_Enable_Static;
float _Gimmick_Spherize_Location_Enable_Dynamic;
float _Gimmick_Spherize_Location_Strength;
float _Gimmick_Spherize_Location_Radius;
#endif

#if defined(_GIMMICK_EYES_00)
float _Gimmick_Eyes00_Enable_Static;
texture2D _Gimmick_Eyes00_Effect_Mask;
#endif

#if defined(_GIMMICK_EYES_01)
float _Gimmick_Eyes01_Radius;
#endif

#if defined(_GIMMICK_EYES_02)
float _Gimmick_Eyes02_N;
float _Gimmick_Eyes02_A0;
float _Gimmick_Eyes02_A1;
float _Gimmick_Eyes02_A2;
float _Gimmick_Eyes02_A3;
float _Gimmick_Eyes02_A4;
float _Gimmick_Eyes02_Animate;
float _Gimmick_Eyes02_Animate_Strength;
float _Gimmick_Eyes02_Animate_Speed;
float _Gimmick_Eyes02_UV_X_Symmetry;
float4 _Gimmick_Eyes02_UV_Adjust;
float4 _Gimmick_Eyes02_Albedo;
float _Gimmick_Eyes02_Metallic;
float _Gimmick_Eyes02_Roughness;
float3 _Gimmick_Eyes02_Emission;
#endif

#if defined(_GIMMICK_DS2)
float _Gimmick_DS2_Enable_Static;
texture2D _Gimmick_DS2_Mask;
texture2D _Gimmick_DS2_Noise;
float _Gimmick_DS2_Choice;
// 00
float _Gimmick_DS2_Albedo_Factor;
float _Gimmick_DS2_Emission_Factor;
float _Gimmick_DS2_00_Domain_Warping_Octaves;
float _Gimmick_DS2_00_Domain_Warping_Strength;
float _Gimmick_DS2_00_Domain_Warping_Scale;
float _Gimmick_DS2_00_Domain_Warping_Speed;
// 01
float4 _Gimmick_DS2_01_Period;
float4 _Gimmick_DS2_01_Count;
float _Gimmick_DS2_01_Radius;
float _Gimmick_DS2_01_Domain_Warping_Octaves;
float _Gimmick_DS2_01_Domain_Warping_Strength;
float _Gimmick_DS2_01_Domain_Warping_Scale;
float _Gimmick_DS2_01_Domain_Warping_Speed;
// 02
float4 _Gimmick_DS2_02_Period;
float4 _Gimmick_DS2_02_Count;
float _Gimmick_DS2_02_Edge_Length;
float _Gimmick_DS2_02_Domain_Warping_Octaves;
float _Gimmick_DS2_02_Domain_Warping_Strength;
float _Gimmick_DS2_02_Domain_Warping_Scale;
float _Gimmick_DS2_02_Domain_Warping_Speed;
// 03
float4 _Gimmick_DS2_03_Period;
float4 _Gimmick_DS2_03_Count;
float _Gimmick_DS2_03_Edge_Length;
float _Gimmick_DS2_03_Domain_Warping_Octaves;
float _Gimmick_DS2_03_Domain_Warping_Strength;
float _Gimmick_DS2_03_Domain_Warping_Scale;
float _Gimmick_DS2_03_Domain_Warping_Speed;
#endif

#if defined(_PIXELLATE)
float _Gimmick_Pixellate_Enable_Static;
float _Gimmick_Pixellate_Resolution_U;
float _Gimmick_Pixellate_Resolution_V;
texture2D _Gimmick_Pixellate_Effect_Mask;
#endif

#if defined(_TROCHOID)
float _Trochoid_R;
float _Trochoid_r;
float _Trochoid_d;
#endif

#if defined(_FACE_ME_WORLD_Y)
float _FaceMeWorldY_Enable_Static;
float _FaceMeWorldY_Enable_Dynamic;
float _FaceMeWorldY_Enable_X;
float _FaceMeWorldY_Enable_Y;
float _FaceMeWorldY_Enable_Z;
#endif

#if defined(_RORSCHACH) || defined(_GLITTER) || defined(_RIM_LIGHTING0_GLITTER) || defined(_RIM_LIGHTING1_GLITTER) || defined(_RIM_LIGHTING2_GLITTER) || defined(_RIM_LIGHTING3_GLITTER)
float _Rorschach_Enable_Dynamic;
float4 _Rorschach_Color;
float _Rorschach_Alpha_Cutoff;
float _Rorschach_Count_X;
float _Rorschach_Count_Y;
float _Rorschach_Center_Randomization;
float _Rorschach_Radius;
float _Rorschach_Emission_Strength;
float _Rorschach_Speed;
float _Rorschach_Quantization;
texture2D _Rorschach_Mask;
float _Rorschach_Mask_Invert;
#endif

#if defined(_MIRROR_UV_FLIP)
float _Mirror_UV_Flip_Enable_Dynamic;
#endif

#if defined(_GIMMICK_LETTER_GRID)
texture2D _Gimmick_Letter_Grid_Texture;
float _Gimmick_Letter_Grid_Res_X;
float _Gimmick_Letter_Grid_Res_Y;
float _Gimmick_Letter_Grid_Tex_Res_X;
float _Gimmick_Letter_Grid_Tex_Res_Y;
float4 _Gimmick_Letter_Grid_UV_Scale_Offset;
float _Gimmick_Letter_Grid_Padding;
float4 _Gimmick_Letter_Grid_Color;
float _Gimmick_Letter_Grid_Metallic;
float _Gimmick_Letter_Grid_Roughness;
float _Gimmick_Letter_Grid_Emission;
float _Gimmick_Letter_Grid_UV_Select;
float _Gimmick_Letter_Grid_Color_Wave_Speed;
float _Gimmick_Letter_Grid_Color_Wave_Frequency;
float _Gimmick_Letter_Grid_Rim_Lighting_Power;
float _Gimmick_Letter_Grid_Rim_Lighting_Center;
float _Gimmick_Letter_Grid_Rim_Lighting_Quantization;
texture2D _Gimmick_Letter_Grid_Rim_Lighting_Mask;
float _Gimmick_Letter_Grid_Rim_Lighting_Mask_UV_Select;
float _Gimmick_Letter_Grid_Rim_Lighting_Mask_Invert;
#endif

#if defined(_GIMMICK_LETTER_GRID_2)
texture2D _Gimmick_Letter_Grid_2_Texture;
float4 _Gimmick_Letter_Grid_2_Texture_TexelSize;
float _Gimmick_Letter_Grid_2_Res_X;
float _Gimmick_Letter_Grid_2_Res_Y;
float4 _Gimmick_Letter_Grid_2_Data_Row_0;
float4 _Gimmick_Letter_Grid_2_Data_Row_1;
float4 _Gimmick_Letter_Grid_2_Data_Row_2;
float4 _Gimmick_Letter_Grid_2_Data_Row_3;
float _Gimmick_Letter_Grid_2_Tex_Res_X;
float _Gimmick_Letter_Grid_2_Tex_Res_Y;
float4 _Gimmick_Letter_Grid_2_UV_Scale_Offset;
float _Gimmick_Letter_Grid_2_Padding;
float4 _Gimmick_Letter_Grid_2_Color;
float _Gimmick_Letter_Grid_2_Metallic;
float _Gimmick_Letter_Grid_2_Roughness;
float _Gimmick_Letter_Grid_2_Emission;
texture2D _Gimmick_Letter_Grid_2_Mask;
float _Gimmick_Letter_Grid_2_Global_Offset;
float _Gimmick_Letter_Grid_2_Screen_Px_Range;
float _Gimmick_Letter_Grid_2_Min_Screen_Px_Range;
float _Gimmick_Letter_Grid_2_Blurriness;
float _Gimmick_Letter_Grid_2_Alpha_Threshold;
#endif

#if defined(_GIMMICK_AL_CHROMA_00)
float _Gimmick_AL_Chroma_00_Forward_Pass;
float _Gimmick_AL_Chroma_00_Forward_Blend;
float _Gimmick_AL_Chroma_00_Outline_Pass;
float _Gimmick_AL_Chroma_00_Outline_Blend;
float _Gimmick_AL_Chroma_00_Outline_Emission;
#if defined(_GIMMICK_AL_CHROMA_00_HUE_SHIFT)
float _Gimmick_AL_Chroma_00_Hue_Shift_Theta;
#endif
#endif

#if defined(_GIMMICK_FOG_00)
float _Gimmick_Fog_00_Max_Ray;
float _Gimmick_Fog_00_Enable_Area_Lighting;
float _Gimmick_Fog_00_Radius;
float _Gimmick_Fog_00_Step_Size_Factor;
float _Gimmick_Fog_00_Noise_Scale;
float _Gimmick_Fog_00_Noise_Exponent;
float _Gimmick_Fog_00_Density;
float _Gimmick_Fog_00_Normal_Cutoff;
float _Gimmick_Fog_00_Alpha_Cutoff;
float _Gimmick_Fog_00_Ray_Origin_Randomization;
float _Gimmick_Fog_00_Lod_Half_Life;
float _Gimmick_Fog_00_Max_Brightness;
texture3D _Gimmick_Fog_00_Noise;
#if defined(_GIMMICK_FOG_00_NOISE_2D)
texture2D _Gimmick_Fog_00_Noise_2D;
float4 _Gimmick_Fog_00_Noise_2D_TexelSize;
#endif
#if defined(_GIMMICK_FOG_00_EMITTER_TEXTURE)
texture2D _Gimmick_Fog_00_Emitter_Texture;
float _Gimmick_Fog_00_Emitter_Brightness_Diffuse;
float _Gimmick_Fog_00_Emitter_Brightness_Direct;
float _Gimmick_Fog_00_Emitter_Lod_Half_Life;

float3 _Gimmick_Fog_00_Emitter0_Location;
float3 _Gimmick_Fog_00_Emitter0_Normal;
float _Gimmick_Fog_00_Emitter0_Scale_X;
float _Gimmick_Fog_00_Emitter0_Scale_Y;
#if defined(_GIMMICK_FOG_00_EMITTER_1)
float3 _Gimmick_Fog_00_Emitter1_Location;
float3 _Gimmick_Fog_00_Emitter1_Normal;
float _Gimmick_Fog_00_Emitter1_Scale_X;
float _Gimmick_Fog_00_Emitter1_Scale_Y;
#endif
#if defined(_GIMMICK_FOG_00_EMITTER_2)
float3 _Gimmick_Fog_00_Emitter2_Location;
float3 _Gimmick_Fog_00_Emitter2_Normal;
float _Gimmick_Fog_00_Emitter2_Scale_X;
float _Gimmick_Fog_00_Emitter2_Scale_Y;
#endif
#endif
#endif

#if defined(_GIMMICK_GERSTNER_WATER)
float _Gimmick_Gerstner_Water_M;
float _Gimmick_Gerstner_Water_h;
float _Gimmick_Gerstner_Water_g;
float3 _Gimmick_Gerstner_Water_Scale;
float4 _Gimmick_Gerstner_Water_a;
float4 _Gimmick_Gerstner_Water_p;
float4 _Gimmick_Gerstner_Water_k_x;
float4 _Gimmick_Gerstner_Water_k_y;
float4 _Gimmick_Gerstner_Water_t_f;
float _Gimmick_Gerstner_Water_Origin_Damping_Direction;
texture2D _Gimmick_Gerstner_Water_Color_Ramp;
float _Gimmick_Gerstner_Water_Color_Ramp_Offset;
float _Gimmick_Gerstner_Water_Color_Ramp_Scale;
#if defined(_GIMMICK_GERSTNER_WATER_OCTAVE_1)
float4 _Gimmick_Gerstner_Water_a1;
float4 _Gimmick_Gerstner_Water_p1;
float4 _Gimmick_Gerstner_Water_k_x1;
float4 _Gimmick_Gerstner_Water_k_y1;
float4 _Gimmick_Gerstner_Water_t_f1;
#endif
#if defined(_GIMMICK_GERSTNER_WATER_COLOR_RAMP)
float4 _Gimmick_Gerstner_Water_Color_Ramp_Mask;
#if defined(_GIMMICK_GERSTNER_WATER_OCTAVE_1)
float4 _Gimmick_Gerstner_Water_Color_Ramp_Mask1;
#endif
#endif
#endif

#if defined(_GIMMICK_FOG_00_RAY_MARCH_0)
float _Gimmick_Fog_00_Ray_March_0_Seed;
#endif

#if defined(_RENDERING_CUTOUT_NOISE_MASK)
texture2D _Rendering_Cutout_Noise_Mask;
float4 _Rendering_Cutout_Noise_Mask_TexelSize;
#endif

#endif

