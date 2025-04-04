using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class ToonerGUI : ShaderGUI {
  Material target;
  MaterialEditor editor;
  MaterialProperty[] properties;
  List<bool> show_ui;

  public override void OnGUI(
      MaterialEditor editor,
      MaterialProperty[] properties) {
    this.target = editor.target as Material;
    this.editor = editor;
    this.properties = properties;
    this.show_ui = new List<bool>();
    DoMain();
  }

  void TexturePropertySingleLine(GUIContent label, MaterialProperty bct)
  {
    if (show_ui.Contains(false)) {
      return;
    }
    editor.TexturePropertySingleLine(label, bct);
  }
  void TexturePropertySingleLine(GUIContent label, MaterialProperty bct, MaterialProperty bc)
  {
    if (show_ui.Contains(false)) {
      return;
    }
    editor.TexturePropertySingleLine(label, bct, bc);
  }
  void TexturePropertyWithHDRColor(GUIContent label, MaterialProperty bct, MaterialProperty bc, bool opt)
  {
    if (show_ui.Contains(false)) {
      return;
    }
    editor.TexturePropertyWithHDRColor(label, bct, bc, opt);
  }
  void TextureScaleOffsetProperty(MaterialProperty bc)
  {
    if (show_ui.Contains(false)) {
      return;
    }
    editor.TextureScaleOffsetProperty(bc);
  }
  void RangeProperty(MaterialProperty bc, string label)
  {
    if (show_ui.Contains(false)) {
      return;
    }
    editor.RangeProperty(bc, label);
  }
  void ShaderProperty(MaterialProperty bc, GUIContent label)
  {
    if (show_ui.Contains(false)) {
      return;
    }
    editor.ShaderProperty(bc, label);
  }
  void FloatProperty(MaterialProperty bc, string label)
  {
    if (show_ui.Contains(false)) {
      return;
    }
    editor.FloatProperty(bc, label);
  }
  void IntegerProperty(MaterialProperty bc, string label)
  {
    if (show_ui.Contains(false)) {
      return;
    }
    editor.IntegerProperty(bc, label);
  }
  void VectorProperty(MaterialProperty bc, string label)
  {
    if (show_ui.Contains(false)) {
      return;
    }
    editor.VectorProperty(bc, label);
  }
  void ColorProperty(MaterialProperty bc, string label)
  {
    if (show_ui.Contains(false)) {
      return;
    }
    editor.ColorProperty(bc, label);
  }
  Enum EnumPopup(GUIContent label, Enum selected)
  {
    if (show_ui.Contains(false)) {
      return selected;
    }
    return EditorGUILayout.EnumPopup(label, selected);
  }
  bool Toggle(string label, bool v)
  {
    if (show_ui.Contains(false)) {
      return v;
    }
    return EditorGUILayout.Toggle(label, v);
  }
  void LabelField(string label)
  {
    if (show_ui.Contains(false)) {
      return;
    }
    EditorGUILayout.LabelField(label);
  }
  void LabelField(string label, UnityEngine.GUIStyle style)
  {
    if (show_ui.Contains(false)) {
      return;
    }
    EditorGUILayout.LabelField(label, style);
  }

  static GUIContent staticLabel = new GUIContent();

  static GUIContent MakeLabel(string prop, string tooltip = null) {
    staticLabel.text = prop;
    staticLabel.tooltip = tooltip;
    return staticLabel;
  }

  static GUIContent MakeLabel(MaterialProperty prop, string tooltip = null) {
    staticLabel.text = prop.displayName;
    staticLabel.tooltip = tooltip;
    return staticLabel;
  }

  void RecordAction (string label) {
    editor.RegisterPropertyChangeUndo(label);
  }

  MaterialProperty FindProperty(string label) {
    return FindProperty(label, properties);
  }

  void SetKeyword(string keyword, bool state) {
    if (state) {
      target.EnableKeyword(keyword);
    } else {
      target.DisableKeyword(keyword);
    }
  }

  void DoBaseColor() {
    MaterialProperty bc = FindProperty("_Color");
    MaterialProperty bct = FindProperty("_MainTex");
    TexturePropertySingleLine(
        MakeLabel(bct, "Base color (RGBA)"),
        bct,
        bc);
    SetKeyword("_BASECOLOR_MAP", bct.textureValue);
    if (bct.textureValue) {
      TextureScaleOffsetProperty(bct);
    }
  }

  void DoNormal() {
    MaterialProperty bct = FindProperty("_BumpMap");
    TexturePropertySingleLine(
        MakeLabel(bct, "Normal"),
        bct,
        FindProperty("_Tex_NormalStr"));
    if (bct.textureValue) {
      TextureScaleOffsetProperty(bct);
    }
    SetKeyword("_NORMAL_MAP", bct.textureValue);
  }

  void DoMetallic() {
    MaterialProperty bc = FindProperty("_Metallic");
    MaterialProperty bct = FindProperty("_MetallicTex");
    TexturePropertySingleLine(
        MakeLabel(bct, "Metallic (RGBA)"),
        bct,
        bc);
    SetKeyword("_METALLIC_MAP", bct.textureValue);
    if (bct.textureValue) {
      TextureScaleOffsetProperty(bct);

      bc = FindProperty("_MetallicTexChannel");
      RangeProperty(bc, "Channel");
    }
  }

  void DoRoughness() {
      MaterialProperty bc = FindProperty("_Roughness");
      MaterialProperty bct = FindProperty("_RoughnessTex");
      TexturePropertySingleLine(
          MakeLabel(bct, "Roughness (RGBA)"),
          bct,
          bc);
      SetKeyword("_ROUGHNESS_MAP", bct.textureValue);
      if (bct.textureValue) {
        TextureScaleOffsetProperty(bct);

        bc = FindProperty("_RoughnessTexChannel");
        RangeProperty(bc, "Channel");

        bc = FindProperty("_Roughness_Invert");
        bool enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = Toggle("Invert", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
      }
  }

  bool AddCollapsibleMenu(string name, string matprop) {
    MaterialProperty bc = FindProperty(matprop + "_UI_Show");
    bool enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    var fs_orig = EditorStyles.label.fontStyle;
    EditorStyles.label.fontStyle = FontStyle.Bold;
    enabled = Toggle(name, enabled);
    EditorStyles.label.fontStyle = fs_orig;
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    return enabled;
  }

  // Why do the cartesian product here rather than in C? Easier to do it here
  // than with C macros!
  enum SamplerMode {
    // Why this order? Backwards compatibility when interpolation selection was introduced
    LinearRepeat,
    LinearClamp,
    PointRepeat,
    PointClamp,
    BilinearRepeat,
    BilinearClamp,
  };
  void DoPBR() {
    show_ui.Add(AddCollapsibleMenu("PBR", "_PBR"));
    EditorGUI.indentLevel += 1;
    {
      DoBaseColor();
      DoNormal();
      DoMetallic();
      DoRoughness();

      EditorGUI.BeginChangeCheck();
      MaterialProperty bc = FindProperty($"_PBR_Sampler_Mode");
      SamplerMode sampler_mode = (SamplerMode) Math.Round(bc.floatValue);
      sampler_mode = (SamplerMode) EnumPopup(
          MakeLabel("Sampler mode"), sampler_mode);
      EditorGUI.EndChangeCheck();
      bc.floatValue = (int) sampler_mode;

      SetKeyword($"_PBR_SAMPLER_LINEAR_REPEAT", sampler_mode == SamplerMode.LinearRepeat);
      SetKeyword($"_PBR_SAMPLER_LINEAR_CLAMP", sampler_mode == SamplerMode.LinearClamp);
      SetKeyword($"_PBR_SAMPLER_BILINEAR_REPEAT", sampler_mode == SamplerMode.BilinearRepeat);
      SetKeyword($"_PBR_SAMPLER_BILINEAR_CLAMP", sampler_mode == SamplerMode.BilinearClamp);
      SetKeyword($"_PBR_SAMPLER_POINT_REPEAT", sampler_mode == SamplerMode.PointRepeat);
      SetKeyword($"_PBR_SAMPLER_POINT_CLAMP", sampler_mode == SamplerMode.PointClamp);
    }
    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  void DoClearcoat() {
    show_ui.Add(AddCollapsibleMenu($"Clearcoat", $"_Clearcoat"));
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;
    bc = FindProperty("_Clearcoat_Enabled");
    bool enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable clearcoat", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_CLEARCOAT", enabled);

    if (enabled) {
        bc = FindProperty("_Clearcoat_Strength");
        RangeProperty(bc, "Strength");
        bc = FindProperty("_Clearcoat_Roughness");
        RangeProperty(bc, "Roughness");
        bc = FindProperty("_Clearcoat_Mask");
        TexturePropertySingleLine(MakeLabel(bc, "Mask"), bc);
        SetKeyword($"_CLEARCOAT_MASK", bc.textureValue);

        if (bc.textureValue) {
          EditorGUI.indentLevel += 1;
          bc = FindProperty("_Clearcoat_Mask_Invert");
          enabled = bc.floatValue > 1E-6;
          EditorGUI.BeginChangeCheck();
          enabled = Toggle("Invert mask", enabled);
          EditorGUI.EndChangeCheck();
          bc.floatValue = enabled ? 1.0f : 0.0f;
          EditorGUI.indentLevel -= 1;
        }

        bc = FindProperty("_Clearcoat_Mask2");
        TexturePropertySingleLine(MakeLabel(bc, "Mask 2"), bc);
        SetKeyword($"_CLEARCOAT_MASK2", bc.textureValue);

        if (bc.textureValue) {
          EditorGUI.indentLevel += 1;
          bc = FindProperty("_Clearcoat_Mask2_Invert");
          enabled = bc.floatValue > 1E-6;
          EditorGUI.BeginChangeCheck();
          enabled = Toggle("Invert mask", enabled);
          EditorGUI.EndChangeCheck();
          bc.floatValue = enabled ? 1.0f : 0.0f;
          EditorGUI.indentLevel -= 1;
        }

        bc = FindProperty("_Clearcoat_Use_Texture_Normals");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = Toggle("Use texture normals", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
    }
    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  enum PbrAlbedoMixMode {
    AlphaBlend,
    Add,
    Min,
    Max,
    Multiply
  };

  void DoPBROverlay() {
    show_ui.Add(AddCollapsibleMenu($"PBR overlays", $"_PBR_Overlay"));
    EditorGUI.indentLevel += 1;
    for (int i = 0; i < 4; i++) {
      show_ui.Add(AddCollapsibleMenu($"PBR overlay {i}", $"_PBR_Overlay{i}"));
      EditorGUI.indentLevel += 1;

      MaterialProperty bc = FindProperty($"_PBR_Overlay{i}_Enable");
      bool enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Enable", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_PBR_OVERLAY{i}", enabled);

      if (enabled) {
        bc = FindProperty($"_PBR_Overlay{i}_BaseColor");
        MaterialProperty bct = FindProperty($"_PBR_Overlay{i}_BaseColorTex");
        TexturePropertySingleLine(
            MakeLabel(bct, "Base color (RGBA)"),
            bct,
            bc);
        if (bct.textureValue) {
          TextureScaleOffsetProperty(bct);
        }
        SetKeyword($"_PBR_OVERLAY{i}_BASECOLOR_MAP", bct.textureValue);

        EditorGUI.BeginChangeCheck();
        bc = FindProperty($"_PBR_Overlay{i}_Mix");
        PbrAlbedoMixMode mode = (PbrAlbedoMixMode) Math.Round(bc.floatValue);
        mode = (PbrAlbedoMixMode) EnumPopup(
            MakeLabel("Mix mode"), mode);
        if (EditorGUI.EndChangeCheck()) {
          RecordAction($"PBR overlay mix mode {i}");
          foreach (Material m in editor.targets) {
            m.SetFloat($"_PBR_Overlay{i}_Mix", (int) mode);
          }
        }
        SetKeyword($"_PBR_OVERLAY{i}_MIX_ALPHA_BLEND", mode == PbrAlbedoMixMode.AlphaBlend);
        SetKeyword($"_PBR_OVERLAY{i}_MIX_ADD", mode == PbrAlbedoMixMode.Add);
        SetKeyword($"_PBR_OVERLAY{i}_MIX_MIN", mode == PbrAlbedoMixMode.Min);
        SetKeyword($"_PBR_OVERLAY{i}_MIX_MAX", mode == PbrAlbedoMixMode.Max);
        SetKeyword($"_PBR_OVERLAY{i}_MIX_MULTIPLY", mode == PbrAlbedoMixMode.Multiply);

        bc = FindProperty($"_PBR_Overlay{i}_Constrain_By_Alpha");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = Toggle("Constrain to transparent sections", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
        if (enabled) {
          EditorGUI.indentLevel += 1;
          bc = FindProperty($"_PBR_Overlay{i}_Constrain_By_Alpha_Min");
          RangeProperty(bc, "Min");
          bc = FindProperty($"_PBR_Overlay{i}_Constrain_By_Alpha_Max");
          RangeProperty(bc, "Max");
          EditorGUI.indentLevel -= 1;
        }
        bc = FindProperty($"_PBR_Overlay{i}_Alpha_Multiplier");
        RangeProperty(bc, "Alpha multiplier");

        bc = FindProperty($"_PBR_Overlay{i}_Emission");
        bct = FindProperty($"_PBR_Overlay{i}_EmissionTex");
        TexturePropertySingleLine(
            MakeLabel(bct, "Emission (RGB)"),
            bct,
            bc);
        if (bct.textureValue) {
          TextureScaleOffsetProperty(bct);
        }
        SetKeyword($"_PBR_OVERLAY{i}_EMISSION_MAP", bct.textureValue);

        bct = FindProperty($"_PBR_Overlay{i}_NormalTex");
        TexturePropertySingleLine(
            MakeLabel(bct, "Normal"),
            bct,
            FindProperty($"_PBR_Overlay{i}_Tex_NormalStr"));
        if (bct.textureValue) {
          TextureScaleOffsetProperty(bct);
        }
        SetKeyword($"_PBR_OVERLAY{i}_NORMAL_MAP", bct.textureValue);

        bc = FindProperty($"_PBR_Overlay{i}_Metallic_Enable");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = Toggle("Enable metallic", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
        SetKeyword($"_PBR_OVERLAY{i}_METALLIC", enabled);

        if (enabled) {
          bc = FindProperty($"_PBR_Overlay{i}_Metallic");
          bct = FindProperty($"_PBR_Overlay{i}_MetallicTex");
          TexturePropertySingleLine(
              MakeLabel(bct, "Metallic (RGBA)"),
              bct,
              bc);
          if (bct.textureValue) {
            TextureScaleOffsetProperty(bct);
          }
          SetKeyword($"_PBR_OVERLAY{i}_METALLIC_MAP", bct.textureValue);
        }

        bc = FindProperty($"_PBR_Overlay{i}_Roughness_Enable");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = Toggle("Enable roughness", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
        SetKeyword($"_PBR_OVERLAY{i}_ROUGHNESS", enabled);

        if (enabled) {
          EditorGUI.indentLevel += 1;
          bc = FindProperty($"_PBR_Overlay{i}_Roughness");
          bct = FindProperty($"_PBR_Overlay{i}_RoughnessTex");
          TexturePropertySingleLine(
              MakeLabel(bct, "Roughness (RGBA)"),
              bct,
              bc);
          if (bct.textureValue) {
            TextureScaleOffsetProperty(bct);
          }
          SetKeyword($"_PBR_OVERLAY{i}_ROUGHNESS_MAP", bct.textureValue);
          EditorGUI.indentLevel -= 1;
        }

        bct = FindProperty($"_PBR_Overlay{i}_Mask");
        TexturePropertySingleLine(
            MakeLabel(bct, "Mask"),
            bct);
        SetKeyword($"_PBR_OVERLAY{i}_MASK", bct.textureValue);

        if (bct.textureValue) {
          TextureScaleOffsetProperty(bct);

          bc = FindProperty($"_PBR_Overlay{i}_Mask_Invert");
          enabled = bc.floatValue > 1E-6;
          EditorGUI.BeginChangeCheck();
          enabled = Toggle("Invert mask", enabled);
          EditorGUI.EndChangeCheck();
          bc.floatValue = enabled ? 1.0f : 0.0f;
        }

        bc = FindProperty($"_PBR_Overlay{i}_UV_Select");
        RangeProperty(
            bc,
            "UV channel");

        bc = FindProperty($"_PBR_Overlay{i}_Mask_Glitter");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = Toggle("Mask glitter", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;

        EditorGUI.BeginChangeCheck();
        bc = FindProperty($"_PBR_Overlay{i}_Sampler_Mode");
        SamplerMode sampler_mode = (SamplerMode) Math.Round(bc.floatValue);
        sampler_mode = (SamplerMode) EnumPopup(
            MakeLabel("Sampler wrapping mode"), sampler_mode);
        EditorGUI.EndChangeCheck();
        bc.floatValue = (int) sampler_mode;
        SetKeyword($"_PBR_OVERLAY{i}_SAMPLER_LINEAR_REPEAT", sampler_mode == SamplerMode.LinearRepeat);
        SetKeyword($"_PBR_OVERLAY{i}_SAMPLER_LINEAR_CLAMP", sampler_mode == SamplerMode.LinearClamp);
        SetKeyword($"_PBR_OVERLAY{i}_SAMPLER_BILINEAR_REPEAT", sampler_mode == SamplerMode.BilinearRepeat);
        SetKeyword($"_PBR_OVERLAY{i}_SAMPLER_BILINEAR_CLAMP", sampler_mode == SamplerMode.BilinearClamp);
        SetKeyword($"_PBR_OVERLAY{i}_SAMPLER_POINT_REPEAT", sampler_mode == SamplerMode.PointRepeat);
        SetKeyword($"_PBR_OVERLAY{i}_SAMPLER_POINT_CLAMP", sampler_mode == SamplerMode.PointClamp);

        bc = FindProperty($"_PBR_Overlay{i}_Mip_Bias");
        FloatProperty(bc, "Mip bias");
      } else {
        SetKeyword($"_PBR_OVERLAY{i}_BASECOLOR_MAP", false);
        SetKeyword($"_PBR_OVERLAY{i}_MIX_ALPHA_BLEND", false);
        SetKeyword($"_PBR_OVERLAY{i}_MIX_ADD", false);
        SetKeyword($"_PBR_OVERLAY{i}_MIX_MIN", false);
        SetKeyword($"_PBR_OVERLAY{i}_MIX_MAX", false);
        SetKeyword($"_PBR_OVERLAY{i}_MIX_MULTIPLY", false);
        SetKeyword($"_PBR_OVERLAY{i}_EMISSION_MAP", false);
        SetKeyword($"_PBR_OVERLAY{i}_NORMAL_MAP", false);
        SetKeyword($"_PBR_OVERLAY{i}_METALLIC_MAP", false);
        SetKeyword($"_PBR_OVERLAY{i}_ROUGHNESS_MAP", false);
        SetKeyword($"_PBR_OVERLAY{i}_MASK", false);
        SetKeyword($"_PBR_OVERLAY{i}_SAMPLER_REPEAT", false);
        SetKeyword($"_PBR_OVERLAY{i}_SAMPLER_CLAMP", false);
      }
      EditorGUI.indentLevel -= 1;
      show_ui.RemoveAt(show_ui.Count - 1);
    }
    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  enum TilingMode {
    Clamp,
    Repeat,
  };
  enum BaseColorMode {
    Color,
    SDF,
  };
  void DoDecal() {
    show_ui.Add(AddCollapsibleMenu("Decals", "_Decal"));
    EditorGUI.indentLevel += 1;
    for (int i = 0; i < 10; i++) {
        show_ui.Add(AddCollapsibleMenu($"Decal {i}", $"_Decal{i}"));
        EditorGUI.indentLevel += 1;

        MaterialProperty bc = FindProperty($"_Decal{i}_Enable");
        bool enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = Toggle("Enable", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
        SetKeyword($"_DECAL{i}", enabled);

        if (enabled) {
          // Add up/down buttons in a horizontal layout
          EditorGUILayout.BeginHorizontal();
          if (i > 0 && GUILayout.Button("↑", GUILayout.Width(30))) {
              SwapDecalSlots(i - 1, i);
          }
          if (i < 9 && GUILayout.Button("↓", GUILayout.Width(30))) {
              SwapDecalSlots(i, i + 1);
          }
          EditorGUILayout.EndHorizontal();

          MaterialProperty bct;
          bc = FindProperty($"_Decal{i}_Color");
          bct = FindProperty($"_Decal{i}_BaseColor");
          TexturePropertySingleLine(MakeLabel(bct, "Base color (RGBA)"), bct, bc);
          // Unconditionally drive scale + offset because it affects all textures.
          TextureScaleOffsetProperty(bct);

          bc = FindProperty($"_Decal{i}_BaseColor_Mode");
          BaseColorMode base_color_mode = (BaseColorMode) Math.Round(bc.floatValue);
          base_color_mode = (BaseColorMode) EnumPopup(MakeLabel("Base color mode"), base_color_mode);
          bc.floatValue = (int) base_color_mode;

          if (base_color_mode == BaseColorMode.SDF) {
            bc = FindProperty($"_Decal{i}_SDF_Threshold");
            RangeProperty(bc, "SDF threshold");

            bc = FindProperty($"_Decal{i}_SDF_Softness");
            RangeProperty(bc, "SDF softness");

            bc = FindProperty($"_Decal{i}_SDF_Px_Range");
            FloatProperty(bc, "SDF px range");

            bc = FindProperty($"_Decal{i}_SDF_Invert");
            enabled = bc.floatValue > 1E-6;
            EditorGUI.BeginChangeCheck();
            enabled = Toggle("Invert SDF", enabled);
            EditorGUI.EndChangeCheck();
            bc.floatValue = enabled ? 1.0f : 0.0f;
          }

          bc = FindProperty($"_Decal{i}_Roughness");
          TexturePropertySingleLine(
              MakeLabel(bc, "Roughness"),
              bc);
          SetKeyword($"_DECAL{i}_ROUGHNESS", bc.textureValue);

          bc = FindProperty($"_Decal{i}_Metallic");
          TexturePropertySingleLine(
              MakeLabel(bc, "Metallic"),
              bc);
          SetKeyword($"_DECAL{i}_METALLIC", bc.textureValue);

          bc = FindProperty($"_Decal{i}_Emission_Strength");
          FloatProperty(
              bc,
              "Emission strength");
          bc = FindProperty($"_Decal{i}_Angle");
          RangeProperty(
              bc,
              "Angle");

          bc = FindProperty($"_Decal{i}_Alpha_Multiplier");
          RangeProperty(bc, "Alpha multiplier");

          bc = FindProperty($"_Decal{i}_Round_Alpha_Multiplier");
          enabled = bc.floatValue > 1E-6;
          EditorGUI.BeginChangeCheck();
          enabled = Toggle("Round alpha multiplier", enabled);
          EditorGUI.EndChangeCheck();
          bc.floatValue = enabled ? 1.0f : 0.0f;

          bct = FindProperty($"_Decal{i}_Mask");
          TexturePropertySingleLine(MakeLabel(bct, "Mask"), bct);
          SetKeyword($"_DECAL{i}_MASK", bct.textureValue);

          if (bct.textureValue) {
            bc = FindProperty($"_Decal{i}_Mask_Invert");
            enabled = bc.floatValue > 1E-6;
            EditorGUI.BeginChangeCheck();
            enabled = Toggle("Invert mask", enabled);
            EditorGUI.EndChangeCheck();
            bc.floatValue = enabled ? 1.0f : 0.0f;
          }

          bc = FindProperty($"_Decal{i}_Tiling_Mode");
          TilingMode tiling_mode = (TilingMode) Math.Round(bc.floatValue);
          tiling_mode = (TilingMode) EnumPopup(
              MakeLabel("Tiling mode"), tiling_mode);
          bc.floatValue = (int) tiling_mode;

          bc = FindProperty($"_Decal{i}_UV_Select");
          RangeProperty(
              bc,
              "UV channel");

          bc = FindProperty($"_Decal{i}_Domain_Warping_Enable_Static");
          enabled = bc.floatValue > 1E-6;
          EditorGUI.BeginChangeCheck();
          enabled = Toggle("Enable domain warping", enabled);
          EditorGUI.EndChangeCheck();
          bc.floatValue = enabled ? 1.0f : 0.0f;
          SetKeyword($"_DECAL{i}_DOMAIN_WARPING", enabled);

          if (enabled) {
            bc = FindProperty($"_Decal{i}_Domain_Warping_Noise");
            TexturePropertySingleLine(MakeLabel(bc, "Domain warping noise"), bc);
            bc = FindProperty($"_Decal{i}_Domain_Warping_Strength");
            FloatProperty(bc, "Domain warping noise strength");
            bc = FindProperty($"_Decal{i}_Domain_Warping_Speed");
            FloatProperty(bc, "Domain warping noise speed");
            bc = FindProperty($"_Decal{i}_Domain_Warping_Octaves");
            FloatProperty(bc, "Domain warping octaves");
            bc = FindProperty($"_Decal{i}_Domain_Warping_Scale");
            FloatProperty(bc, "Domain warping scale");
          }
        }
        EditorGUI.indentLevel -= 1;
        show_ui.RemoveAt(show_ui.Count - 1);
    }
    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  void SwapDecalSlots(int slotA, int slotB) {
    // List of property suffixes to swap
    string[] propertiesToSwap = new string[] {
        "_Enable",
        "_Color",
        "_BaseColor",
        "_BaseColor_Mode",
        "_SDF_Threshold",
        "_SDF_Softness",
        "_SDF_Px_Range",
        "_Roughness",
        "_Metallic",
        "_Emission_Strength",
        "_Angle",
        "_Alpha_Multiplier",
        "_Round_Alpha_Multiplier",
        "_Mask",
        "_Mask_Invert",
        "_Tiling_Mode",
        "_UV_Select",
        "_Domain_Warping_Enable_Static",
        "_Domain_Warping_Noise",
        "_Domain_Warping_Strength", 
        "_Domain_Warping_Speed",
        "_Domain_Warping_Octaves",
        "_Domain_Warping_Scale"
    };

    // Record undo
    RecordAction($"Swap decal slots {slotA} and {slotB}");

    // For each property, swap values between slots
    foreach (string prop in propertiesToSwap) {
        MaterialProperty propA = FindProperty($"_Decal{slotA}{prop}");
        MaterialProperty propB = FindProperty($"_Decal{slotB}{prop}");
        
        if (propA != null && propB != null) {
            if (propA.type == MaterialProperty.PropType.Color) {
                Color tempColor = propA.colorValue;
                propA.colorValue = propB.colorValue;
                propB.colorValue = tempColor;
            } else if (propA.type == MaterialProperty.PropType.Texture) {
                var tempTex = propA.textureValue;
                propA.textureValue = propB.textureValue;
                propB.textureValue = tempTex;
                
                // Also swap texture scale and offset
                Vector4 tempScale = propA.textureScaleAndOffset;
                propA.textureScaleAndOffset = propB.textureScaleAndOffset;
                propB.textureScaleAndOffset = tempScale;
            } else {
              var tempValue = propA.floatValue;
              propA.floatValue = propB.floatValue;
              propB.floatValue = tempValue;
            }
        }
    }
  }

  void DoEmission() {
    show_ui.Add(AddCollapsibleMenu("Emission", "_Emission"));
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;
    MaterialProperty bct;
    {
      LabelField($"Base slot", EditorStyles.boldLabel);
      EditorGUI.indentLevel += 1;

      bc = FindProperty($"_EmissionColor");
      bct = FindProperty($"_EmissionMap");
      TexturePropertyWithHDRColor(
          MakeLabel(bct, "Emission (RGB)"),
          bct, bc, false);
      SetKeyword($"_EMISSION", bct.textureValue);

      EditorGUI.indentLevel -= 1;
    }
    for (int i = 0; i < 2; i++) {
      LabelField($"Extra slot {i}", EditorStyles.boldLabel);
      EditorGUI.indentLevel += 1;
      {
        bc = FindProperty($"_Emission{i}Color");
        bct = FindProperty($"_Emission{i}Tex");
        TexturePropertyWithHDRColor(
            MakeLabel(bct, "Emission (RGB)"),
            bct, bc, false);
        SetKeyword($"_EMISSION{i}", bct.textureValue);

        if (bct.textureValue) {
          bc = FindProperty($"_Emission{i}_UV_Select");
          RangeProperty(
              bc,
              "UV channel");

          bc = FindProperty($"_Emission{i}Multiplier");
          RangeProperty(bc, "Multiplier");
        }
      }
      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Global_Emission_Factor");
    FloatProperty(bc, "Global emissions multiplier");

    bc = FindProperty("_Global_Emission_Additive_Factor");
    FloatProperty(bc, "Global emissions additive factor");

    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  enum MatcapMode {
    Add,
    Multiply,
    Replace,
    Subtract,
    Min,
    Max,
  };

  void DoMatcap() {
    for (int i = 0; i < 2; i++) {
      show_ui.Add(AddCollapsibleMenu($"Matcap {i}", $"_Matcap{i}"));
      EditorGUI.indentLevel += 1;

      MaterialProperty bc;

      bc = FindProperty($"_Matcap{i}");
      TexturePropertySingleLine(
          MakeLabel(bc, $"Matcap {i}"),
          bc);
      SetKeyword($"_MATCAP{i}", bc.textureValue);

      if (!bc.textureValue) {
        EditorGUI.indentLevel -= 1;
        show_ui.RemoveAt(show_ui.Count - 1);
        continue;
      }

      bc = FindProperty($"_Matcap{i}_Mask");
      TexturePropertySingleLine(
          MakeLabel(bc, "Mask"),
          bc);
      SetKeyword($"_MATCAP{i}_MASK", bc.textureValue);

      bool enabled;  // c# is a shitty language
      if (bc.textureValue) {
        EditorGUI.indentLevel += 1;
        bc = FindProperty($"_Matcap{i}_Mask_Invert");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = Toggle("Invert mask", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;

        bc = FindProperty($"_Matcap{i}_Mask_UV_Select");
        RangeProperty(
            bc,
            "UV channel");
        EditorGUI.indentLevel -= 1;
      }

      bc = FindProperty($"_Matcap{i}_Mask2");
      TexturePropertySingleLine(
          MakeLabel(bc, "Mask"),
          bc);
      SetKeyword($"_MATCAP{i}_MASK2", bc.textureValue);

      if (bc.textureValue) {
        EditorGUI.indentLevel += 1;
        bc = FindProperty($"_Matcap{i}_Mask2_Invert_Colors");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = Toggle("Invert mask colors", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;

        bc = FindProperty($"_Matcap{i}_Mask2_Invert_Alpha");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = Toggle("Invert mask alpha", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;

        bc = FindProperty($"_Matcap{i}_Mask2_UV_Select");
        RangeProperty(
            bc,
            "UV channel");
        EditorGUI.indentLevel -= 1;
      }

      bc = FindProperty($"_Matcap{i}_Center_Eye_Fix");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Center eye fix", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;

      EditorGUI.BeginChangeCheck();
      bc = FindProperty($"_Matcap{i}Mode");
      MatcapMode mode = (MatcapMode) Math.Round(bc.floatValue);
      mode = (MatcapMode) EnumPopup(
          MakeLabel("Matcap mode"), mode);
      if (EditorGUI.EndChangeCheck()) {
        RecordAction($"Matcap {i}");
        foreach (Material m in editor.targets) {
          m.SetFloat($"_Matcap{i}Mode", (int) mode);
        }
      }

      bc = FindProperty($"_Matcap{i}Str");
      FloatProperty(
          bc,
          "Matcap strength");

      bc = FindProperty($"_Matcap{i}MixFactor");
      RangeProperty(
          bc,
          "Mix factor");

      bc = FindProperty($"_Matcap{i}Emission");
      FloatProperty(
          bc,
          "Emission strength");

      bc = FindProperty($"_Matcap{i}Quantization");
      FloatProperty(
          bc,
          "Quantization");

      bc = FindProperty($"_Matcap{i}Normal_Enabled");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Replace normals", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_MATCAP{i}_NORMAL", enabled);

      if (enabled) {
        EditorGUI.indentLevel += 1;
        bc = FindProperty($"_Matcap{i}Normal");
        TexturePropertySingleLine(
            MakeLabel(bc, "Normal map"),
            bc);
        if (bc.textureValue) {
          TextureScaleOffsetProperty(bc);

          bc = FindProperty($"_Matcap{i}Normal_Str");
          RangeProperty(bc, "Strength");

          bc = FindProperty($"_Matcap{i}Normal_UV_Select");
          RangeProperty(
              bc,
              "UV channel");

          bc = FindProperty($"_Matcap{i}Normal_Mip_Bias");
          FloatProperty(bc, "Mip bias");
        }
        EditorGUI.indentLevel -= 1;
      }

      bc = FindProperty($"_Matcap{i}Distortion0");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Enable distortion 0", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_MATCAP{i}_DISTORTION0", enabled);

      for (int j = 0; j < 4; j++) {
        bc = FindProperty($"_Matcap{i}_Overwrite_Rim_Lighting_{j}");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = Toggle($"Overwrite rim lighting {j}", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
      }

      EditorGUI.indentLevel -= 1;
      show_ui.RemoveAt(show_ui.Count - 1);
    }
  }

  void DoRimLighting() {
    for (int i = 0; i < 4; i++) {
      show_ui.Add(AddCollapsibleMenu($"Rim lighting {i}", $"_Rim_Lighting{i}"));
      EditorGUI.indentLevel += 1;

      MaterialProperty bc;

      bc = FindProperty($"_Rim_Lighting{i}_Enabled");
      bool enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Enable", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_RIM_LIGHTING{i}", enabled);

      if (!enabled) {
        EditorGUI.indentLevel -= 1;
        show_ui.RemoveAt(show_ui.Count - 1);
        continue;
      }

      bc = FindProperty($"_Rim_Lighting{i}_Color");
      ColorProperty(bc, "Color (RGB)");

      bc = FindProperty($"_Rim_Lighting{i}_Mask");
      TexturePropertySingleLine(
          MakeLabel(bc, "Mask"),
          bc);
      SetKeyword($"_RIM_LIGHTING{i}_MASK", bc.textureValue);
      if (bc.textureValue) {
        EditorGUI.indentLevel += 1;

        bc = FindProperty($"_Rim_Lighting{i}_Mask_Invert");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = Toggle("Invert mask", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;

        bc = FindProperty($"_Rim_Lighting{i}_Mask_UV_Select");
        RangeProperty(bc, "UV channel");

        EditorGUI.indentLevel -= 1;
      }

      bc = FindProperty($"_Rim_Lighting{i}_Mask2");
      TexturePropertySingleLine(
          MakeLabel(bc, "Mask 2"),
          bc);
      SetKeyword($"_RIM_LIGHTING{i}_MASK2", bc.textureValue);
      if (bc.textureValue) {
        EditorGUI.indentLevel += 1;

        bc = FindProperty($"_Rim_Lighting{i}_Mask2_Invert_Colors");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = Toggle("Invert mask colors", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;

        bc = FindProperty($"_Rim_Lighting{i}_Mask2_Invert_Alpha");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = Toggle("Invert mask alpha", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;

        bc = FindProperty($"_Rim_Lighting{i}_Mask2_UV_Select");
        RangeProperty(bc, "UV channel");

        EditorGUI.indentLevel -= 1;
      }

      bc = FindProperty($"_Rim_Lighting{i}_Mask_Sampler_Mode");
      SamplerMode sampler_mode = (SamplerMode) Math.Round(bc.floatValue);
      sampler_mode = (SamplerMode) EnumPopup(
          MakeLabel("Sampler mode"), sampler_mode);
      EditorGUI.EndChangeCheck();
      bc.floatValue = (int) sampler_mode;

      SetKeyword($"_RIM_LIGHTING{i}_SAMPLER_LINEAR_REPEAT", sampler_mode == SamplerMode.LinearRepeat);
      SetKeyword($"_RIM_LIGHTING{i}_SAMPLER_LINEAR_CLAMP", sampler_mode == SamplerMode.LinearClamp);
      SetKeyword($"_RIM_LIGHTING{i}_SAMPLER_BILINEAR_REPEAT", sampler_mode == SamplerMode.BilinearRepeat);
      SetKeyword($"_RIM_LIGHTING{i}_SAMPLER_BILINEAR_CLAMP", sampler_mode == SamplerMode.BilinearClamp);
      SetKeyword($"_RIM_LIGHTING{i}_SAMPLER_POINT_REPEAT", sampler_mode == SamplerMode.PointRepeat);
      SetKeyword($"_RIM_LIGHTING{i}_SAMPLER_POINT_CLAMP", sampler_mode == SamplerMode.PointClamp);

      bc = FindProperty($"_Rim_Lighting{i}_Center_Eye_Fix");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Center eye fix", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;

      bc = FindProperty($"_Rim_Lighting{i}_Use_Texture_Normals");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Use texture normals", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;

      EditorGUI.BeginChangeCheck();
      bc = FindProperty($"_Rim_Lighting{i}_Mode");
      MatcapMode mode = (MatcapMode) Math.Round(bc.floatValue);
      mode = (MatcapMode) EnumPopup(
          MakeLabel("Rim lighting mode"), mode);
      if (EditorGUI.EndChangeCheck()) {
        RecordAction("Rim lighting mode");
        foreach (Material m in editor.targets) {
          m.SetFloat($"_Rim_Lighting{i}_Mode", (int) mode);
        }
      }

      bc = FindProperty($"_Rim_Lighting{i}_Center");
      FloatProperty(
          bc,
          "Center");

      bc = FindProperty($"_Rim_Lighting{i}_Power");
      FloatProperty(
          bc,
          "Power");

      bc = FindProperty($"_Rim_Lighting{i}_Strength");
      FloatProperty(
          bc,
          "Strength");

      bc = FindProperty($"_Rim_Lighting{i}_Emission");
      FloatProperty(
          bc,
          "Emission");

      bc = FindProperty($"_Rim_Lighting{i}_Quantization");
      FloatProperty(
          bc,
          "Quantization");

      bc = FindProperty($"_Rim_Lighting{i}_Glitter_Enabled");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Glitter", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_RIM_LIGHTING{i}_GLITTER", enabled);

      if (enabled) {
        EditorGUI.indentLevel += 1;

        bc = FindProperty($"_Rim_Lighting{i}_Glitter_Density");
        FloatProperty(
            bc,
            "Density");

        bc = FindProperty($"_Rim_Lighting{i}_Glitter_Amount");
        FloatProperty(
            bc,
            "Amount");

        bc = FindProperty($"_Rim_Lighting{i}_Glitter_Speed");
        FloatProperty(
            bc,
            "Speed");

        bc = FindProperty($"_Rim_Lighting{i}_Glitter_Quantization");
        FloatProperty(
            bc,
            "Quantization");

        bc = FindProperty($"_Rim_Lighting{i}_Glitter_UV_Select");
        RangeProperty(
            bc,
            "UV channel");

        EditorGUI.indentLevel -= 1;
      }

      bc = FindProperty($"_Rim_Lighting{i}_PolarMask_Enabled");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Polar mask", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_RIM_LIGHTING{i}_POLAR_MASK", enabled);

      if (enabled) {
        EditorGUI.indentLevel += 1;
        bc = FindProperty($"_Rim_Lighting{i}_PolarMask_Theta");
        FloatProperty(
            bc,
            "Theta");
        bc = FindProperty($"_Rim_Lighting{i}_PolarMask_Power");
        FloatProperty(
            bc,
            "Power");
        EditorGUI.indentLevel -= 1;
      }

      bc = FindProperty($"_Rim_Lighting{i}_Custom_View_Vector_Enabled");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Custom view vector", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_RIM_LIGHTING{i}_CUSTOM_VIEW_VECTOR", enabled);

      if (enabled) {
        EditorGUI.indentLevel += 1;
        bc = FindProperty($"_Rim_Lighting{i}_Custom_View_Vector");
        VectorProperty(bc, "Vector");
        EditorGUI.indentLevel -= 1;
      }

      bc = FindProperty($"_Rim_Lighting{i}_Reflect_In_World_Space");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Reflect in world space", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_RIM_LIGHTING{i}_REFLECT_IN_WORLD", enabled);

      EditorGUI.indentLevel -= 1;
      show_ui.RemoveAt(show_ui.Count - 1);
    }
  }

  void DoMatcapRL() {
    show_ui.Add(AddCollapsibleMenu("Matcaps", "_Matcaps"));
    EditorGUI.indentLevel += 1;

    DoMatcap();
    DoRimLighting();

    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  enum NormalsMode {
    Flat,
    Spherical,
    Realistic,
    Toon
  };

  void DoShadingMode() {
    show_ui.Add(AddCollapsibleMenu("Shading", "_Shading"));
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;

    bc = FindProperty($"_Mesh_Normals_Mode");
    EditorGUI.BeginChangeCheck();
    NormalsMode mode = (NormalsMode) Math.Round(bc.floatValue, 0);
    mode = (NormalsMode) EnumPopup(
        MakeLabel("Normals mode"), mode);
    if (EditorGUI.EndChangeCheck()) {
      RecordAction("Rendering mode");
    }
    bc.floatValue = (float) mode;

    if (mode == NormalsMode.Flat) {
      bc = FindProperty("_Flatten_Mesh_Normals_Str");
      FloatProperty(
          bc,
          "Flattening strength");
    }
    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  void DoOKLAB() {
    show_ui.Add(AddCollapsibleMenu("OKLAB", "_Hue_Shift_OKLAB"));
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;

    bc = FindProperty("_OKLAB_Enabled");
    bool enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    SetKeyword("_OKLAB", enabled);

    if (enabled) {
      bc = FindProperty("_OKLAB_Mask");
      TexturePropertySingleLine(
          MakeLabel(bc, "Mask"),
          bc);

      if (bc.textureValue) {
        bc = FindProperty("_OKLAB_Mask_Invert");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = Toggle("Invert", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
      }

      bc = FindProperty("_OKLAB_Lightness_Shift");
      RangeProperty(
          bc,
          "Lightness shift");
      bc = FindProperty("_OKLAB_Chroma_Shift");
      RangeProperty(
          bc,
          "Chroma shift");
      bc = FindProperty("_OKLAB_Hue_Shift");
      RangeProperty(
          bc,
          "Hue shift");
    }
    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  void DoHSV() {
    show_ui.Add(AddCollapsibleMenu("HSV", "_Hue_Shift_HSV"));
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;

		for (int i = 0; i < 3; i++) {
			bc = FindProperty($"_HSV{i}_Enabled");
			bool enabled = bc.floatValue > 1E-6;
			EditorGUI.BeginChangeCheck();
			enabled = Toggle($"Enable slot {i}", enabled);
			EditorGUI.EndChangeCheck();
			bc.floatValue = enabled ? 1.0f : 0.0f;

			SetKeyword($"_HSV{i}", enabled);

			if (enabled) {
				bc = FindProperty($"_HSV{i}_Mask");
				TexturePropertySingleLine(
						MakeLabel(bc, "Mask"),
						bc);

				if (bc.textureValue) {
					bc = FindProperty($"_HSV{i}_Mask_Invert");
					enabled = bc.floatValue > 1E-6;
					EditorGUI.BeginChangeCheck();
					enabled = Toggle("Invert", enabled);
					EditorGUI.EndChangeCheck();
					bc.floatValue = enabled ? 1.0f : 0.0f;
				}

				bc = FindProperty($"_HSV{i}_Hue_Shift");
				RangeProperty(
						bc,
						"Hue shift");
				bc = FindProperty($"_HSV{i}_Sat_Shift");
				RangeProperty(
						bc,
						"Saturation shift");
				bc = FindProperty($"_HSV{i}_Val_Shift");
				RangeProperty(
						bc,
						"Value shift");
			}
		}
    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  void DoHueShift() {
    show_ui.Add(AddCollapsibleMenu("Hue shift", "_Hue_Shift"));
    EditorGUI.indentLevel += 1;

    DoOKLAB();
    DoHSV();

    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  void DoClones() {
    show_ui.Add(AddCollapsibleMenu("Clones", "_Clones"));
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;

    bc = FindProperty("_Clones_Enabled");
    bool enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    SetKeyword("_CLONES", enabled);

    if (enabled) {
      bc = FindProperty("_Clones_Count");
      RangeProperty(
          bc,
          "Number of clones");
      bc = FindProperty("_Clones_dx");
      RangeProperty(bc, "x offset");
      bc = FindProperty("_Clones_dy");
      RangeProperty(bc, "y offset");
      bc = FindProperty("_Clones_dz");
      RangeProperty(bc, "z offset");
      bc = FindProperty("_Clones_Scale");
      VectorProperty(bc, "Scale");
    }
    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  void DoOutlines() {
    show_ui.Add(AddCollapsibleMenu("Outlines", "_Outlines"));
    EditorGUI.indentLevel += 1;
    MaterialProperty bc;

    bc = FindProperty("_Outline_Width");
    RangeProperty(
        bc,
        "Outline width");
    SetKeyword("_OUTLINES", bc.floatValue > 1E-9);

    if (bc.floatValue > 1E-6) {
      bc = FindProperty("_Outline_Color");
      ColorProperty(
          bc,
          "Outline color (RGBA)");

      bc = FindProperty("_Outline_Emission_Strength");
      RangeProperty(
          bc,
          "Outline emission strength");

      bc = FindProperty("_Outline_Mask");
      TexturePropertySingleLine(
          MakeLabel(bc, "Outline mask"),
          bc);

      bc = FindProperty("_Outline_Mask_Invert");
      bool inverted = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      inverted = Toggle("Invert mask", inverted);
      EditorGUI.EndChangeCheck();
      bc.floatValue = inverted ? 1.0f : 0.0f;

      bc = FindProperty("_Outline_Width_Multiplier");
      FloatProperty(
          bc,
          "Outline width multiplier");
    }
    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  void DoGlitter() {
    show_ui.Add(AddCollapsibleMenu("Glitter", "_Glitter"));
    EditorGUI.indentLevel += 1;

    MaterialProperty bc = FindProperty("_Glitter_Enabled");
    bool enabled = bc.floatValue > 1E-6;

    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable", enabled);
    EditorGUI.EndChangeCheck();
    SetKeyword("_GLITTER", enabled);
    bc.floatValue = enabled ? 1.0f : 0.0f;

    if (enabled) {
      bc = FindProperty("_Glitter_Mask");
      TexturePropertySingleLine(
          MakeLabel(bc, "Glitter mask (RGBA)"),
          bc);

      bc = FindProperty("_Glitter_Color");
      ColorProperty(bc, "Color");

      bc = FindProperty("_Glitter_Density");
      FloatProperty(
          bc,
          "Density");

      bc = FindProperty("_Glitter_Amount");
      FloatProperty(
          bc,
          "Amount");

      bc = FindProperty("_Glitter_Speed");
      FloatProperty(
          bc,
          "Speed");

      bc = FindProperty("_Glitter_Brightness_Lit");
      FloatProperty(
          bc,
          "Brightness (lit)");

      bc = FindProperty("_Glitter_Brightness");
      FloatProperty(
          bc,
          "Brightness (unlit)");

      bc = FindProperty("_Glitter_Angle");
      FloatProperty(
          bc,
          "Angle");

      bc = FindProperty("_Glitter_Power");
      FloatProperty(
          bc,
          "Power");

      bc = FindProperty("_Glitter_UV_Select");
      RangeProperty(
          bc,
          "UV select");

      bc = FindProperty("_Glitter_Vector_Mask_Enabled");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Vector mask", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;

      if (enabled) {
        EditorGUI.indentLevel += 1;

        bc = FindProperty("_Glitter_Vector_Mask_Vector");
        VectorProperty(bc, "Vector");
        bc = FindProperty("_Glitter_Vector_Mask_Power");
        FloatProperty(bc, "Power");
        bc = FindProperty("_Glitter_Vector_Mask_Invert");
        bool inverted = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        inverted = Toggle("Invert", inverted);
        EditorGUI.EndChangeCheck();
        bc.floatValue = inverted ? 1.0f : 0.0f;

        EditorGUI.indentLevel -= 1;
      }
    }
    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  void DoExplosion() {
    show_ui.Add(AddCollapsibleMenu("Explosion", "_Explosion"));
    EditorGUI.indentLevel += 1;

    MaterialProperty bc = FindProperty("_Explode_Toggle");
    bool enabled = bc.floatValue > 1E-6;

    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable", enabled);
    EditorGUI.EndChangeCheck();
    SetKeyword("_EXPLODE", enabled);
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Explode_Phase");
    if (enabled) {
      RangeProperty(
          bc,
          "Explosion phase");
    } else {
      bc.floatValue = 0.0f;
    }
    bc = FindProperty("_OutlinesCull");
    bc.floatValue = (float) UnityEngine.Rendering.CullMode.Front;

    /*
    if (enabled) {
      bc = FindProperty("_Explode_Phase");
      RangeProperty(
          bc,
          "Explosion phase");
      if (bc.floatValue > 1E-3) {
        bc = FindProperty("_Cull");
        bc.floatValue = (float) UnityEngine.Rendering.CullMode.Back;
      } else {
        bc = FindProperty("_Cull");
        bc.floatValue = (float) UnityEngine.Rendering.CullMode.Front;
      }
    } else {
      bc = FindProperty("_Explode_Phase");
      bc.floatValue = 0.0f;
      bc = FindProperty("_Cull");
      bc.floatValue = (float) UnityEngine.Rendering.CullMode.Front;
    }
    */
    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  void DoGeoScroll() {
    show_ui.Add(AddCollapsibleMenu("Geometry scroll", "_Geometry_Scroll"));
    EditorGUI.indentLevel += 1;

    MaterialProperty bc = FindProperty("_Scroll_Toggle");
    bool enabled = bc.floatValue > 1E-6;

    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable", enabled);
    EditorGUI.EndChangeCheck();
    SetKeyword("_SCROLL", enabled);
    bc.floatValue = enabled ? 1.0f : 0.0f;

    if (enabled) {
      bc = FindProperty("_Scroll_Top");
      RangeProperty(
          bc,
          "Scroll top");

      bc = FindProperty("_Scroll_Bottom");
      RangeProperty(
          bc,
          "Scroll bottom");

      bc = FindProperty("_Scroll_Width");
      RangeProperty(
          bc,
          "Scroll width");

      bc = FindProperty("_Scroll_Strength");
      RangeProperty(
          bc,
          "Scroll strength");

      bc = FindProperty("_Scroll_Speed");
      RangeProperty(
          bc,
          "Scroll speed");
    }
    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  void DoUVScroll() {
    show_ui.Add(AddCollapsibleMenu("UV Scroll", "_UV_Scroll"));
    EditorGUI.indentLevel += 1;

    MaterialProperty bc = FindProperty("_UVScroll_Enabled");
    bool enabled = bc.floatValue > 1E-6;

    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable", enabled);
    EditorGUI.EndChangeCheck();
    SetKeyword("_UVSCROLL", enabled);
    bc.floatValue = enabled ? 1.0f : 0.0f;

    if (enabled) {
      bc = FindProperty("_UVScroll_Mask");
      TexturePropertySingleLine(
          MakeLabel(bc, "Mask"),
          bc);

      bc = FindProperty("_UVScroll_U_Speed");
      FloatProperty(
          bc,
          "U speed");

      bc = FindProperty("_UVScroll_V_Speed");
      FloatProperty(
          bc,
          "V speed");

      bc = FindProperty("_UVScroll_Alpha");
      TexturePropertySingleLine(
          MakeLabel(bc, "Alpha"),
          bc);
    }
    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  void DoGimmickFlatColor()
  {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Flat_Color_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Flat color", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_FLAT_COLOR", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Flat_Color_Enable_Dynamic");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Gimmick_Flat_Color_Color");
    ColorProperty(bc, "Color");
    bc = FindProperty("_Gimmick_Flat_Color_Emission");
    ColorProperty(bc, "Emission");

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickUVDomainWarping() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_UV_Domain_Warping_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("UV domain warping", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_UV_DOMAIN_WARPING", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_UV_Domain_Warping_Octaves");
    FloatProperty(bc, "Octaves");
    bc = FindProperty("_Gimmick_UV_Domain_Warping_Strength");
    FloatProperty(bc, "Strength");
    bc = FindProperty("_Gimmick_UV_Domain_Warping_Scale");
    FloatProperty(bc, "Scale");
    bc = FindProperty("_Gimmick_UV_Domain_Warping_Speed");
    FloatProperty(bc, "Speed");
    bc = FindProperty("_Gimmick_UV_Domain_Warping_Noise");
    TexturePropertySingleLine(
        MakeLabel(bc, "Noise"),
        bc);
    bc = FindProperty("_Gimmick_UV_Domain_Warping_Mask");
    TexturePropertySingleLine(
        MakeLabel(bc, "Mask"),
        bc);
    if (bc.textureValue) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Gimmick_UV_Domain_Warping_Mask_Invert");
      FloatProperty(bc, "Invert");
      EditorGUI.indentLevel -= 1;
    }

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickQuantizeLocation() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Quantize_Location_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Quantize location", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_QUANTIZE_LOCATION", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Quantize_Location_Enable_Dynamic");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Gimmick_Quantize_Location_Precision");
    FloatProperty(bc, "Precision");
    bc = FindProperty("_Gimmick_Quantize_Location_Direction");
    FloatProperty(bc, "Direction");
    bc = FindProperty("_Gimmick_Quantize_Location_Multiplier");
    RangeProperty(bc, "Multiplier");
    bc = FindProperty("_Gimmick_Quantize_Location_Mask");
    TexturePropertySingleLine(
        MakeLabel(bc, "Mask"),
        bc);

    bc = FindProperty("_Gimmick_Quantize_Location_Audiolink_Enable_Static");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Audiolink", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_QUANTIZE_LOCATION_AUDIOLINK", enabled);

    if (enabled) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Gimmick_Quantize_Location_Audiolink_Enable_Dynamic");
      enabled = (bc.floatValue != 0.0);
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Enable (runtime switch)", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;

      bc = FindProperty("_Gimmick_Quantize_Location_Audiolink_Strength");
      FloatProperty(
          bc,
          "Strength");

      EditorGUI.indentLevel -= 1;
    }

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickShearLocation() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Shear_Location_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Shear location", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_SHEAR_LOCATION", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Shear_Location_Enable_Dynamic");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Gimmick_Shear_Location_Strength");
    VectorProperty(bc, "Strength");

    bc = FindProperty("_Gimmick_Shear_Location_Mesh_Renderer_Fix");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Mesh renderer fix", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    if (enabled) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Gimmick_Shear_Location_Mesh_Renderer_Offset");
      VectorProperty(bc, "Offset");
      bc = FindProperty("_Gimmick_Shear_Location_Mesh_Renderer_Rotation");
      VectorProperty(bc, "Rotation");
      bc = FindProperty("_Gimmick_Shear_Location_Mesh_Renderer_Scale");
      VectorProperty(bc, "Scale");
      EditorGUI.indentLevel -= 1;
    }

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickSpherizeLocation() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Spherize_Location_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Spherize location", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_SPHERIZE_LOCATION", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Spherize_Location_Enable_Dynamic");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Gimmick_Spherize_Location_Strength");
    RangeProperty(bc, "Strength");
    bc = FindProperty("_Gimmick_Spherize_Location_Radius");
    FloatProperty(bc, "Radius");

    EditorGUI.indentLevel -= 1;
  }


  void DoGimmickEyes00() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Eyes00_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Eyes 00", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_EYES_00", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Eyes00_Effect_Mask");
    TexturePropertySingleLine(
        MakeLabel(bc, "Effect mask"),
        bc);

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickEyes01() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Eyes01_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Eyes 01", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_EYES_01", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Eyes01_Radius");
    FloatProperty(bc, "Radius (meters, object space)");

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickEyes02() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Eyes02_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Eyes 02", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_EYES_02", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Eyes02_N");
    RangeProperty(bc, "n");
    bc = FindProperty("_Gimmick_Eyes02_A0");
    RangeProperty(bc, "a0");
    bc = FindProperty("_Gimmick_Eyes02_A1");
    RangeProperty(bc, "a1");
    bc = FindProperty("_Gimmick_Eyes02_A2");
    RangeProperty(bc, "a2");
    bc = FindProperty("_Gimmick_Eyes02_A3");
    RangeProperty(bc, "a3");
    bc = FindProperty("_Gimmick_Eyes02_A4");
    RangeProperty(bc, "a4");

    bc = FindProperty("_Gimmick_Eyes02_Animate");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Animate", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    if (enabled) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Gimmick_Eyes02_Animate_Speed");
      FloatProperty(bc, "Speed");

      bc = FindProperty("_Gimmick_Eyes02_Animate_Strength");
      FloatProperty(bc, "Strength");
      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Gimmick_Eyes02_UV_X_Symmetry");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("UV x symmetry", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Gimmick_Eyes02_UV_Adjust");
    VectorProperty(bc, "UV scale & offset");

    bc = FindProperty("_Gimmick_Eyes02_Albedo");
    ColorProperty(bc, "Albedo");
    bc = FindProperty("_Gimmick_Eyes02_Metallic");
    FloatProperty(bc, "Metallic");
    bc = FindProperty("_Gimmick_Eyes02_Roughness");
    FloatProperty(bc, "Roughness");
    bc = FindProperty("_Gimmick_Eyes02_Emission");
    ColorProperty(bc, "Emission");

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickDownstairs2() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_DS2_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Downstairs 2", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_DS2", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_DS2_Mask");
    TexturePropertySingleLine(MakeLabel(bc, "Mask"), bc);
    bc = FindProperty("_Gimmick_DS2_Noise");
    TexturePropertySingleLine(MakeLabel(bc, "Noise"), bc);
    bc = FindProperty("_Gimmick_DS2_Albedo_Factor");
    FloatProperty(bc, "Albedo factor");
    bc = FindProperty("_Gimmick_DS2_Emission_Factor");
    FloatProperty(bc, "Emission factor");

    bc = FindProperty("_Gimmick_DS2_Choice");
    FloatProperty(bc, "Choice");
    float choice = bc.floatValue;

    if (Mathf.Round(choice) == -1) {
      EditorGUI.indentLevel += 1;

      EditorGUI.indentLevel -= 1;
    }

    if (Mathf.Round(choice) == 0) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Gimmick_DS2_00_Domain_Warping_Octaves");
      FloatProperty(bc, "Domain warping octaves");
      bc = FindProperty("_Gimmick_DS2_00_Domain_Warping_Strength");
      FloatProperty(bc, "Domain warping strength");
      bc = FindProperty("_Gimmick_DS2_00_Domain_Warping_Scale");
      FloatProperty(bc, "Domain warping scale");
      bc = FindProperty("_Gimmick_DS2_00_Domain_Warping_Speed");
      FloatProperty(bc, "Domain warping speed");

      EditorGUI.indentLevel -= 1;
    }

    if (Mathf.Round(choice) == 1) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Gimmick_DS2_01_Period");
      VectorProperty(bc, "Period");
      bc = FindProperty("_Gimmick_DS2_01_Count");
      VectorProperty(bc, "Count");
      bc = FindProperty("_Gimmick_DS2_01_Radius");
      FloatProperty(bc, "Radius");

      bc = FindProperty("_Gimmick_DS2_01_Domain_Warping_Octaves");
      FloatProperty(bc, "Domain warping octaves");
      bc = FindProperty("_Gimmick_DS2_01_Domain_Warping_Strength");
      FloatProperty(bc, "Domain warping strength");
      bc = FindProperty("_Gimmick_DS2_01_Domain_Warping_Scale");
      FloatProperty(bc, "Domain warping scale");
      bc = FindProperty("_Gimmick_DS2_01_Domain_Warping_Speed");
      FloatProperty(bc, "Domain warping speed");

      EditorGUI.indentLevel -= 1;
    }

    if (Mathf.Round(choice) == 2) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Gimmick_DS2_02_Period");
      VectorProperty(bc, "Period");
      bc = FindProperty("_Gimmick_DS2_02_Count");
      VectorProperty(bc, "Count");
      bc = FindProperty("_Gimmick_DS2_02_Edge_Length");
      FloatProperty(bc, "Edge length");

      bc = FindProperty("_Gimmick_DS2_02_Domain_Warping_Octaves");
      FloatProperty(bc, "Domain warping octaves");
      bc = FindProperty("_Gimmick_DS2_02_Domain_Warping_Strength");
      FloatProperty(bc, "Domain warping strength");
      bc = FindProperty("_Gimmick_DS2_02_Domain_Warping_Scale");
      FloatProperty(bc, "Domain warping scale");
      bc = FindProperty("_Gimmick_DS2_02_Domain_Warping_Speed");
      FloatProperty(bc, "Domain warping speed");

      EditorGUI.indentLevel -= 1;
    }

    if (Mathf.Round(choice) == 3) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Gimmick_DS2_03_Period");
      VectorProperty(bc, "Period");
      bc = FindProperty("_Gimmick_DS2_03_Count");
      VectorProperty(bc, "Count");
      bc = FindProperty("_Gimmick_DS2_03_Edge_Length");
      FloatProperty(bc, "Edge length");

      EditorGUI.indentLevel -= 1;
    }

    if (Mathf.Round(choice) == 11) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Gimmick_DS2_11_Fog_Enable");
      enabled = (bc.floatValue != 0.0);
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Fog enable", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;

      if (enabled) {
        bc = FindProperty("_Gimmick_DS2_11_Fog_Density");
        FloatProperty(bc, "Fog density");
        bc = FindProperty("_Gimmick_DS2_11_Fog_Sun_Direction");
        VectorProperty(bc, "Fog sun direction");
        bc = FindProperty("_Gimmick_DS2_11_Fog_Sun_Exponent");
        FloatProperty(bc, "Fog sun exponent");
        bc = FindProperty("_Gimmick_DS2_11_Fog_Color");
        ColorProperty(bc, "Fog color");
        bc = FindProperty("_Gimmick_DS2_11_Fog_Sun_Color");
        ColorProperty(bc, "Fog sun color");

        bc = FindProperty("_Gimmick_DS2_11_Fog_Sun_Color_2_Enable");
        enabled = (bc.floatValue != 0.0);
        EditorGUI.BeginChangeCheck();
        enabled = Toggle("Fog sun color 2 enable", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;

        if (enabled) {
          bc = FindProperty("_Gimmick_DS2_11_Fog_Sun_Color_2");
          ColorProperty(bc, "Fog sun color 2");
          bc = FindProperty("_Gimmick_DS2_11_Fog_Sun_Exponent_2");
          FloatProperty(bc, "Fog sun exponent 2");
        }
      }

      bc = FindProperty("_Gimmick_DS2_11_FBM");
      TexturePropertySingleLine(MakeLabel(bc, "FBM"), bc);

      bc = FindProperty("_Gimmick_DS2_11_Snow_Color");
      ColorProperty(bc, "Snow color");
      bc = FindProperty("_Gimmick_DS2_11_Snowline");
      FloatProperty(bc, "Snowline");
      bc = FindProperty("_Gimmick_DS2_11_Snowline_Octaves");
      FloatProperty(bc, "Snowline octaves");
      bc = FindProperty("_Gimmick_DS2_11_Snowline_Width");
      FloatProperty(bc, "Snowline width");
      bc = FindProperty("_Gimmick_DS2_11_Snowline_Noise_Scale");
      FloatProperty(bc, "Snowline noise scale");

      bc = FindProperty("_Gimmick_DS2_11_Rock_Color");
      ColorProperty(bc, "Rock color");
      bc = FindProperty("_Gimmick_DS2_11_Rockline");
      FloatProperty(bc, "Rockline");
      bc = FindProperty("_Gimmick_DS2_11_Rockline_Octaves");
      FloatProperty(bc, "Rockline octaves");
      bc = FindProperty("_Gimmick_DS2_11_Rockline_Width");
      FloatProperty(bc, "Rockline width");
      bc = FindProperty("_Gimmick_DS2_11_Rockline_Noise_Scale");
      FloatProperty(bc, "Rockline noise scale");

      bc = FindProperty("_Gimmick_DS2_11_Grass_Color");
      ColorProperty(bc, "Grass color");
      bc = FindProperty("_Gimmick_DS2_11_Alpha");
      RangeProperty(bc, "Alpha");

      bc = FindProperty("_Gimmick_DS2_11_Offset");
      VectorProperty(bc, "Offset");
      bc = FindProperty("_Gimmick_DS2_11_Octaves");
      FloatProperty(bc, "Octaves");
      bc = FindProperty("_Gimmick_DS2_11_March_Initial_Offset");
      FloatProperty(bc, "March initial offset");
      bc = FindProperty("_Gimmick_DS2_11_March_Initial_Step_Size");
      FloatProperty(bc, "March initial step size");
      bc = FindProperty("_Gimmick_DS2_11_March_Steps");
      FloatProperty(bc, "March steps");
      bc = FindProperty("_Gimmick_DS2_11_March_Backtrack_Steps");
      FloatProperty(bc, "March backtrack steps");
      bc = FindProperty("_Gimmick_DS2_11_Simulation_Scale");
      FloatProperty(bc, "Simulation scale");
      bc = FindProperty("_Gimmick_DS2_11_Coord_Scale");
      FloatProperty(bc, "Coord scale");
      bc = FindProperty("_Gimmick_DS2_11_Height_Scale");
      FloatProperty(bc, "Height scale");
      bc = FindProperty("_Gimmick_DS2_11_Height_Power");
      FloatProperty(bc, "Height power");
      bc = FindProperty("_Gimmick_DS2_11_Valley_Power");
      FloatProperty(bc, "Valley power");
      bc = FindProperty("_Gimmick_DS2_11_Valley_Depth");
      FloatProperty(bc, "Valley depth");
      bc = FindProperty("_Gimmick_DS2_11_Early_Exit_Cutoff_Cos_Theta");
      FloatProperty(bc, "Early exit cutoff (cos theta)");

      bc = FindProperty("_Gimmick_DS2_11_Distance_Culling_Enable");
      enabled = (bc.floatValue != 0.0);
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Distance culling enable", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      
      if (enabled) {
        EditorGUI.indentLevel += 1;

        bc = FindProperty("_Gimmick_DS2_11_Activation_Y");
        FloatProperty(bc, "Activation Y");

        EditorGUI.indentLevel -= 1;
      }

      bc = FindProperty("_Gimmick_DS2_11_Normal_Epsilon");
      FloatProperty(bc, "Normal epsilon");

      EditorGUI.indentLevel -= 1;
    }

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickHalo00() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Halo00_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Halo 00", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_HALO_00", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickPixellate() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Pixellate_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Pixellate", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_PIXELLATE", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Pixellate_Resolution_U");
    FloatProperty(bc, "Resolution (U)");
    bc = FindProperty("_Gimmick_Pixellate_Resolution_V");
    FloatProperty(bc, "Resolution (V)");
    bc = FindProperty("_Gimmick_Pixellate_Effect_Mask");
    TexturePropertySingleLine(
        MakeLabel(bc, "Effect mask"),
        bc);

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickTrochoid() {
    MaterialProperty bc;
    bc = FindProperty("_Trochoid_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Trochoid", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_TROCHOID", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Trochoid_R");
    FloatProperty(bc, "R");
    bc = FindProperty("_Trochoid_r");
    FloatProperty(bc, "r");
    bc = FindProperty("_Trochoid_d");
    FloatProperty(bc, "d");
    bc = FindProperty("_Trochoid_Speed");
    FloatProperty(bc, "Speed");
    bc = FindProperty("_Trochoid_Radius_Power");
    FloatProperty(bc, "Radius power");
    bc = FindProperty("_Trochoid_Radius_Scale");
    FloatProperty(bc, "Radius scale");
    bc = FindProperty("_Trochoid_Height_Scale");
    FloatProperty(bc, "Height scale");

    bc = FindProperty("_Trochoid_Enable_Fragment_Normals");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable fragment normals", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Trochoid_Distance_Culling_Enable");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Distance culling enable", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    if (enabled) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Trochoid_Activation_Center");
      VectorProperty(bc, "Activation center");
      bc = FindProperty("_Trochoid_Activation_Radius");
      FloatProperty(bc, "Activation radius");

      EditorGUI.indentLevel -= 1;
    }

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickFaceMeWorldY() {
    MaterialProperty bc;
    bc = FindProperty("_FaceMeWorldY_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("FaceMeWorldY", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_FACE_ME_WORLD_Y", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_FaceMeWorldY_Enable_Dynamic");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_FaceMeWorldY_Enable_X");
    FloatProperty(bc, "X");
    bc = FindProperty("_FaceMeWorldY_Enable_Y");
    FloatProperty(bc, "Y");
    bc = FindProperty("_FaceMeWorldY_Enable_Z");
    FloatProperty(bc, "Z");

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickRorschach() {
    MaterialProperty bc;
    bc = FindProperty("_Rorschach_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Rorschach", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_RORSCHACH", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Rorschach_Enable_Dynamic");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Rorschach_Color");
    ColorProperty(bc, "Color");
    bc = FindProperty("_Rorschach_Count_X");
    FloatProperty(bc, "Count (x)");
    bc = FindProperty("_Rorschach_Count_Y");
    FloatProperty(bc, "Count (y)");
    bc = FindProperty("_Rorschach_Center_Randomization");
    FloatProperty(bc, "Center randomization");
    bc = FindProperty("_Rorschach_Radius");
    FloatProperty(bc, "Radius");
    bc = FindProperty("_Rorschach_Emission_Strength");
    FloatProperty(bc, "Emission strength");
    bc = FindProperty("_Rorschach_Speed");
    FloatProperty(bc, "Speed");
    bc = FindProperty("_Rorschach_Quantization");
    FloatProperty(bc, "Quantization");
    bc = FindProperty("_Rorschach_Alpha_Cutoff");
    FloatProperty(bc, "Alpha cutoff");
    bc = FindProperty("_Rorschach_Mask");
    TexturePropertySingleLine(
        MakeLabel(bc, "Mask"),
        bc);
    SetKeyword("_RORSCHACH_MASK", bc.textureValue);
    if (bc.textureValue) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Rorschach_Mask_Invert");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Invert", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      EditorGUI.indentLevel -= 1;
    }

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickMirrorUVFlip() {
    MaterialProperty bc;
    bc = FindProperty("_Mirror_UV_Flip_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Flip UVs in mirror", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_MIRROR_UV_FLIP", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Mirror_UV_Flip_Enable_Dynamic");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    EditorGUI.indentLevel -= 1;
  }

	void DoGimmickLetterGrid() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Letter_Grid_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Letter grid", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_LETTER_GRID", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Letter_Grid_Texture");
    TexturePropertySingleLine(
        MakeLabel(bc, "Texture"),
        bc);

    bc = FindProperty("_Gimmick_Letter_Grid_Tex_Res_X");
    FloatProperty(bc, "Number of glyphs in texture (X)");
    bc = FindProperty("_Gimmick_Letter_Grid_Tex_Res_Y");
    FloatProperty(bc, "Number of glyphs in texture (Y)");

    bc = FindProperty("_Gimmick_Letter_Grid_Res_X");
    FloatProperty(bc, "Number of glyphs in grid (X)");
    bc = FindProperty("_Gimmick_Letter_Grid_Res_Y");
    FloatProperty(bc, "Number of glyphs in grid (Y)");

    bc = FindProperty("_Gimmick_Letter_Grid_UV_Scale_Offset");
    VectorProperty(bc, "UV scale & offset");
    bc = FindProperty("_Gimmick_Letter_Grid_Padding");
    FloatProperty(bc, "Padding");

    bc = FindProperty("_Gimmick_Letter_Grid_Color");
    bc = FindProperty("_Gimmick_Letter_Grid_Metallic");
    RangeProperty(bc, "Metallic");
    bc = FindProperty("_Gimmick_Letter_Grid_Roughness");
    RangeProperty(bc, "Roughness");
    bc = FindProperty("_Gimmick_Letter_Grid_Emission");
    FloatProperty(bc, "Emission");

    bc = FindProperty("_Gimmick_Letter_Grid_UV_Select");
    RangeProperty(
        bc,
        "UV channel");

    bc = FindProperty("_Gimmick_Letter_Grid_Color_Wave");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Color waves", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_LETTER_GRID_COLOR_WAVE", enabled);

    if (enabled) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Gimmick_Letter_Grid_Color_Wave_Speed");
      FloatProperty(bc, "Speed");
      bc = FindProperty("_Gimmick_Letter_Grid_Color_Wave_Frequency");
      FloatProperty(bc, "Frequency");
      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Gimmick_Letter_Grid_Rim_Lighting");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Rim lighting", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_LETTER_GRID_RIM_LIGHTING", enabled);

    if (enabled) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Gimmick_Letter_Grid_Rim_Lighting_Power");
      FloatProperty(bc, "Power");
      bc = FindProperty("_Gimmick_Letter_Grid_Rim_Lighting_Center");
      FloatProperty(bc, "Center");
      bc = FindProperty("_Gimmick_Letter_Grid_Rim_Lighting_Quantization");
      FloatProperty(bc, "Quantization");
      bc = FindProperty("_Gimmick_Letter_Grid_Rim_Lighting_Mask");
      TexturePropertySingleLine(MakeLabel(bc, "Mask"), bc);
      if (bc.textureValue) {
        EditorGUI.indentLevel += 1;
        bc = FindProperty("_Gimmick_Letter_Grid_Rim_Lighting_Mask_UV_Select");
        FloatProperty(bc, "Mask UV Select");
        bc = FindProperty("_Gimmick_Letter_Grid_Rim_Lighting_Mask_Invert");
        FloatProperty(bc, "Mask invert");
        EditorGUI.indentLevel -= 1;
      }
      EditorGUI.indentLevel -= 1;
    }

    EditorGUI.indentLevel -= 1;
	}

	void DoGimmickLetterGrid2() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Letter_Grid_2_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Letter grid 2", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_LETTER_GRID_2", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Letter_Grid_2_Texture");
    TexturePropertySingleLine(
        MakeLabel(bc, "Texture"),
        bc);

    bc = FindProperty("_Gimmick_Letter_Grid_2_Tex_Res_X");
    FloatProperty(bc, "Number of glyphs in texture (X)");
    bc = FindProperty("_Gimmick_Letter_Grid_2_Tex_Res_Y");
    FloatProperty(bc, "Number of glyphs in texture (Y)");

    MaterialProperty rows = FindProperty("_Gimmick_Letter_Grid_2_Res_X");
    RangeProperty(rows, "Number of glyphs in grid (X)");
    MaterialProperty cols = FindProperty("_Gimmick_Letter_Grid_2_Res_Y");
    RangeProperty(cols, "Number of glyphs in grid (Y)");

    for (int i = 0; i < rows.floatValue; i++) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty($"_Gimmick_Letter_Grid_2_Data_Row_{i}");
      VectorProperty(bc, $"Letter grid data row {i}");
      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Gimmick_Letter_Grid_2_UV_Scale_Offset");
    VectorProperty(bc, "UV scale & offset");
    bc = FindProperty("_Gimmick_Letter_Grid_2_Padding");
    FloatProperty(bc, "Padding");

    bc = FindProperty("_Gimmick_Letter_Grid_2_Color");
    ColorProperty(bc, "Color");
    bc = FindProperty("_Gimmick_Letter_Grid_2_Metallic");
    RangeProperty(bc, "Metallic");
    bc = FindProperty("_Gimmick_Letter_Grid_2_Roughness");
    RangeProperty(bc, "Roughness");
    bc = FindProperty("_Gimmick_Letter_Grid_2_Emission");
    FloatProperty(bc, "Emission");

    bc = FindProperty("_Gimmick_Letter_Grid_2_Mask");
    TexturePropertySingleLine(MakeLabel(bc, "Mask"), bc);

    bc = FindProperty("_Gimmick_Letter_Grid_2_Global_Offset");
    FloatProperty(bc, "Global offset");

    bc = FindProperty("_Gimmick_Letter_Grid_2_Screen_Px_Range");
    FloatProperty(bc, "Screen px range (from msdfgen)");
    bc = FindProperty("_Gimmick_Letter_Grid_2_Min_Screen_Px_Range");
    FloatProperty(bc, "Minimum screen px range");
    bc = FindProperty("_Gimmick_Letter_Grid_2_Blurriness");
    FloatProperty(bc, "Blurriness");
    bc = FindProperty("_Gimmick_Letter_Grid_2_Alpha_Threshold");
    RangeProperty(bc, "Alpha threshold");

    EditorGUI.indentLevel -= 1;
	}

	void DoGimmickAudiolinkChroma00() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_AL_Chroma_00_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Audiolink chroma 00", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_AL_CHROMA_00", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_AL_Chroma_00_Forward_Pass");
    enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Forward pass", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    if (enabled) {
      bc = FindProperty("_Gimmick_AL_Chroma_00_Forward_Blend");
      RangeProperty(bc, "Blend factor");
    }

    bc = FindProperty("_Gimmick_AL_Chroma_00_Outline_Pass");
    enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Outline pass", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    if (enabled) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Gimmick_AL_Chroma_00_Outline_Blend");
      RangeProperty(bc, "Blend factor");

      bc = FindProperty("_Gimmick_AL_Chroma_00_Outline_Emission");
      RangeProperty(bc, "Emission strength");
      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Gimmick_AL_Chroma_00_Hue_Shift_Enable_Static");
    enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Hue shift", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_AL_CHROMA_00_HUE_SHIFT", enabled);

    if (enabled) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Gimmick_AL_Chroma_00_Hue_Shift_Theta");
      RangeProperty(bc, "Theta");

      EditorGUI.indentLevel -= 1;
    }

    EditorGUI.indentLevel -= 1;
	}

  enum GimmickFog00BoundaryType {
    Cylinder = 0,
    Plane = 1,
    Sphere = 2,
  };

  void DoGimmickFog0() {
    MaterialProperty bc;

    bc = FindProperty("_Gimmick_Fog_00_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Fog 00", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_FOG_00", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Fog_00_Density");
    RangeProperty(bc, "Density");

    bc = FindProperty("_Gimmick_Fog_00_Boundary_Type");
    EditorGUI.BeginChangeCheck();
    GimmickFog00BoundaryType boundary_type = (GimmickFog00BoundaryType) Math.Round(bc.floatValue);
    boundary_type = (GimmickFog00BoundaryType) EnumPopup(
        MakeLabel("Boundary type"), boundary_type);
    EditorGUI.EndChangeCheck();
    bc.floatValue = (int) boundary_type;

    if (boundary_type == GimmickFog00BoundaryType.Cylinder || boundary_type == GimmickFog00BoundaryType.Sphere) {
      bc = FindProperty("_Gimmick_Fog_00_Radius");
      FloatProperty(bc, "Radius");
    } else if (boundary_type == GimmickFog00BoundaryType.Plane) {
      bc = FindProperty("_Gimmick_Fog_00_Plane_Normal");
      VectorProperty(bc, "Plane normal");
      bc = FindProperty("_Gimmick_Fog_00_Plane_Center");
      VectorProperty(bc, "Plane center");
    }
    SetKeyword("_GIMMICK_FOG_00_BOUNDARY_CYLINDER", boundary_type == GimmickFog00BoundaryType.Cylinder);
    SetKeyword("_GIMMICK_FOG_00_BOUNDARY_SPHERE", boundary_type == GimmickFog00BoundaryType.Sphere);
    SetKeyword("_GIMMICK_FOG_00_BOUNDARY_PLANE", boundary_type == GimmickFog00BoundaryType.Plane);

    bc = FindProperty("_Gimmick_Fog_00_Step_Size_Factor");
    FloatProperty(bc, "Step size multiplier");
    bc = FindProperty("_Gimmick_Fog_00_Initial_Offset");
    FloatProperty(bc, "Initial offset");
    bc = FindProperty("_Gimmick_Fog_00_Max_Ray");
    FloatProperty(bc, "Max ray length (m)");
    bc = FindProperty("_Gimmick_Fog_00_Noise_Scale");
    VectorProperty(bc, "Noise scale");
    bc = FindProperty("_Gimmick_Fog_00_Motion_Vector");
    VectorProperty(bc, "Motion vector");
    bc = FindProperty("_Gimmick_Fog_00_Noise_Exponent");
    FloatProperty(bc, "Noise exponent");
    bc = FindProperty("_Gimmick_Fog_00_Normal_Cutoff");
    RangeProperty(bc, "Normal cutoff");
    bc = FindProperty("_Gimmick_Fog_00_Alpha_Cutoff");
    RangeProperty(bc, "Alpha cutoff");
    bc = FindProperty("_Gimmick_Fog_00_Ray_Origin_Randomization");
    RangeProperty(bc, "Ray origin randomization");
    bc = FindProperty("_Gimmick_Fog_00_Lod_Half_Life");
    FloatProperty(bc, "LOD half life");
    bc = FindProperty("_Gimmick_Fog_00_Max_Brightness");
    RangeProperty(bc, "Max brightness");
    bc = FindProperty("_Gimmick_Fog_00_Noise");
    TexturePropertySingleLine(
        MakeLabel(bc, "3D Noise"),
        bc);
    bc = FindProperty("_Gimmick_Fog_00_Noise_2D");
    TexturePropertySingleLine(
        MakeLabel(bc, "2D Noise (optional)"),
        bc);
    SetKeyword("_GIMMICK_FOG_00_NOISE_2D", bc.textureValue);

    bc = FindProperty("_Gimmick_Fog_00_LTCGI_Brightness");
    FloatProperty(bc, "LTCGI brightness");

    bc = FindProperty("_Gimmick_Fog_00_Emitter_Texture");
    TexturePropertySingleLine(
        MakeLabel(bc, "Emitter texture"),
        bc);
    SetKeyword("_GIMMICK_FOG_00_EMITTER_TEXTURE", bc.textureValue);
    if (bc.textureValue) {
      EditorGUI.indentLevel += 1;

      // TODO this is a misnomer, it's actually enabling normal-based
      // lighting.
      bc = FindProperty("_Gimmick_Fog_00_Emitter_Variable_Density");
      enabled = (bc.floatValue != 0.0);
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Enable variable density", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword("_GIMMICK_FOG_00_EMITTER_VARIABLE_DENSITY", enabled);

      bc = FindProperty("_Gimmick_Fog_00_Emitter0_Location");
      VectorProperty(bc, "Location (world)");
      bc = FindProperty("_Gimmick_Fog_00_Emitter0_Normal");
      VectorProperty(bc, "Normal (world)");
      bc = FindProperty("_Gimmick_Fog_00_Emitter0_Tangent");
      VectorProperty(bc, "Tangent (world)");
      bc = FindProperty("_Gimmick_Fog_00_Emitter0_Scale_T");
      FloatProperty(bc, "Scale (tangent)");
      bc = FindProperty("_Gimmick_Fog_00_Emitter0_Scale_NxT");
      FloatProperty(bc, "Scale (normal x tangent)");

      bc = FindProperty("_Gimmick_Fog_00_Emitter_Brightness_Diffuse");
      FloatProperty(bc, "Brightness (diffuse)");
      bc = FindProperty("_Gimmick_Fog_00_Emitter_Brightness_Direct");
      FloatProperty(bc, "Brightness (direct)");
      bc = FindProperty("_Gimmick_Fog_00_Emitter_Lod_Half_Life");
      FloatProperty(bc, "LOD half life");

      for (int i = 0; i < 2; i++) {
        bc = FindProperty($"_Gimmick_Fog_00_Emitter{i+1}_Enable_Static");
        enabled = (bc.floatValue != 0.0);
        EditorGUI.BeginChangeCheck();
        enabled = Toggle($"Enable emitter {i+1}", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
        SetKeyword($"_GIMMICK_FOG_00_EMITTER_{i+1}", enabled);

        if (enabled) {
          EditorGUI.indentLevel += 1;

          bc = FindProperty($"_Gimmick_Fog_00_Emitter{i+1}_Location");
          VectorProperty(bc, "Location (world)");
          bc = FindProperty($"_Gimmick_Fog_00_Emitter{i+1}_Normal");
          VectorProperty(bc, "Normal (world)");
          bc = FindProperty($"_Gimmick_Fog_00_Emitter{i+1}_Scale_X");
          FloatProperty(bc, "Scale (x)");
          bc = FindProperty($"_Gimmick_Fog_00_Emitter{i+1}_Scale_Y");
          FloatProperty(bc, "Scale (y)");

          EditorGUI.indentLevel -= 1;
        }
      }

      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Gimmick_Fog_00_Ray_March_0_Enable_Static");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Ray march effect 0", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_FOG_00_RAY_MARCH_0", enabled);

    if (enabled) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Gimmick_Fog_00_Ray_March_0_Seed");
      FloatProperty(bc, "Seed");

      EditorGUI.indentLevel -= 1;
    }

    // Composite fog on top of some raymarched effect. Does not rely on depth
    // buffer; uses whatever the raymarch generated.
    bc = FindProperty("_Gimmick_Fog_00_Overlay_Mode");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Overlay mode", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickFog1() {
    MaterialProperty bc;

    bc = FindProperty("_Gimmick_Fog_01_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Fog 01", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_FOG_01", enabled);

    if (!enabled) {
      return;
    }
    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Fog_01_Density");
    RangeProperty(bc, "Density");
    bc = FindProperty("_Gimmick_Fog_01_Sun_Direction");
    VectorProperty(bc, "Sun direction");
    bc = FindProperty("_Gimmick_Fog_01_Color");
    ColorProperty(bc, "Color");
    bc = FindProperty("_Gimmick_Fog_01_Sun_Color");
    ColorProperty(bc, "Sun color");
    bc = FindProperty("_Gimmick_Fog_01_Sun_Exponent");
    FloatProperty(bc, "Sun exponent");

    bc = FindProperty("_Gimmick_Fog_01_Sun_Color_2_Enable");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Sun color 2", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    if (enabled) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Gimmick_Fog_01_Sun_Color_2");
      ColorProperty(bc, "Color");
      bc = FindProperty("_Gimmick_Fog_01_Sun_Exponent_2");
      FloatProperty(bc, "Exponent");

      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Gimmick_Fog_01_Distance_Culling_Enable");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Distance culling enable", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    if (enabled) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Gimmick_Fog_01_Activation_Center");
      VectorProperty(bc, "Activation center");
      bc = FindProperty("_Gimmick_Fog_01_Activation_Radius");
      FloatProperty(bc, "Activation radius");

      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Gimmick_Fog_01_Overlay_Mode");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Overlay mode", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickZWriteAbomination() {
    MaterialProperty bc;

    bc = FindProperty("_Gimmick_ZWrite_Abomination_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Zwrite abomination", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_ZWRITE_ABOMINATION", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_ZWrite_Abomination_Min_Hit_Dist");
    FloatProperty(bc, "Min hit dist");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_March_Steps");
    FloatProperty(bc, "March steps");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Normal_Epsilon");
    FloatProperty(bc, "Normal epsilon");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Initial_Step_Size");
    FloatProperty(bc, "Initial step size");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Global_Scale");
    FloatProperty(bc, "Global scale");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Vertex_Expansion_Factor");
    FloatProperty(bc, "Vertex expansion factor");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Global_Offset");
    VectorProperty(bc, "Global offset");

    bc = FindProperty("_Gimmick_ZWrite_Abomination_Body_Half_Height");
    FloatProperty(bc, "Body half height");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Body_Radius");
    FloatProperty(bc, "Body radius");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Denim_Radius");
    FloatProperty(bc, "Denim radius");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Denim_Half_Height");
    FloatProperty(bc, "Denim half height");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Denim_Center");
    VectorProperty(bc, "Denim center");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Denim_Strap_Theta");
    FloatProperty(bc, "Denim strap theta");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Denim_Strap_RA");
    FloatProperty(bc, "Denim strap RA");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Denim_Strap_RB");
    FloatProperty(bc, "Denim strap RB");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Denim_Strap_Z_Theta");
    FloatProperty(bc, "Denim strap z theta");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Denim_Strap_Center");
    VectorProperty(bc, "Denim strap center");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Lens_Radius");
    FloatProperty(bc, "Lens radius");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Lens_Depth");
    FloatProperty(bc, "Lens depth");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Lens_Thickness");
    FloatProperty(bc, "Lens thickness");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Lens_Strap_Height");
    FloatProperty(bc, "Lens strap height");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Pupil_Radius");
    FloatProperty(bc, "Pupil radius");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Eye_Center");
    VectorProperty(bc, "Eye center");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Arm_Radius");
    FloatProperty(bc, "Arm radius");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Arm_Half_Length");
    FloatProperty(bc, "Arm half length");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Arm_Center");
    VectorProperty(bc, "Arm center");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Leg_Radius");
    FloatProperty(bc, "Leg radius");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Leg_Half_Length");
    FloatProperty(bc, "Leg half length");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Leg_Center");
    VectorProperty(bc, "Leg center");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Mouth_Theta");
    FloatProperty(bc, "Mouth theta");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Mouth_RA");
    FloatProperty(bc, "Mouth RA");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Mouth_RB");
    FloatProperty(bc, "Mouth RB");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Mouth_Center");
    VectorProperty(bc, "Mouth center");

    bc = FindProperty("_Gimmick_ZWrite_Abomination_Lens_Strap_Color");
    ColorProperty(bc, "Lens strap color");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Lens_Strap_Metallic");
    FloatProperty(bc, "Lens strap metallic");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Lens_Strap_Roughness");
    FloatProperty(bc, "Lens strap roughness");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Skin_Color");
    ColorProperty(bc, "Skin color");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Skin_Metallic");
    FloatProperty(bc, "Skin metallic");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Skin_Roughness");
    FloatProperty(bc, "Skin roughness");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Lens_Color");
    ColorProperty(bc, "Lens color");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Lens_Metallic");
    FloatProperty(bc, "Lens metallic");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Lens_Roughness");
    FloatProperty(bc, "Lens roughness");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Denim_Color");
    ColorProperty(bc, "Denim color");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Denim_Metallic");
    FloatProperty(bc, "Denim metallic");
    bc = FindProperty("_Gimmick_ZWrite_Abomination_Denim_Roughness");
    FloatProperty(bc, "Denim roughness");

    EditorGUI.indentLevel -= 1;
  }


  void DoGimmickAurora() {
    MaterialProperty bc;

    bc = FindProperty("_Gimmick_Aurora_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Aurora", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_AURORA", enabled);

    if (!enabled) {
      return;
    }
    EditorGUI.indentLevel += 1;
    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickGerstnerWater() {
    MaterialProperty bc;

    bc = FindProperty("_Gimmick_Gerstner_Water_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Water (gerstner)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_GERSTNER_WATER", enabled);

    if (!enabled) {
      return;
    }
    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Gerstner_Water_M");
    FloatProperty(bc, "M");
    int num_octaves = (int) Math.Floor((bc.floatValue-1)/4);
    SetKeyword("_GIMMICK_GERSTNER_WATER_OCTAVE_1", num_octaves >= 1);

    bc = FindProperty("_Gimmick_Gerstner_Water_Color_Ramp");
    TexturePropertySingleLine(
        MakeLabel(bc, "Color ramp"),
        bc);
    SetKeyword("_GIMMICK_GERSTNER_WATER_COLOR_RAMP", bc.textureValue);

    if (bc.textureValue) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Gimmick_Gerstner_Water_Color_Ramp_Offset");
      FloatProperty(bc, "Offset");
      bc = FindProperty("_Gimmick_Gerstner_Water_Color_Ramp_Scale");
      FloatProperty(bc, "Scale");
      bc = FindProperty("_Gimmick_Gerstner_Water_Color_Ramp_Mask");
      VectorProperty(bc, "Mask (octave 0)");
      bc = FindProperty("_Gimmick_Gerstner_Water_Color_Ramp_Mask1");
      VectorProperty(bc, "Mask (octave 1)");

      EditorGUI.indentLevel -= 1;
    }

    {
      LabelField("Octave 0", EditorStyles.boldLabel);
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Gimmick_Gerstner_Water_a");
      VectorProperty(bc, "a");
      bc = FindProperty("_Gimmick_Gerstner_Water_p");
      VectorProperty(bc, "p");
      bc = FindProperty("_Gimmick_Gerstner_Water_k_x");
      VectorProperty(bc, "k_x");
      bc = FindProperty("_Gimmick_Gerstner_Water_k_y");
      VectorProperty(bc, "k_y");
      bc = FindProperty("_Gimmick_Gerstner_Water_t_f");
      VectorProperty(bc, "Time speed");
      EditorGUI.indentLevel -= 1;
    }
    if (num_octaves > 0) {
      LabelField("Octave 1", EditorStyles.boldLabel);
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Gimmick_Gerstner_Water_a1");
      VectorProperty(bc, "a");
      bc = FindProperty("_Gimmick_Gerstner_Water_p1");
      VectorProperty(bc, "p");
      bc = FindProperty("_Gimmick_Gerstner_Water_k_x1");
      VectorProperty(bc, "k_x");
      bc = FindProperty("_Gimmick_Gerstner_Water_k_y1");
      VectorProperty(bc, "k_y");
      bc = FindProperty("_Gimmick_Gerstner_Water_t_f1");
      VectorProperty(bc, "Time speed");
      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Gimmick_Gerstner_Water_h");
    FloatProperty(bc, "h");
    bc = FindProperty("_Gimmick_Gerstner_Water_g");
    FloatProperty(bc, "g");
    bc = FindProperty("_Gimmick_Gerstner_Water_Scale");
    VectorProperty(bc, "Scale");
    bc = FindProperty("_Gimmick_Gerstner_Water_Origin_Damping_Direction");
    FloatProperty(bc, "Origin damping direction");

    EditorGUI.indentLevel -= 1;
  }
  
  // Discard unless camera is inside this box.
  void DoGimmickBoxDiscard() {
    MaterialProperty bc;

    bc = FindProperty("_Gimmick_Box_Discard_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Box discard", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_BOX_DISCARD", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Box_Discard_Corner_1");
    VectorProperty(bc, "Corner 1");
    bc = FindProperty("_Gimmick_Box_Discard_Corner_2");
    VectorProperty(bc, "Corner 2");

    bc = FindProperty("_Gimmick_Box_Discard_Invert");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Invert", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    EditorGUI.indentLevel -= 1;
  }

  // Dim and desaturate colors. This is in no way comprehensive. Proceed with
  // utmost caution whenever creating effects for users with photosensitive
  // epilepsy.
  void DoGimmickEpilepsyMode() {
    MaterialProperty bc;

    bc = FindProperty("_Gimmick_Epilepsy_Mode_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Epilepsy protection mode", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_EPILEPSY_MODE", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Epilepsy_Mode_Enable_Dynamic");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Gimmick_Epilepsy_Mode_Luminance_Cutoff");
    RangeProperty(bc, "Luminance cutoff");
    bc = FindProperty("_Gimmick_Epilepsy_Mode_Saturation_Cutoff");
    RangeProperty(bc, "Saturation cutoff");

    bc = FindProperty("_Gimmick_Epilepsy_Mode_Rolloff_Power");
    FloatProperty(bc, "Rolloff power");

    EditorGUI.indentLevel -= 1;
  }

  enum Lens00Mode {
    Bayer,
    InterleavedGradientNoise,
    SurfaceStableFractalDithering,
  }

  void DoLens00() {
    MaterialProperty bc;

    bc = FindProperty("_Gimmick_Lens_00_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Lens00", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_LENS_00", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Lens_00_Enable_Frame_Counter");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Frame counter", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_LENS_00_FRAME_COUNTER", enabled);

    bc = FindProperty("_Gimmick_Lens_00_Subdivisions");
    FloatProperty(bc, "Quantization subdivisions");

    if (enabled) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Gimmick_Lens_00_Frame_Counter_Speed");
      FloatProperty(bc, "Speed");
      EditorGUI.indentLevel -= 1;
    }


    bc = FindProperty("_Gimmick_Lens_00_Scale");
    FloatProperty(bc, "Scale");

    bc = FindProperty("_Gimmick_Lens_00_Mode");
    Lens00Mode mode = (Lens00Mode) Math.Round(bc.floatValue);
    EditorGUI.BeginChangeCheck();
    mode = (Lens00Mode) EnumPopup(
        MakeLabel("Mode"), mode);
    EditorGUI.EndChangeCheck();
    bc.floatValue = (float) mode;
    SetKeyword("_GIMMICK_LENS_00_BAYER", mode == Lens00Mode.Bayer);
    SetKeyword("_GIMMICK_LENS_00_INTERLEAVED_GRADIENT_NOISE", mode == Lens00Mode.InterleavedGradientNoise);
    SetKeyword("_GIMMICK_LENS_00_SSFD", mode == Lens00Mode.SurfaceStableFractalDithering);

    if (mode == Lens00Mode.SurfaceStableFractalDithering) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Gimmick_Lens_00_SSFD_Scale");
      FloatProperty(bc, "Scale");
      bc = FindProperty("_Gimmick_Lens_00_SSFD_Max_Fwidth");
      FloatProperty(bc, "Max fwidth");
      bc = FindProperty("_Gimmick_Lens_00_SSFD_Size_Factor");
      FloatProperty(bc, "Size factor");
      bc = FindProperty("_Gimmick_Lens_00_SSFD_Noise");
      TexturePropertySingleLine(MakeLabel(bc, "Noise"), bc);
      EditorGUI.indentLevel -= 1;
    }


    EditorGUI.indentLevel -= 1;
  }

  void DoSurfaceStableFractalDithering() {
    MaterialProperty bc;

    bc = FindProperty("_Surface_Stable_Fractal_Dithering_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Stable fractal dithering", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_SURFACE_STABLE_FRACTAL_DITHERING", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Surface_Stable_Fractal_Dithering_Enable_Dynamic");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Surface_Stable_Fractal_Dithering_Noise");
    TexturePropertySingleLine(MakeLabel(bc, "Noise"), bc);
    bc = FindProperty("_Surface_Stable_Fractal_Dithering_Scale");
    RangeProperty(bc, "Scale");
    bc = FindProperty("_Surface_Stable_Fractal_Dithering_Max_Fwidth");
    FloatProperty(bc, "Max fwidth");
    bc = FindProperty("_Surface_Stable_Fractal_Dithering_Size_Factor");
    FloatProperty(bc, "Size factor");
    bc = FindProperty("_Surface_Stable_Fractal_Dithering_Brightness_Factor");
    FloatProperty(bc, "Brightness factor");
    bc = FindProperty("_Surface_Stable_Fractal_Dithering_UV_Offset_R");
    VectorProperty(bc, "UV offset (r)");
    bc = FindProperty("_Surface_Stable_Fractal_Dithering_UV_Offset_G");
    VectorProperty(bc, "UV offset (g)");
    bc = FindProperty("_Surface_Stable_Fractal_Dithering_UV_Offset_B");
    VectorProperty(bc, "UV offset (b)");

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmicks() {
    show_ui.Add(AddCollapsibleMenu("Gimmicks", "_Gimmicks"));
    EditorGUI.indentLevel += 1;

    DoGimmickFlatColor();
    DoGimmickUVDomainWarping();
    DoGimmickQuantizeLocation();
    DoGimmickShearLocation();
    DoGimmickSpherizeLocation();
    DoGimmickEyes00();
    DoGimmickEyes01();
    DoGimmickEyes02();
    DoGimmickDownstairs2();
    DoGimmickHalo00();
    DoGimmickPixellate();
    DoGimmickTrochoid();
    DoGimmickFaceMeWorldY();
    DoGimmickRorschach();
    DoGimmickMirrorUVFlip();
    DoGimmickLetterGrid();
    DoGimmickLetterGrid2();
    DoGimmickAudiolinkChroma00();
    DoGimmickFog0();
    DoGimmickFog1();
    DoGimmickZWriteAbomination();
    DoGimmickAurora();
    DoGimmickGerstnerWater();
    DoGimmickBoxDiscard();
    DoClones();
    DoExplosion();
    DoGeoScroll();
    DoGimmickEpilepsyMode();
    DoLens00();
    DoSurfaceStableFractalDithering();

    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  void DoMochieParams() {
    show_ui.Add(AddCollapsibleMenu("Mochie", "_Mochie"));
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;

    bc = FindProperty("_WrappingFactor");
    RangeProperty(bc, "Wrapping factor");
    bc = FindProperty("_SpecularStrength");
    RangeProperty(bc, "Specular strength");
    bc = FindProperty("_FresnelStrength");
    RangeProperty(bc, "Fresnel strength");

    bc = FindProperty("_UseFresnel");
    bool enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Use fresnel", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    MaterialProperty bct = FindProperty("_ReflectionStrengthTex");
    bc = FindProperty("_ReflectionStrength");
    TexturePropertySingleLine(
        MakeLabel(bct, "Ambient occlusion"),
        bct, bc);
    SetKeyword("_REFLECTION_STRENGTH_TEX", bct.textureValue);


    bc = FindProperty("_Enable_SSR");
    enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable SSR", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("SSR_ENABLED", enabled);

    if (enabled) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_SSRStrength");
      FloatProperty(bc, "Strength");

      bc = FindProperty("_SSRHeight");
      FloatProperty(bc, "Height");

      bc = FindProperty("_SSR_Mask");
      TexturePropertySingleLine(
          MakeLabel(bc, "Mask"),
          bc);
      SetKeyword("SSR_MASK", bc.textureValue);

      EditorGUI.indentLevel -= 1;
    } else {
      SetKeyword("SSR_MASK", false);
    }

    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  enum RenderingMode {
    Opaque,
    Cutout,
    Fade,
    Transparent,
    TransClipping,
  }

  enum CutoutMode {
    Cutoff,
    Stochastic,
    InterleavedGradientNoise,
    NoiseMask,
    SurfaceStableFractalDithering,
  }

  // unity is made by fucking morons and they don't expose this so i'm
  // reimplementing it
  // ref: https://docs.unity3d.com/6000.0/Documentation/Manual/SL-ZTest.html
  enum ZTestMode {
    Disabled,
    Never,
    Less,
    Equal,
    LEqual,
    Greater,
    NotEqual,
    GEqual,
    Always
  }

  void DoRendering() {
    show_ui.Add(AddCollapsibleMenu("Rendering", "_Rendering"));
    EditorGUI.indentLevel += 1;

    RenderingMode mode = RenderingMode.Opaque;
    if (target.IsKeywordEnabled("_RENDERING_CUTOUT")) {
      mode = RenderingMode.Cutout;
    } else if (target.IsKeywordEnabled("_RENDERING_FADE")) {
      mode = RenderingMode.Fade;
    } else if (target.IsKeywordEnabled("_RENDERING_TRANSPARENT")) {
      mode = RenderingMode.Transparent;
    } else if (target.IsKeywordEnabled("_RENDERING_TRANSCLIPPING")) {
      mode = RenderingMode.TransClipping;
    }

    MaterialProperty bc;

    EditorGUI.BeginChangeCheck();
    mode = (RenderingMode) EnumPopup(
        MakeLabel("Rendering mode"), mode);
    BlendMode src_blend = BlendMode.One;
    BlendMode dst_blend = BlendMode.Zero;
    bool zwrite = false;
    EditorGUI.EndChangeCheck();
    RecordAction("Rendering mode");

    bc = FindProperty("_Render_Queue_Offset");
    IntegerProperty(
        bc,
        "Render queue offset");
    int queue_offset = bc.intValue;

    {
      SetKeyword("_RENDERING_CUTOUT", mode == RenderingMode.Cutout);
      SetKeyword("_RENDERING_FADE", mode == RenderingMode.Fade);
      SetKeyword("_RENDERING_TRANSPARENT", mode == RenderingMode.Transparent);
      SetKeyword("_RENDERING_TRANSCLIPPING", mode == RenderingMode.TransClipping);

      RenderQueue queue = RenderQueue.Geometry;
      string render_type = "";
      switch (mode) {
        case RenderingMode.Opaque:
          queue = RenderQueue.Geometry;
          render_type = "";
          src_blend = BlendMode.One;
          dst_blend = BlendMode.Zero;
          zwrite = true;
          break;
        case RenderingMode.Cutout:
          queue = RenderQueue.AlphaTest;
          render_type = "TransparentCutout";
          src_blend = BlendMode.One;
          dst_blend = BlendMode.Zero;
          zwrite = true;
          break;
        case RenderingMode.Fade:
          queue = RenderQueue.Transparent;
          render_type = "Transparent";
          src_blend = BlendMode.SrcAlpha;
          dst_blend = BlendMode.OneMinusSrcAlpha;
          zwrite = false;
          break;
        case RenderingMode.Transparent:
          queue = RenderQueue.Transparent;
          render_type = "Transparent";
          src_blend = BlendMode.One;
          dst_blend = BlendMode.OneMinusSrcAlpha;
          zwrite = false;
          break;
        case RenderingMode.TransClipping:
          queue = RenderQueue.AlphaTest;
          render_type = "Transparent";
          src_blend = BlendMode.SrcAlpha;
          dst_blend = BlendMode.OneMinusSrcAlpha;
          zwrite = true;
          break;
      }

      foreach (Material m in editor.targets) {
        m.renderQueue = ((int) queue) + queue_offset;
        m.SetOverrideTag("RenderType", render_type);
        m.SetInt("_SrcBlend", (int) src_blend);
        m.SetInt("_DstBlend", (int) dst_blend);
        m.SetInt("_ZWrite", zwrite ? 1 : 0);
      }
    }

    if (mode == RenderingMode.Cutout) {
      EditorGUI.BeginChangeCheck();
      bc = FindProperty("_Cutout_Mode");
      CutoutMode cmode = (CutoutMode) Math.Round(bc.floatValue);
      cmode = (CutoutMode) EnumPopup(
          MakeLabel("Cutout mode"), cmode);
      EditorGUI.EndChangeCheck();
      bc.floatValue = (float) cmode;
      SetKeyword("_RENDERING_CUTOUT_STOCHASTIC", cmode == CutoutMode.Stochastic);
      SetKeyword("_RENDERING_CUTOUT_IGN", cmode == CutoutMode.InterleavedGradientNoise);
      SetKeyword("_RENDERING_CUTOUT_NOISE_MASK", cmode == CutoutMode.NoiseMask);
      SetKeyword("_RENDERING_CUTOUT_SSFD", cmode == CutoutMode.SurfaceStableFractalDithering);

      EditorGUI.indentLevel += 1;
      {
        if (cmode == CutoutMode.Cutoff) {
          bc = FindProperty("_Alpha_Cutoff");
          ShaderProperty(bc, MakeLabel(bc));
        } else if (cmode == CutoutMode.NoiseMask) {
          bc = FindProperty("_Rendering_Cutout_Noise_Mask");
          TexturePropertySingleLine(
              MakeLabel(bc, "Noise mask"),
              bc);
        } else if (cmode == CutoutMode.InterleavedGradientNoise) {
          bc = FindProperty("_Rendering_Cutout_Ign_Seed");
          FloatProperty(bc, "Seed");
        } else if (cmode == CutoutMode.SurfaceStableFractalDithering) {
          bc = FindProperty("_Rendering_Cutout_SSFD_Scale");
          FloatProperty(bc, "Scale");
          bc = FindProperty("_Rendering_Cutout_SSFD_Max_Fwidth");
          FloatProperty(bc, "Max fwidth");
          bc = FindProperty("_Rendering_Cutout_SSFD_Noise");
          TexturePropertySingleLine(MakeLabel(bc, "Noise"), bc);
        }

        bc = FindProperty("_Rendering_Cutout_Speed");
        FloatProperty(bc, "Speed (for stochastic methods)");
      }
      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Rendering_Cutout_Noise_Scale");
    FloatProperty(bc, "Cutout noise scale");

    bc = FindProperty("_Frame_Counter_Enable_Static");
    bool enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Frame counter", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_FRAME_COUNTER", enabled);
    if (enabled) {
      bc = FindProperty("_Frame_Counter");
      FloatProperty(bc, "Frame counter");
    }

    bc = FindProperty("_Cull");
    UnityEngine.Rendering.CullMode cull_mode = (UnityEngine.Rendering.CullMode) bc.floatValue;
    EditorGUI.BeginChangeCheck();
    cull_mode = (UnityEngine.Rendering.CullMode) EnumPopup(
        MakeLabel("Culling mode"), cull_mode);
    if (EditorGUI.EndChangeCheck()) {
      RecordAction("Culling mode");
      bc.floatValue = (float) cull_mode;
    }

    EditorGUI.BeginChangeCheck();
    bc = FindProperty("_ZTest");
    ZTestMode zmode = (ZTestMode) Math.Round(bc.floatValue);
    zmode = (ZTestMode) EnumPopup(
        MakeLabel("ZTest"), zmode);
    EditorGUI.EndChangeCheck();
    bc.floatValue = (float) zmode;

    bc = FindProperty("_Discard_Enable_Static");
    enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Discard", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_DISCARD", enabled);
    if (enabled) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Discard_Enable_Dynamic");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Enable", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Enable_Unity_Fog");
    enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable Unity fog", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_UNITY_FOG", enabled);

    LabelField("Stenciling", EditorStyles.boldLabel);
    for (int i = 0; i < 2; i++) {
      EditorGUI.indentLevel += 1;

      string pass_str = "";
      switch (i) {
        case 0:
          pass_str = "Base";
          break;
        case 1:
          pass_str = "Outline";
          break;
      }

      LabelField($"{pass_str} pass");
      {
        EditorGUI.indentLevel += 1;
        bc = FindProperty($"_Stencil_Ref_{pass_str}");
        FloatProperty(bc, "Ref");

        bc = FindProperty($"_Stencil_Comp_{pass_str}");
        EditorGUI.BeginChangeCheck();
        UnityEngine.Rendering.CompareFunction stencil_comp =
          (UnityEngine.Rendering.CompareFunction) bc.floatValue;
        stencil_comp = (UnityEngine.Rendering.CompareFunction)
          EnumPopup(MakeLabel("Comp"), stencil_comp);
        EditorGUI.EndChangeCheck();
        RecordAction("Rendering mode");
        bc.floatValue = (float) stencil_comp;

        bc = FindProperty($"_Stencil_Pass_Op_{pass_str}");
        EditorGUI.BeginChangeCheck();
        UnityEngine.Rendering.StencilOp stencil_op =
          (UnityEngine.Rendering.StencilOp) bc.floatValue;
        stencil_op = (UnityEngine.Rendering.StencilOp)
          EnumPopup(MakeLabel("Pass op"), stencil_op);
        EditorGUI.EndChangeCheck();
        RecordAction("Rendering mode");
        bc.floatValue = (float) stencil_op;

        bc = FindProperty($"_Stencil_Fail_Op_{pass_str}");
        EditorGUI.BeginChangeCheck();
        stencil_op = (UnityEngine.Rendering.StencilOp) bc.floatValue;
        stencil_op = (UnityEngine.Rendering.StencilOp)
          EnumPopup(MakeLabel("Fail op"), stencil_op);
        EditorGUI.EndChangeCheck();
        RecordAction("Rendering mode");
        bc.floatValue = (float) stencil_op;

        EditorGUI.indentLevel -= 1;
      }
      EditorGUI.indentLevel -= 1;
    }
    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  void DoLighting() {
    show_ui.Add(AddCollapsibleMenu("Lighting", "_Lighting"));
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;

    bc = FindProperty("_Enable_Brightness_Clamp");
    bool brightness_clamp_enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    brightness_clamp_enabled = Toggle("Clamp brightness",
        brightness_clamp_enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = brightness_clamp_enabled ? 1.0f : 0.0f;
    SetKeyword("_BRIGHTNESS_CLAMP", brightness_clamp_enabled);
    if (brightness_clamp_enabled) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Min_Brightness");
      RangeProperty(
          bc,
          "Min brightness");

      bc = FindProperty("_Max_Brightness");
      RangeProperty(
          bc,
          "Max brightness");
      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Ambient_Occlusion");
    TexturePropertySingleLine(
        MakeLabel(bc, "Ambient occlusion"),
        bc);
    SetKeyword("_AMBIENT_OCCLUSION", bc.textureValue);
    if (bc.textureValue) {
      TextureScaleOffsetProperty(bc);
    }

    if (bc.textureValue) {
      bc = FindProperty("_Ambient_Occlusion_Strength");
      RangeProperty(bc, "Ambient occlusion strength");
    }

    bc = FindProperty("_Cubemap");
    TexturePropertySingleLine(
        MakeLabel(bc, "Cubemap"),
        bc);
    SetKeyword("_CUBEMAP", bc.textureValue);

    if (bc.textureValue) {
      bc = FindProperty("_Cubemap_Limit_To_Metallic");
      bool cube_lim_enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      cube_lim_enabled = Toggle("Limit to metallic",
          cube_lim_enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = cube_lim_enabled ? 1.0f : 0.0f;
    }

    bc = FindProperty("_Lighting_Factor");
    RangeProperty(
        bc,
        "Lighting multiplier");

    {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Direct_Lighting_Factor");
      RangeProperty(
          bc,
          "Direct multiplier");

      bc = FindProperty("_Vertex_Lighting_Factor");
      RangeProperty(
          bc,
          "Vertex light multiplier");

      bc = FindProperty("_Indirect_Specular_Lighting_Factor");
      RangeProperty(
          bc,
          "Indirect specular multiplier");

      bc = FindProperty("_Indirect_Specular_Lighting_Factor2");
      RangeProperty(
          bc,
          "Secondary ind. spec. multiplier");

      bc = FindProperty("_Indirect_Diffuse_Lighting_Factor");
      RangeProperty(
          bc,
          "Indirect diffuse multiplier");
      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Reflection_Probe_Saturation");
    RangeProperty(
        bc,
        "Reflection probe saturation");

    bc = FindProperty("_Shadow_Strength");
    RangeProperty(
        bc,
        "Shadows strength");

    bc = FindProperty("_Global_Sample_Bias");
    FloatProperty(
        bc,
        "Global mipmap bias");

    bc = FindProperty("_Proximity_Dimming_Enable_Static");
    bool enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Proximity dimming", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_PROXIMITY_DIMMING", enabled);

    if (enabled) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Proximity_Dimming_Min_Dist");
      FloatProperty(bc, "Min distance");

      bc = FindProperty("_Proximity_Dimming_Max_Dist");
      FloatProperty(bc, "Max distance");

      bc = FindProperty("_Proximity_Dimming_Factor");
      FloatProperty(bc, "Dimming factor");

      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_LTCGI_Enabled");
    enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable LTCGI", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_LTCGI", enabled);

    if (enabled) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_LTCGI_Enabled_Dynamic");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = Toggle("Enable (runtime switch)", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;

      bc = FindProperty("_LTCGI_SpecularColor");
      ColorProperty(bc, "Specular color (RGB)");

      bc = FindProperty("_LTCGI_DiffuseColor");
      ColorProperty(bc, "Diffuse color (RGB)");

      bc = FindProperty("_LTCGI_Strength");
      FloatProperty(bc, "LTCGI strength");

      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Force_World_Lighting");
    enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Force world lighting", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_FORCE_WORLD_LIGHTING", enabled);

    bc = FindProperty("_Aces_Filmic_Enable_Static");
    enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = Toggle("Enable ACES filmic", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_ACES_FILMIC", enabled);

    EditorGUI.BeginChangeCheck();
    editor.LightmapEmissionProperty();
    if (EditorGUI.EndChangeCheck()) {
      foreach (Material m in editor.targets) {
        m.globalIlluminationFlags &=
          ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
      }
    }

    EditorGUI.indentLevel -= 1;
    show_ui.RemoveAt(show_ui.Count - 1);
  }

  void DoMain() {
    DoPBR();
    DoPBROverlay();
    DoClearcoat();
    DoDecal();
    DoEmission();
    DoShadingMode();
    DoMatcapRL();
    DoOutlines();
    DoGlitter();
    DoUVScroll();
    DoHueShift();
    DoGimmicks();
    DoMochieParams();
    DoLighting();
    DoRendering();
  }
}

