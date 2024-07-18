Shader "yum_food/tooner"
{
  Properties
  {
    _Color("Base color", Color) = (0.8, 0.8, 0.8, 1)
    _Metallic("Metallic", Range(0, 1)) = 0
    _Roughness("Roughness", Range(0, 1)) = 1

    _Clearcoat_Enabled("Clearcoat enabled", Float) = 0
    _Clearcoat_Strength("Clearcoat strength", Range(0, 1)) = 0
    _Clearcoat_Roughness("Clearcoat strength", Range(0, 1)) = 0
    _Clearcoat_Mask("Clearcoat mask", 2D) = "white" {}

    [NoScaleOffset] _MainTex("Base color", 2D) = "white" {}
    [NoScaleOffset] _NormalTex("Normal", 2D) = "bump" {}
    [NoScaleOffset] _MetallicTex("Metallic", 2D) = "white" {}
    [NoScaleOffset] _RoughnessTex("Roughness", 2D) = "black" {}

    _PBR_Overlay0_Enable("Enable PBR overlay", Float) = 0.0
    _PBR_Overlay0_BaseColor("Base color", Color) = (0.8, 0.8, 0.8, 1)
    _PBR_Overlay0_Metallic("Metallic", Range(0, 1)) = 0
    _PBR_Overlay0_Roughness("Roughness", Range(0, 1)) = 1
    _PBR_Overlay0_BaseColorTex("Base color", 2D) = "white" {}
    _PBR_Overlay0_Emission("Emission", Color) = (1, 1, 1, 1)
    _PBR_Overlay0_EmissionTex("Emission", 2D) = "black" {}
    _PBR_Overlay0_NormalTex("Normal", 2D) = "bump" {}
    _PBR_Overlay0_MetallicTex("Metallic", 2D) = "white" {}
    _PBR_Overlay0_RoughnessTex("Roughness", 2D) = "black" {}
    _PBR_Overlay0_Tex_NormalStr("Normal texture strength", Range(0, 10)) = 1
    _PBR_Overlay0_Mask("Mask", 2D) = "white" {}
    _PBR_Overlay0_Mask_Invert("Mask invert", Float) = 0.0
    _PBR_Overlay0_Mix("Mix mode", Float) = 0.0

    _PBR_Overlay1_Enable("Enable PBR overlay", Float) = 0.0
    _PBR_Overlay1_BaseColor("Base color", Color) = (0.8, 0.8, 0.8, 1)
    _PBR_Overlay1_Metallic("Metallic", Range(0, 1)) = 0
    _PBR_Overlay1_Roughness("Roughness", Range(0, 1)) = 1
    _PBR_Overlay1_BaseColorTex("Base color", 2D) = "white" {}
    _PBR_Overlay1_Emission("Emission", Color) = (1, 1, 1, 1)
    _PBR_Overlay1_EmissionTex("Emission", 2D) = "black" {}
    _PBR_Overlay1_NormalTex("Normal", 2D) = "bump" {}
    _PBR_Overlay1_MetallicTex("Metallic", 2D) = "white" {}
    _PBR_Overlay1_RoughnessTex("Roughness", 2D) = "black" {}
    _PBR_Overlay1_Tex_NormalStr("Normal texture strength", Range(0, 10)) = 1
    _PBR_Overlay1_Mask("Mask", 2D) = "white" {}
    _PBR_Overlay1_Mask_Invert("Mask invert", Float) = 0.0
    _PBR_Overlay1_Mix("Mix mode", Float) = 0.0

    _PBR_Overlay2_Enable("Enable PBR overlay", Float) = 0.0
    _PBR_Overlay2_BaseColor("Base color", Color) = (0.8, 0.8, 0.8, 1)
    _PBR_Overlay2_Metallic("Metallic", Range(0, 1)) = 0
    _PBR_Overlay2_Roughness("Roughness", Range(0, 1)) = 1
    _PBR_Overlay2_BaseColorTex("Base color", 2D) = "white" {}
    _PBR_Overlay2_Emission("Emission", Color) = (1, 1, 1, 1)
    _PBR_Overlay2_EmissionTex("Emission", 2D) = "black" {}
    _PBR_Overlay2_NormalTex("Normal", 2D) = "bump" {}
    _PBR_Overlay2_MetallicTex("Metallic", 2D) = "white" {}
    _PBR_Overlay2_RoughnessTex("Roughness", 2D) = "black" {}
    _PBR_Overlay2_Tex_NormalStr("Normal texture strength", Range(0, 10)) = 1
    _PBR_Overlay2_Mask("Mask", 2D) = "white" {}
    _PBR_Overlay2_Mask_Invert("Mask invert", Float) = 0.0
    _PBR_Overlay2_Mix("Mix mode", Float) = 0.0

    _PBR_Overlay3_Enable("Enable PBR overlay", Float) = 0.0
    _PBR_Overlay3_BaseColor("Base color", Color) = (0.8, 0.8, 0.8, 1)
    _PBR_Overlay3_Metallic("Metallic", Range(0, 1)) = 0
    _PBR_Overlay3_Roughness("Roughness", Range(0, 1)) = 1
    _PBR_Overlay3_BaseColorTex("Base color", 2D) = "white" {}
    _PBR_Overlay3_Emission("Emission", Color) = (1, 1, 1, 1)
    _PBR_Overlay3_EmissionTex("Emission", 2D) = "black" {}
    _PBR_Overlay3_NormalTex("Normal", 2D) = "bump" {}
    _PBR_Overlay3_MetallicTex("Metallic", 2D) = "white" {}
    _PBR_Overlay3_RoughnessTex("Roughness", 2D) = "black" {}
    _PBR_Overlay3_Tex_NormalStr("Normal texture strength", Range(0, 10)) = 1
    _PBR_Overlay3_Mask("Mask", 2D) = "white" {}
    _PBR_Overlay3_Mask_Invert("Mask invert", Float) = 0.0
    _PBR_Overlay3_Mix("Mix mode", Float) = 0.0

    _Decal0_Enable("Enable decal", Float) = 0.0
    _Decal0_BaseColor("Base color", 2D) = "white" {}
    _Decal0_Emission_Strength("Emission strength", Float) = 0
    _Decal0_Angle("Emission strength", Range(0,1)) = 0

    _Decal1_Enable("Enable decal", Float) = 0.0
    _Decal1_BaseColor("Base color", 2D) = "white" {}
    _Decal1_Emission_Strength("Emission strength", Float) = 0
    _Decal1_Angle("Emission strength", Range(0,1)) = 0

    _Decal2_Enable("Enable decal", Float) = 0.0
    _Decal2_BaseColor("Base color", 2D) = "white" {}
    _Decal2_Emission_Strength("Emission strength", Float) = 0
    _Decal2_Angle("Emission strength", Range(0,1)) = 0

    _Decal3_Enable("Enable decal", Float) = 0.0
    _Decal3_BaseColor("Base color", 2D) = "white" {}
    _Decal3_Emission_Strength("Emission strength", Float) = 0
    _Decal3_Angle("Emission strength", Range(0,1)) = 0

    [NoScaleOffset] _EmissionTex("Emission map", 2D) = "black" {}
    _EmissionStrength("Emission strength", Range(0, 2)) = 0

    [NoScaleOffset] _Tex_NormalStr("Normal texture strength", Range(0, 10)) = 1

		_Cubemap("Cubemap", Cube) = "" {}
    _Lighting_Factor("Lighting factor", Range(0, 5)) = 1
    _Direct_Lighting_Factor("Direct lighting factor", Range(0, 5)) = 1
    _Indirect_Specular_Lighting_Factor("Indirect specular lighting factor", Range(0, 5)) = 1
    _Indirect_Diffuse_Lighting_Factor("Indirect diffuse lighting factor", Range(0, 5)) = 1
    _Reflection_Probe_Saturation("Reflection probe saturation", Range(0, 1)) = 1
    _Min_Brightness("Min brightness", Range(0, 1)) = 0
    _Max_Brightness("Max brightness", Range(0, 1.5)) = 1
    _Mesh_Normal_Strength("Mesh normal strength", Range(0, 10)) = 1
    _NormalStr("Normal strength", Range(0, 10)) = 1
    _Ambient_Occlusion("Ambient occlusion", 2D) = "white" {}
    _Ambient_Occlusion_Strength("Ambient occlusion", Range(0,1)) = 1

    _Shading_Mode("Shading mode", Range(0, 1)) = 0
    _Mesh_Normals_Mode("Normals mode", Float) = 0.0
    _Flatten_Mesh_Normals_Str("Flatten mesh normals strength", Float) = 100.0
    [MaterialToggle] _Confabulate_Normals("Confabulate mesh normals", Float) = 0.0

    _Alpha_Cutoff("Alpha cutoff", Range(0, 1)) = 0.5

    _Outline_Width("Outline width", Range(0, 0.1)) = 0.01
    _Outline_Color("Outline color", Color) = (0, 0, 0, 1)
    _Outline_Emission_Strength("Outline emission strength", Range(0, 2)) = 0.2
    _Outline_Mask("Outline mask", 2D) = "white" {}
    _Outline_Mask_Invert("Invert outline mask", Float) = 0.0
    _Outline_Width_Multiplier("Outline width multiplier", Float) = 1
    [MaterialToggle] _Outline_Stenciling("Enable outline stenciling", Float) = 1

    _Glitter_Enabled("Glitter enabled", Float) = 0
    _Glitter_Mask("Glitter mask", 2D) = "white" {}
    _Glitter_Density("Glitter density", float) = 400
    _Glitter_Amount("Glitter amount", Range(1, 100)) = 35
    _Glitter_Speed("Glitter speed", float) = 1
    _Glitter_Seed("Glitter seed", float) = 1
    _Glitter_Brightness("Glitter brightness", float) = 1
    _Glitter_Angle("Glitter angle", Range(0, 90)) = 90
    _Glitter_Power("Glitter power", float) = 30

		[MaterialToggle] _Explode_Toggle("Explode toggle", Float) = 0
		_Explode_Phase("Explode phase", Range(0, 1)) = 0
    [Enum(UnityEngine.Rendering.CullMode)] _OutlinesCull ("Outlines pass culling mode", Float) = 1
    [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Culling mode", Float) = 2

		[MaterialToggle] _Scroll_Toggle("Scroll toggle", Float) = 0
		_Scroll_Top("Scroll top (m)", Range(-5, 5)) = 1
		_Scroll_Bottom("Scroll bottom (m)", Range(-5, 5)) = 0
		_Scroll_Width("Scroll width", Range(0, 1)) = 0
		_Scroll_Strength("Scroll strength", Range(0, 1)) = 0
    _Scroll_Speed("Scroll speed", Range(0, 1)) = 1

    [HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
    [HideInInspector] _DstBlend ("_SrcBlend", Float) = 0
    [HideInInspector] _ZWrite ("_ZWrite", Float) = 1

    _Matcap0("Matcap", 2D) = "black" {}
    _Matcap0_Mask("Matcap mask", 2D) = "white" {}
    _Matcap0_Mask_Invert("Invert mask", Float) = 0.0
    _Matcap0Mode("Matcap mode", Float) = 0
    _Matcap0Str("Matcap strength", Float) = 1
    _Matcap0Emission("Matcap emission", Float) = 0
    _Matcap0Quantization("Matcap quantization", Float) = -1
    _Matcap0Distortion0("Matcap distortion0", Float) = 0

    _Matcap1("Matcap", 2D) = "black" {}
    _Matcap1_Mask("Matcap mask", 2D) = "white" {}
    _Matcap1_Mask_Invert("Invert mask", Float) = 0.0
    _Matcap1Mode("Matcap mode", Float) = 0
    _Matcap1Str("Matcap strength", Float) = 1
    _Matcap1Emission("Matcap emission", Float) = 0
    _Matcap1Quantization("Matcap quantization", Float) = -1
    _Matcap1Distortion0("Matcap distortion0", Float) = 0

    _Rim_Lighting0_Enabled("Enable rim lighting", Float) = 0
    _Rim_Lighting0_Mode("Rim lighting mode", Float) = 0
    _Rim_Lighting0_Mask("Rim lighting mask", 2D) = "white" {}
    _Rim_Lighting0_Mask_Invert("Invert rim lighting mask", Float) = 0.0
    _Rim_Lighting0_Color("Rim lighting color", Color) = (1, 1, 1, 1)
    _Rim_Lighting0_Center("Rim lighting center", Float) = 0.5
    _Rim_Lighting0_Power("Rim lighting power", Float) = 2.0
    _Rim_Lighting0_Strength("Rim lighting strength", Float) = 1.0
    _Rim_Lighting0_Emission("Rim lighting emission", Float) = 0
    _Rim_Lighting0_Quantization("Rim lighting quantization", Float) = -1
    _Rim_Lighting0_Glitter_Enabled("Rim lighting glitter", Float) = 0
    _Rim_Lighting0_Glitter_Density("Rim lighting glitter density", Float) = 100
    _Rim_Lighting0_Glitter_Amount("Rim lighting glitter amount", Float) = 100
    _Rim_Lighting0_Glitter_Speed("Rim lighting glitter speed", Float) = 1
    _Rim_Lighting0_Glitter_Quantization("Rim lighting glitter quantization", Float) = 1000
    _Rim_Lighting0_PolarMask_Enabled("Rim lighting polar mask enabled", Float) = 0
    _Rim_Lighting0_PolarMask_Theta("Rim lighting polar mask - theta", Float) = 0
    _Rim_Lighting0_PolarMask_Power("Rim lighting polar mask - power", Float) = 3

    _Rim_Lighting1_Enabled("Enable rim lighting", Float) = 0
    _Rim_Lighting1_Mode("Rim lighting mode", Float) = 0
    _Rim_Lighting1_Mask("Rim lighting mask", 2D) = "white" {}
    _Rim_Lighting1_Mask_Invert("Invert rim lighting mask", Float) = 0.0
    _Rim_Lighting1_Color("Rim lighting color", Color) = (1, 1, 1, 1)
    _Rim_Lighting1_Center("Rim lighting center", Float) = 0.5
    _Rim_Lighting1_Power("Rim lighting power", Float) = 2.0
    _Rim_Lighting1_Strength("Rim lighting strength", Float) = 1.0
    _Rim_Lighting1_Emission("Rim lighting emission", Float) = 0
    _Rim_Lighting1_Quantization("Rim lighting quantization", Float) = -1
    _Rim_Lighting1_Glitter_Enabled("Rim lighting glitter", Float) = 0
    _Rim_Lighting1_Glitter_Density("Rim lighting glitter density", Float) = 100
    _Rim_Lighting1_Glitter_Amount("Rim lighting glitter amount", Float) = 100
    _Rim_Lighting1_Glitter_Speed("Rim lighting glitter speed", Float) = 1
    _Rim_Lighting1_Glitter_Quantization("Rim lighting glitter quantization", Float) = 1000
    _Rim_Lighting1_PolarMask_Enabled("Rim lighting polar mask enabled", Float) = 0
    _Rim_Lighting1_PolarMask_Theta("Rim lighting polar mask - theta", Float) = 0
    _Rim_Lighting1_PolarMask_Power("Rim lighting polar mask - power", Float) = 3

    _OKLAB_Enabled("Enable OKLAB", Float) = 0.0
    _OKLAB_Mask("Mask", 2D) = "white" {}
    _OKLAB_Lightness_Shift("OKLAB lightness shift", Range(-1.0, 1.0)) = 0.0
    _OKLAB_Chroma_Shift("OKLAB chroma shift", Range(-0.37, 0.37)) = 0.0
    _OKLAB_Hue_Shift("OKLAB hue shift", Range(0, 6.283185307)) = 0.0

    _Clones_Enabled("Enable clones", Float) = 0.0
    _Clones_Count("Clones count", Range(0,16)) = 0.0
    _Clones_Dist_Cutoff("Clones distance cutoff", Float) = -1.0
    _Clones_dx("Clones dx", Range(0, 1)) = 1.0

    _UVScroll_Enabled("Enable UV scrolling", Float) = 0.0
    _UVScroll_Mask("UV scroll mask", 2D) = "white"
    _UVScroll_U_Speed("UV scroll U speed", Float) = 0.0
    _UVScroll_V_Speed("UV scroll V speed", Float) = 1.0
    _UVScroll_Alpha("UV scroll alpha", 2D) = "white" {}

    _LTCGI_Enabled("LTCGI enabled", Float) = 0.0
    _LTCGI_SpecularColor("LTCGI specular color", Color) = (1, 1, 1, 1)
    _LTCGI_DiffuseColor("LTCGI diffuse color", Color) = (1, 1, 1, 1)

    _Enable_Tessellation("Enable tessellation", Float) = 0.0
    _Tess_Factor("Tessellation factor", Range(1, 64)) = 1.0
    _Tess_Dist_Cutoff("Tessellation distance cutoff", Float) = -1.0

    _Cutout_Mode("Cutout rendering mode", Float) = 0.0
    _Render_Queue_Offset("Render queue offset", Integer) = 0

    _Shadow_Strength("Shadows strength", Range(0, 1)) = 1.0
    _Mip_Multiplier("Mipmap multiplier", Float) = 1.0

    _Gimmick_Flat_Color_Enable_Static("Enable flat color gimmick", Float) = 0.0
    _Gimmick_Flat_Color_Enable_Dynamic("Enable flat color gimmick", Float) = 0.0
    _Gimmick_Flat_Color_Color("Flat color gimmick color", Color) = (0, 0, 0, 1)
    _Gimmick_Flat_Color_Emission("Flat color gimmick emission", Color) = (0, 0, 0, 1)

    _Gimmick_Quantize_Location_Enable_Static("Enable quantize location gimmick", Float) = 0.0
    _Gimmick_Quantize_Location_Enable_Dynamic("quantize location gimmick", Float) = 0.0
    _Gimmick_Quantize_Location_Precision("quantize location precision", Float) = 100.0
    _Gimmick_Quantize_Location_Direction("quantize location direction", Float) = 1.0
    _Gimmick_Quantize_Location_Multiplier("quantize location multiplier", Range(0.01, 4)) = 1.0
    _Gimmick_Quantize_Location_Mask("Mask", 2D) = "white" {}
    _Gimmick_Quantize_Location_Audiolink_Enable_Static("Audiolink static", Float) = 0.0
    _Gimmick_Quantize_Location_Audiolink_Enable_Dynamic("Audiolink dynamic", Float) = 0.0
    _Gimmick_Quantize_Location_Audiolink_Strength("Strength", Float) = 1.0

    _Gimmick_Shear_Location_Enable_Static("Enable shear location gimmick", Float) = 0.0
    _Gimmick_Shear_Location_Enable_Dynamic("Enable shear location gimmick", Float) = 0.0
    _Gimmick_Shear_Location_Strength("Strength", Vector) = (1, 1, 1, 1)
    _Gimmick_Shear_Location_Mesh_Renderer_Fix("Mesh renderer fix", Float) = 0.0
    _Gimmick_Shear_Location_Mesh_Renderer_Offset("Mesh renderer offset", Vector) = (0, 0, 0, 0)
    _Gimmick_Shear_Location_Mesh_Renderer_Rotation("Mesh renderer rotation", Vector) = (0, 0, 0, 0)
    _Gimmick_Shear_Location_Mesh_Renderer_Scale("Mesh renderer scale", Vector) = (0, 0, 0, 0)

    _Gimmick_Vertex_Normal_Slide_Enable_Static("Enable vertex normal slide", Float) = 0.0
    _Gimmick_Vertex_Normal_Slide_Enable_Dynamic("Enable vertex normal slide", Float) = 0.0
    _Gimmick_Vertex_Normal_Slide_Distance("Vertex normal slide distance", Float) = 0.01

    _Gimmick_Eyes00_Enable_Static("Enable eyes 00", Float) = 0.0
    _Gimmick_Eyes00_Effect_Mask("Effect mask", 2D) = "white"

    _Gimmick_Pixellate_Enable_Static("Enable pixellation", Float) = 0.0
    _Gimmick_Pixellate_Resolution_U("Resolution (U)", Float) = 64
    _Gimmick_Pixellate_Resolution_V("Resolution (V)", Float) = 64
    _Gimmick_Pixellate_Effect_Mask("Effect mask", 2D) = "white"

    _Trochoid_Enable_Static("Enable trochoid", Float) = 0.0
    _Trochoid_R("R", Float) = 5.0
    _Trochoid_r("r", Float) = 3.0
    _Trochoid_d("d", Float) = 5.0

    _Enable_SSR("Enable SSR", Float) = 0
    _SSRStrength("SSR Strength", Float) = 1
    _SSRHeight("SSR Height", Float) = 0.1
    [HideInInspector]_NoiseTexSSR("SSR Noise Texture", 2D) = "black" {}
    _EdgeFade("Edge Fade", Range(0,1)) = 0.1
    [ToggleUI]_EdgeFadeToggle("Edge Fade Toggle", Int) = 1

    _ScatterDist("_ScatterDist", Float) = 0
    _ScatterPow("_ScatterPow", Float) = 0
    _ScatterIntensity("_ScatterIntensity", Float) = 0
    _ScatterAmbient("_ScatterAmbient", Float) = 0
    _GSAA("_GSAA", Float) = 0
    _GSAAStrength("_GSAAStrength", Float) = 0
    _WrappingFactor("_WrappingFactor", Float) = 0
    _Subsurface("_Subsurface", Float) = 0
    _SpecularStrength("_SpecularStrength", Float) = 1
    _FresnelStrength("_FresnelStrength", Float) = 1
    _UseFresnel("_UseFresnel", Float) = 1
    _ReflectionStrength("_ReflectionStrength", Float) = 1
    shadowedReflections("shadowedReflections", Vector) = (0, 0, 0, 0)
    _ReflShadows("_ReflShadows", Vector) = (0, 0, 0, 0)
    _ReflShadowStrength("_ReflShadowStrength", Vector) = (0, 0, 0, 0)
  }
  SubShader
  {
    Tags {
      "VRCFallback"="ToonCutout"
    }
    Pass {
      Tags {
        "RenderType"="Opaque"
        "Queue"="Geometry"
        "LightMode"="ForwardBase"
      }
      Blend [_SrcBlend] [_DstBlend]
      ZWrite [_ZWrite]
      ZTest LEqual
      Cull [_Cull]

      Stencil {
        Ref 1
        Comp Always
        Pass Replace
      }

      CGPROGRAM
      #pragma target 5.0

      #pragma multi_compile _ VERTEXLIGHT_ON SHADOWS_SCREEN

      #include "feature_macros.cginc"

			#pragma vertex vert
			//#pragma vertex hull_vertex
			//#pragma hull hull
			//#pragma domain domain

      #pragma geometry geom
      #pragma fragment frag

      #define FORWARD_BASE_PASS

      #include "tooner_lighting.cginc"
      ENDCG
    }
    Pass {
      Tags {
        "RenderType" = "Opaque"
        "Queue"="Geometry"
        "LightMode" = "ForwardAdd"
      }
      Blend [_SrcBlend] One
      ZWrite Off
      Cull [_Cull]

      CGPROGRAM
      #pragma target 5.0

      #pragma multi_compile_fwdadd_fullshadows
      #pragma multi_compile DIRECTIONAL DIRECTIONAL_COOKIE POINT SPOT
      #include "feature_macros.cginc"

			#pragma vertex vert
			//#pragma vertex hull_vertex
			//#pragma hull hull
			//#pragma domain domain

      #pragma geometry geom
      #pragma fragment frag

      #include "tooner_lighting.cginc"
      ENDCG
    }
		Pass {
      Cull [_OutlinesCull]

      ZWrite [_ZWrite]
      ZTest LEqual

      Stencil {
        Ref [_Outline_Stenciling]
        Comp Greater
      }

			CGPROGRAM
      #pragma target 5.0
      #include "feature_macros.cginc"

			#pragma vertex vert
			//#pragma vertex hull_vertex
			//#pragma hull hull
			//#pragma domain domain

      #pragma geometry geom
			#pragma fragment frag

			#include "tooner_outline_pass.cginc"
			ENDCG
		}
		Pass {
      Tags {
        "LightMode" = "ShadowCaster"
      }
			CGPROGRAM
      #pragma target 5.0
      #include "feature_macros.cginc"

      #pragma vertex vert
      #pragma fragment frag

      #include "mochie_shadow_caster.cginc"
			ENDCG
		}
  }
  CustomEditor "ToonerGUI"
}

