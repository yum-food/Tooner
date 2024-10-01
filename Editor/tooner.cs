using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class ToonerGUI : ShaderGUI {
  Material target;
  MaterialEditor editor;
  MaterialProperty[] properties;

  public override void OnGUI(
      MaterialEditor editor,
      MaterialProperty[] properties) {
    this.target = editor.target as Material;
    this.editor = editor;
    this.properties = properties;
    DoMain();
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

  void DoBaseColorLogic() {
      MaterialProperty bct = FindProperty("_MainTex");
      SetKeyword("_BASECOLOR_MAP", bct.textureValue);
  }
  void DoBaseColorUI() {
      MaterialProperty bc = FindProperty("_Color");
      MaterialProperty bct = FindProperty("_MainTex");
      editor.TexturePropertySingleLine(
          MakeLabel(bct, "Base color (RGBA)"),
          bct,
          bc);
      if (bct.textureValue) {
        editor.TextureScaleOffsetProperty(bct);
      }
  }

  void DoNormalLogic() {
      MaterialProperty bct = FindProperty("_BumpMap");
      SetKeyword("_NORMAL_MAP", bct.textureValue);
  }
  void DoNormalUI() {
      MaterialProperty bct = FindProperty("_BumpMap");
      editor.TexturePropertySingleLine(
          MakeLabel(bct, "Normal"),
          bct,
          FindProperty("_Tex_NormalStr"));
      if (bct.textureValue) {
        editor.TextureScaleOffsetProperty(bct);
      }
  }

  void DoMetallicLogic() {
      MaterialProperty bct = FindProperty("_MetallicTex");
      SetKeyword("_METALLIC_MAP", bct.textureValue);
  }
  void DoMetallicUI() {
      MaterialProperty bc = FindProperty("_Metallic");
      MaterialProperty bct = FindProperty("_MetallicTex");
      editor.TexturePropertySingleLine(
          MakeLabel(bct, "Metallic (RGBA)"),
          bct,
          bc);
      if (bct.textureValue) {
        editor.TextureScaleOffsetProperty(bct);

        bc = FindProperty("_MetallicTexChannel");
        editor.RangeProperty(bc, "Channel");
      }
  }

  void DoRoughnessLogic() {
      MaterialProperty bct = FindProperty("_RoughnessTex");
      SetKeyword("_ROUGHNESS_MAP", bct.textureValue);
  }
  void DoRoughnessUI() {
      MaterialProperty bc = FindProperty("_Roughness");
      MaterialProperty bct = FindProperty("_RoughnessTex");
      editor.TexturePropertySingleLine(
          MakeLabel(bct, "Roughness (RGBA)"),
          bct,
          bc);
      if (bct.textureValue) {
        editor.TextureScaleOffsetProperty(bct);

        bc = FindProperty("_RoughnessTexChannel");
        editor.RangeProperty(bc, "Channel");

        bc = FindProperty("_Roughness_Invert");
        bool enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = EditorGUILayout.Toggle("Invert", enabled);
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
    enabled = EditorGUILayout.Toggle(name, enabled);
    EditorStyles.label.fontStyle = fs_orig;
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    return enabled;
  }

  enum SamplerMode {
    Repeat,
    Clamp,
  };
  void DoPBRLogic() {
      DoBaseColorLogic();
      DoNormalLogic();
      DoMetallicLogic();
      DoRoughnessLogic();

      MaterialProperty bc = FindProperty($"_PBR_Sampler_Mode");
      SamplerMode sampler_mode = (SamplerMode) Math.Round(bc.floatValue);
      SetKeyword($"_PBR_SAMPLER_REPEAT", sampler_mode == SamplerMode.Repeat);
      SetKeyword($"_PBR_SAMPLER_CLAMP", sampler_mode == SamplerMode.Clamp);
  }
  void DoPBRUI() {
    if (!AddCollapsibleMenu("PBR", "_PBR")) {
      return;
    }
    EditorGUI.indentLevel += 1;
    {
      DoBaseColorUI();
      DoNormalUI();
      DoMetallicUI();
      DoRoughnessUI();

      EditorGUI.BeginChangeCheck();
      MaterialProperty bc = FindProperty($"_PBR_Sampler_Mode");
      SamplerMode sampler_mode = (SamplerMode) Math.Round(bc.floatValue);
      sampler_mode = (SamplerMode) EditorGUILayout.EnumPopup(
          MakeLabel("Sampler mode"), sampler_mode);
      EditorGUI.EndChangeCheck();
      bc.floatValue = (int) sampler_mode;
    }
    EditorGUI.indentLevel -= 1;
  }
  void DoPBR() {
    DoPBRLogic();
    DoPBRUI();
  }

  void DoClearcoat() {
    if (!AddCollapsibleMenu($"Clearcoat", $"_Clearcoat")) {
      return;
    }
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;
    bc = FindProperty("_Clearcoat_Enabled");
    bool enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Enable clearcoat", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_CLEARCOAT", enabled);

    if (enabled) {
        bc = FindProperty("_Clearcoat_Strength");
        editor.RangeProperty(bc, "Strength");
        bc = FindProperty("_Clearcoat_Roughness");
        editor.RangeProperty(bc, "Roughness");
        bc = FindProperty("_Clearcoat_Mask");
        editor.TexturePropertySingleLine(MakeLabel(bc, "Mask"), bc);
        SetKeyword($"_CLEARCOAT_MASK", bc.textureValue);

        if (bc.textureValue) {
          EditorGUI.indentLevel += 1;
          bc = FindProperty("_Clearcoat_Mask_Invert");
          enabled = bc.floatValue > 1E-6;
          EditorGUI.BeginChangeCheck();
          enabled = EditorGUILayout.Toggle("Invert mask", enabled);
          EditorGUI.EndChangeCheck();
          bc.floatValue = enabled ? 1.0f : 0.0f;
          EditorGUI.indentLevel -= 1;
        }

        bc = FindProperty("_Clearcoat_Mask2");
        editor.TexturePropertySingleLine(MakeLabel(bc, "Mask 2"), bc);
        SetKeyword($"_CLEARCOAT_MASK2", bc.textureValue);

        if (bc.textureValue) {
          EditorGUI.indentLevel += 1;
          bc = FindProperty("_Clearcoat_Mask2_Invert");
          enabled = bc.floatValue > 1E-6;
          EditorGUI.BeginChangeCheck();
          enabled = EditorGUILayout.Toggle("Invert mask", enabled);
          EditorGUI.EndChangeCheck();
          bc.floatValue = enabled ? 1.0f : 0.0f;
          EditorGUI.indentLevel -= 1;
        }
    }
    EditorGUI.indentLevel -= 1;
  }

  enum PbrAlbedoMixMode {
    AlphaBlend,
    Add,
    Min,
    Max
  };

  void DoPBROverlay() {
    if (!AddCollapsibleMenu($"PBR overlays", $"_PBR_Overlay")) {
      return;
    }
    EditorGUI.indentLevel += 1;
    for (int i = 0; i < 4; i++) {
      if (!AddCollapsibleMenu($"PBR overlay {i}", $"_PBR_Overlay{i}")) {
        continue;
      }
      EditorGUI.indentLevel += 1;

      MaterialProperty bc = FindProperty($"_PBR_Overlay{i}_Enable");
      bool enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = EditorGUILayout.Toggle("Enable", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_PBR_OVERLAY{i}", enabled);

      if (enabled) {
        bc = FindProperty($"_PBR_Overlay{i}_BaseColor");
        MaterialProperty bct = FindProperty($"_PBR_Overlay{i}_BaseColorTex");
        editor.TexturePropertySingleLine(
            MakeLabel(bct, "Base color (RGBA)"),
            bct,
            bc);
        if (bct.textureValue) {
          editor.TextureScaleOffsetProperty(bct);
        }
        SetKeyword($"_PBR_OVERLAY{i}_BASECOLOR_MAP", bct.textureValue);

        EditorGUI.BeginChangeCheck();
        bc = FindProperty($"_PBR_Overlay{i}_Mix");
        PbrAlbedoMixMode mode = (PbrAlbedoMixMode) Math.Round(bc.floatValue);
        mode = (PbrAlbedoMixMode) EditorGUILayout.EnumPopup(
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

        bc = FindProperty($"_PBR_Overlay{i}_Constrain_By_Alpha");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = EditorGUILayout.Toggle("Constrain to transparent sections", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
        if (enabled) {
          EditorGUI.indentLevel += 1;
          bc = FindProperty($"_PBR_Overlay{i}_Constrain_By_Alpha_Min");
          editor.RangeProperty(bc, "Min");
          bc = FindProperty($"_PBR_Overlay{i}_Constrain_By_Alpha_Max");
          editor.RangeProperty(bc, "Max");
          EditorGUI.indentLevel -= 1;
        }
        bc = FindProperty($"_PBR_Overlay{i}_Alpha_Multiplier");
        editor.RangeProperty(bc, "Alpha multiplier");

        bc = FindProperty($"_PBR_Overlay{i}_Emission");
        bct = FindProperty($"_PBR_Overlay{i}_EmissionTex");
        editor.TexturePropertySingleLine(
            MakeLabel(bct, "Emission (RGB)"),
            bct,
            bc);
        if (bct.textureValue) {
          editor.TextureScaleOffsetProperty(bct);
        }
        SetKeyword($"_PBR_OVERLAY{i}_EMISSION_MAP", bct.textureValue);

        bct = FindProperty($"_PBR_Overlay{i}_NormalTex");
        editor.TexturePropertySingleLine(
            MakeLabel(bct, "Normal"),
            bct,
            FindProperty($"_PBR_Overlay{i}_Tex_NormalStr"));
        if (bct.textureValue) {
          editor.TextureScaleOffsetProperty(bct);
        }
        SetKeyword($"_PBR_OVERLAY{i}_NORMAL_MAP", bct.textureValue);

        bc = FindProperty($"_PBR_Overlay{i}_Metallic_Enable");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = EditorGUILayout.Toggle("Enable metallic", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
        SetKeyword($"_PBR_OVERLAY{i}_METALLIC", enabled);

        if (enabled) {
          bc = FindProperty($"_PBR_Overlay{i}_Metallic");
          bct = FindProperty($"_PBR_Overlay{i}_MetallicTex");
          editor.TexturePropertySingleLine(
              MakeLabel(bct, "Metallic (RGBA)"),
              bct,
              bc);
          if (bct.textureValue) {
            editor.TextureScaleOffsetProperty(bct);
          }
          SetKeyword($"_PBR_OVERLAY{i}_METALLIC_MAP", bct.textureValue);
        }

        bc = FindProperty($"_PBR_Overlay{i}_Roughness_Enable");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = EditorGUILayout.Toggle("Enable roughness", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
        SetKeyword($"_PBR_OVERLAY{i}_ROUGHNESS", enabled);

        if (enabled) {
          EditorGUI.indentLevel += 1;
          bc = FindProperty($"_PBR_Overlay{i}_Roughness");
          bct = FindProperty($"_PBR_Overlay{i}_RoughnessTex");
          editor.TexturePropertySingleLine(
              MakeLabel(bct, "Roughness (RGBA)"),
              bct,
              bc);
          if (bct.textureValue) {
            editor.TextureScaleOffsetProperty(bct);
          }
          SetKeyword($"_PBR_OVERLAY{i}_ROUGHNESS_MAP", bct.textureValue);
          EditorGUI.indentLevel -= 1;
        }

        bct = FindProperty($"_PBR_Overlay{i}_Mask");
        editor.TexturePropertySingleLine(
            MakeLabel(bct, "Mask"),
            bct);
        SetKeyword($"_PBR_OVERLAY{i}_MASK", bct.textureValue);

        if (bct.textureValue) {
          bc = FindProperty($"_PBR_Overlay{i}_Mask_Invert");
          enabled = bc.floatValue > 1E-6;
          EditorGUI.BeginChangeCheck();
          enabled = EditorGUILayout.Toggle("Invert mask", enabled);
          EditorGUI.EndChangeCheck();
          bc.floatValue = enabled ? 1.0f : 0.0f;
        }

        bc = FindProperty($"_PBR_Overlay{i}_UV_Select");
        editor.RangeProperty(
            bc,
            "UV channel");

        bc = FindProperty($"_PBR_Overlay{i}_Mask_Glitter");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = EditorGUILayout.Toggle("Mask glitter", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;

        EditorGUI.BeginChangeCheck();
        bc = FindProperty($"_PBR_Overlay{i}_Sampler_Mode");
        SamplerMode sampler_mode = (SamplerMode) Math.Round(bc.floatValue);
        sampler_mode = (SamplerMode) EditorGUILayout.EnumPopup(
            MakeLabel("Sampler mode"), sampler_mode);
        EditorGUI.EndChangeCheck();
        bc.floatValue = (int) sampler_mode;
        SetKeyword($"_PBR_OVERLAY{i}_SAMPLER_REPEAT", sampler_mode == SamplerMode.Repeat);
        SetKeyword($"_PBR_OVERLAY{i}_SAMPLER_CLAMP", sampler_mode == SamplerMode.Clamp);

        bc = FindProperty($"_PBR_Overlay{i}_Mip_Bias");
        editor.FloatProperty(bc, "Mip bias");
      } else {
        SetKeyword($"_PBR_OVERLAY{i}_BASECOLOR_MAP", false);
        SetKeyword($"_PBR_OVERLAY{i}_MIX_ALPHA_BLEND", false);
        SetKeyword($"_PBR_OVERLAY{i}_MIX_ADD", false);
        SetKeyword($"_PBR_OVERLAY{i}_MIX_MIN", false);
        SetKeyword($"_PBR_OVERLAY{i}_MIX_MAX", false);
        SetKeyword($"_PBR_OVERLAY{i}_EMISSION_MAP", false);
        SetKeyword($"_PBR_OVERLAY{i}_NORMAL_MAP", false);
        SetKeyword($"_PBR_OVERLAY{i}_METALLIC_MAP", false);
        SetKeyword($"_PBR_OVERLAY{i}_ROUGHNESS_MAP", false);
        SetKeyword($"_PBR_OVERLAY{i}_MASK", false);
        SetKeyword($"_PBR_OVERLAY{i}_SAMPLER_REPEAT", false);
        SetKeyword($"_PBR_OVERLAY{i}_SAMPLER_CLAMP", false);
      }
      EditorGUI.indentLevel -= 1;
    }
    EditorGUI.indentLevel -= 1;
  }

  void DoDecal() {
    if (!AddCollapsibleMenu("Decals", "_Decal")) {
      return;
    }
    EditorGUI.indentLevel += 1;
    for (int i = 0; i < 4; i++) {
      if (!AddCollapsibleMenu($"Decal {i}", $"_Decal{i}")) {
        continue;
      }
      EditorGUI.indentLevel += 1;

      MaterialProperty bc = FindProperty($"_Decal{i}_Enable");
      bool enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = EditorGUILayout.Toggle("Enable", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_DECAL{i}", enabled);

      if (enabled) {
        bc = FindProperty($"_Decal{i}_BaseColor");
        editor.TexturePropertySingleLine(
            MakeLabel(bc, "Base color (RGBA)"),
            bc);
        if (bc.textureValue) {
          editor.TextureScaleOffsetProperty(bc);
        }

        bc = FindProperty($"_Decal{i}_Roughness");
        editor.TexturePropertySingleLine(
            MakeLabel(bc, "Roughness"),
            bc);
        SetKeyword($"_DECAL{i}_ROUGHNESS", bc.textureValue);

        bc = FindProperty($"_Decal{i}_Metallic");
        editor.TexturePropertySingleLine(
            MakeLabel(bc, "Metallic"),
            bc);
        SetKeyword($"_DECAL{i}_METALLIC", bc.textureValue);

        bc = FindProperty($"_Decal{i}_Emission_Strength");
        editor.FloatProperty(
            bc,
            "Emission strength");
        bc = FindProperty($"_Decal{i}_Angle");
        editor.RangeProperty(
            bc,
            "Angle");

        bc = FindProperty($"_Decal{i}_UV_Select");
        editor.RangeProperty(
            bc,
            "UV channel");
      }

      EditorGUI.indentLevel -= 1;
    }
  }

  void DoEmission() {
    if (!AddCollapsibleMenu("Emission", "_Emission")) {
      return;
    }
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;
    MaterialProperty bct;
    {
      EditorGUILayout.LabelField($"Base slot", EditorStyles.boldLabel);
      EditorGUI.indentLevel += 1;

      bc = FindProperty($"_EmissionColor");
      bct = FindProperty($"_EmissionMap");
      editor.TexturePropertyWithHDRColor(
          MakeLabel(bct, "Emission (RGB)"),
          bct, bc, false);
      SetKeyword($"_EMISSION", bct.textureValue);

      EditorGUI.indentLevel -= 1;
    }
    for (int i = 0; i < 2; i++) {
      EditorGUILayout.LabelField($"Extra slot {i}", EditorStyles.boldLabel);
      EditorGUI.indentLevel += 1;
      {
        bc = FindProperty($"_Emission{i}Color");
        bct = FindProperty($"_Emission{i}Tex");
        editor.TexturePropertyWithHDRColor(
            MakeLabel(bct, "Emission (RGB)"),
            bct, bc, false);
        SetKeyword($"_EMISSION{i}", bct.textureValue);

        if (bct.textureValue) {
          bc = FindProperty($"_Emission{i}_UV_Select");
          editor.RangeProperty(
              bc,
              "UV channel");

          bc = FindProperty($"_Emission{i}Multiplier");
          editor.RangeProperty(bc, "Multiplier");
        }
      }
      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Global_Emission_Factor");
    editor.FloatProperty(bc, "Global emissions multiplier");

    bc = FindProperty("_Global_Emission_Additive_Factor");
    editor.FloatProperty(bc, "Global emissions additive factor");

    EditorGUI.indentLevel -= 1;
  }

  enum MatcapMode {
    Add,
    Multiply,
    Replace,
    Subtract,
    Min,
    Max,
  }

  void DoMatcap() {
    for (int i = 0; i < 2; i++) {
      if (!AddCollapsibleMenu($"Matcap {i}", $"_Matcap{i}")) {
        continue;
      }
      EditorGUI.indentLevel += 1;

      MaterialProperty bc;

      bc = FindProperty($"_Matcap{i}");
      editor.TexturePropertySingleLine(
          MakeLabel(bc, $"Matcap {i}"),
          bc);
      SetKeyword($"_MATCAP{i}", bc.textureValue);

      if (!bc.textureValue) {
        EditorGUI.indentLevel -= 1;
        continue;
      }

      bc = FindProperty($"_Matcap{i}_Mask");
      editor.TexturePropertySingleLine(
          MakeLabel(bc, "Mask"),
          bc);
      SetKeyword($"_MATCAP{i}_MASK", bc.textureValue);

      bool enabled;  // c# is a shitty language
      if (bc.textureValue) {
        EditorGUI.indentLevel += 1;
        bc = FindProperty($"_Matcap{i}_Mask_Invert");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = EditorGUILayout.Toggle("Invert mask", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;

        bc = FindProperty($"_Matcap{i}_Mask_UV_Select");
        editor.RangeProperty(
            bc,
            "UV channel");
        EditorGUI.indentLevel -= 1;
      }

      bc = FindProperty($"_Matcap{i}_Mask2");
      editor.TexturePropertySingleLine(
          MakeLabel(bc, "Mask"),
          bc);
      SetKeyword($"_MATCAP{i}_MASK2", bc.textureValue);

      if (bc.textureValue) {
        EditorGUI.indentLevel += 1;
        bc = FindProperty($"_Matcap{i}_Mask2_Invert");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = EditorGUILayout.Toggle("Invert mask", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;

        bc = FindProperty($"_Matcap{i}_Mask2_UV_Select");
        editor.RangeProperty(
            bc,
            "UV channel");
        EditorGUI.indentLevel -= 1;
      }

      bc = FindProperty($"_Matcap{i}_Center_Eye_Fix");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = EditorGUILayout.Toggle("Center eye fix", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;

      EditorGUI.BeginChangeCheck();
      bc = FindProperty($"_Matcap{i}Mode");
      MatcapMode mode = (MatcapMode) Math.Round(bc.floatValue);
      mode = (MatcapMode) EditorGUILayout.EnumPopup(
          MakeLabel("Matcap mode"), mode);
      if (EditorGUI.EndChangeCheck()) {
        RecordAction($"Matcap {i}");
        foreach (Material m in editor.targets) {
          m.SetFloat($"_Matcap{i}Mode", (int) mode);
        }
      }

      bc = FindProperty($"_Matcap{i}Str");
      editor.FloatProperty(
          bc,
          "Matcap strength");

      bc = FindProperty($"_Matcap{i}MixFactor");
      editor.RangeProperty(
          bc,
          "Mix factor");

      bc = FindProperty($"_Matcap{i}Emission");
      editor.FloatProperty(
          bc,
          "Emission strength");

      bc = FindProperty($"_Matcap{i}Quantization");
      editor.FloatProperty(
          bc,
          "Quantization");

      bc = FindProperty($"_Matcap{i}Normal_Enabled");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = EditorGUILayout.Toggle("Replace normals", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_MATCAP{i}_NORMAL", enabled);

      if (enabled) {
        EditorGUI.indentLevel += 1;
        bc = FindProperty($"_Matcap{i}Normal");
        editor.TexturePropertySingleLine(
            MakeLabel(bc, "Normal map"),
            bc);
        if (bc.textureValue) {
          editor.TextureScaleOffsetProperty(bc);

          bc = FindProperty($"_Matcap{i}Normal_Str");
          editor.RangeProperty(bc, "Strength");

          bc = FindProperty($"_Matcap{i}Normal_UV_Select");
          editor.RangeProperty(
              bc,
              "UV channel");

          bc = FindProperty($"_Matcap{i}Normal_Mip_Bias");
          editor.FloatProperty(bc, "Mip bias");
        }
        EditorGUI.indentLevel -= 1;
      }

      bc = FindProperty($"_Matcap{i}Distortion0");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = EditorGUILayout.Toggle("Enable distortion 0", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_MATCAP{i}_DISTORTION0", enabled);

      for (int j = 0; j < 4; j++) {
        bc = FindProperty($"_Matcap{i}_Overwrite_Rim_Lighting_{j}");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = EditorGUILayout.Toggle($"Overwrite rim lighting {j}", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
      }

      EditorGUI.indentLevel -= 1;
    }
  }

  void DoRimLighting() {
    for (int i = 0; i < 4; i++) {
      if (!AddCollapsibleMenu($"Rim lighting {i}", $"_Rim_Lighting{i}")) {
        continue;
      }
      EditorGUI.indentLevel += 1;

      MaterialProperty bc;

      bc = FindProperty($"_Rim_Lighting{i}_Enabled");
      bool enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = EditorGUILayout.Toggle("Enable", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_RIM_LIGHTING{i}", enabled);

      if (!enabled) {
        continue;
      }

      bc = FindProperty($"_Rim_Lighting{i}_Color");
      editor.ColorProperty(bc, "Color (RGB)");

      bc = FindProperty($"_Rim_Lighting{i}_Mask");
      editor.TexturePropertySingleLine(
          MakeLabel(bc, "Mask"),
          bc);
      SetKeyword($"_RIM_LIGHTING{i}_MASK", bc.textureValue);

      if (bc.textureValue) {
        EditorGUI.indentLevel += 1;

        bc = FindProperty($"_Rim_Lighting{i}_Mask_Invert");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = EditorGUILayout.Toggle("Invert mask", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;

        bc = FindProperty($"_Rim_Lighting{i}_Mask_UV_Select");
        editor.RangeProperty(
            bc,
            "UV channel");

        bc = FindProperty($"_Rim_Lighting{i}_Mask_Sampler_Mode");
        SamplerMode sampler_mode = (SamplerMode) Math.Round(bc.floatValue);
        sampler_mode = (SamplerMode) EditorGUILayout.EnumPopup(
            MakeLabel("Sampler mode"), sampler_mode);
        EditorGUI.EndChangeCheck();
        bc.floatValue = (int) sampler_mode;

        SetKeyword($"_RIM_LIGHTING{i}_SAMPLER_REPEAT", sampler_mode == SamplerMode.Repeat);
        SetKeyword($"_RIM_LIGHTING{i}_SAMPLER_CLAMP", sampler_mode == SamplerMode.Clamp);

        EditorGUI.indentLevel -= 1;
      }

      bc = FindProperty($"_Rim_Lighting{i}_Center_Eye_Fix");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = EditorGUILayout.Toggle("Center eye fix", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;

      EditorGUI.BeginChangeCheck();
      bc = FindProperty($"_Rim_Lighting{i}_Mode");
      MatcapMode mode = (MatcapMode) Math.Round(bc.floatValue);
      mode = (MatcapMode) EditorGUILayout.EnumPopup(
          MakeLabel("Rim lighting mode"), mode);
      if (EditorGUI.EndChangeCheck()) {
        RecordAction("Rim lighting mode");
        foreach (Material m in editor.targets) {
          m.SetFloat($"_Rim_Lighting{i}_Mode", (int) mode);
        }
      }

      bc = FindProperty($"_Rim_Lighting{i}_Center");
      editor.FloatProperty(
          bc,
          "Center");

      bc = FindProperty($"_Rim_Lighting{i}_Power");
      editor.FloatProperty(
          bc,
          "Power");

      bc = FindProperty($"_Rim_Lighting{i}_Strength");
      editor.FloatProperty(
          bc,
          "Strength");

      bc = FindProperty($"_Rim_Lighting{i}_Emission");
      editor.FloatProperty(
          bc,
          "Emission");

      bc = FindProperty($"_Rim_Lighting{i}_Quantization");
      editor.FloatProperty(
          bc,
          "Quantization");

      bc = FindProperty($"_Rim_Lighting{i}_Glitter_Enabled");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = EditorGUILayout.Toggle("Glitter", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_RIM_LIGHTING{i}_GLITTER", enabled);

      if (enabled) {
        EditorGUI.indentLevel += 1;

        bc = FindProperty($"_Rim_Lighting{i}_Glitter_Density");
        editor.FloatProperty(
            bc,
            "Density");

        bc = FindProperty($"_Rim_Lighting{i}_Glitter_Amount");
        editor.FloatProperty(
            bc,
            "Amount");

        bc = FindProperty($"_Rim_Lighting{i}_Glitter_Speed");
        editor.FloatProperty(
            bc,
            "Speed");

        bc = FindProperty($"_Rim_Lighting{i}_Glitter_Quantization");
        editor.FloatProperty(
            bc,
            "Quantization");

        bc = FindProperty($"_Rim_Lighting{i}_Glitter_UV_Select");
        editor.RangeProperty(
            bc,
            "UV channel");

        EditorGUI.indentLevel -= 1;
      }

      bc = FindProperty($"_Rim_Lighting{i}_PolarMask_Enabled");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = EditorGUILayout.Toggle("Polar mask", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_RIM_LIGHTING{i}_POLAR_MASK", enabled);

      if (enabled) {
        EditorGUI.indentLevel += 1;
        bc = FindProperty($"_Rim_Lighting{i}_PolarMask_Theta");
        editor.FloatProperty(
            bc,
            "Theta");
        bc = FindProperty($"_Rim_Lighting{i}_PolarMask_Power");
        editor.FloatProperty(
            bc,
            "Power");
        EditorGUI.indentLevel -= 1;
      }

      EditorGUI.indentLevel -= 1;
    }
  }

  void DoMatcapRL() {
    if (!AddCollapsibleMenu("Matcaps", "_Matcaps")) {
      return;
    }
    EditorGUI.indentLevel += 1;

    DoMatcap();
    DoRimLighting();

    EditorGUI.indentLevel -= 1;
  }

  enum NormalsMode {
    Flat,
    Spherical,
    Realistic,
    Toon
  };

  void DoShadingMode() {
    if (!AddCollapsibleMenu("Shading", "_Shading")) {
      return;
    }
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;

    bc = FindProperty($"_Mesh_Normals_Mode");
    EditorGUI.BeginChangeCheck();
    NormalsMode mode = (NormalsMode) Math.Round(bc.floatValue, 0);
    mode = (NormalsMode) EditorGUILayout.EnumPopup(
        MakeLabel("Normals mode"), mode);
    if (EditorGUI.EndChangeCheck()) {
      RecordAction("Rendering mode");
    }
    bc.floatValue = (float) mode;

    if (mode == NormalsMode.Flat) {
      bc = FindProperty("_Flatten_Mesh_Normals_Str");
      editor.FloatProperty(
          bc,
          "Flattening strength");
    }
    EditorGUI.indentLevel -= 1;
  }

  void DoOKLAB() {
    if (!AddCollapsibleMenu("OKLAB", "_Hue_Shift_OKLAB")) {
      return;
    }
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;

    bc = FindProperty("_OKLAB_Enabled");
    bool enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Enable", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    SetKeyword("_OKLAB", enabled);

    if (enabled) {
      bc = FindProperty("_OKLAB_Mask");
      editor.TexturePropertySingleLine(
          MakeLabel(bc, "Mask"),
          bc);

      if (bc.textureValue) {
        bc = FindProperty("_OKLAB_Mask_Invert");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = EditorGUILayout.Toggle("Invert", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
      }

      bc = FindProperty("_OKLAB_Lightness_Shift");
      editor.RangeProperty(
          bc,
          "Lightness shift");
      bc = FindProperty("_OKLAB_Chroma_Shift");
      editor.RangeProperty(
          bc,
          "Chroma shift");
      bc = FindProperty("_OKLAB_Hue_Shift");
      editor.RangeProperty(
          bc,
          "Hue shift");
    }
    EditorGUI.indentLevel -= 1;
  }

  void DoHSV() {
    if (!AddCollapsibleMenu("HSV", "_Hue_Shift_HSV")) {
      return;
    }
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;

		for (int i = 0; i < 2; i++) {
			bc = FindProperty($"_HSV{i}_Enabled");
			bool enabled = bc.floatValue > 1E-6;
			EditorGUI.BeginChangeCheck();
			enabled = EditorGUILayout.Toggle($"Enable slot {i}", enabled);
			EditorGUI.EndChangeCheck();
			bc.floatValue = enabled ? 1.0f : 0.0f;

			SetKeyword($"_HSV{i}", enabled);

			if (enabled) {
				bc = FindProperty($"_HSV{i}_Mask");
				editor.TexturePropertySingleLine(
						MakeLabel(bc, "Mask"),
						bc);

				if (bc.textureValue) {
					bc = FindProperty($"_HSV{i}_Mask_Invert");
					enabled = bc.floatValue > 1E-6;
					EditorGUI.BeginChangeCheck();
					enabled = EditorGUILayout.Toggle("Invert", enabled);
					EditorGUI.EndChangeCheck();
					bc.floatValue = enabled ? 1.0f : 0.0f;
				}

				bc = FindProperty($"_HSV{i}_Hue_Shift");
				editor.RangeProperty(
						bc,
						"Hue shift");
				bc = FindProperty($"_HSV{i}_Sat_Shift");
				editor.RangeProperty(
						bc,
						"Saturation shift");
				bc = FindProperty($"_HSV{i}_Val_Shift");
				editor.RangeProperty(
						bc,
						"Value shift");
			}
		}
    EditorGUI.indentLevel -= 1;
  }

  void DoHueShift() {
    if (!AddCollapsibleMenu("Hue shift", "_Hue_Shift")) {
      return;
    }
    EditorGUI.indentLevel += 1;

    DoOKLAB();
    DoHSV();

    EditorGUI.indentLevel -= 1;
  }

  void DoClones() {
    if (!AddCollapsibleMenu("Clones", "_Clones")) {
      return;
    }
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;

    bc = FindProperty("_Clones_Enabled");
    bool enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Enable", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    SetKeyword("_CLONES", enabled);

    if (enabled) {
      bc = FindProperty("_Clones_Count");
      editor.RangeProperty(
          bc,
          "Number of clones");
      bc = FindProperty("_Clones_dx");
      editor.RangeProperty(
          bc,
          "x offset");
    }
    EditorGUI.indentLevel -= 1;
  }

  void DoOutlines() {
    if (!AddCollapsibleMenu("Outlines", "_Outlines")) {
      return;
    }
    EditorGUI.indentLevel += 1;
    MaterialProperty bc;

    bc = FindProperty("_Outline_Width");
    editor.RangeProperty(
        bc,
        "Outline width");
    SetKeyword("_OUTLINES", bc.floatValue > 1E-6);

    if (bc.floatValue > 1E-6) {
      bc = FindProperty("_Outline_Color");
      editor.ColorProperty(
          bc,
          "Outline color (RGBA)");

      bc = FindProperty("_Outline_Emission_Strength");
      editor.RangeProperty(
          bc,
          "Outline emission strength");

      bc = FindProperty("_Outline_Mask");
      editor.TexturePropertySingleLine(
          MakeLabel(bc, "Outline mask"),
          bc);

      bc = FindProperty("_Outline_Mask_Invert");
      bool inverted = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      inverted = EditorGUILayout.Toggle("Invert mask", inverted);
      EditorGUI.EndChangeCheck();
      bc.floatValue = inverted ? 1.0f : 0.0f;

      bc = FindProperty("_Outline_Width_Multiplier");
      editor.FloatProperty(
          bc,
          "Outline width multiplier");
    }
    EditorGUI.indentLevel -= 1;
  }

  void DoGlitter() {
    if (!AddCollapsibleMenu("Glitter", "_Glitter")) {
      return;
    }
    EditorGUI.indentLevel += 1;

    MaterialProperty bc = FindProperty("_Glitter_Enabled");
    bool enabled = bc.floatValue > 1E-6;

    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Enable", enabled);
    EditorGUI.EndChangeCheck();
    SetKeyword("_GLITTER", enabled);
    bc.floatValue = enabled ? 1.0f : 0.0f;

    if (enabled) {
      bc = FindProperty("_Glitter_Mask");
      editor.TexturePropertySingleLine(
          MakeLabel(bc, "Glitter mask (RGBA)"),
          bc);

      bc = FindProperty("_Glitter_Color");
      editor.ColorProperty(bc, "Color");

      bc = FindProperty("_Glitter_Density");
      editor.FloatProperty(
          bc,
          "Density");

      bc = FindProperty("_Glitter_Amount");
      editor.FloatProperty(
          bc,
          "Amount");

      bc = FindProperty("_Glitter_Speed");
      editor.FloatProperty(
          bc,
          "Speed");

      bc = FindProperty("_Glitter_Brightness_Lit");
      editor.FloatProperty(
          bc,
          "Brightness (lit)");

      bc = FindProperty("_Glitter_Brightness");
      editor.FloatProperty(
          bc,
          "Brightness (unlit)");

      bc = FindProperty("_Glitter_Angle");
      editor.FloatProperty(
          bc,
          "Angle");

      bc = FindProperty("_Glitter_Power");
      editor.FloatProperty(
          bc,
          "Power");

      bc = FindProperty("_Glitter_UV_Select");
      editor.RangeProperty(
          bc,
          "UV select");
    }
    EditorGUI.indentLevel -= 1;
  }

  void DoExplosion() {
    if (!AddCollapsibleMenu("Explosion", "_Explosion")) {
      return;
    }
    EditorGUI.indentLevel += 1;

    MaterialProperty bc = FindProperty("_Explode_Toggle");
    bool enabled = bc.floatValue > 1E-6;

    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Enable", enabled);
    EditorGUI.EndChangeCheck();
    SetKeyword("_EXPLODE", enabled);
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Explode_Phase");
    if (enabled) {
      editor.RangeProperty(
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
      editor.RangeProperty(
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
  }

  void DoGeoScroll() {
    if (!AddCollapsibleMenu("Geometry scroll", "_Geometry_Scroll")) {
      return;
    }
    EditorGUI.indentLevel += 1;

    MaterialProperty bc = FindProperty("_Scroll_Toggle");
    bool enabled = bc.floatValue > 1E-6;

    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Enable", enabled);
    EditorGUI.EndChangeCheck();
    SetKeyword("_SCROLL", enabled);
    bc.floatValue = enabled ? 1.0f : 0.0f;

    if (enabled) {
      bc = FindProperty("_Scroll_Top");
      editor.RangeProperty(
          bc,
          "Scroll top");

      bc = FindProperty("_Scroll_Bottom");
      editor.RangeProperty(
          bc,
          "Scroll bottom");

      bc = FindProperty("_Scroll_Width");
      editor.RangeProperty(
          bc,
          "Scroll width");

      bc = FindProperty("_Scroll_Strength");
      editor.RangeProperty(
          bc,
          "Scroll strength");

      bc = FindProperty("_Scroll_Speed");
      editor.RangeProperty(
          bc,
          "Scroll speed");
    }
    EditorGUI.indentLevel -= 1;
  }

  void DoUVScroll() {
    if (!AddCollapsibleMenu("UV Scroll", "_UV_Scroll")) {
      return;
    }
    EditorGUI.indentLevel += 1;

    MaterialProperty bc = FindProperty("_UVScroll_Enabled");
    bool enabled = bc.floatValue > 1E-6;

    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Enable", enabled);
    EditorGUI.EndChangeCheck();
    SetKeyword("_UVSCROLL", enabled);
    bc.floatValue = enabled ? 1.0f : 0.0f;

    if (enabled) {
      bc = FindProperty("_UVScroll_Mask");
      editor.TexturePropertySingleLine(
          MakeLabel(bc, "Mask"),
          bc);

      bc = FindProperty("_UVScroll_U_Speed");
      editor.FloatProperty(
          bc,
          "U speed");

      bc = FindProperty("_UVScroll_V_Speed");
      editor.FloatProperty(
          bc,
          "V speed");

      bc = FindProperty("_UVScroll_Alpha");
      editor.TexturePropertySingleLine(
          MakeLabel(bc, "Alpha"),
          bc);
    }
    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickFlatColor()
  {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Flat_Color_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Flat color", enabled);
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
    enabled = EditorGUILayout.Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Gimmick_Flat_Color_Color");
    editor.ColorProperty(bc, "Color");
    bc = FindProperty("_Gimmick_Flat_Color_Emission");
    editor.ColorProperty(bc, "Emission");

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickQuantizeLocation() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Quantize_Location_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Quantize location", enabled);
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
    enabled = EditorGUILayout.Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Gimmick_Quantize_Location_Precision");
    editor.FloatProperty(bc, "Precision");
    bc = FindProperty("_Gimmick_Quantize_Location_Direction");
    editor.FloatProperty(bc, "Direction");
    bc = FindProperty("_Gimmick_Quantize_Location_Multiplier");
    editor.RangeProperty(bc, "Multiplier");
    bc = FindProperty("_Gimmick_Quantize_Location_Mask");
    editor.TexturePropertySingleLine(
        MakeLabel(bc, "Mask"),
        bc);

    bc = FindProperty("_Gimmick_Quantize_Location_Audiolink_Enable_Static");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Audiolink", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_QUANTIZE_LOCATION_AUDIOLINK", enabled);

    if (enabled) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Gimmick_Quantize_Location_Audiolink_Enable_Dynamic");
      enabled = (bc.floatValue != 0.0);
      EditorGUI.BeginChangeCheck();
      enabled = EditorGUILayout.Toggle("Enable (runtime switch)", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;

      bc = FindProperty("_Gimmick_Quantize_Location_Audiolink_Strength");
      editor.FloatProperty(
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
    enabled = EditorGUILayout.Toggle("Shear location", enabled);
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
    enabled = EditorGUILayout.Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Gimmick_Shear_Location_Strength");
    editor.VectorProperty(bc, "Strength");

    bc = FindProperty("_Gimmick_Shear_Location_Mesh_Renderer_Fix");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Mesh renderer fix", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    if (enabled) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Gimmick_Shear_Location_Mesh_Renderer_Offset");
      editor.VectorProperty(bc, "Offset");
      bc = FindProperty("_Gimmick_Shear_Location_Mesh_Renderer_Rotation");
      editor.VectorProperty(bc, "Rotation");
      bc = FindProperty("_Gimmick_Shear_Location_Mesh_Renderer_Scale");
      editor.VectorProperty(bc, "Scale");
      EditorGUI.indentLevel -= 1;
    }

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickSpherizeLocation() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Spherize_Location_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Spherize location", enabled);
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
    enabled = EditorGUILayout.Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Gimmick_Spherize_Location_Strength");
    editor.RangeProperty(bc, "Strength");
    bc = FindProperty("_Gimmick_Spherize_Location_Radius");
    editor.FloatProperty(bc, "Radius");

    EditorGUI.indentLevel -= 1;
  }


  void DoGimmickEyes00() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Eyes00_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Eyes 00", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_EYES_00", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Eyes00_Effect_Mask");
    editor.TexturePropertySingleLine(
        MakeLabel(bc, "Effect mask"),
        bc);

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickEyes01() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Eyes01_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Eyes 01", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_EYES_01", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Eyes01_Radius");
    editor.FloatProperty(bc, "Radius (meters, object space)");

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickEyes02() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Eyes02_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Eyes 02", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_EYES_02", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Eyes02_N");
    editor.RangeProperty(bc, "n");
    bc = FindProperty("_Gimmick_Eyes02_A0");
    editor.RangeProperty(bc, "a0");
    bc = FindProperty("_Gimmick_Eyes02_A1");
    editor.RangeProperty(bc, "a1");
    bc = FindProperty("_Gimmick_Eyes02_A2");
    editor.RangeProperty(bc, "a2");
    bc = FindProperty("_Gimmick_Eyes02_A3");
    editor.RangeProperty(bc, "a3");
    bc = FindProperty("_Gimmick_Eyes02_A4");
    editor.RangeProperty(bc, "a4");

    bc = FindProperty("_Gimmick_Eyes02_Animate");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Animate", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    if (enabled) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Gimmick_Eyes02_Animate_Speed");
      editor.FloatProperty(bc, "Speed");

      bc = FindProperty("_Gimmick_Eyes02_Animate_Strength");
      editor.FloatProperty(bc, "Strength");
      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Gimmick_Eyes02_UV_X_Symmetry");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("UV x symmetry", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Gimmick_Eyes02_UV_Adjust");
    editor.VectorProperty(bc, "UV scale & offset");

    bc = FindProperty("_Gimmick_Eyes02_Albedo");
    editor.ColorProperty(bc, "Albedo");
    bc = FindProperty("_Gimmick_Eyes02_Metallic");
    editor.FloatProperty(bc, "Metallic");
    bc = FindProperty("_Gimmick_Eyes02_Roughness");
    editor.FloatProperty(bc, "Roughness");
    bc = FindProperty("_Gimmick_Eyes02_Emission");
    editor.ColorProperty(bc, "Emission");

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickHalo00() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Halo00_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Halo 00", enabled);
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
    enabled = EditorGUILayout.Toggle("Pixellate", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_PIXELLATE", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Pixellate_Resolution_U");
    editor.FloatProperty(bc, "Resolution (U)");
    bc = FindProperty("_Gimmick_Pixellate_Resolution_V");
    editor.FloatProperty(bc, "Resolution (V)");
    bc = FindProperty("_Gimmick_Pixellate_Effect_Mask");
    editor.TexturePropertySingleLine(
        MakeLabel(bc, "Effect mask"),
        bc);

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickTrochoid() {
    MaterialProperty bc;
    bc = FindProperty("_Trochoid_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Trochoid", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_TROCHOID", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Trochoid_R");
    editor.FloatProperty(bc, "R");
    bc = FindProperty("_Trochoid_r");
    editor.FloatProperty(bc, "r");
    bc = FindProperty("_Trochoid_d");
    editor.FloatProperty(bc, "d");

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickFaceMeWorldY() {
    MaterialProperty bc;
    bc = FindProperty("_FaceMeWorldY_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("FaceMeWorldY", enabled);
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
    enabled = EditorGUILayout.Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_FaceMeWorldY_Enable_X");
    editor.FloatProperty(bc, "X");
    bc = FindProperty("_FaceMeWorldY_Enable_Y");
    editor.FloatProperty(bc, "Y");
    bc = FindProperty("_FaceMeWorldY_Enable_Z");
    editor.FloatProperty(bc, "Z");

    EditorGUI.indentLevel -= 1;
  }

  void DoGimmickRorschach() {
    MaterialProperty bc;
    bc = FindProperty("_Rorschach_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Rorschach", enabled);
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
    enabled = EditorGUILayout.Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_Rorschach_Color");
    editor.ColorProperty(bc, "Color");
    bc = FindProperty("_Rorschach_Count_X");
    editor.FloatProperty(bc, "Count (x)");
    bc = FindProperty("_Rorschach_Count_Y");
    editor.FloatProperty(bc, "Count (y)");
    bc = FindProperty("_Rorschach_Center_Randomization");
    editor.FloatProperty(bc, "Center randomization");
    bc = FindProperty("_Rorschach_Radius");
    editor.FloatProperty(bc, "Radius");
    bc = FindProperty("_Rorschach_Emission_Strength");
    editor.FloatProperty(bc, "Emission strength");
    bc = FindProperty("_Rorschach_Speed");
    editor.FloatProperty(bc, "Speed");
    bc = FindProperty("_Rorschach_Quantization");
    editor.FloatProperty(bc, "Quantization");
    bc = FindProperty("_Rorschach_Alpha_Cutoff");
    editor.FloatProperty(bc, "Alpha cutoff");
    bc = FindProperty("_Rorschach_Mask");
    editor.TexturePropertySingleLine(
        MakeLabel(bc, "Mask"),
        bc);
    SetKeyword("_RORSCHACH_MASK", bc.textureValue);
    if (bc.textureValue) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Rorschach_Mask_Invert");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = EditorGUILayout.Toggle("Invert", enabled);
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
    enabled = EditorGUILayout.Toggle("Flip UVs in mirror", enabled);
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
    enabled = EditorGUILayout.Toggle("Enable (runtime switch)", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    EditorGUI.indentLevel -= 1;
  }

	void DoGimmickLetterGrid() {
    MaterialProperty bc;
    bc = FindProperty("_Gimmick_Letter_Grid_Enable_Static");
    bool enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Letter grid", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_LETTER_GRID", enabled);

    if (!enabled) {
      return;
    }

    EditorGUI.indentLevel += 1;

    bc = FindProperty("_Gimmick_Letter_Grid_Texture");
    editor.TexturePropertySingleLine(
        MakeLabel(bc, "Texture"),
        bc);

    bc = FindProperty("_Gimmick_Letter_Grid_Tex_Res_X");
    editor.FloatProperty(bc, "Number of glyphs in texture (X)");
    bc = FindProperty("_Gimmick_Letter_Grid_Tex_Res_Y");
    editor.FloatProperty(bc, "Number of glyphs in texture (Y)");

    bc = FindProperty("_Gimmick_Letter_Grid_Res_X");
    editor.FloatProperty(bc, "Number of glyphs in grid (X)");
    bc = FindProperty("_Gimmick_Letter_Grid_Res_Y");
    editor.FloatProperty(bc, "Number of glyphs in grid (Y)");

    bc = FindProperty("_Gimmick_Letter_Grid_UV_Scale_Offset");
    editor.VectorProperty(bc, "UV scale & offset");
    bc = FindProperty("_Gimmick_Letter_Grid_Padding");
    editor.FloatProperty(bc, "Padding");

    bc = FindProperty("_Gimmick_Letter_Grid_Color");
    editor.ColorProperty(bc, "Color");
    bc = FindProperty("_Gimmick_Letter_Grid_Metallic");
    editor.RangeProperty(bc, "Metallic");
    bc = FindProperty("_Gimmick_Letter_Grid_Roughness");
    editor.RangeProperty(bc, "Roughness");
    bc = FindProperty("_Gimmick_Letter_Grid_Emission");
    editor.FloatProperty(bc, "Emission");

    bc = FindProperty("_Gimmick_Letter_Grid_UV_Select");
    editor.RangeProperty(
        bc,
        "UV channel");

    bc = FindProperty("_Gimmick_Letter_Grid_Color_Wave");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Color waves", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_LETTER_GRID_COLOR_WAVE", enabled);

    if (enabled) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Gimmick_Letter_Grid_Color_Wave_Speed");
      editor.FloatProperty(bc, "Speed");
      bc = FindProperty("_Gimmick_Letter_Grid_Color_Wave_Frequency");
      editor.FloatProperty(bc, "Frequency");
      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Gimmick_Letter_Grid_Rim_Lighting");
    enabled = (bc.floatValue != 0.0);
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Rim lighting", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_GIMMICK_LETTER_GRID_RIM_LIGHTING", enabled);

    if (enabled) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Gimmick_Letter_Grid_Rim_Lighting_Power");
      editor.FloatProperty(bc, "Power");
      bc = FindProperty("_Gimmick_Letter_Grid_Rim_Lighting_Center");
      editor.FloatProperty(bc, "Center");
      bc = FindProperty("_Gimmick_Letter_Grid_Rim_Lighting_Quantization");
      editor.FloatProperty(bc, "Quantization");
      bc = FindProperty("_Gimmick_Letter_Grid_Rim_Lighting_Mask");
      editor.TexturePropertySingleLine(MakeLabel(bc, "Mask"), bc);
      if (bc.textureValue) {
        EditorGUI.indentLevel += 1;
        bc = FindProperty("_Gimmick_Letter_Grid_Rim_Lighting_Mask_UV_Select");
        editor.FloatProperty(bc, "Mask UV Select");
        bc = FindProperty("_Gimmick_Letter_Grid_Rim_Lighting_Mask_Invert");
        editor.FloatProperty(bc, "Mask invert");
        EditorGUI.indentLevel -= 1;
      }
      EditorGUI.indentLevel -= 1;
    }

    EditorGUI.indentLevel -= 1;
	}

  void DoGimmicks() {
    if (!AddCollapsibleMenu("Gimmicks", "_Gimmicks")) {
      return;
    }
    EditorGUI.indentLevel += 1;

    DoGimmickFlatColor();
    DoGimmickQuantizeLocation();
    DoGimmickShearLocation();
    DoGimmickSpherizeLocation();
    DoGimmickEyes00();
    DoGimmickEyes01();
    DoGimmickEyes02();
    DoGimmickHalo00();
    DoGimmickPixellate();
    DoGimmickTrochoid();
    DoGimmickFaceMeWorldY();
    DoGimmickRorschach();
    DoGimmickMirrorUVFlip();
    DoGimmickLetterGrid();
    DoClones();
    DoExplosion();
    DoGeoScroll();

    EditorGUI.indentLevel -= 1;
  }

  void DoMochieParams() {
    if (!AddCollapsibleMenu("Mochie", "_Mochie")) {
      return;
    }
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;

    bc = FindProperty("_WrappingFactor");
    editor.RangeProperty(bc, "Wrapping factor");
    bc = FindProperty("_SpecularStrength");
    editor.RangeProperty(bc, "Specular strength");
    bc = FindProperty("_FresnelStrength");
    editor.RangeProperty(bc, "Fresnel strength");

    bc = FindProperty("_UseFresnel");
    bool enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Use fresnel", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;

    bc = FindProperty("_ReflectionStrength");
    editor.RangeProperty(bc, "Reflection strength");

    EditorGUI.indentLevel -= 1;
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
    Stochastic
  }

  void DoRendering() {
    if (!AddCollapsibleMenu("Rendering", "_Rendering")) {
      return;
    }
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
    mode = (RenderingMode) EditorGUILayout.EnumPopup(
        MakeLabel("Rendering mode"), mode);
    BlendMode src_blend = BlendMode.One;
    BlendMode dst_blend = BlendMode.Zero;
    bool zwrite = false;
    EditorGUI.EndChangeCheck();
    RecordAction("Rendering mode");

    bc = FindProperty("_Render_Queue_Offset");
    editor.IntegerProperty(
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
      cmode = (CutoutMode) EditorGUILayout.EnumPopup(
          MakeLabel("Cutout mode"), cmode);
      EditorGUI.EndChangeCheck();
      bc.floatValue = (float) cmode;
      SetKeyword("_RENDERING_CUTOUT_STOCHASTIC", cmode == CutoutMode.Stochastic);

      if (cmode == CutoutMode.Cutoff) {
        bc = FindProperty("_Alpha_Cutoff");
        editor.ShaderProperty(bc, MakeLabel(bc));
      }
    }

    bc = FindProperty("_Cull");
    UnityEngine.Rendering.CullMode cull_mode = (UnityEngine.Rendering.CullMode) bc.floatValue;
    EditorGUI.BeginChangeCheck();
    cull_mode = (UnityEngine.Rendering.CullMode) EditorGUILayout.EnumPopup(
        MakeLabel("Culling mode"), cull_mode);
    if (EditorGUI.EndChangeCheck()) {
      RecordAction("Culling mode");
      bc.floatValue = (float) cull_mode;
    }

    bc = FindProperty("_Discard_Enable_Static");
    bool enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Discard", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_DISCARD", enabled);
    if (enabled) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Discard_Enable_Dynamic");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = EditorGUILayout.Toggle("Enable", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      EditorGUI.indentLevel -= 1;
    }

    EditorGUILayout.LabelField("Stenciling", EditorStyles.boldLabel);
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

      EditorGUILayout.LabelField($"{pass_str} pass");
      {
        EditorGUI.indentLevel += 1;
        bc = FindProperty($"_Stencil_Ref_{pass_str}");
        editor.FloatProperty(bc, "Ref");

        bc = FindProperty($"_Stencil_Comp_{pass_str}");
        EditorGUI.BeginChangeCheck();
        UnityEngine.Rendering.CompareFunction stencil_comp =
          (UnityEngine.Rendering.CompareFunction) bc.floatValue;
        stencil_comp = (UnityEngine.Rendering.CompareFunction)
          EditorGUILayout.EnumPopup(MakeLabel("Comp"), stencil_comp);
        EditorGUI.EndChangeCheck();
        RecordAction("Rendering mode");
        bc.floatValue = (float) stencil_comp;

        bc = FindProperty($"_Stencil_Pass_Op_{pass_str}");
        EditorGUI.BeginChangeCheck();
        UnityEngine.Rendering.StencilOp stencil_op =
          (UnityEngine.Rendering.StencilOp) bc.floatValue;
        stencil_op = (UnityEngine.Rendering.StencilOp)
          EditorGUILayout.EnumPopup(MakeLabel("Pass op"), stencil_op);
        EditorGUI.EndChangeCheck();
        RecordAction("Rendering mode");
        bc.floatValue = (float) stencil_op;

        bc = FindProperty($"_Stencil_Fail_Op_{pass_str}");
        EditorGUI.BeginChangeCheck();
        stencil_op = (UnityEngine.Rendering.StencilOp) bc.floatValue;
        stencil_op = (UnityEngine.Rendering.StencilOp)
          EditorGUILayout.EnumPopup(MakeLabel("Fail op"), stencil_op);
        EditorGUI.EndChangeCheck();
        RecordAction("Rendering mode");
        bc.floatValue = (float) stencil_op;

        EditorGUI.indentLevel -= 1;
      }
      EditorGUI.indentLevel -= 1;
    }
    EditorGUI.indentLevel -= 1;
  }

  void DoLighting() {
    if (!AddCollapsibleMenu("Lighting", "_Lighting")) {
      return;
    }
    EditorGUI.indentLevel += 1;

    MaterialProperty bc;

    bc = FindProperty("_Enable_Brightness_Clamp");
    bool brightness_clamp_enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    brightness_clamp_enabled = EditorGUILayout.Toggle("Clamp brightness",
        brightness_clamp_enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = brightness_clamp_enabled ? 1.0f : 0.0f;
    SetKeyword("_BRIGHTNESS_CLAMP", brightness_clamp_enabled);
    if (brightness_clamp_enabled) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Min_Brightness");
      editor.RangeProperty(
          bc,
          "Min brightness");

      bc = FindProperty("_Max_Brightness");
      editor.RangeProperty(
          bc,
          "Max brightness");
      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Ambient_Occlusion");
    editor.TexturePropertySingleLine(
        MakeLabel(bc, "Ambient occlusion"),
        bc);
    SetKeyword("_AMBIENT_OCCLUSION", bc.textureValue);
    if (bc.textureValue) {
      editor.TextureScaleOffsetProperty(bc);
    }

    if (bc.textureValue) {
      bc = FindProperty("_Ambient_Occlusion_Strength");
      editor.RangeProperty(bc, "Ambient occlusion strength");
    }

    bc = FindProperty("_Cubemap");
    editor.TexturePropertySingleLine(
        MakeLabel(bc, "Cubemap"),
        bc);
    SetKeyword("_CUBEMAP", bc.textureValue);

    if (bc.textureValue) {
      bc = FindProperty("_Cubemap_Limit_To_Metallic");
      bool cube_lim_enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      cube_lim_enabled = EditorGUILayout.Toggle("Limit to metallic",
          cube_lim_enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = cube_lim_enabled ? 1.0f : 0.0f;
    }

    bc = FindProperty("_Lighting_Factor");
    editor.RangeProperty(
        bc,
        "Lighting multiplier");

    {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_Direct_Lighting_Factor");
      editor.RangeProperty(
          bc,
          "Direct multiplier");

      bc = FindProperty("_Vertex_Lighting_Factor");
      editor.RangeProperty(
          bc,
          "Vertex light multiplier");

      bc = FindProperty("_Indirect_Specular_Lighting_Factor");
      editor.RangeProperty(
          bc,
          "Indirect specular multiplier");

      bc = FindProperty("_Indirect_Specular_Lighting_Factor2");
      editor.RangeProperty(
          bc,
          "Secondary ind. spec. multiplier");

      bc = FindProperty("_Indirect_Diffuse_Lighting_Factor");
      editor.RangeProperty(
          bc,
          "Indirect diffuse multiplier");
      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_Reflection_Probe_Saturation");
    editor.RangeProperty(
        bc,
        "Reflection probe saturation");

    bc = FindProperty("_Shadow_Strength");
    editor.RangeProperty(
        bc,
        "Shadows strength");

    bc = FindProperty("_Global_Sample_Bias");
    editor.FloatProperty(
        bc,
        "Global mipmap bias");

    bc = FindProperty("_Proximity_Dimming_Enable_Static");
    bool enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Proximity dimming", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_PROXIMITY_DIMMING", enabled);

    if (enabled) {
      EditorGUI.indentLevel += 1;

      bc = FindProperty("_Proximity_Dimming_Min_Dist");
      editor.FloatProperty(bc, "Min distance");

      bc = FindProperty("_Proximity_Dimming_Max_Dist");
      editor.FloatProperty(bc, "Max distance");

      bc = FindProperty("_Proximity_Dimming_Factor");
      editor.FloatProperty(bc, "Dimming factor");

      EditorGUI.indentLevel -= 1;
    }

    bc = FindProperty("_LTCGI_Enabled");
    enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Enable LTCGI", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_LTCGI", enabled);

    if (enabled) {
      EditorGUI.indentLevel += 1;
      bc = FindProperty("_LTCGI_SpecularColor");
      editor.ColorProperty(bc, "Specular color (RGB)");

      bc = FindProperty("_LTCGI_DiffuseColor");
      editor.ColorProperty(bc, "Diffuse color (RGB)");
      EditorGUI.indentLevel -= 1;
    }

    EditorGUI.BeginChangeCheck();
    editor.LightmapEmissionProperty();
    if (EditorGUI.EndChangeCheck()) {
      foreach (Material m in editor.targets) {
        m.globalIlluminationFlags &=
          ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
      }
    }

    EditorGUI.indentLevel -= 1;
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

