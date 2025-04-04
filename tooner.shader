Shader "yum_food/tooner"
{
  // Unity fucking sucks ass and sometimes incorrectly uses an old cached
  // version of the shader. Bump the nonce below to encourage it to use the
  // current version.
  // Build nonce: 39
  Properties
  {
    _Color("Base color", Color) = (0.8, 0.8, 0.8, 1)
    _Metallic("Metallic", Range(0, 1)) = 0
    _Roughness("Roughness", Range(0, 4)) = 0.5
    _Roughness_Invert("Roughness invert", Float) = 0

    _Clearcoat_Enabled("Clearcoat enabled", Float) = 0
    _Clearcoat_Strength("Clearcoat strength", Range(0, 1)) = 0
    _Clearcoat_Roughness("Clearcoat strength", Range(0, 1)) = 0
    _Clearcoat_Mask("Clearcoat mask", 2D) = "white" {}
    _Clearcoat_Mask_Invert("Clearcoat mask invert", Float) = 0
    _Clearcoat_Mask2("Clearcoat mask 2", 2D) = "white" {}
    _Clearcoat_Mask2_Invert("Clearcoat mask 2 invert", Float) = 0
    _Clearcoat_Use_Texture_Normals("Use texture normals", Float) = 1

    _Rendering_Cutout_Noise_Mask("Noise mask", 2D) = "white" {}
    _Rendering_Cutout_Speed("Speed (for stochastic methods)", Float) = 1
    _Rendering_Cutout_SSFD_Scale("Scale", Float) = 1
    _Rendering_Cutout_SSFD_Max_Fwidth("Max fwidth", Float) = 1
    _Rendering_Cutout_SSFD_Noise("Noise", 3D) = "black" {}

    _MainTex("Base color", 2D) = "white" {}
    [Normal] _BumpMap("Normal", 2D) = "bump" {}
    _MetallicTex("Metallic", 2D) = "white" {}
    _MetallicTexChannel("Metallic", Range(0, 3)) = 2
    _RoughnessTex("Roughness", 2D) = "black" {}
    _RoughnessTexChannel("Roughness", Range(0, 3)) = 1
    _PBR_Sampler_Mode("Sampler mode", Range(0,1)) = 0

    _PBR_Overlay0_Enable("Enable PBR overlay", Float) = 0.0
    _PBR_Overlay0_BaseColor("Base color", Color) = (0.8, 0.8, 0.8, 1)
    _PBR_Overlay0_Metallic_Enable("Metallic enable", Float) = 0
    _PBR_Overlay0_Metallic("Metallic", Range(0, 1)) = 0
    _PBR_Overlay0_Roughness_Enable("Roughness enable", Float) = 0
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
    _PBR_Overlay0_Constrain_By_Alpha("Constrain by alpha channel", Float) = 0.0
    _PBR_Overlay0_Constrain_By_Alpha_Min("Constrain by alpha channel", Range(0, 1)) = 0
    _PBR_Overlay0_Constrain_By_Alpha_Max("Constrain by alpha channel", Range(0, 1)) = 1
    _PBR_Overlay0_Alpha_Multiplier("Constrain by alpha channel", Range(0, 5)) = 1
    _PBR_Overlay0_UV_Select("UV channel", Range(0,7)) = 0
    _PBR_Overlay0_Sampler_Mode("Sampler mode", Range(0,1)) = 0
    _PBR_Overlay0_Mip_Bias("Mip bias", Float) = 0.0
    _PBR_Overlay0_Mask_Glitter("Mask glitter", Float) = 0.0

    _PBR_Overlay1_Enable("Enable PBR overlay", Float) = 0.0
    _PBR_Overlay1_BaseColor("Base color", Color) = (0.8, 0.8, 0.8, 1)
    _PBR_Overlay1_Metallic_Enable("Metallic enable", Float) = 0
    _PBR_Overlay1_Metallic("Metallic", Range(0, 1)) = 0
    _PBR_Overlay1_Roughness_Enable("Roughness enable", Float) = 0
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
    _PBR_Overlay1_Constrain_By_Alpha("Constrain by alpha channel", Float) = 0.0
    _PBR_Overlay1_Constrain_By_Alpha_Min("Constrain by alpha channel", Range(0, 1)) = 0
    _PBR_Overlay1_Constrain_By_Alpha_Max("Constrain by alpha channel", Range(0, 1)) = 1
    _PBR_Overlay1_Alpha_Multiplier("Constrain by alpha channel", Range(0, 5)) = 1
    _PBR_Overlay1_UV_Select("UV channel", Range(0,7)) = 0
    _PBR_Overlay1_Sampler_Mode("Sampler mode", Range(0,1)) = 0
    _PBR_Overlay1_Mip_Bias("Mip bias", Float) = 0.0
    _PBR_Overlay1_Mask_Glitter("Mask glitter", Float) = 0.0

    _PBR_Overlay2_Enable("Enable PBR overlay", Float) = 0.0
    _PBR_Overlay2_BaseColor("Base color", Color) = (0.8, 0.8, 0.8, 1)
    _PBR_Overlay2_Metallic_Enable("Metallic enable", Float) = 0
    _PBR_Overlay2_Metallic("Metallic", Range(0, 1)) = 0
    _PBR_Overlay2_Roughness_Enable("Roughness enable", Float) = 0
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
    _PBR_Overlay2_Constrain_By_Alpha("Constrain by alpha channel", Float) = 0.0
    _PBR_Overlay2_Constrain_By_Alpha_Min("Constrain by alpha channel", Range(0, 1)) = 0
    _PBR_Overlay2_Constrain_By_Alpha_Max("Constrain by alpha channel", Range(0, 1)) = 1
    _PBR_Overlay2_Alpha_Multiplier("Constrain by alpha channel", Range(0, 5)) = 1
    _PBR_Overlay2_UV_Select("UV channel", Range(0,7)) = 0
    _PBR_Overlay2_Sampler_Mode("Sampler mode", Range(0,1)) = 0
    _PBR_Overlay2_Mip_Bias("Mip bias", Float) = 0.0
    _PBR_Overlay2_Mask_Glitter("Mask glitter", Float) = 0.0

    _PBR_Overlay3_Enable("Enable PBR overlay", Float) = 0.0
    _PBR_Overlay3_BaseColor("Base color", Color) = (0.8, 0.8, 0.8, 1)
    _PBR_Overlay3_Metallic_Enable("Metallic enable", Float) = 0
    _PBR_Overlay3_Metallic("Metallic", Range(0, 1)) = 0
    _PBR_Overlay3_Roughness_Enable("Roughness enable", Float) = 0
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
    _PBR_Overlay3_Constrain_By_Alpha("Constrain by alpha channel", Float) = 0.0
    _PBR_Overlay3_Constrain_By_Alpha_Min("Constrain by alpha channel", Range(0, 1)) = 0
    _PBR_Overlay3_Constrain_By_Alpha_Max("Constrain by alpha channel", Range(0, 1)) = 1
    _PBR_Overlay3_Alpha_Multiplier("Constrain by alpha channel", Range(0, 5)) = 1
    _PBR_Overlay3_UV_Select("UV channel", Range(0,7)) = 0
    _PBR_Overlay3_Sampler_Mode("Sampler mode", Range(0,1)) = 0
    _PBR_Overlay3_Mip_Bias("Mip bias", Float) = 0.0
    _PBR_Overlay3_Mask_Glitter("Mask glitter", Float) = 0.0

    _Decal0_Enable("Enable decal", Float) = 0.0
    _Decal0_Color("Base color", Color) = (1, 1, 1, 1)
    _Decal0_BaseColor("Base color", 2D) = "white" {}
    _Decal0_BaseColor_Mode("Base color mode", Float) = 0
    _Decal0_SDF_Threshold("SDF threshold", Range(0, 1)) = 0.5
    _Decal0_SDF_Invert("SDF invert", Float) = 0
    _Decal0_SDF_Softness("SDF softness", Range(0, 1)) = 0.01
    _Decal0_SDF_Px_Range("SDF px range", Float) = 2
    _Decal0_Roughness("Roughness", 2D) = "white" {}
    _Decal0_Metallic("Metallic", 2D) = "black" {}
    _Decal0_Emission_Strength("Emission strength", Float) = 0
    _Decal0_Angle("Emission strength", Range(0,1)) = 0
    _Decal0_Alpha_Multiplier("Alpha multiplier", Range(0, 1)) = 1
    _Decal0_Round_Alpha_Multiplier("Round alpha multiplier", Float) = 0
    _Decal0_Mask("Mask", 2D) = "white" {}
    _Decal0_Mask_Invert("Mask invert", Float) = 0.0
    _Decal0_Tiling_Mode("Tiling mode", Range(0,1)) = 0
    _Decal0_UV_Select("UV channel", Range(0,7)) = 0
    _Decal0_Domain_Warping_Enable_Static("Enable domain warping", Float) = 0
    _Decal0_Domain_Warping_Noise("Domain warping noise", 2D) = "black" {}
    _Decal0_Domain_Warping_Strength("Domain warping noise strength", Float) = 0.05
    _Decal0_Domain_Warping_Speed("Domain warping noise speed", Float) = .1
    _Decal0_Domain_Warping_Octaves("Domain warping octaves", Float) = 5
    _Decal0_Domain_Warping_Scale("Domain warping scale", Float) = .1

    _Decal1_Enable("Enable decal", Float) = 0.0
    _Decal1_Color("Base color", Color) = (1, 1, 1, 1)
    _Decal1_BaseColor("Base color", 2D) = "white" {}
    _Decal1_BaseColor_Mode("Base color mode", Float) = 0
    _Decal1_SDF_Threshold("SDF threshold", Range(0, 1)) = 0.5
    _Decal1_SDF_Invert("SDF invert", Float) = 0
    _Decal1_SDF_Softness("SDF softness", Range(0, 1)) = 0.01
    _Decal1_SDF_Px_Range("SDF px range", Float) = 2
    _Decal1_Roughness("Roughness", 2D) = "white" {}
    _Decal1_Metallic("Metallic", 2D) = "black" {}
    _Decal1_Emission_Strength("Emission strength", Float) = 0
    _Decal1_Angle("Emission strength", Range(0,1)) = 0
    _Decal1_Alpha_Multiplier("Alpha multiplier", Range(0, 1)) = 1
    _Decal1_Round_Alpha_Multiplier("Round alpha multiplier", Float) = 0
    _Decal1_Mask("Mask", 2D) = "white" {}
    _Decal1_Mask_Invert("Mask invert", Float) = 0.0
    _Decal1_Tiling_Mode("Tiling mode", Range(0,1)) = 0
    _Decal1_UV_Select("UV channel", Range(0,7)) = 0
    _Decal1_Domain_Warping_Enable_Static("Enable domain warping", Float) = 0
    _Decal1_Domain_Warping_Noise("Domain warping noise", 2D) = "black" {}
    _Decal1_Domain_Warping_Strength("Domain warping noise strength", Float) = 0.05
    _Decal1_Domain_Warping_Speed("Domain warping noise speed", Float) = .1
    _Decal1_Domain_Warping_Octaves("Domain warping octaves", Float) = 5
    _Decal1_Domain_Warping_Scale("Domain warping scale", Float) = .1

    _Decal2_Enable("Enable decal", Float) = 0.0
    _Decal2_Color("Base color", Color) = (1, 1, 1, 1)
    _Decal2_BaseColor("Base color", 2D) = "white" {}
    _Decal2_BaseColor_Mode("Base color mode", Float) = 0
    _Decal2_SDF_Threshold("SDF threshold", Range(0, 1)) = 0.5
    _Decal2_SDF_Invert("SDF invert", Float) = 0
    _Decal2_SDF_Softness("SDF softness", Range(0, 1)) = 0.01
    _Decal2_SDF_Px_Range("SDF px range", Float) = 2
    _Decal2_Roughness("Roughness", 2D) = "white" {}
    _Decal2_Metallic("Metallic", 2D) = "black" {}
    _Decal2_Emission_Strength("Emission strength", Float) = 0
    _Decal2_Angle("Emission strength", Range(0,1)) = 0
    _Decal2_Alpha_Multiplier("Alpha multiplier", Range(0, 1)) = 1
    _Decal2_Round_Alpha_Multiplier("Round alpha multiplier", Float) = 0
    _Decal2_Mask("Mask", 2D) = "white" {}
    _Decal2_Mask_Invert("Mask invert", Float) = 0.0
    _Decal2_Tiling_Mode("Tiling mode", Range(0,1)) = 0
    _Decal2_UV_Select("UV channel", Range(0,7)) = 0
    _Decal2_Domain_Warping_Enable_Static("Enable domain warping", Float) = 0
    _Decal2_Domain_Warping_Noise("Domain warping noise", 2D) = "black" {}
    _Decal2_Domain_Warping_Strength("Domain warping noise strength", Float) = 0.05
    _Decal2_Domain_Warping_Speed("Domain warping noise speed", Float) = .1
    _Decal2_Domain_Warping_Octaves("Domain warping octaves", Float) = 5
    _Decal2_Domain_Warping_Scale("Domain warping scale", Float) = .1

    _Decal3_Enable("Enable decal", Float) = 0.0
    _Decal3_Color("Base color", Color) = (1, 1, 1, 1)
    _Decal3_BaseColor("Base color", 2D) = "white" {}
    _Decal3_BaseColor_Mode("Base color mode", Float) = 0
    _Decal3_SDF_Threshold("SDF threshold", Range(0, 1)) = 0.5
    _Decal3_SDF_Invert("SDF invert", Float) = 0
    _Decal3_SDF_Softness("SDF softness", Range(0, 1)) = 0.01
    _Decal3_SDF_Px_Range("SDF px range", Float) = 2
    _Decal3_Roughness("Roughness", 2D) = "white" {}
    _Decal3_Metallic("Metallic", 2D) = "black" {}
    _Decal3_Emission_Strength("Emission strength", Float) = 0
    _Decal3_Angle("Emission strength", Range(0,1)) = 0
    _Decal3_Alpha_Multiplier("Alpha multiplier", Range(0, 1)) = 1
    _Decal3_Round_Alpha_Multiplier("Round alpha multiplier", Float) = 0
    _Decal3_Mask("Mask", 2D) = "white" {}
    _Decal3_Mask_Invert("Mask invert", Float) = 0.0
    _Decal3_Tiling_Mode("Tiling mode", Range(0,1)) = 0
    _Decal3_UV_Select("UV channel", Range(0,7)) = 0
    _Decal3_Domain_Warping_Enable_Static("Enable domain warping", Float) = 0
    _Decal3_Domain_Warping_Noise("Domain warping noise", 2D) = "black" {}
    _Decal3_Domain_Warping_Strength("Domain warping noise strength", Float) = 0.05
    _Decal3_Domain_Warping_Speed("Domain warping noise speed", Float) = .1
    _Decal3_Domain_Warping_Octaves("Domain warping octaves", Float) = 5
    _Decal3_Domain_Warping_Scale("Domain warping scale", Float) = .1

    _Decal4_Enable("Enable decal", Float) = 0.0
    _Decal4_Color("Base color", Color) = (1, 1, 1, 1)
    _Decal4_BaseColor("Base color", 2D) = "white" {}
    _Decal4_BaseColor_Mode("Base color mode", Float) = 0
    _Decal4_SDF_Threshold("SDF threshold", Range(0, 1)) = 0.5
    _Decal4_SDF_Invert("SDF invert", Float) = 0
    _Decal4_SDF_Softness("SDF softness", Range(0, 1)) = 0.01
    _Decal4_SDF_Px_Range("SDF px range", Float) = 2
    _Decal4_Roughness("Roughness", 2D) = "white" {}
    _Decal4_Metallic("Metallic", 2D) = "black" {}
    _Decal4_Emission_Strength("Emission strength", Float) = 0
    _Decal4_Angle("Emission strength", Range(0,1)) = 0
    _Decal4_Alpha_Multiplier("Alpha multiplier", Range(0, 1)) = 1
    _Decal4_Round_Alpha_Multiplier("Round alpha multiplier", Float) = 0
    _Decal4_Mask("Mask", 2D) = "white" {}
    _Decal4_Mask_Invert("Mask invert", Float) = 0.0
    _Decal4_Tiling_Mode("Tiling mode", Range(0,1)) = 0
    _Decal4_UV_Select("UV channel", Range(0,7)) = 0
    _Decal4_Domain_Warping_Enable_Static("Enable domain warping", Float) = 0
    _Decal4_Domain_Warping_Noise("Domain warping noise", 2D) = "black" {}
    _Decal4_Domain_Warping_Strength("Domain warping noise strength", Float) = 0.05
    _Decal4_Domain_Warping_Speed("Domain warping noise speed", Float) = .1
    _Decal4_Domain_Warping_Octaves("Domain warping octaves", Float) = 5
    _Decal4_Domain_Warping_Scale("Domain warping scale", Float) = .1

    _Decal5_Enable("Enable decal", Float) = 0.0
    _Decal5_Color("Base color", Color) = (1, 1, 1, 1)
    _Decal5_BaseColor("Base color", 2D) = "white" {}
    _Decal5_BaseColor_Mode("Base color mode", Float) = 0
    _Decal5_SDF_Threshold("SDF threshold", Range(0, 1)) = 0.5
    _Decal5_SDF_Invert("SDF invert", Float) = 0
    _Decal5_SDF_Softness("SDF softness", Range(0, 1)) = 0.01
    _Decal5_SDF_Px_Range("SDF px range", Float) = 2
    _Decal5_Roughness("Roughness", 2D) = "white" {}
    _Decal5_Metallic("Metallic", 2D) = "black" {}
    _Decal5_Emission_Strength("Emission strength", Float) = 0
    _Decal5_Angle("Emission strength", Range(0,1)) = 0
    _Decal5_Alpha_Multiplier("Alpha multiplier", Range(0, 1)) = 1
    _Decal5_Round_Alpha_Multiplier("Round alpha multiplier", Float) = 0
    _Decal5_Mask("Mask", 2D) = "white" {}
    _Decal5_Mask_Invert("Mask invert", Float) = 0.0
    _Decal5_Tiling_Mode("Tiling mode", Range(0,1)) = 0
    _Decal5_UV_Select("UV channel", Range(0,7)) = 0
    _Decal5_Domain_Warping_Enable_Static("Enable domain warping", Float) = 0
    _Decal5_Domain_Warping_Noise("Domain warping noise", 2D) = "black" {}
    _Decal5_Domain_Warping_Strength("Domain warping noise strength", Float) = 0.05
    _Decal5_Domain_Warping_Speed("Domain warping noise speed", Float) = .1
    _Decal5_Domain_Warping_Octaves("Domain warping octaves", Float) = 5
    _Decal5_Domain_Warping_Scale("Domain warping scale", Float) = .1

    _Decal6_Enable("Enable decal", Float) = 0.0
    _Decal6_Color("Base color", Color) = (1, 1, 1, 1)
    _Decal6_BaseColor("Base color", 2D) = "white" {}
    _Decal6_BaseColor_Mode("Base color mode", Float) = 0
    _Decal6_SDF_Threshold("SDF threshold", Range(0, 1)) = 0.5
    _Decal6_SDF_Invert("SDF invert", Float) = 0
    _Decal6_SDF_Softness("SDF softness", Range(0, 1)) = 0.01
    _Decal6_SDF_Px_Range("SDF px range", Float) = 2
    _Decal6_Roughness("Roughness", 2D) = "white" {}
    _Decal6_Metallic("Metallic", 2D) = "black" {}
    _Decal6_Emission_Strength("Emission strength", Float) = 0
    _Decal6_Angle("Emission strength", Range(0,1)) = 0
    _Decal6_Alpha_Multiplier("Alpha multiplier", Range(0, 1)) = 1
    _Decal6_Round_Alpha_Multiplier("Round alpha multiplier", Float) = 0
    _Decal6_Mask("Mask", 2D) = "white" {}
    _Decal6_Mask_Invert("Mask invert", Float) = 0.0
    _Decal6_Tiling_Mode("Tiling mode", Range(0,1)) = 0
    _Decal6_UV_Select("UV channel", Range(0,7)) = 0
    _Decal6_Domain_Warping_Enable_Static("Enable domain warping", Float) = 0
    _Decal6_Domain_Warping_Noise("Domain warping noise", 2D) = "black" {}
    _Decal6_Domain_Warping_Strength("Domain warping noise strength", Float) = 0.05
    _Decal6_Domain_Warping_Speed("Domain warping noise speed", Float) = .1
    _Decal6_Domain_Warping_Octaves("Domain warping octaves", Float) = 5
    _Decal6_Domain_Warping_Scale("Domain warping scale", Float) = .1

    _Decal7_Enable("Enable decal", Float) = 0.0
    _Decal7_Color("Base color", Color) = (1, 1, 1, 1)
    _Decal7_BaseColor("Base color", 2D) = "white" {}
    _Decal7_BaseColor_Mode("Base color mode", Float) = 0
    _Decal7_SDF_Threshold("SDF threshold", Range(0, 1)) = 0.5
    _Decal7_SDF_Invert("SDF invert", Float) = 0
    _Decal7_SDF_Softness("SDF softness", Range(0, 1)) = 0.01
    _Decal7_SDF_Px_Range("SDF px range", Float) = 2
    _Decal7_Roughness("Roughness", 2D) = "white" {}
    _Decal7_Metallic("Metallic", 2D) = "black" {}
    _Decal7_Emission_Strength("Emission strength", Float) = 0
    _Decal7_Angle("Emission strength", Range(0,1)) = 0
    _Decal7_Alpha_Multiplier("Alpha multiplier", Range(0, 1)) = 1
    _Decal7_Round_Alpha_Multiplier("Round alpha multiplier", Float) = 0
    _Decal7_Mask("Mask", 2D) = "white" {}
    _Decal7_Mask_Invert("Mask invert", Float) = 0.0
    _Decal7_Tiling_Mode("Tiling mode", Range(0,1)) = 0
    _Decal7_UV_Select("UV channel", Range(0,7)) = 0
    _Decal7_Domain_Warping_Enable_Static("Enable domain warping", Float) = 0
    _Decal7_Domain_Warping_Noise("Domain warping noise", 2D) = "black" {}
    _Decal7_Domain_Warping_Strength("Domain warping noise strength", Float) = 0.05
    _Decal7_Domain_Warping_Speed("Domain warping noise speed", Float) = .1
    _Decal7_Domain_Warping_Octaves("Domain warping octaves", Float) = 5
    _Decal7_Domain_Warping_Scale("Domain warping scale", Float) = .1

    _Decal8_Enable("Enable decal", Float) = 0.0
    _Decal8_Color("Base color", Color) = (1, 1, 1, 1)
    _Decal8_BaseColor("Base color", 2D) = "white" {}
    _Decal8_BaseColor_Mode("Base color mode", Float) = 0
    _Decal8_SDF_Threshold("SDF threshold", Range(0, 1)) = 0.5
    _Decal8_SDF_Invert("SDF invert", Float) = 0
    _Decal8_SDF_Softness("SDF softness", Range(0, 1)) = 0.01
    _Decal8_SDF_Px_Range("SDF px range", Float) = 2
    _Decal8_Roughness("Roughness", 2D) = "white" {}
    _Decal8_Metallic("Metallic", 2D) = "black" {}
    _Decal8_Emission_Strength("Emission strength", Float) = 0
    _Decal8_Angle("Emission strength", Range(0,1)) = 0
    _Decal8_Alpha_Multiplier("Alpha multiplier", Range(0, 1)) = 1
    _Decal8_Round_Alpha_Multiplier("Round alpha multiplier", Float) = 0
    _Decal8_Mask("Mask", 2D) = "white" {}
    _Decal8_Mask_Invert("Mask invert", Float) = 0.0
    _Decal8_Tiling_Mode("Tiling mode", Range(0,1)) = 0
    _Decal8_UV_Select("UV channel", Range(0,7)) = 0
    _Decal8_Domain_Warping_Enable_Static("Enable domain warping", Float) = 0
    _Decal8_Domain_Warping_Noise("Domain warping noise", 2D) = "black" {}
    _Decal8_Domain_Warping_Strength("Domain warping noise strength", Float) = 0.05
    _Decal8_Domain_Warping_Speed("Domain warping noise speed", Float) = .1
    _Decal8_Domain_Warping_Octaves("Domain warping octaves", Float) = 5
    _Decal8_Domain_Warping_Scale("Domain warping scale", Float) = .1

    _Decal9_Enable("Enable decal", Float) = 0.0
    _Decal9_Color("Base color", Color) = (1, 1, 1, 1)
    _Decal9_BaseColor("Base color", 2D) = "white" {}
    _Decal9_BaseColor_Mode("Base color mode", Float) = 0
    _Decal9_SDF_Threshold("SDF threshold", Range(0, 1)) = 0.5
    _Decal9_SDF_Invert("SDF invert", Float) = 0
    _Decal9_SDF_Softness("SDF softness", Range(0, 1)) = 0.01
    _Decal9_SDF_Px_Range("SDF px range", Float) = 2
    _Decal9_Roughness("Roughness", 2D) = "white" {}
    _Decal9_Metallic("Metallic", 2D) = "black" {}
    _Decal9_Emission_Strength("Emission strength", Float) = 0
    _Decal9_Angle("Emission strength", Range(0,1)) = 0
    _Decal9_Alpha_Multiplier("Alpha multiplier", Range(0, 1)) = 1
    _Decal9_Round_Alpha_Multiplier("Round alpha multiplier", Float) = 0
    _Decal9_Mask("Mask", 2D) = "white" {}
    _Decal9_Mask_Invert("Mask invert", Float) = 0.0
    _Decal9_Tiling_Mode("Tiling mode", Range(0,1)) = 0
    _Decal9_UV_Select("UV channel", Range(0,7)) = 0
    _Decal9_Domain_Warping_Enable_Static("Enable domain warping", Float) = 0
    _Decal9_Domain_Warping_Noise("Domain warping noise", 2D) = "black" {}
    _Decal9_Domain_Warping_Strength("Domain warping strength", Float) = 0.05
    _Decal9_Domain_Warping_Speed("Domain warping speed", Float) = .1
    _Decal9_Domain_Warping_Octaves("Domain warping octaves", Float) = 5
    _Decal9_Domain_Warping_Scale("Domain warping scale", Float) = .1

    [NoScaleOffset] _EmissionMap("Emission map", 2D) = "black" {}
    _EmissionColor("Emission color", Color) = (0, 0, 0)

    [NoScaleOffset] _Emission0Tex("Emission map", 2D) = "black" {}
    _Emission0Color("Emission color", Color) = (0, 0, 0)
    _Emission0Multiplier("Emission multiplier", Range(0, 2)) = 1
    _Emission0_UV_Select("UV channel", Range(0,7)) = 0
    [NoScaleOffset] _Emission1Tex("Emission map", 2D) = "black" {}
    _Emission1Color("Emission color", Color) = (0, 0, 0)
    _Emission1Multiplier("Emission multiplier", Range(0, 2)) = 1
    _Emission1_UV_Select("UV channel", Range(0,7)) = 0
    _Global_Emission_Factor("Global emission factor", Float) = 1
    _Global_Emission_Additive_Factor("Global emission additive factor", Float) = 0

    [NoScaleOffset] _Tex_NormalStr("Normal texture strength", Range(0, 10)) = 1

		_Cubemap("Cubemap", Cube) = "" {}
    _Cubemap_Limit_To_Metallic("Limit cubemap to metallic", Float) = 0.0
    _Lighting_Factor("Lighting factor", Range(0, 5)) = 1
    _Direct_Lighting_Factor("Direct lighting factor", Range(0, 5)) = 1
    _Vertex_Lighting_Factor("Vertex lighting factor", Range(0, 5)) = 1
    _Indirect_Specular_Lighting_Factor("Indirect specular lighting factor", Range(0, 5)) = 1
    _Indirect_Specular_Lighting_Factor2("Indirect specular lighting factor", Range(0, 5)) = 1
    _Indirect_Diffuse_Lighting_Factor("Indirect diffuse lighting factor", Range(0, 5)) = 1
    _Reflection_Probe_Saturation("Reflection probe saturation", Range(0, 1)) = 1
    _Enable_Brightness_Clamp("Enable brightness clamp", Float) = 0
    _Min_Brightness("Min brightness", Range(0, 1)) = 0
    _Max_Brightness("Max brightness", Range(0, 10)) = 1
    _Mesh_Normal_Strength("Mesh normal strength", Range(0, 10)) = 1
    _NormalStr("Normal strength", Range(0, 10)) = 1
    _Ambient_Occlusion("Ambient occlusion", 2D) = "white" {}
    _Ambient_Occlusion_Strength("Ambient occlusion", Range(0,1)) = 1
    _Aces_Filmic_Enable_Static("Enable ACES filmic tonemapping", Float) = 0

    _Proximity_Dimming_Enable_Static("Enable proximity dimming", Float) = 0
    _Proximity_Dimming_Min_Dist("Proximity dimming min distance", Float) = 0
    _Proximity_Dimming_Max_Dist("Proximity dimming max distance", Float) = 1
    _Proximity_Dimming_Factor("Proximity dimming max distance", Float) = 0

    _Shading_Mode("Shading mode", Range(0, 1)) = 0
    _Mesh_Normals_Mode("Normals mode", Float) = 3
    _Flatten_Mesh_Normals_Str("Flatten mesh normals strength", Float) = 100.0
    [MaterialToggle] _Confabulate_Normals("Confabulate mesh normals", Float) = 0.0

    _Alpha_Cutoff("Alpha cutoff", Range(0, 1)) = 0.5
    _Rendering_Cutout_Noise_Scale("Noise scale", Float) = 1
    _Rendering_Cutout_Ign_Seed("IGN seed", Float) = 0
    _Frame_Counter_Enable_Static("Frame counter enable", Float) = 0
    _Frame_Counter("Frame counter", Float) = 0

    _Outline_Width("Outline width", Range(0, 0.1)) = 0.01
    _Outline_Color("Outline color", Color) = (0, 0, 0, 1)
    _Outline_Emission_Strength("Outline emission strength", Range(0, 2)) = 0.2
    _Outline_Mask("Outline mask", 2D) = "white" {}
    _Outline_Mask_Invert("Invert outline mask", Float) = 0.0
    _Outline_Width_Multiplier("Outline width multiplier", Float) = 1

    _Glitter_Enabled("Glitter enabled", Float) = 0
    _Glitter_Mask("Glitter mask", 2D) = "white" {}
    _Glitter_Color("Glitter color", Color) = (1, 1, 1, 1)
    _Glitter_Density("Glitter density", Float) = 400
    _Glitter_Amount("Glitter amount", Range(1, 100)) = 35
    _Glitter_Speed("Glitter speed", Float) = 1
    _Glitter_Seed("Glitter seed", Float) = 1
    _Glitter_Brightness("Glitter brightness (unlit)", Float) = 1
    _Glitter_Brightness_Lit("Glitter brightness (lit)", Float) = 0
    _Glitter_Angle("Glitter angle", Range(0, 90)) = 90
    _Glitter_Power("Glitter power", Float) = 30
    _Glitter_UV_Select("Glitter UV channel", Range(0, 7)) = 0
    _Glitter_Vector_Mask_Enabled("Glitter vector mask enabled", Float) = 0
    _Glitter_Vector_Mask_Vector("Glitter vector mask vector", Vector) = (1, 0, 0)
    _Glitter_Vector_Mask_Power("Glitter vector mask power", Float) = 1
    _Glitter_Vector_Mask_Invert("Glitter vector mask invert", Float) = 0

    _Gimmick_Letter_Grid_Enable_Static("Enable letter grid (static)", Float) = 0
    _Gimmick_Letter_Grid_Texture("Letter grid texture", 2D) = "black" {}
    _Gimmick_Letter_Grid_Tex_Res_X("Texture letter grid X resolution", Float) = 16
    _Gimmick_Letter_Grid_Tex_Res_Y("Texture letter grid Y resolution", Float) = 8
    _Gimmick_Letter_Grid_Res_X("Letter grid X resolution", Float) = 8
    _Gimmick_Letter_Grid_Res_Y("Letter grid Y resolution", Float) = 8
    _Gimmick_Letter_Grid_UV_Scale_Offset("Letter grid UV bounds", Vector) = (1, 1, 0, 0)
    _Gimmick_Letter_Grid_Padding("Padding", Float) = 0.02
    _Gimmick_Letter_Grid_Color("Color", Color) = (1, 1, 1, 1)
    _Gimmick_Letter_Grid_Metallic("Metallic", Range(0, 1)) = 0
    _Gimmick_Letter_Grid_Roughness("Roughness", Range(0 ,1)) = 0.5
    _Gimmick_Letter_Grid_Emission("Emission", Range(0 ,1)) = 0.0
    _Gimmick_Letter_Grid_UV_Select("Letter grid UV channel", Range(0, 7)) = 0
    _Gimmick_Letter_Grid_Color_Wave("Letter grid color wave", Float) = 0
    _Gimmick_Letter_Grid_Color_Wave_Speed("Letter grid color wave", Float) = 1
    _Gimmick_Letter_Grid_Color_Wave_Frequency("Letter grid color wave", Float) = 1
    _Gimmick_Letter_Grid_Rim_Lighting("_Gimmick_Letter_Grid_Rim_Lighting", Float) = 0
    _Gimmick_Letter_Grid_Rim_Lighting_Power("_Gimmick_Letter_Grid_Rim_Lighting_Power", Float) = 5
    _Gimmick_Letter_Grid_Rim_Lighting_Center("_Gimmick_Letter_Grid_Rim_Lighting_Center", Float) = 0
    _Gimmick_Letter_Grid_Rim_Lighting_Quantization("_Gimmick_Letter_Grid_Rim_Lighting_Quantization", Float) = -1
    _Gimmick_Letter_Grid_Rim_Lighting_Mask("Mask", 2D) = "white" {}
    _Gimmick_Letter_Grid_Rim_Lighting_Mask_UV_Select("_Gimmick_Letter_Grid_Rim_Lighting_Mask_UV_Select", Float) = 0
    _Gimmick_Letter_Grid_Rim_Lighting_Mask_Invert("_Gimmick_Letter_Grid_Rim_Lighting_Mask_Invert", Float) = 0

    _Gimmick_Letter_Grid_2_Enable_Static("Enable letter grid 2 (static)", Float) = 0
    _Gimmick_Letter_Grid_2_Texture("Letter grid texture", 2D) = "black" {}
    _Gimmick_Letter_Grid_2_Tex_Res_X("Texture letter grid X resolution", Float) = 16
    _Gimmick_Letter_Grid_2_Tex_Res_Y("Texture letter grid Y resolution", Float) = 8
    _Gimmick_Letter_Grid_2_Res_X("Letter grid X resolution", Range(1, 4)) = 1
    _Gimmick_Letter_Grid_2_Res_Y("Letter grid Y resolution", Range(1, 4)) = 1
    _Gimmick_Letter_Grid_2_Data_Row_0("Letter grid data row 0", Vector) = (0, 0, 0, 0)
    _Gimmick_Letter_Grid_2_Data_Row_1("Letter grid data row 1", Vector) = (0, 0, 0, 0)
    _Gimmick_Letter_Grid_2_Data_Row_2("Letter grid data row 2", Vector) = (0, 0, 0, 0)
    _Gimmick_Letter_Grid_2_Data_Row_3("Letter grid data row 3", Vector) = (0, 0, 0, 0)
    _Gimmick_Letter_Grid_2_UV_Scale_Offset("Letter grid UV bounds", Vector) = (1, 1, 0, 0)
    _Gimmick_Letter_Grid_2_Padding("Padding", Float) = 0.02
    _Gimmick_Letter_Grid_2_Color("Color", Color) = (1, 1, 1, 1)
    _Gimmick_Letter_Grid_2_Metallic("Metallic", Range(0, 1)) = 0
    _Gimmick_Letter_Grid_2_Roughness("Roughness", Range(0 ,1)) = 0.5
    _Gimmick_Letter_Grid_2_Emission("Emission", Range(0 ,1)) = 0.0
    _Gimmick_Letter_Grid_2_Mask("Mask", 2D) = "white" {}
    _Gimmick_Letter_Grid_2_Global_Offset("Global offset", Float) = 0
    _Gimmick_Letter_Grid_2_Screen_Px_Range("Screen px range (from msdfgen)", Float) = 10
    _Gimmick_Letter_Grid_2_Min_Screen_Px_Range("Minimum screen px range", Float) = 1
    _Gimmick_Letter_Grid_2_Blurriness("Blurriness", Float) = 0.5
    _Gimmick_Letter_Grid_2_Alpha_Threshold("Alpha threshold", Range(0, 1)) = 0.5

		[MaterialToggle] _Explode_Toggle("Explode toggle", Float) = 0
		_Explode_Phase("Explode phase", Range(0, 1)) = 0
    [Enum(UnityEngine.Rendering.CullMode)] _OutlinesCull ("Outlines pass culling mode", Float) = 1
    [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Culling mode", Float) = 2
    _Enable_Unity_Fog("Enable Unity fog", Float) = 1

    _Stencil_Ref_Base("Stencil ref", Float) = 1
    [Enum(UnityEngine.Rendering.CompareFunction)] _Stencil_Comp_Base("Stencil compare", Float) = 0  // Disabled
    [Enum(UnityEngine.Rendering.StencilOp)] _Stencil_Pass_Op_Base("Stencil op", Float) = 0  // Keep
    [Enum(UnityEngine.Rendering.StencilOp)] _Stencil_Fail_Op_Base("Stencil op", Float) = 0  // Keep

    _Stencil_Ref_Outline("Stencil ref", Float) = 1
    [Enum(UnityEngine.Rendering.CompareFunction)] _Stencil_Comp_Outline("Stencil compare", Float) = 0  // Disabled
    [Enum(UnityEngine.Rendering.StencilOp)] _Stencil_Pass_Op_Outline("Stencil op", Float) = 0  // Keep
    [Enum(UnityEngine.Rendering.StencilOp)] _Stencil_Fail_Op_Outline("Stencil op", Float) = 0  // Keep

		[MaterialToggle] _Scroll_Toggle("Scroll toggle", Float) = 0
		_Scroll_Top("Scroll top (m)", Range(-5, 5)) = 1
		_Scroll_Bottom("Scroll bottom (m)", Range(-5, 5)) = 0
		_Scroll_Width("Scroll width", Range(0, 1)) = 0
		_Scroll_Strength("Scroll strength", Range(0, 1)) = 0
    _Scroll_Speed("Scroll speed", Range(0, 1)) = 1

    [HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
    [HideInInspector] _DstBlend ("_SrcBlend", Float) = 0
    [HideInInspector] _ZWrite ("_ZWrite", Float) = 1
    [HideInInspector] _ZTest ("_ZTest", Float) = 4  // LEqual

    _Matcap0("Matcap", 2D) = "black" {}
    _Matcap0_Mask("Matcap mask", 2D) = "white" {}
    _Matcap0_Mask_Invert("Invert mask", Float) = 0.0
    _Matcap0_Mask_UV_Select("Matcap mask UV select", Range(0, 7)) = 0
    _Matcap0_Mask2("Matcap mask 2", 2D) = "white" {}
    _Matcap0_Mask2_Invert_Colors("Invert mask", Float) = 0.0
    _Matcap0_Mask2_Invert_Alpha("Invert mask", Float) = 0.0
    _Matcap0_Mask2_UV_Select("Matcap mask UV select", Range(0, 7)) = 0
    _Matcap0Mode("Matcap mode", Float) = 0
    _Matcap0Str("Matcap strength", Float) = 1
    _Matcap0MixFactor("Matcap mix factor", Range(0, 1)) = 1
    _Matcap0Emission("Matcap emission", Float) = 0
    _Matcap0Quantization("Matcap quantization", Float) = -1
    _Matcap0Distortion0("Matcap distortion0", Float) = 0
    _Matcap0Normal_Enabled("Enable normal replacement", Float) = 0
    _Matcap0Normal("Matcap normals", 2D) = "bump" {}
    _Matcap0Normal_Mip_Bias("Matcap normals mip bias", Float) = 0
    _Matcap0Normal_Str("Matcap normals", Range(0, 10)) = 1
    _Matcap0Normal_UV_Select("Matcap normals", Range(0, 7)) = 0
    _Matcap0_Overwrite_Rim_Lighting_0("Overwrite RL", Float) = 0
    _Matcap0_Overwrite_Rim_Lighting_1("Overwrite RL", Float) = 0
    _Matcap0_Overwrite_Rim_Lighting_2("Overwrite RL", Float) = 0
    _Matcap0_Overwrite_Rim_Lighting_3("Overwrite RL", Float) = 0
    _Matcap0_Center_Eye_Fix("Enable center eye fix", Float) = 0

    _Matcap1("Matcap", 2D) = "black" {}
    _Matcap1_Mask("Matcap mask", 2D) = "white" {}
    _Matcap1_Mask_Invert("Invert mask", Float) = 0.0
    _Matcap1_Mask_UV_Select("Matcap mask UV select", Range(0, 7)) = 0
    _Matcap1_Mask2("Matcap mask 2", 2D) = "white" {}
    _Matcap1_Mask2_Invert_Colors("Invert mask", Float) = 0.0
    _Matcap1_Mask2_Invert_Alpha("Invert mask", Float) = 0.0
    _Matcap1_Mask2_UV_Select("Matcap mask UV select", Range(0, 7)) = 0
    _Matcap1Mode("Matcap mode", Float) = 0
    _Matcap1Str("Matcap strength", Float) = 1
    _Matcap1MixFactor("Matcap mix factor", Range(0, 1)) = 1
    _Matcap1Emission("Matcap emission", Float) = 0
    _Matcap1Quantization("Matcap quantization", Float) = -1
    _Matcap1Distortion0("Matcap distortion0", Float) = 0
    _Matcap1Normal_Enabled("Enable normal replacement", Float) = 0
    _Matcap1Normal("Matcap normals", 2D) = "bump" {}
    _Matcap1Normal_Mip_Bias("Matcap normals mip bias", Float) = 0
    _Matcap1Normal_Str("Matcap normals", Range(0, 10)) = 1
    _Matcap1Normal_UV_Select("Matcap normals", Range(0, 7)) = 0
    _Matcap1_Overwrite_Rim_Lighting_0("Overwrite RL", Float) = 0
    _Matcap1_Overwrite_Rim_Lighting_1("Overwrite RL", Float) = 0
    _Matcap1_Overwrite_Rim_Lighting_2("Overwrite RL", Float) = 0
    _Matcap1_Overwrite_Rim_Lighting_3("Overwrite RL", Float) = 0
    _Matcap1_Center_Eye_Fix("Enable center eye fix", Float) = 0

    _Rim_Lighting0_Enabled("Enable rim lighting", Float) = 0
    _Rim_Lighting0_Mode("Rim lighting mode", Float) = 0
    _Rim_Lighting0_Mask("Rim lighting mask", 2D) = "white" {}
    _Rim_Lighting0_Mask_Invert("Invert rim lighting mask", Float) = 0.0
    _Rim_Lighting0_Mask_UV_Select("mask UV select", Range(0, 7)) = 0.0
    _Rim_Lighting0_Mask_Sampler_Mode("mask sampler mode", Range(0, 1)) = 0.0
    _Rim_Lighting0_Mask2("Rim lighting mask 2", 2D) = "white" {}
    _Rim_Lighting0_Mask2_Invert_Colors("Invert rim lighting mask 2", Float) = 0.0
    _Rim_Lighting0_Mask2_Invert_Alpha("Invert rim lighting mask 2", Float) = 0.0
    _Rim_Lighting0_Mask2_UV_Select("mask 2 UV select", Range(0, 7)) = 0.0
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
    _Rim_Lighting0_Glitter_UV_Select("Rim lighting glitter UV select", Range(0, 7)) = 0
    _Rim_Lighting0_PolarMask_Enabled("Rim lighting polar mask enabled", Float) = 0
    _Rim_Lighting0_PolarMask_Theta("Rim lighting polar mask - theta", Float) = 0
    _Rim_Lighting0_PolarMask_Power("Rim lighting polar mask - power", Float) = 3
    _Rim_Lighting0_Custom_View_Vector_Enabled("custom view vector", Float) = 0
    _Rim_Lighting0_Custom_View_Vector("custom view vector", Vector) = (1, 0, 0, 0)
    _Rim_Lighting0_Center_Eye_Fix("Enable center eye fix", Float) = 0
    _Rim_Lighting0_Use_Texture_Normals("Use texture normals", Float) = 1
    _Rim_Lighting0_Reflect_In_World_Space("Reflect in world space", Float) = 0

    _Rim_Lighting1_Enabled("Enable rim lighting", Float) = 0
    _Rim_Lighting1_Mode("Rim lighting mode", Float) = 0
    _Rim_Lighting1_Mask("Rim lighting mask", 2D) = "white" {}
    _Rim_Lighting1_Mask_Invert("Invert rim lighting mask", Float) = 0.0
    _Rim_Lighting1_Mask_UV_Select("mask UV select", Range(0, 7)) = 0.0
    _Rim_Lighting1_Mask_Sampler_Mode("mask sampler mode", Range(0, 1)) = 0.0
    _Rim_Lighting1_Mask2("Rim lighting mask 2", 2D) = "white" {}
    _Rim_Lighting1_Mask2_Invert_Colors("Invert rim lighting mask 2", Float) = 0.0
    _Rim_Lighting1_Mask2_Invert_Alpha("Invert rim lighting mask 2", Float) = 0.0
    _Rim_Lighting1_Mask2_UV_Select("mask 2 UV select", Range(0, 7)) = 0.0
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
    _Rim_Lighting1_Glitter_UV_Select("Rim lighting glitter UV select", Range(0, 7)) = 0
    _Rim_Lighting1_PolarMask_Enabled("Rim lighting polar mask enabled", Float) = 0
    _Rim_Lighting1_PolarMask_Theta("Rim lighting polar mask - theta", Float) = 0
    _Rim_Lighting1_PolarMask_Power("Rim lighting polar mask - power", Float) = 3
    _Rim_Lighting1_Custom_View_Vector_Enabled("custom view vector", Float) = 0
    _Rim_Lighting1_Custom_View_Vector("custom view vector", Vector) = (1, 0, 0, 0)
    _Rim_Lighting1_Center_Eye_Fix("Enable center eye fix", Float) = 0
    _Rim_Lighting1_Use_Texture_Normals("Use texture normals", Float) = 1
    _Rim_Lighting1_Reflect_In_World_Space("Reflect in world space", Float) = 0

    _Rim_Lighting2_Enabled("Enable rim lighting", Float) = 0
    _Rim_Lighting2_Mode("Rim lighting mode", Float) = 0
    _Rim_Lighting2_Mask("Rim lighting mask", 2D) = "white" {}
    _Rim_Lighting2_Mask_Invert("Invert rim lighting mask", Float) = 0.0
    _Rim_Lighting2_Mask_UV_Select("mask UV select", Range(0, 7)) = 0.0
    _Rim_Lighting2_Mask_Sampler_Mode("mask sampler mode", Range(0, 1)) = 0.0
    _Rim_Lighting2_Mask2("Rim lighting mask 2", 2D) = "white" {}
    _Rim_Lighting2_Mask2_Invert_Colors("Invert rim lighting mask 2", Float) = 0.0
    _Rim_Lighting2_Mask2_Invert_Alpha("Invert rim lighting mask 2", Float) = 0.0
    _Rim_Lighting2_Mask2_UV_Select("mask 2 UV select", Range(0, 7)) = 0.0
    _Rim_Lighting2_Color("Rim lighting color", Color) = (1, 1, 1, 1)
    _Rim_Lighting2_Center("Rim lighting center", Float) = 0.5
    _Rim_Lighting2_Power("Rim lighting power", Float) = 2.0
    _Rim_Lighting2_Strength("Rim lighting strength", Float) = 1.0
    _Rim_Lighting2_Emission("Rim lighting emission", Float) = 0
    _Rim_Lighting2_Quantization("Rim lighting quantization", Float) = -1
    _Rim_Lighting2_Glitter_Enabled("Rim lighting glitter", Float) = 0
    _Rim_Lighting2_Glitter_Density("Rim lighting glitter density", Float) = 100
    _Rim_Lighting2_Glitter_Amount("Rim lighting glitter amount", Float) = 100
    _Rim_Lighting2_Glitter_Speed("Rim lighting glitter speed", Float) = 1
    _Rim_Lighting2_Glitter_Quantization("Rim lighting glitter quantization", Float) = 1000
    _Rim_Lighting2_Glitter_UV_Select("Rim lighting glitter UV select", Range(0, 7)) = 0
    _Rim_Lighting2_PolarMask_Enabled("Rim lighting polar mask enabled", Float) = 0
    _Rim_Lighting2_PolarMask_Theta("Rim lighting polar mask - theta", Float) = 0
    _Rim_Lighting2_PolarMask_Power("Rim lighting polar mask - power", Float) = 3
    _Rim_Lighting2_Custom_View_Vector_Enabled("custom view vector", Float) = 0
    _Rim_Lighting2_Custom_View_Vector("custom view vector", Vector) = (1, 0, 0, 0)
    _Rim_Lighting2_Center_Eye_Fix("Enable center eye fix", Float) = 0
    _Rim_Lighting2_Use_Texture_Normals("Use texture normals", Float) = 1
    _Rim_Lighting2_Reflect_In_World_Space("Reflect in world space", Float) = 0

    _Rim_Lighting3_Enabled("Enable rim lighting", Float) = 0
    _Rim_Lighting3_Mode("Rim lighting mode", Float) = 0
    _Rim_Lighting3_Mask("Rim lighting mask", 2D) = "white" {}
    _Rim_Lighting3_Mask_Invert("Invert rim lighting mask", Float) = 0.0
    _Rim_Lighting3_Mask_UV_Select("mask UV select", Range(0, 7)) = 0.0
    _Rim_Lighting3_Mask_Sampler_Mode("mask sampler mode", Range(0, 1)) = 0.0
    _Rim_Lighting3_Mask2("Rim lighting mask 2", 2D) = "white" {}
    _Rim_Lighting3_Mask2_Invert_Colors("Invert rim lighting mask 2", Float) = 0.0
    _Rim_Lighting3_Mask2_Invert_Alpha("Invert rim lighting mask 2", Float) = 0.0
    _Rim_Lighting3_Mask2_UV_Select("mask 2 UV select", Range(0, 7)) = 0.0
    _Rim_Lighting3_Color("Rim lighting color", Color) = (1, 1, 1, 1)
    _Rim_Lighting3_Center("Rim lighting center", Float) = 0.5
    _Rim_Lighting3_Power("Rim lighting power", Float) = 2.0
    _Rim_Lighting3_Strength("Rim lighting strength", Float) = 1.0
    _Rim_Lighting3_Emission("Rim lighting emission", Float) = 0
    _Rim_Lighting3_Quantization("Rim lighting quantization", Float) = -1
    _Rim_Lighting3_Glitter_Enabled("Rim lighting glitter", Float) = 0
    _Rim_Lighting3_Glitter_Density("Rim lighting glitter density", Float) = 100
    _Rim_Lighting3_Glitter_Amount("Rim lighting glitter amount", Float) = 100
    _Rim_Lighting3_Glitter_Speed("Rim lighting glitter speed", Float) = 1
    _Rim_Lighting3_Glitter_Quantization("Rim lighting glitter quantization", Float) = 1000
    _Rim_Lighting3_Glitter_UV_Select("Rim lighting glitter UV select", Range(0, 7)) = 0
    _Rim_Lighting3_PolarMask_Enabled("Rim lighting polar mask enabled", Float) = 0
    _Rim_Lighting3_PolarMask_Theta("Rim lighting polar mask - theta", Float) = 0
    _Rim_Lighting3_PolarMask_Power("Rim lighting polar mask - power", Float) = 3
    _Rim_Lighting3_Custom_View_Vector_Enabled("custom view vector", Float) = 0
    _Rim_Lighting3_Custom_View_Vector("custom view vector", Vector) = (1, 0, 0, 0)
    _Rim_Lighting3_Center_Eye_Fix("Enable center eye fix", Float) = 0
    _Rim_Lighting3_Use_Texture_Normals("Use texture normals", Float) = 1
    _Rim_Lighting3_Reflect_In_World_Space("Reflect in world space", Float) = 0

    _OKLAB_Enabled("Enable OKLAB", Float) = 0.0
    _OKLAB_Mask("Mask", 2D) = "white" {}
    _OKLAB_Mask_Invert("Mask invert", Float) = 0.0
    _OKLAB_Lightness_Shift("OKLAB lightness shift", Range(-1.0, 1.0)) = 0.0
    _OKLAB_Chroma_Shift("OKLAB chroma shift", Range(-0.37, 0.37)) = 0.0
    _OKLAB_Hue_Shift("OKLAB hue shift", Range(0, 6.283185307)) = 0.0

    _HSV0_Enabled("Enable HSV", Float) = 0.0
    _HSV0_Mask("Mask", 2D) = "white" {}
    _HSV0_Mask_Invert("Mask invert", Float) = 0.0
    _HSV0_Hue_Shift("HSV hue shift", Range(0.0, 1.0)) = 0.0
    _HSV0_Sat_Shift("HSV saturation shift", Range(-1.0, 1.0)) = 0.0
    _HSV0_Val_Shift("HSV value shift", Range(-1.0, 1.0)) = 0.0

    _HSV1_Enabled("Enable HSV", Float) = 0.0
    _HSV1_Mask("Mask", 2D) = "white" {}
    _HSV1_Mask_Invert("Mask invert", Float) = 0.0
    _HSV1_Hue_Shift("HSV hue shift", Range(0.0, 1.0)) = 0.0
    _HSV1_Sat_Shift("HSV saturation shift", Range(-1.0, 1.0)) = 0.0
    _HSV1_Val_Shift("HSV value shift", Range(-1.0, 1.0)) = 0.0

    _HSV2_Enabled("Enable HSV", Float) = 0.0
    _HSV2_Mask("Mask", 2D) = "white" {}
    _HSV2_Mask_Invert("Mask invert", Float) = 0.0
    _HSV2_Hue_Shift("HSV hue shift", Range(0.0, 1.0)) = 0.0
    _HSV2_Sat_Shift("HSV saturation shift", Range(-1.0, 1.0)) = 0.0
    _HSV2_Val_Shift("HSV value shift", Range(-1.0, 1.0)) = 0.0

    _Clones_Enabled("Enable clones", Float) = 0.0
    _Clones_Count("Clones count", Range(0,16)) = 0.0
    _Clones_Dist_Cutoff("distance cutoff", Float) = -1.0
    _Clones_dx("dx", Range(0, 10)) = 1.0
    _Clones_dy("dy", Range(0, 10)) = 1.0
    _Clones_dz("dz", Range(0, 10)) = 1.0
    _Clones_Scale("scale", Vector) = (1, 1, 1, 1)

    _UVScroll_Enabled("Enable UV scrolling", Float) = 0.0
    _UVScroll_Mask("UV scroll mask", 2D) = "white"
    _UVScroll_U_Speed("UV scroll U speed", Float) = 0.0
    _UVScroll_V_Speed("UV scroll V speed", Float) = 1.0
    _UVScroll_Alpha("UV scroll alpha", 2D) = "white" {}

    _LTCGI_Enabled("LTCGI enabled", Float) = 0.0
    _LTCGI_Strength("LTCGI strength", Float) = 5.0
    // This is set to 1 for backwards compatibility. Don't want to have to go
    // click on like 30 materials....
    _LTCGI_Enabled_Dynamic("LTCGI enabled (runtime switch)", Float) = 1.0
    _LTCGI_SpecularColor("LTCGI specular color", Color) = (1, 1, 1, 1)
    _LTCGI_DiffuseColor("LTCGI diffuse color", Color) = (1, 1, 1, 1)

    _Force_World_Lighting("Force world lighting", Float) = 0.0

    _Cutout_Mode("Cutout rendering mode", Float) = 0.0
    _Render_Queue_Offset("Render queue offset", Integer) = 0

    _Shadow_Strength("Shadows strength", Range(0, 1)) = 1.0
    _Global_Sample_Bias("Mipmap multiplier", Float) = 0.0

    _Gimmick_Flat_Color_Enable_Static("Enable flat color gimmick", Float) = 0.0
    _Gimmick_Flat_Color_Enable_Dynamic("Enable flat color gimmick", Float) = 0.0
    _Gimmick_Flat_Color_Color("Flat color gimmick color", Color) = (0, 0, 0, 1)
    _Gimmick_Flat_Color_Emission("Flat color gimmick emission", Color) = (0, 0, 0, 1)

    _Gimmick_UV_Domain_Warping_Enable_Static("Enable UV domain warping", Float) = 0.0
    _Gimmick_UV_Domain_Warping_Octaves("UV domain warping octaves", Float) = 3
    _Gimmick_UV_Domain_Warping_Strength("UV domain warping strength", Float) = 1
    _Gimmick_UV_Domain_Warping_Scale("UV domain warping scale", Float) = 1
    _Gimmick_UV_Domain_Warping_Speed("UV domain warping speed", Float) = 1
    _Gimmick_UV_Domain_Warping_Noise("UV domain warping noise", 2D) = "black" {}
    _Gimmick_UV_Domain_Warping_Mask("UV domain warping mask", 2D) = "white" {}
    _Gimmick_UV_Domain_Warping_Mask_Invert("UV domain warping mask invert", Float) = 0.0

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

    _Gimmick_Spherize_Location_Enable_Static("Enable spherize location gimmick", Float) = 0.0
    _Gimmick_Spherize_Location_Enable_Dynamic("Enable spherize location gimmick", Float) = 0.0
    _Gimmick_Spherize_Location_Strength("Strength", Range(0, 1)) = 0
    _Gimmick_Spherize_Location_Radius("Strength", Float) = 1

    _Gimmick_Vertex_Normal_Slide_Enable_Static("Enable vertex normal slide", Float) = 0.0
    _Gimmick_Vertex_Normal_Slide_Enable_Dynamic("Enable vertex normal slide", Float) = 0.0
    _Gimmick_Vertex_Normal_Slide_Distance("Vertex normal slide distance", Float) = 0.01

    _Gimmick_Eyes00_Enable_Static("Enable eyes 00", Float) = 0.0
    _Gimmick_Eyes00_Effect_Mask("Effect mask", 2D) = "white" {}

    _Gimmick_Eyes01_Enable_Static("Enable eyes 01", Float) = 0.0
    _Gimmick_Eyes01_Radius("Radius (meters, obj space)", Float) = 1.0

    _Gimmick_Eyes02_Enable_Static  ("Enable (static)", Float) = 0
    _Gimmick_Eyes02_N  ("n",  Range(2, 16)) = 5
    _Gimmick_Eyes02_A0 ("a0", Range(-6, 6)) = 1.5
    _Gimmick_Eyes02_A1 ("a1", Range(-6, 6)) = -1.75
    _Gimmick_Eyes02_A2 ("a2", Range(-6, 6)) = .01
    _Gimmick_Eyes02_A3 ("a3", Range(-2, 2)) = 0
    _Gimmick_Eyes02_A4 ("a4", Range(-2, 2)) = .5
    _Gimmick_Eyes02_Animate ("animate", Float) = 0.0
    _Gimmick_Eyes02_Animate_Strength ("animation strength", Float) = 1.0
    _Gimmick_Eyes02_Animate_Speed ("animation speed", Float) = 1.0
    _Gimmick_Eyes02_UV_X_Symmetry ("UV x symmetry", Float) = 1.0
    _Gimmick_Eyes02_UV_Adjust ("UV scale and center", Vector) = (0.9, 1.1, .753, .675)
    _Gimmick_Eyes02_Albedo ("Albedo", Color) = (1, 1, 1, 1)
    _Gimmick_Eyes02_Metallic ("Metallic", Range(0, 1)) = 0
    _Gimmick_Eyes02_Roughness ("Roughness", Range(0, 1)) = 0.5
    _Gimmick_Eyes02_Emission ("Emission", Color) = (0, 0, 0, 1)

    _Gimmick_DS2_Enable_Static  ("Enable (static)", Float) = 0
    _Gimmick_DS2_Choice  ("Choice", Float) = 0
    _Gimmick_DS2_Noise  ("Noise", 2D) = "black" {}
    _Gimmick_DS2_Mask("Mask", 2D) = "white" {}
    _Gimmick_DS2_Albedo_Factor("Albedo factor", Float) = 1
    _Gimmick_DS2_Emission_Factor("Emission factor", Float) = 1
    // Effect 00
    _Gimmick_DS2_00_Domain_Warping_Octaves("Domain warping octaves", Float) = 3
    _Gimmick_DS2_00_Domain_Warping_Strength("Domain warping strength", Float) = 1
    _Gimmick_DS2_00_Domain_Warping_Scale("Domain warping scale", Float) = 1
    _Gimmick_DS2_00_Domain_Warping_Speed("Domain warping speed", Float) = 1
    // Effect 01
    _Gimmick_DS2_01_Period("Period", Vector) = (1, 1, 1, 1)
    _Gimmick_DS2_01_Count("Count", Vector) = (1, 1, 1, 1)
    _Gimmick_DS2_01_Radius("Radius", Float) = 1
    _Gimmick_DS2_01_Domain_Warping_Octaves("Domain warping octaves", Float) = 3
    _Gimmick_DS2_01_Domain_Warping_Strength("Domain warping strength", Float) = 1
    _Gimmick_DS2_01_Domain_Warping_Scale("Domain warping scale", Float) = 1
    _Gimmick_DS2_01_Domain_Warping_Speed("Domain warping speed", Float) = 1
    // Effect 02
    _Gimmick_DS2_02_Period("Period", Vector) = (1, 1, 1, 1)
    _Gimmick_DS2_02_Count("Count", Vector) = (1, 1, 1, 1)
    _Gimmick_DS2_02_Edge_Length("Edge length", Float) = 0.1
    _Gimmick_DS2_02_Domain_Warping_Octaves("Domain warping octaves", Float) = 3
    _Gimmick_DS2_02_Domain_Warping_Strength("Domain warping strength", Float) = 1
    _Gimmick_DS2_02_Domain_Warping_Scale("Domain warping scale", Float) = 1
    _Gimmick_DS2_02_Domain_Warping_Speed("Domain warping speed", Float) = 1
    // Effect 03
    _Gimmick_DS2_03_Period("Period", Vector) = (1, 1, 1, 1)
    _Gimmick_DS2_03_Count("Count", Vector) = (1, 1, 1, 1)
    _Gimmick_DS2_03_Edge_Length("Edge length", Float) = 0.1
    // Effect 11
    _Gimmick_DS2_11_Fog_Enable("Fog enable", Float) = 0
    _Gimmick_DS2_11_Fog_Density("Fog density", Float) = 1
    _Gimmick_DS2_11_Fog_Sun_Direction("Fog sun direction", Vector) = (0, 0, 0, 0)
    _Gimmick_DS2_11_Fog_Sun_Exponent("Fog sun exponent", Float) = 1
    _Gimmick_DS2_11_Fog_Sun_Color_2_Enable("Fog sun color 2 enable", Float) = 0
    [HDR] _Gimmick_DS2_11_Fog_Sun_Color_2("Fog sun color 2", Color) = (1, 1, 1, 1)
    _Gimmick_DS2_11_Fog_Sun_Exponent_2("Fog sun exponent 2", Float) = 1
    [HDR] _Gimmick_DS2_11_Fog_Color("Fog color", Color) = (1, 1, 1, 1)
    [HDR] _Gimmick_DS2_11_Fog_Sun_Color("Fog sun color", Color) = (1, 1, 1, 1)
    _Gimmick_DS2_11_Snowline("Snowline", Float) = 1
    _Gimmick_DS2_11_Snowline_Octaves("Snowline octaves", Float) = 1
    _Gimmick_DS2_11_Snowline_Width("Snowline width", Float) = 0.1
    _Gimmick_DS2_11_Snowline_Noise_Scale("Snowline noise scale", Float) = 1
    _Gimmick_DS2_11_FBM("FBM", 2D) = "white" {}
    [HDR] _Gimmick_DS2_11_Snow_Color("Snow color", Color) = (1, 1, 1, 1)
    _Gimmick_DS2_11_Rockline("Rockline", Float) = 0
    _Gimmick_DS2_11_Rockline_Octaves("Rockline octaves", Float) = 1
    _Gimmick_DS2_11_Rockline_Width("Rockline width", Float) = 0.1
    _Gimmick_DS2_11_Rockline_Noise_Scale("Rockline noise scale", Float) = 1
    [HDR] _Gimmick_DS2_11_Rock_Color("Rock color", Color) = (1, 1, 1, 1)
    [HDR] _Gimmick_DS2_11_Grass_Color("Grass color", Color) = (1, 1, 1, 1)
    _Gimmick_DS2_11_Alpha("Alpha", Range(0, 1)) = 0.5
    _Gimmick_DS2_11_Octaves("Octaves", Float) = 12
    _Gimmick_DS2_11_March_Steps("March steps", Float) = 24
    _Gimmick_DS2_11_March_Backtrack_Steps("March backtrack steps", Float) = 5
    _Gimmick_DS2_11_March_Initial_Offset("March initial offset", Float) = 0
    _Gimmick_DS2_11_March_Initial_Step_Size("March initial step size", Float) = 0.01
    _Gimmick_DS2_11_Simulation_Scale("Simulation scale", Float) = 1
    _Gimmick_DS2_11_Coord_Scale("Coord scale", Float) = 1
    _Gimmick_DS2_11_Height_Scale("Height scale", Float) = 1
    _Gimmick_DS2_11_Height_Power("Height power", Float) = 1
    _Gimmick_DS2_11_Offset("XZ offset", Vector) = (0, 0, 0, 0)
    _Gimmick_DS2_11_Distance_Culling_Enable("Distance culling enable", Float) = 0
    _Gimmick_DS2_11_Activation_Y("Activation Y", Float) = 0
    _Gimmick_DS2_11_Early_Exit_Cutoff_Cos_Theta("Early exit cutoff (cos theta)", Float) = 0
    _Gimmick_DS2_11_Normal_Epsilon("Normal epsilon", Float) = 0.001
    _Gimmick_DS2_11_Valley_Power("Valley power", Float) = 8
    _Gimmick_DS2_11_Valley_Depth("Valley scale", Float) = .15

    _Gimmick_Halo00_Enable_Static("Enable halo", Float) = 0.0

    _Gimmick_Epilepsy_Mode_Enable_Static("Enable epilepsy mode", Float) = 0.0
    _Gimmick_Epilepsy_Mode_Enable_Dynamic("Enable epilepsy mode", Float) = 0.0
    _Gimmick_Epilepsy_Mode_Luminance_Cutoff("Luminance cutoff", Range(0, 1)) = 0.5
    _Gimmick_Epilepsy_Mode_Saturation_Cutoff("Saturation cutoff", Range(0, 1)) = 0.4
    _Gimmick_Epilepsy_Mode_Rolloff_Power("Rolloff power", Range(0, 1)) = 8

    _Gimmick_Pixellate_Enable_Static("Enable pixellation", Float) = 0.0
    _Gimmick_Pixellate_Resolution_U("Resolution (U)", Float) = 64
    _Gimmick_Pixellate_Resolution_V("Resolution (V)", Float) = 64
    _Gimmick_Pixellate_Effect_Mask("Effect mask", 2D) = "white" {}

    _Gimmick_AL_Chroma_00_Enable_Static("Enable AL chroma effect 00", Float) = 0.0
    _Gimmick_AL_Chroma_00_Forward_Pass("Enable in forward pass", Float) = 0.0
    _Gimmick_AL_Chroma_00_Forward_Blend("Forward pass blend", Range(0, 1)) = 1.0
    _Gimmick_AL_Chroma_00_Outline_Pass("Enable in outline pass", Float) = 1.0
    _Gimmick_AL_Chroma_00_Outline_Emission("Outline emission", Range(0, 1)) = 0
    _Gimmick_AL_Chroma_00_Outline_Blend("Outline pass blend", Range(0 ,1)) = 1.0
    _Gimmick_AL_Chroma_00_Hue_Shift_Enable_Static("Enable hue shift", Float) = 0.0
    _Gimmick_AL_Chroma_00_Hue_Shift_Theta("Hue shift", Range(0, 1)) = 0.0

    _Trochoid_Enable_Static("Enable trochoid", Float) = 0.0
    _Trochoid_R("R", Float) = 5.0
    _Trochoid_r("r", Float) = 3.0
    _Trochoid_d("d", Float) = 5.0
    _Trochoid_Speed("Speed", Float) = 1.0
    _Trochoid_Radius_Power("Radius power", Float) = 1.0
    _Trochoid_Radius_Scale("Radius scale", Float) = 1.0
    _Trochoid_Height_Scale("Height scale", Float) = 1.0
    _Trochoid_Enable_Fragment_Normals("Enable fragment normals", Float) = 1.0
    _Trochoid_Distance_Culling_Enable("Distance culling enable", Float) = 0
    _Trochoid_Activation_Center("Activation center", Vector) = (0, 0, 0, 0)
    _Trochoid_Activation_Radius("Activation radius", Float) = 1

    _FaceMeWorldY_Enable_Static("Enable face me gimmick", Float) = 0.0
    _FaceMeWorldY_Enable_Dynamic("Enable face me gimmick", Float) = 0.0
    _FaceMeWorldY_Enable_X("x", Float) = 0
    _FaceMeWorldY_Enable_Y("x", Float) = 1
    _FaceMeWorldY_Enable_Z("x", Float) = 0

    _Rorschach_Enable_Static("Enable rorschach gimmick", Float) = 0.0
    _Rorschach_Enable_Dynamic("Enable rorschach gimmick", Float) = 0.0
    _Rorschach_Color("Col", Color) = (1, 1, 1, 1)
    _Rorschach_Alpha_Cutoff("Alpha cutoff", Float) = 0.0
    _Rorschach_Count_X("Enable rorschach gimmick", Float) = 2
    _Rorschach_Count_Y("Enable rorschach gimmick", Float) = 2
    _Rorschach_Center_Randomization("Center randomization", Float) = 0
    _Rorschach_Radius("Radius", Float) = 1
    _Rorschach_Emission_Strength("Emission", Float) = 0
    _Rorschach_Speed("Speed", Float) = 1
    _Rorschach_Quantization("Quantization", Float) = -1
    _Rorschach_Mask("Mask", 2D) = "white" {}
    _Rorschach_Mask_Invert("Mask invert", Float) = 0

    _Mirror_UV_Flip_Enable_Static("Enable rorschach gimmick", Float) = 0.0
    _Mirror_UV_Flip_Enable_Dynamic("Enable rorschach gimmick", Float) = 0.0

    _Enable_SSR("Enable SSR", Float) = 0
    _SSR_Mask("SSR mask", 2D) = "white" {}
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
    _WrappingFactor("_WrappingFactor", Range(0,1)) = 0
    _Subsurface("_Subsurface", Float) = 0
    _SpecularStrength("_SpecularStrength", Range(0,1)) = 1
    _FresnelStrength("_FresnelStrength", Range(0,1)) = 1
    _UseFresnel("_UseFresnel", Float) = 1
    _ReflectionStrength("_ReflectionStrength", Range(0,1)) = 1
    _ReflectionStrengthTex("Reflection strength", 2D) = "white" {}
    shadowedReflections("shadowedReflections", Vector) = (0, 0, 0, 0)
    _ReflShadows("_ReflShadows", Vector) = (0, 0, 0, 0)
    _ReflShadowStrength("_ReflShadowStrength", Vector) = (0, 0, 0, 0)

    _Discard_Enable_Static("Enable discard feature (static)", Float) = 0
    _Discard_Enable_Dynamic("Enable discard feature (dynamic)", Float) = 0

    _PBR_UI_Show("UI show", Float) = 1
    _PBR_Overlay_UI_Show("UI show", Float) = 0
    _PBR_Overlay0_UI_Show("UI show", Float) = 0
    _PBR_Overlay1_UI_Show("UI show", Float) = 0
    _PBR_Overlay2_UI_Show("UI show", Float) = 0
    _PBR_Overlay3_UI_Show("UI show", Float) = 0
    _Clearcoat_UI_Show("UI show", Float) = 0
    _Decal_UI_Show("UI show", Float) = 0
    _Decal0_UI_Show("UI show", Float) = 0
    _Decal1_UI_Show("UI show", Float) = 0
    _Decal2_UI_Show("UI show", Float) = 0
    _Decal3_UI_Show("UI show", Float) = 0
    _Decal4_UI_Show("UI show", Float) = 0
    _Decal5_UI_Show("UI show", Float) = 0
    _Decal6_UI_Show("UI show", Float) = 0
    _Decal7_UI_Show("UI show", Float) = 0
    _Decal8_UI_Show("UI show", Float) = 0
    _Decal9_UI_Show("UI show", Float) = 0
    _Lighting_UI_Show("UI show", Float) = 0
    _Emission_UI_Show("UI show", Float) = 0
    _Shading_UI_Show("UI show", Float) = 0
    _Matcaps_UI_Show("UI show", Float) = 0
    _Matcap0_UI_Show("UI show", Float) = 0
    _Matcap1_UI_Show("UI show", Float) = 0
    _Rim_Lighting0_UI_Show("UI show", Float) = 0
    _Rim_Lighting1_UI_Show("UI show", Float) = 0
    _Rim_Lighting2_UI_Show("UI show", Float) = 0
    _Rim_Lighting3_UI_Show("UI show", Float) = 0
    _Outlines_UI_Show("UI show", Float) = 0
    _Glitter_UI_Show("UI show", Float) = 0
    _Gimmicks_UI_Show("UI show", Float) = 0
    _Rendering_UI_Show("UI show", Float) = 0
    _Explosion_UI_Show("UI show", Float) = 0
    _Geometry_Scroll_UI_Show("UI show", Float) = 0
    _UV_Scroll_UI_Show("UI show", Float) = 0
    _Hue_Shift_UI_Show("UI show", Float) = 0
    _Hue_Shift_OKLAB_UI_Show("UI show", Float) = 0
    _Hue_Shift_HSV_UI_Show("UI show", Float) = 0
    _Clones_UI_Show("UI show", Float) = 0
    _Mochie_UI_Show("UI show", Float) = 0

    _Gimmick_Fog_00_Enable_Static("Enable fog 00", Float) = 0
    _Gimmick_Fog_00_Enable_Area_Lighting("Enable fog 00 area lighting", Float) = 1
    // 0 = cylinder, 1 = plane
    _Gimmick_Fog_00_Boundary_Type("Boundary type", Float) = 0
    _Gimmick_Fog_00_Radius("Radius", Float) = 25
    _Gimmick_Fog_00_Plane_Normal("Plane normal", Vector) = (0, 1, 0, 0)
    _Gimmick_Fog_00_Plane_Center("Plane center", Vector) = (0, 0, 0, 0)
    _Gimmick_Fog_00_Noise("3D noise", 3D) = "white" {}
    _Gimmick_Fog_00_Noise_2D("2D noise", 2D) = "black" {}
    _Gimmick_Fog_00_Max_Ray("Max ray", Float) = 25
    _Gimmick_Fog_00_Step_Size_Factor("Step size (meters)", Float) = 1
    _Gimmick_Fog_00_Noise_Scale("Noise scale", Vector) = (1, 1, 1, 1)
    _Gimmick_Fog_00_Motion_Vector("Motion vector", Vector) = (0, 0, 0, 0)
    _Gimmick_Fog_00_Noise_Exponent("Noise exponent", Float) = 2.0
    _Gimmick_Fog_00_Density("Density", Range(0,10)) = 1.0
    _Gimmick_Fog_00_Normal_Cutoff("Normal cutoff (alpha)", Range(0,1)) = 0.5
    _Gimmick_Fog_00_Alpha_Cutoff("Albedo cutoff (alpha)", Range(0,1)) = 0.9
    _Gimmick_Fog_00_Ray_Origin_Randomization("Enable ray origin randomization", Range(0,1)) = 1
    _Gimmick_Fog_00_Lod_Half_Life("fog", Float) = 5
    _Gimmick_Fog_00_Max_Brightness("max brightness", Range(0, 1)) = 1
    _Gimmick_Fog_00_LTCGI_Brightness("LTCGI brightness", Float) = 1
    _Gimmick_Fog_00_Overlay_Mode("Overlay mode", Float) = 0
    _Gimmick_Fog_00_Emitter_Texture("Emitter texture", 2D) = "black" {}
    _Gimmick_Fog_00_Emitter_Variable_Density("Enable emitter variable density", Float) = 0
    _Gimmick_Fog_00_Emitter_Brightness_Diffuse("fog", Float) = 1
    _Gimmick_Fog_00_Emitter_Brightness_Direct("fog", Float) = 1
    _Gimmick_Fog_00_Emitter_Lod_Half_Life("fog", Float) = 5
    _Gimmick_Fog_00_Initial_Offset("Initial offset", Float) = 0.00001

    _Gimmick_Fog_00_Emitter0_Location("fog", Vector) = (0, 0, 0, 0)
    _Gimmick_Fog_00_Emitter0_Normal("fog", Vector) = (-1, 0, 0, 0)
    _Gimmick_Fog_00_Emitter0_Tangent("fog", Vector) = (-1, 0, 0, 0)
    _Gimmick_Fog_00_Emitter0_Scale_T("fog", Float) = 1
    _Gimmick_Fog_00_Emitter0_Scale_NxT("fog", Float) = 1

    _Gimmick_Fog_00_Emitter1_Enable_Static("fog", Float) = 0
    _Gimmick_Fog_00_Emitter1_Location("fog", Vector) = (0, 0, 0, 0)
    _Gimmick_Fog_00_Emitter1_Normal("fog", Vector) = (-1, 0, 0, 0)
    _Gimmick_Fog_00_Emitter1_Scale_X("fog", Float) = 1
    _Gimmick_Fog_00_Emitter1_Scale_Y("fog", Float) = 1

    _Gimmick_Fog_00_Emitter2_Enable_Static("fog", Float) = 0
    _Gimmick_Fog_00_Emitter2_Location("fog", Vector) = (0, 0, 0, 0)
    _Gimmick_Fog_00_Emitter2_Normal("fog", Vector) = (-1, 0, 0, 0)
    _Gimmick_Fog_00_Emitter2_Scale_X("fog", Float) = 1
    _Gimmick_Fog_00_Emitter2_Scale_Y("fog", Float) = 1

    _Gimmick_Fog_00_Ray_March_0_Enable_Static("enable ray march effect 0", Float) = 0
    _Gimmick_Fog_00_Ray_March_0_Seed("seed", Float) = 0

    _Gimmick_Fog_01_Enable_Static("Enable fog 01", Float) = 0
    _Gimmick_Fog_01_Overlay_Mode("Overlay mode", Float) = 0
    _Gimmick_Fog_01_Density("Density", Range(0, 1)) = 1
    _Gimmick_Fog_01_Sun_Direction("Sun direction", Vector) = (0.866, 0.5, 0, 0)
    _Gimmick_Fog_01_Sun_Exponent("Sun exponent", Float) = 1
    _Gimmick_Fog_01_Sun_Exponent_2("Sun exponent 2", Float) = 1
    [HDR] _Gimmick_Fog_01_Color("Color", Color) = (1, 1, 1, 1)
    [HDR] _Gimmick_Fog_01_Sun_Color("Sun color", Color) = (1, 1, 1, 1)
    [HDR] _Gimmick_Fog_01_Sun_Color_2("Sun color 2", Color) = (1, 1, 1, 1)
    _Gimmick_Fog_01_Sun_Color_2_Enable("Sun color 2 enable", Float) = 0
    _Gimmick_Fog_01_Distance_Culling_Enable("Distance culling enable", Float) = 0
    _Gimmick_Fog_01_Activation_Center("Activation center", Vector) = (0, 0, 0, 0)
    _Gimmick_Fog_01_Activation_Radius("Activation radius", Float) = 1

    _Gimmick_ZWrite_Abomination_Enable_Static("Enable zwrite abomination", Float) = 0
    _Gimmick_ZWrite_Abomination_Min_Hit_Dist("Min hit dist", Float) = 0.001
    _Gimmick_ZWrite_Abomination_March_Steps("March steps", Float) = 30
    _Gimmick_ZWrite_Abomination_Normal_Epsilon("Normal epsilon", Float) = 0.001
    _Gimmick_ZWrite_Abomination_Initial_Step_Size("Initial step size", Float) = 0.001
    _Gimmick_ZWrite_Abomination_Global_Scale("Global scale", Float) = 1
    _Gimmick_ZWrite_Abomination_Vertex_Expansion_Factor("Vertex expansion factor", Float) = 1
    _Gimmick_ZWrite_Abomination_Global_Offset("Global offset", Vector) = (0, 0, 0, 0)

    _Gimmick_ZWrite_Abomination_Body_Half_Height("Body half height", Float) = 0.1
    _Gimmick_ZWrite_Abomination_Body_Radius("Body radius", Float) = 0.1
    _Gimmick_ZWrite_Abomination_Denim_Half_Height("Denim half height", Float) = 0.1
    _Gimmick_ZWrite_Abomination_Denim_Radius("Denim radius", Float) = 0.1
    _Gimmick_ZWrite_Abomination_Denim_Center("Denim center", Vector) = (0, 0, 0, 0)
    _Gimmick_ZWrite_Abomination_Denim_Strap_Theta("Denim strap theta", Float) = 0
    _Gimmick_ZWrite_Abomination_Denim_Strap_RA("Denim strap RA", Float) = 0.01
    _Gimmick_ZWrite_Abomination_Denim_Strap_RB("Denim strap RB", Float) = 0.01
    _Gimmick_ZWrite_Abomination_Denim_Strap_Z_Theta("Denim strap z theta", Float) = 0
    _Gimmick_ZWrite_Abomination_Denim_Strap_Center("Denim strap center", Vector) = (0, 0, 0, 0)
    _Gimmick_ZWrite_Abomination_Lens_Radius("Lens radius", Float) = 0.05
    _Gimmick_ZWrite_Abomination_Lens_Depth("Lens depth", Float) = 0.01
    _Gimmick_ZWrite_Abomination_Lens_Thickness("Lens thickness", Float) = 0.01
    _Gimmick_ZWrite_Abomination_Lens_Strap_Height("Lens strap height", Float) = 0.01
    _Gimmick_ZWrite_Abomination_Pupil_Radius("Pupil radius", Float) = 0.01
    _Gimmick_ZWrite_Abomination_Eye_Center("Eye center", Vector) = (0, 0, 0, 0)
    _Gimmick_ZWrite_Abomination_Arm_Center("Arm center", Vector) = (0, 0, 0, 0)
    _Gimmick_ZWrite_Abomination_Arm_Radius("Arm radius", Float) = 0.01
    _Gimmick_ZWrite_Abomination_Arm_Half_Length("Arm half length", Float) = 0.05
    _Gimmick_ZWrite_Abomination_Leg_Center("Leg center", Vector) = (0, 0, 0, 0)
    _Gimmick_ZWrite_Abomination_Leg_Radius("Leg radius", Float) = 0.01
    _Gimmick_ZWrite_Abomination_Leg_Half_Length("Leg half length", Float) = 0.05
    _Gimmick_ZWrite_Abomination_Mouth_Center("Mouth center", Vector) = (0, 0, 0, 0)
    _Gimmick_ZWrite_Abomination_Mouth_Theta("Mouth theta", Float) = 0
    _Gimmick_ZWrite_Abomination_Mouth_RA("Mouth RA", Float) = 0.01
    _Gimmick_ZWrite_Abomination_Mouth_RB("Mouth RB", Float) = 0.01
    _Gimmick_ZWrite_Abomination_Skin_Color("Skin color", Color) = (1, 1, 1, 1)
    _Gimmick_ZWrite_Abomination_Skin_Metallic("Skin metallic", Float) = 0
    _Gimmick_ZWrite_Abomination_Skin_Roughness("Skin roughness", Float) = 0
    _Gimmick_ZWrite_Abomination_Lens_Color("Lens color", Color) = (1, 1, 1, 1)
    _Gimmick_ZWrite_Abomination_Lens_Metallic("Lens metallic", Float) = 0
    _Gimmick_ZWrite_Abomination_Lens_Roughness("Lens roughness", Float) = 0
    _Gimmick_ZWrite_Abomination_Denim_Color("Denim color", Color) = (1, 1, 1, 1)
    _Gimmick_ZWrite_Abomination_Denim_Metallic("Denim metallic", Float) = 0
    _Gimmick_ZWrite_Abomination_Denim_Roughness("Denim roughness", Float) = 0
    _Gimmick_ZWrite_Abomination_Lens_Strap_Color("Lens strap color", Color) = (1, 1, 1, 1)
    _Gimmick_ZWrite_Abomination_Lens_Strap_Metallic("Lens strap metallic", Float) = 0
    _Gimmick_ZWrite_Abomination_Lens_Strap_Roughness("Lens strap roughness", Float) = 0

    _Gimmick_Aurora_Enable_Static("Enable aurora", Float) = 0

    _Gimmick_Gerstner_Water_Enable_Static("Enable water (gerstner)", Float) = 0
    _Gimmick_Gerstner_Water_M("# of components considered", Float) = 4

    _Gimmick_Gerstner_Water_a("Amplitudes", Vector) = (.001, .0005, .00025, .000125)
    _Gimmick_Gerstner_Water_p("Phases", Vector) = (0, 0, 0, 0)
    _Gimmick_Gerstner_Water_k_x("Wavenumbers (x)", Vector) = (1, 1, 1, 1)
    _Gimmick_Gerstner_Water_k_y("Wavenumbers (y)", Vector) = (1, 1, 1, 1)
    _Gimmick_Gerstner_Water_t_f("Time factor", Vector) = (1, 1, 1, 1)
    _Gimmick_Gerstner_Water_Color_Ramp_Mask("Color ramp mask", Vector) = (1, 1, 1, 1)

    _Gimmick_Gerstner_Water_a1("Amplitudes", Vector) = (0, 0, 0, 0)
    _Gimmick_Gerstner_Water_p1("Phases", Vector) = (0, 0, 0, 0)
    _Gimmick_Gerstner_Water_k_x1("Wavenumbers (x)", Vector) = (1, 1, 1, 1)
    _Gimmick_Gerstner_Water_k_y1("Wavenumbers (y)", Vector) = (1, 1, 1, 1)
    _Gimmick_Gerstner_Water_t_f1("Time factor", Vector) = (1, 1, 1, 1)
    _Gimmick_Gerstner_Water_Color_Ramp_Mask1("Color ramp mask", Vector) = (1, 1, 1, 1)

    _Gimmick_Gerstner_Water_h("Mean water depth", Float) = 10
    _Gimmick_Gerstner_Water_g("Gravity", Float) = 9.8
    _Gimmick_Gerstner_Water_Scale("Scale", Vector) = (1000, 1000, .1, 0)
    _Gimmick_Gerstner_Water_Origin_Damping_Direction("Origin damping direction", Float) = 1
    _Gimmick_Gerstner_Water_Color_Ramp("Color ramp", 2D) = "white" {}
    _Gimmick_Gerstner_Water_Color_Ramp_Offset("Color ramp offset", Float) = 0.5
    _Gimmick_Gerstner_Water_Color_Ramp_Scale("Color ramp offset", Float) = 1

    _Gimmick_Box_Discard_Enable_Static("Enable box discard (static)", Float) = 0
    _Gimmick_Box_Discard_Corner_1("Corner 1", Vector) = (0, 0, 0, 0)
    _Gimmick_Box_Discard_Corner_2("Corner 2", Vector) = (0, 0, 0, 0)
    _Gimmick_Box_Discard_Invert("Invert", Float) = 0

    _Gimmick_Lens_00_Enable_Static("Enable lens 00", Float) = 0
    _Gimmick_Lens_00_Enable_Frame_Counter("Enable frame counter", Float) = 0
    _Gimmick_Lens_00_Frame_Counter_Speed("Speed", Float) = 1
    _Gimmick_Lens_00_Subdivisions("Quantization subdivisions", Float) = 1
    _Gimmick_Lens_00_Mode("Mode", Float) = 0  // 0 = Bayer, 1 = InterleavedGradientNoise
    _Gimmick_Lens_00_Scale("Scale", Float) = 1
    _Gimmick_Lens_00_SSFD_Scale("Scale", Float) = 1
    _Gimmick_Lens_00_SSFD_Max_Fwidth("Max fwidth", Float) = 0.001
    _Gimmick_Lens_00_SSFD_Size_Factor("Size factor", Float) = 1
    _Gimmick_Lens_00_SSFD_Noise("Noise", 3D) = "white" {}

    _Surface_Stable_Fractal_Dithering_Enable_Static("Enable stable fractal dithering", Float) = 0
    _Surface_Stable_Fractal_Dithering_Enable_Dynamic("Enable stable fractal dithering (dynamic)", Float) = 0
    _Surface_Stable_Fractal_Dithering_Noise("Noise", 3D) = "white" {}
    _Surface_Stable_Fractal_Dithering_Scale("Scale", Range(0, 1)) = .1
    _Surface_Stable_Fractal_Dithering_Max_Fwidth("Max fwidth", Float) = 0.01
    _Surface_Stable_Fractal_Dithering_Size_Factor("Size factor", Float) = 0.5
    _Surface_Stable_Fractal_Dithering_Brightness_Factor("Brightness factor", Float) = 1
    _Surface_Stable_Fractal_Dithering_UV_Offset_R("UV offset (r)", Vector) = (0, 0, 0, 0)
    _Surface_Stable_Fractal_Dithering_UV_Offset_G("UV offset (g)", Vector) = (0, 0, 0, 0)
    _Surface_Stable_Fractal_Dithering_UV_Offset_B("UV offset (b)", Vector) = (0, 0, 0, 0)
  }
  SubShader


  {
    GrabPass { "_Tooner_Grabpass" }
    Tags {
      "VRCFallback"="ToonCutout"
      "DisableBatching"="True"
    }
    Pass {
      Tags {
        "RenderType"="Opaque"
        "Queue"="Geometry"
        "LightMode"="ForwardBase"
        "LTCGI"="ALWAYS"
        "DisableBatching"="True"
      }
      Blend [_SrcBlend] [_DstBlend]
      ZWrite [_ZWrite]
      ZTest [_ZTest]
      Cull [_Cull]

      Stencil {
        Ref [_Stencil_Ref_Base]
        Comp [_Stencil_Comp_Base]
        Pass [_Stencil_Pass_Op_Base]
        Fail [_Stencil_Fail_Op_Base]
      }

      CGPROGRAM
      #pragma target 5.0

			#pragma multi_compile_instancing
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
      #pragma multi_compile _ VERTEXLIGHT_ON

      #include "feature_macros.cginc"

			#pragma vertex vert
      #pragma geometry geom
      #pragma fragment frag

      #define FORWARD_BASE_PASS

      #include "tooner_lighting.cginc"
      ENDCG
    }
    Pass {
      Tags {
        "RenderType"="Opaque"
        "Queue"="Geometry"
        "LightMode"="ForwardAdd"
        "DisableBatching"="True"
      }
      Blend [_SrcBlend] One
      ZWrite Off
      Cull [_Cull]

      Stencil {
        Ref [_Stencil_Ref_Base]
        Comp [_Stencil_Comp_Base]
        Pass [_Stencil_Pass_Op_Base]
        Fail [_Stencil_Fail_Op_Base]
      }

      CGPROGRAM
      #pragma target 5.0

			#pragma multi_compile_instancing
      #pragma multi_compile_fwdadd_fullshadows

      #include "feature_macros.cginc"

			#pragma vertex vert
      #pragma geometry geom
      #pragma fragment frag

      #include "tooner_lighting.cginc"
      ENDCG
    }
		Pass {
      Tags {
        "DisableBatching"="True"
      }
      Cull [_OutlinesCull]

      ZWrite [_ZWrite]
      ZTest [_ZTest]

      Stencil {
        Ref [_Stencil_Ref_Outline]
        Comp [_Stencil_Comp_Outline]
        Pass [_Stencil_Pass_Op_Outline]
        Fail [_Stencil_Fail_Op_Outline]
      }

			CGPROGRAM
      #pragma target 5.0
			#pragma multi_compile_instancing

      #include "feature_macros.cginc"

			#pragma vertex vert
      #pragma geometry geom
			#pragma fragment frag

			#include "tooner_outline_pass.cginc"
			ENDCG
		}
		Pass {
      Tags {
        "LightMode" = "ShadowCaster"
        "DisableBatching"="True"
      }
      Cull [_Cull]

      Stencil {
        Ref [_Stencil_Ref_Base]
        Comp [_Stencil_Comp_Base]
        Pass [_Stencil_Pass_Op_Base]
        Fail [_Stencil_Fail_Op_Base]
      }

			CGPROGRAM
      #pragma target 5.0
			#pragma multi_compile_instancing

      #include "feature_macros.cginc"

      #pragma vertex vert
      #pragma fragment frag

      #include "mochie_shadow_caster.cginc"
			ENDCG
		}
  }
  CustomEditor "ToonerGUI"
}

