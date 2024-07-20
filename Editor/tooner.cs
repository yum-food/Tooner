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

  void DoBaseColor() {
      MaterialProperty bc = FindProperty("_Color");
      MaterialProperty bct = FindProperty("_MainTex");
      editor.TexturePropertySingleLine(
          MakeLabel(bct, "Base color (RGBA)"),
          bct,
          bc);
      if (bct.textureValue) {
        editor.TextureScaleOffsetProperty(bct);
      }
      SetKeyword("_BASECOLOR_MAP", bct.textureValue);
  }

  void DoNormal() {
      MaterialProperty bct = FindProperty("_NormalTex");
      editor.TexturePropertySingleLine(
          MakeLabel(bct, "Normal"),
          bct,
          FindProperty("_Tex_NormalStr"));
      if (bct.textureValue) {
        editor.TextureScaleOffsetProperty(bct);
      }
      SetKeyword("_NORMAL_MAP", bct.textureValue);
  }

  void DoMetallic() {
      MaterialProperty bc = FindProperty("_Metallic");
      MaterialProperty bct = FindProperty("_MetallicTex");
      editor.TexturePropertySingleLine(
          MakeLabel(bct, "Metallic (RGBA)"),
          bct,
          bc);
      if (bct.textureValue) {
        editor.TextureScaleOffsetProperty(bct);
      }
      SetKeyword("_METALLIC_MAP", bct.textureValue);
  }

  void DoRoughness() {
      MaterialProperty bc = FindProperty("_Roughness");
      MaterialProperty bct = FindProperty("_RoughnessTex");
      editor.TexturePropertySingleLine(
          MakeLabel(bct, "Roughness (RGBA)"),
          bct,
          bc);
      if (bct.textureValue) {
        editor.TextureScaleOffsetProperty(bct);
      }
      SetKeyword("_ROUGHNESS_MAP", bct.textureValue);
  }

  void DoClearcoat() {
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
    }
  }

  enum PbrAlbedoMixMode {
    AlphaBlend,
    Add,
    Min,
    Max
  };

  void DoPBROverlay() {
    for (int i = 0; i < 4; i++) {
      GUILayout.Label($"PBR overlay {i}", EditorStyles.boldLabel);
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
      }
      EditorGUI.indentLevel -= 1;
    }
  }

  void DoDecal() {
    for (int i = 0; i < 4; i++) {
      GUILayout.Label($"Decal {i}", EditorStyles.boldLabel);
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
        bc = FindProperty($"_Decal{i}_Emission_Strength");
        editor.FloatProperty(
            bc,
            "Emission strength");
        bc = FindProperty($"_Decal{i}_Angle");
        editor.RangeProperty(
            bc,
            "Angle");
      }

      EditorGUI.indentLevel -= 1;
    }
  }

  void DoBrightness() {
      MaterialProperty bc;

  }

  void DoEmission() {
      MaterialProperty bc = FindProperty("_EmissionTex");
      MaterialProperty bct = FindProperty("_EmissionStrength");
      editor.TexturePropertySingleLine(
          MakeLabel(bct, "Emission map"),
          bc,
          bct);
      SetKeyword("_EMISSION", bc.textureValue);
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
      GUILayout.Label($"Matcap {i}", EditorStyles.boldLabel);
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
        bc = FindProperty($"_Matcap{i}_Mask_Invert");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = EditorGUILayout.Toggle("Invert mask", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
      }

      bc = FindProperty($"_Matcap{i}_Mask2");
      editor.TexturePropertySingleLine(
          MakeLabel(bc, "Mask"),
          bc);
      SetKeyword($"_MATCAP{i}_MASK2", bc.textureValue);

      if (bc.textureValue) {
        bc = FindProperty($"_Matcap{i}_Mask2_Invert");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = EditorGUILayout.Toggle("Invert mask", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
      }

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

      bc = FindProperty($"_Matcap{i}Emission");
      editor.FloatProperty(
          bc,
          "Emission strength");

      bc = FindProperty($"_Matcap{i}Quantization");
      editor.FloatProperty(
          bc,
          "Quantization");

      bc = FindProperty($"_Matcap{i}Distortion0");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = EditorGUILayout.Toggle("Enable distortion 0", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_MATCAP{i}_DISTORTION0", enabled);

      EditorGUI.indentLevel -= 1;
    }
  }

  void DoRimLighting() {
    for (int i = 0; i < 2; i++) {
      GUILayout.Label($"Rim lighting {i}", EditorStyles.boldLabel);
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
        return;
      }

      bc = FindProperty($"_Rim_Lighting{i}_Color");
      editor.ColorProperty(bc, "Color (RGB)");

      bc = FindProperty($"_Rim_Lighting{i}_Mask");
      editor.TexturePropertySingleLine(
          MakeLabel(bc, "Mask"),
          bc);
      SetKeyword($"_RIM_LIGHTING{i}_MASK", bc.textureValue);

      if (bc.textureValue) {
        bc = FindProperty($"_Rim_Lighting{i}_Mask_Invert");
        enabled = bc.floatValue > 1E-6;
        EditorGUI.BeginChangeCheck();
        enabled = EditorGUILayout.Toggle("Invert mask", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 0.0f;
      }

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

  enum NormalsMode {
    Flat,
    Spherical,
    Realistic,
    Toon
  };

  void DoShadingMode() {
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

    bc = FindProperty("_Confabulate_Normals");
    bool enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Confabulate normals", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
  }

  void DoOKLAB() {
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
  }

  void DoClones() {
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
  }

  void DoOutlines() {
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

        bc = FindProperty("_Outline_Stenciling");
        bool enabled = (bc.floatValue == 1.0);
        EditorGUI.BeginChangeCheck();
        enabled = EditorGUILayout.Toggle("Enable stenciling", enabled);
        EditorGUI.EndChangeCheck();
        bc.floatValue = enabled ? 1.0f : 2.0f;
      }
  }

  void DoGlitter() {
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

      bc = FindProperty("_Glitter_Density");
      editor.FloatProperty(
          bc,
          "Glitter density");

      bc = FindProperty("_Glitter_Amount");
      editor.FloatProperty(
          bc,
          "Glitter amount");

      bc = FindProperty("_Glitter_Speed");
      editor.FloatProperty(
          bc,
          "Glitter speed");

      bc = FindProperty("_Glitter_Brightness");
      editor.FloatProperty(
          bc,
          "Glitter brightness");

      bc = FindProperty("_Glitter_Angle");
      editor.FloatProperty(
          bc,
          "Glitter angle");

      bc = FindProperty("_Glitter_Power");
      editor.FloatProperty(
          bc,
          "Glitter power");
    }
  }

  void DoExplosion() {
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
  }

  void DoGeoScroll() {
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
  }

  void DoUVScroll() {
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
  }

  void DoTessellation() {
    MaterialProperty bc = FindProperty("_Enable_Tessellation");
    bool enabled = bc.floatValue > 1E-6;

    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Enable", enabled);
    EditorGUI.EndChangeCheck();
    SetKeyword("_TESSELLATION", enabled);
    bc.floatValue = enabled ? 1.0f : 0.0f;

    if (enabled) {
      bc = FindProperty("_Tess_Factor");
      editor.RangeProperty(
          bc,
          "Tessellation factor");

      bc = FindProperty("_Tess_Dist_Cutoff");
      editor.FloatProperty(
          bc,
          "Activation distance (negative=always on)");
    }
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


  void DoGimmicks() {
    DoGimmickFlatColor();
    DoGimmickQuantizeLocation();
    DoGimmickShearLocation();
    DoGimmickSpherizeLocation();
    DoGimmickEyes00();
    DoGimmickPixellate();
    DoGimmickTrochoid();
  }

  void DoMochieParams() {
    MaterialProperty bc;

    bc = FindProperty("_WrappingFactor");
    editor.FloatProperty(bc, "Wrapping factor");
    bc = FindProperty("_SpecularStrength");
    editor.FloatProperty(bc, "Specular strength");
    bc = FindProperty("_FresnelStrength");
    editor.FloatProperty(bc, "Fresnel strength");
    bc = FindProperty("_UseFresnel");
    editor.FloatProperty(bc, "Use fresnel");
    bc = FindProperty("_ReflectionStrength");
    editor.FloatProperty(bc, "Reflection strength");
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
          src_blend = BlendMode.One;
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
  }

  void DoLighting() {
    MaterialProperty bc;
    bc = FindProperty("_Min_Brightness");
    editor.RangeProperty(
        bc,
        "Min brightness");

    bc = FindProperty("_Max_Brightness");
    editor.RangeProperty(
        bc,
        "Max brightness");

    bc = FindProperty("_Ambient_Occlusion");
    editor.TexturePropertySingleLine(
        MakeLabel(bc, "Ambient occlusion"),
        bc);
    SetKeyword("_AMBIENT_OCCLUSION", bc.textureValue);

    if (bc.textureValue) {
      bc = FindProperty("_Ambient_Occlusion_Strength");
      editor.RangeProperty(bc, "Ambient occlusion strength");
    }

    bc = FindProperty("_Cubemap");
    editor.TexturePropertySingleLine(
        MakeLabel(bc, "Cubemap"),
        bc);
    SetKeyword("_CUBEMAP", bc.textureValue);

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

      bc = FindProperty("_Indirect_Specular_Lighting_Factor");
      editor.RangeProperty(
          bc,
          "Indirect specular multiplier");

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

    bc = FindProperty("_Mip_Multiplier");
    editor.FloatProperty(
        bc,
        "Mipmap multiplier");
    bc.floatValue = (float) Math.Max(1E-6, bc.floatValue);

#if LTCGI_INCLUDED
    bc = FindProperty("_LTCGI_Enabled");
    bool enabled = bc.floatValue > 1E-6;
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
#endif
  }

  void DoLTCGI() {
  }

  void DoMain() {
    GUILayout.Label("PBR", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoBaseColor();
    DoNormal();
    DoMetallic();
    DoRoughness();
    EditorGUI.indentLevel -= 1;

    DoPBROverlay();

    GUILayout.Label("Clearcoat", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoClearcoat();
    EditorGUI.indentLevel -= 1;

    DoDecal();

    GUILayout.Label("Lighting", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoLighting();
    EditorGUI.indentLevel -= 1;

    GUILayout.Label("Emission", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoEmission();
    EditorGUI.indentLevel -= 1;

    GUILayout.Label("Shading", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoShadingMode();
    EditorGUI.indentLevel -= 1;

    DoMatcap();
    DoRimLighting();

    GUILayout.Label("Outlines", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoOutlines();
    EditorGUI.indentLevel -= 1;

    GUILayout.Label("Glitter", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoGlitter();
    EditorGUI.indentLevel -= 1;

    GUILayout.Label("Explosion", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoExplosion();
    EditorGUI.indentLevel -= 1;

    GUILayout.Label("Geometry scroll", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoGeoScroll();
    EditorGUI.indentLevel -= 1;

    GUILayout.Label("UV scroll", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoUVScroll();
    EditorGUI.indentLevel -= 1;

    GUILayout.Label("Tessellation", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoTessellation();
    EditorGUI.indentLevel -= 1;

    GUILayout.Label("Hue shift", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoOKLAB();
    EditorGUI.indentLevel -= 1;

    GUILayout.Label("Clones", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoClones();
    EditorGUI.indentLevel -= 1;

    GUILayout.Label("Gimmicks", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoGimmicks();
    EditorGUI.indentLevel -= 1;

    GUILayout.Label("Mochie", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoMochieParams();
    EditorGUI.indentLevel -= 1;

    GUILayout.Label("Rendering", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoRendering();
    EditorGUI.indentLevel -= 1;
  }
}

