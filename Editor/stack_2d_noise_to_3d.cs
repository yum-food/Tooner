using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

public class ImageSequenceToTexture3D : EditorWindow
{
    private List<Texture2D> sourceImages = new List<Texture2D>();
    private string textureName = "Texture3DFromSequence";
    private FilterMode filterMode = FilterMode.Bilinear;
    private TextureWrapMode wrapMode = TextureWrapMode.Repeat;

    [MenuItem("Tools/yum_food/Image Sequence to Texture3D")]
    public static void ShowWindow()
    {
        GetWindow<ImageSequenceToTexture3D>("Image Sequence to Texture3D");
    }

    private void OnGUI()
    {
        GUILayout.Label("Image Sequence to Texture3D Converter", EditorStyles.boldLabel);
        EditorGUILayout.HelpBox("Add images in the order they should appear in the Z-axis", MessageType.Info);

        // Image sequence management
        EditorGUILayout.LabelField("Source Images", EditorStyles.boldLabel);
        for (int i = 0; i < sourceImages.Count; i++)
        {
            EditorGUILayout.BeginHorizontal();
            sourceImages[i] = (Texture2D)EditorGUILayout.ObjectField($"Slice {i}", sourceImages[i], typeof(Texture2D), false);
            if (GUILayout.Button("Remove", GUILayout.Width(60)))
            {
                sourceImages.RemoveAt(i);
                GUILayout.EndHorizontal();
                break;
            }
            EditorGUILayout.EndHorizontal();
        }

        if (GUILayout.Button("Add Image Slot"))
        {
            sourceImages.Add(null);
        }

        textureName = EditorGUILayout.TextField("Texture Name", textureName);
        filterMode = (FilterMode)EditorGUILayout.EnumPopup("Filter Mode", filterMode);
        wrapMode = (TextureWrapMode)EditorGUILayout.EnumPopup("Wrap Mode", wrapMode);

        if (GUILayout.Button("Generate 3D Texture"))
        {
            if (ValidateInputs())
            {
                Generate3DTexture();
            }
        }
    }

    private bool ValidateInputs()
    {
        if (sourceImages.Count == 0)
        {
            EditorUtility.DisplayDialog("Error", "Please add at least one image.", "OK");
            return false;
        }

        if (sourceImages.Contains(null))
        {
            EditorUtility.DisplayDialog("Error", "Please assign all image slots.", "OK");
            return false;
        }

        // Verify all images have the same dimensions
        int width = sourceImages[0].width;
        int height = sourceImages[0].height;
        
        for (int i = 1; i < sourceImages.Count; i++)
        {
            if (sourceImages[i].width != width || sourceImages[i].height != height)
            {
                EditorUtility.DisplayDialog("Error", 
                    $"All images must have the same dimensions. Expected {width}x{height}, but image {i} is {sourceImages[i].width}x{sourceImages[i].height}", 
                    "OK");
                return false;
            }
        }

        return true;
    }

    private void Generate3DTexture()
    {
        int width = sourceImages[0].width;
        int height = sourceImages[0].height;
        int depth = sourceImages.Count;

        // Create the 3D texture
        Texture3D texture3D = new Texture3D(width, height, depth, TextureFormat.RGBA32, false);
        texture3D.filterMode = filterMode;
        texture3D.wrapMode = wrapMode;

        // Prepare the color array
        Color[] colors = new Color[width * height * depth];

        // Copy the pixel data from each source image
        for (int z = 0; z < depth; z++)
        {
            Color[] imageColors = sourceImages[z].GetPixels();
            System.Array.Copy(imageColors, 0, colors, z * width * height, width * height);
        }

        texture3D.SetPixels(colors);
        texture3D.Apply();

        // Save the texture asset
        string path = $"Assets/{textureName}.asset";
        AssetDatabase.CreateAsset(texture3D, path);
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        EditorUtility.DisplayDialog("Success", $"3D texture generated and saved at {path}", "OK");
    }
}
