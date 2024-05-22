#ifndef __GLOBALS_INC
#define __GLOBALS_INC

#include "AutoLight.cginc"

float4 _BaseColor;
float _Metallic;
float _Roughness;

texture2D _BaseColorTex;
texture2D _NormalTex;
texture2D _MetallicTex;
texture2D _RoughnessTex;

float4 _PBR_Overlay_BaseColor;
float _PBR_Overlay_Metallic;
float _PBR_Overlay_Roughness;
texture2D _PBR_Overlay_BaseColorTex;
texture2D _PBR_Overlay_NormalTex;
texture2D _PBR_Overlay_MetallicTex;
texture2D _PBR_Overlay_RoughnessTex;
float _PBR_Overlay_Tex_NormalStr;

texture2D _EmissionTex;
float _EmissionStrength;

SamplerState linear_repeat_s;

float _Tex_NormalStr;
float _NormalStr;

float _Min_Brightness;
float _Max_Brightness;

float _Alpha_Cutoff;

float _Mesh_Normals_Mode;
float _Flatten_Mesh_Normals_Str;
float _Confabulate_Normals;

float _Outline_Width;
float4 _Outline_Color;
float _Outline_Emission_Strength;
texture2D _Outline_Mask;
float _Outline_Mask_Invert;

texture2D _Glitter_Mask;
float _Glitter_Density;
float _Glitter_Amount;
float _Glitter_Speed;
float _Glitter_Seed;
float _Glitter_Brightness;
float _Glitter_Angle;

float _Explode_Phase;

float _Scroll_Toggle;
float _Scroll_Top;
float _Scroll_Bottom;
float _Scroll_Width;
float _Scroll_Strength;
float _Scroll_Speed;

float _Tess_Factor;
float _Tess_Dist_Cutoff;

float _Enable_Matcap0;
texture2D _Matcap0;
texture2D _Matcap0_Mask;
float _Matcap0_Mask_Invert;
float _Matcap0Str;
float _Matcap0Mode;
float _Matcap0Emission;

float _Enable_Matcap1;
texture2D _Matcap1;
texture2D _Matcap1_Mask;
float _Matcap1_Mask_Invert;
float _Matcap1Str;
float _Matcap1Mode;
float _Matcap1Emission;

float _Rim_Lighting0_Enabled;
float _Rim_Lighting0_Mode;
float3 _Rim_Lighting0_Color;
texture2D _Rim_Lighting0_Mask;
float _Rim_Lighting0_Mask_Invert;
float _Rim_Lighting0_Center;
float _Rim_Lighting0_Power;
float _Rim_Lighting0_Strength;
float _Rim_Lighting0_Emission;

float _Rim_Lighting1_Enabled;
float _Rim_Lighting1_Mode;
float3 _Rim_Lighting1_Color;
texture2D _Rim_Lighting1_Mask;
float _Rim_Lighting1_Mask_Invert;
float _Rim_Lighting1_Center;
float _Rim_Lighting1_Power;
float _Rim_Lighting1_Strength;
float _Rim_Lighting1_Emission;

float _OKLAB_Enabled;
texture2D _OKLAB_Mask;
float _OKLAB_Lightness_Shift;
float _OKLAB_Chroma_Shift;
float _OKLAB_Hue_Shift;

float _Clones_Enabled;
float _Clones_Count;
float _Clones_dx;
float _Clones_Dist_Cutoff;

float _UVScroll_Enabled;
texture2D _UVScroll_Mask;
float _UVScroll_U_Speed;
float _UVScroll_V_Speed;
texture2D _UVScroll_Alpha;

float _LTCGI_Enabled;
float4 _LTCGI_SpecularColor;
float4 _LTCGI_DiffuseColor;

#endif

