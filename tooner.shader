Shader "yum_food/tooner"
{
  Properties
  {
    _BaseColor("Base color", Color) = (0.8, 0.8, 0.8, 1)
    _Metallic("Metallic", Range(0, 1)) = 0
    _Roughness("Roughness", Range(0, 1)) = 1

    [NoScaleOffset] _BaseColorTex("Base color", 2D) = "white" {}
    [NoScaleOffset] _NormalTex("Normal", 2D) = "bump" {}
    [NoScaleOffset] _MetallicTex("Metallic", 2D) = "white" {}
    [NoScaleOffset] _RoughnessTex("Roughness", 2D) = "black" {}

    _PBR_Overlay_Enable("Enable PBR overlay", Float) = 0.0
    _PBR_Overlay_BaseColor("Base color", Color) = (0.8, 0.8, 0.8, 1)
    _PBR_Overlay_Metallic("Metallic", Range(0, 1)) = 0
    _PBR_Overlay_Roughness("Roughness", Range(0, 1)) = 1
    [NoScaleOffset] _PBR_Overlay_BaseColorTex("Base color", 2D) = "white" {}
    [NoScaleOffset] _PBR_Overlay_NormalTex("Normal", 2D) = "bump" {}
    [NoScaleOffset] _PBR_Overlay_MetallicTex("Metallic", 2D) = "white" {}
    [NoScaleOffset] _PBR_Overlay_RoughnessTex("Roughness", 2D) = "black" {}
    [NoScaleOffset] _PBR_Overlay_Tex_NormalStr("Normal texture strength", Range(0, 10)) = 1
    [NoScaleOffset] _PBR_Overlay_Mask("Mask", 2D) = "white" {}

    [NoScaleOffset] _EmissionTex("Emission map", 2D) = "black" {}
    _EmissionStrength("Emission strength", Range(0, 2)) = 0

    [NoScaleOffset] _Tex_NormalStr("Normal texture strength", Range(0, 10)) = 1

		_Cubemap("Cubemap", Cube) = "" {}
    _Min_Brightness("Min brightness", Range(0, 1)) = 0
    _Max_Brightness("Max brightness", Range(0, 1.5)) = 1
    _Mesh_Normal_Strength("Mesh normal strength", Range(0, 10)) = 1
    _NormalStr("Normal strength", Range(0, 10)) = 1

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
    _Matcap0Distortion0("Matcap distortion0", Float) = 0

    _Matcap1("Matcap", 2D) = "black" {}
    _Matcap1_Mask("Matcap mask", 2D) = "white" {}
    _Matcap1_Mask_Invert("Invert mask", Float) = 0.0
    _Matcap1Mode("Matcap mode", Float) = 0
    _Matcap1Str("Matcap strength", Float) = 1
    _Matcap1Emission("Matcap emission", Float) = 0
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

    _Rim_Lighting1_Enabled("Enable rim lighting", Float) = 0
    _Rim_Lighting1_Mode("Rim lighting mode", Float) = 0
    _Rim_Lighting1_Mask("Rim lighting mask", 2D) = "white" {}
    _Rim_Lighting1_Mask_Invert("Invert rim lighting mask", Float) = 0.0
    _Rim_Lighting1_Color("Rim lighting color", Color) = (1, 1, 1, 1)
    _Rim_Lighting1_Center("Rim lighting center", Float) = 0.5
    _Rim_Lighting1_Power("Rim lighting power", Float) = 2.0
    _Rim_Lighting1_Strength("Rim lighting strength", Float) = 1.0
    _Rim_Lighting1_Emission("Rim lighting emission", Float) = 0

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
  }
  SubShader
  {
    Pass {
      Tags {
        "RenderType"="Opaque"
        "Queue"="Geometry"
        "LightMode" = "ForwardBase"
        "VRCFallback"="Hidden"
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

      #pragma multi_compile _ LIGHTMAP_ON VERTEXLIGHT_ON
      #pragma shader_feature_local _ _BASECOLOR_MAP
      #pragma shader_feature_local _ _NORMAL_MAP
      #pragma shader_feature_local _ _METALLIC_MAP
      #pragma shader_feature_local _ _ROUGHNESS_MAP
      #pragma shader_feature_local _ _CUBEMAP
      #pragma shader_feature_local _ _EMISSION
      //#pragma shader_feature_local _ _SHADING_MODE_FLAT
      #pragma shader_feature_local _ _RENDERING_CUTOUT
      #pragma shader_feature_local _ _RENDERING_CUTOUT_STOCHASTIC
      #pragma shader_feature_local _ _RENDERING_FADE
      #pragma shader_feature_local _ _OUTLINES
      #pragma shader_feature_local _ _GLITTER
      #pragma shader_feature_local _ _EXPLODE
      #pragma shader_feature_local _ _SCROLL
      #pragma shader_feature_local _ _UVSCROLL
      #pragma shader_feature_local _ _MATCAP0
      #pragma shader_feature_local _ _MATCAP0_MASK
      #pragma shader_feature_local _ _MATCAP1
      #pragma shader_feature_local _ _MATCAP1_MASK
      #pragma shader_feature_local _ _RIM_LIGHTING0
      #pragma shader_feature_local _ _RIM_LIGHTING0_MASK
      #pragma shader_feature_local _ _RIM_LIGHTING1
      #pragma shader_feature_local _ _RIM_LIGHTING1_MASK
      #pragma shader_feature_local _ _OKLAB
      #pragma shader_feature_local _ _CLONES
      #pragma shader_feature_local _ _PBR_OVERLAY
      #pragma shader_feature_local _ _PBR_OVERLAY_BASECOLOR_MAP
      #pragma shader_feature_local _ _PBR_OVERLAY_NORMAL_MAP
      #pragma shader_feature_local _ _PBR_OVERLAY_ROUGHNESS_MAP
      #pragma shader_feature_local _ _PBR_OVERLAY_METALLIC_MAP
      #pragma shader_feature_local _ _LTCGI
      #pragma shader_feature_local _ _TESSELLATION
      #pragma shader_feature_local _ _MATCAP0_DISTORTION0
      #pragma shader_feature_local _ _MATCAP1_DISTORTION0

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
        "VRCFallback"="Hidden"
      }
      Blend [_SrcBlend] One
      ZWrite Off
      Cull [_Cull]

      CGPROGRAM
      #pragma target 5.0

      #pragma multi_compile_fwdadd
      #pragma multi_compile DIRECTIONAL DIRECTIONAL_COOKIE POINT SPOT
      #pragma shader_feature_local _BASECOLOR_MAP
      #pragma shader_feature_local _NORMAL_MAP
      #pragma shader_feature_local _METALLIC_MAP
      #pragma shader_feature_local _ROUGHNESS_MAP
      #pragma shader_feature_local _CUBEMAP
      #pragma shader_feature_local _ _EMISSION
      //#pragma shader_feature_local _SHADING_MODE_FLAT
      #pragma shader_feature_local _RENDERING_CUTOUT
      #pragma shader_feature_local _RENDERING_CUTOUT_STOCHASTIC
      #pragma shader_feature_local _RENDERING_FADE
      #pragma shader_feature_local _OUTLINES
      #pragma shader_feature_local _GLITTER
      #pragma shader_feature_local _EXPLODE
      #pragma shader_feature_local _SCROLL
      #pragma shader_feature_local _UVSCROLL
      #pragma shader_feature_local _MATCAP0
      #pragma shader_feature_local _ _MATCAP0_MASK
      #pragma shader_feature_local _MATCAP1
      #pragma shader_feature_local _ _MATCAP1_MASK
      #pragma shader_feature_local _ _RIM_LIGHTING0
      #pragma shader_feature_local _ _RIM_LIGHTING0_MASK
      #pragma shader_feature_local _ _RIM_LIGHTING1
      #pragma shader_feature_local _ _RIM_LIGHTING1_MASK
      #pragma shader_feature_local _ _OKLAB
      #pragma shader_feature_local _ _CLONES
      #pragma shader_feature_local _ _PBR_OVERLAY
      #pragma shader_feature_local _ _PBR_OVERLAY_BASECOLOR_MAP
      #pragma shader_feature_local _ _PBR_OVERLAY_NORMAL_MAP
      #pragma shader_feature_local _ _PBR_OVERLAY_ROUGHNESS_MAP
      #pragma shader_feature_local _ _PBR_OVERLAY_METALLIC_MAP
      #pragma shader_feature_local _ _LTCGI
      #pragma shader_feature_local _ _TESSELLATION
      #pragma shader_feature_local _ _MATCAP0_DISTORTION0
      #pragma shader_feature_local _ _MATCAP1_DISTORTION0

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

			CGPROGRAM
      #pragma target 5.0
			#pragma shader_feature_local _BASECOLOR_MAP
			#pragma shader_feature_local _RENDERING_CUTOUT
      #pragma shader_feature_local _RENDERING_CUTOUT_STOCHASTIC
			#pragma shader_feature_local _OUTLINES
      #pragma shader_feature_local _EXPLODE
      #pragma shader_feature_local _ _SCROLL
      #pragma shader_feature_local _ _UVSCROLL
      #pragma shader_feature_local _MATCAP0
      #pragma shader_feature_local _ _MATCAP0_MASK
      #pragma shader_feature_local _MATCAP1
      #pragma shader_feature_local _ _MATCAP1_MASK
      #pragma shader_feature_local _ _RIM_LIGHTING0
      #pragma shader_feature_local _ _RIM_LIGHTING0_MASK
      #pragma shader_feature_local _ _RIM_LIGHTING1
      #pragma shader_feature_local _ _RIM_LIGHTING1_MASK
      #pragma shader_feature_local _ _OKLAB
      #pragma shader_feature_local _ _CLONES
      #pragma shader_feature_local _ _PBR_OVERLAY
      #pragma shader_feature_local _ _PBR_OVERLAY_BASECOLOR_MAP
      #pragma shader_feature_local _ _PBR_OVERLAY_NORMAL_MAP
      #pragma shader_feature_local _ _PBR_OVERLAY_ROUGHNESS_MAP
      #pragma shader_feature_local _ _PBR_OVERLAY_METALLIC_MAP
      #pragma shader_feature_local _ _LTCGI
      #pragma shader_feature_local _ _TESSELLATION

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
        "VRCFallback"="Hidden"
      }
			CGPROGRAM
      #include "mochie_shadow_caster.cginc"
			ENDCG
		}
  }
  Fallback "Transparent"
  CustomEditor "ToonerGUI"
}

