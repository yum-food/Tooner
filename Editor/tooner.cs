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
      MaterialProperty bc = FindProperty("_BaseColor");
      MaterialProperty bct = FindProperty("_BaseColorTex");
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

  void DoCubemap() {
      MaterialProperty bc = FindProperty("_Cubemap");
      editor.TexturePropertySingleLine(
          MakeLabel(bc, "Cubemap"),
          bc);
      SetKeyword("_CUBEMAP", bc.textureValue);
  }

  void DoBrightness() {
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
      EditorGUI.indentLevel -= 1;

      bc = FindProperty($"_Matcap{i}Distortion0");
      enabled = bc.floatValue > 1E-6;
      EditorGUI.BeginChangeCheck();
      enabled = EditorGUILayout.Toggle("Enable distortion 0", enabled);
      EditorGUI.EndChangeCheck();
      bc.floatValue = enabled ? 1.0f : 0.0f;
      SetKeyword($"_MATCAP{i}_DISTORTION0", enabled);
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
          "Rim lighting emission");

      EditorGUI.indentLevel -= 1;
    }
  }

  enum NormalsMode {
    Flat,
    Spherical
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

    EditorGUI.BeginChangeCheck();
    mode = (RenderingMode) EditorGUILayout.EnumPopup(
        MakeLabel("Rendering mode"), mode);
    BlendMode src_blend = BlendMode.One;
    BlendMode dst_blend = BlendMode.Zero;
    bool zwrite = false;

    if (EditorGUI.EndChangeCheck()) {
      RecordAction("Rendering mode");
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
        m.renderQueue = (int) queue;
        m.SetOverrideTag("RenderType", render_type);
        m.SetInt("_SrcBlend", (int) src_blend);
        m.SetInt("_DstBlend", (int) dst_blend);
        m.SetInt("_ZWrite", zwrite ? 1 : 0);
      }
    }

    MaterialProperty bc;
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

  void DoLTCGI() {
#if LTCGI_INCLUDED
    GUILayout.Label($"Available: yes");

    MaterialProperty bc = FindProperty("_LTCGI_Enabled");
    bool enabled = bc.floatValue > 1E-6;
    EditorGUI.BeginChangeCheck();
    enabled = EditorGUILayout.Toggle("Enable", enabled);
    EditorGUI.EndChangeCheck();
    bc.floatValue = enabled ? 1.0f : 0.0f;
    SetKeyword("_LTCGI", enabled);

    bc = FindProperty("_LTCGI_SpecularColor");
    editor.ColorProperty(bc, "Specular color (RGB)");

    bc = FindProperty("_LTCGI_DiffuseColor");
    editor.ColorProperty(bc, "Diffuse color (RGB)");
#else
    GUILayout.Label($"Available: no");
#endif  // LTCGI_INCLUDED
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

    GUILayout.Label("Lighting", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoCubemap();
    DoBrightness();
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

    GUILayout.Label("Rendering", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoRendering();
    EditorGUI.indentLevel -= 1;

    GUILayout.Label("LTCGI", EditorStyles.boldLabel);
    EditorGUI.indentLevel += 1;
    DoLTCGI();
    EditorGUI.indentLevel -= 1;
  }
}


