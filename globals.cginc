#ifndef __GLOBALS_INC
#define __GLOBALS_INC

#include "AutoLight.cginc"

SamplerState linear_repeat_s;
SamplerState linear_clamp_s;

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
float3 shadowedReflections;
float3 _ReflShadows;
float3 _ReflShadowStrength;

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
UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
sampler2D _GrabTexture; 
sampler2D _NoiseTexSSR;
float4 _GrabTexture_TexelSize;
float4 _NoiseTexSSR_TexelSize;
float _EdgeFade;
float _SSRStrength;
float _SSRHeight;
#endif


#if defined(_BASECOLOR_MAP)
texture2D _MainTex;
float4 _MainTex_ST;
#endif
texture2D _NormalTex;
float4 _NormalTex_ST;
texture2D _MetallicTex;
float4 _MetallicTex_ST;
texture2D _RoughnessTex;
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
float _PBR_Overlay0_Mask_Invert;
float _PBR_Overlay0_Constrain_By_Alpha;
float _PBR_Overlay0_Constrain_By_Alpha_Min;
float _PBR_Overlay0_Constrain_By_Alpha_Max;
float _PBR_Overlay0_Alpha_Multiplier;
float _PBR_Overlay0_UV_Select;
float _PBR_Overlay0_Sampler_Mode;
float _PBR_Overlay0_Mip_Bias;
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
float _PBR_Overlay1_Mask_Invert;
float _PBR_Overlay1_Constrain_By_Alpha;
float _PBR_Overlay1_Constrain_By_Alpha_Min;
float _PBR_Overlay1_Constrain_By_Alpha_Max;
float _PBR_Overlay1_Alpha_Multiplier;
float _PBR_Overlay1_UV_Select;
float _PBR_Overlay1_Sampler_Mode;
float _PBR_Overlay1_Mip_Bias;
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
float _PBR_Overlay2_Mask_Invert;
float _PBR_Overlay2_Constrain_By_Alpha;
float _PBR_Overlay2_Constrain_By_Alpha_Min;
float _PBR_Overlay2_Constrain_By_Alpha_Max;
float _PBR_Overlay2_Alpha_Multiplier;
float _PBR_Overlay2_UV_Select;
float _PBR_Overlay2_Sampler_Mode;
float _PBR_Overlay2_Mip_Bias;
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
float _PBR_Overlay3_Mask_Invert;
float _PBR_Overlay3_Constrain_By_Alpha;
float _PBR_Overlay3_Constrain_By_Alpha_Min;
float _PBR_Overlay3_Constrain_By_Alpha_Max;
float _PBR_Overlay3_Alpha_Multiplier;
float _PBR_Overlay3_UV_Select;
float _PBR_Overlay3_Sampler_Mode;
float _PBR_Overlay3_Mip_Bias;
#endif

#if defined(_DECAL0)
texture2D _Decal0_BaseColor;
float4 _Decal0_BaseColor_ST;
texture2D _Decal0_Roughness;
texture2D _Decal0_Metallic;
float _Decal0_Emission_Strength;
float _Decal0_Angle;
float _Decal0_UV_Select;
#endif
#if defined(_DECAL1)
texture2D _Decal1_BaseColor;
float4 _Decal1_BaseColor_ST;
texture2D _Decal1_Roughness;
texture2D _Decal1_Metallic;
float _Decal1_Emission_Strength;
float _Decal1_Angle;
float _Decal1_UV_Select;
#endif
#if defined(_DECAL2)
texture2D _Decal2_BaseColor;
float4 _Decal2_BaseColor_ST;
texture2D _Decal2_Roughness;
texture2D _Decal2_Metallic;
float _Decal2_Emission_Strength;
float _Decal2_Angle;
float _Decal2_UV_Select;
#endif
#if defined(_DECAL3)
texture2D _Decal3_BaseColor;
float4 _Decal3_BaseColor_ST;
texture2D _Decal3_Roughness;
texture2D _Decal3_Metallic;
float _Decal3_Emission_Strength;
float _Decal3_Angle;
float _Decal3_UV_Select;
#endif

#if defined(_EMISSION)
texture2D _EmissionTex;
float _EmissionStrength;
#endif
float _Global_Emission_Factor;

#if defined(_AMBIENT_OCCLUSION)
texture2D _Ambient_Occlusion;
float _Ambient_Occlusion_Strength;
#endif

#if defined(_RENDERING_CUTOUT)
float _Alpha_Cutoff;
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
float _Glitter_Density;
float _Glitter_Amount;
float _Glitter_Speed;
float _Glitter_Brightness;
float _Glitter_Angle;
float _Glitter_Power;
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
texture2D _Matcap0_Mask2;
float _Matcap0_Mask2_Invert;
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
texture2D _Matcap1_Mask2;
float _Matcap1_Mask2_Invert;
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
#endif
#if defined(_RIM_LIGHTING0_POLAR_MASK)
float _Rim_Lighting0_PolarMask_Enabled;
float _Rim_Lighting0_PolarMask_Theta;
float _Rim_Lighting0_PolarMask_Power;
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
#endif
#if defined(_RIM_LIGHTING1_POLAR_MASK)
float _Rim_Lighting1_PolarMask_Enabled;
float _Rim_Lighting1_PolarMask_Theta;
float _Rim_Lighting1_PolarMask_Power;
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
#endif
#if defined(_RIM_LIGHTING2_POLAR_MASK)
float _Rim_Lighting2_PolarMask_Enabled;
float _Rim_Lighting2_PolarMask_Theta;
float _Rim_Lighting2_PolarMask_Power;
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
#endif
#if defined(_RIM_LIGHTING3_POLAR_MASK)
float _Rim_Lighting3_PolarMask_Enabled;
float _Rim_Lighting3_PolarMask_Theta;
float _Rim_Lighting3_PolarMask_Power;
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

#if defined(_CLONES)
float _Clones_Enabled;
float _Clones_Count;
float _Clones_dx;
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
float _LTCGI_Enabled;
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

#endif

