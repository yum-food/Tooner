using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.Linq;

public class ImageSequenceToTexture3D : EditorWindow
{
    private string sourcePath = "";
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
        EditorGUILayout.HelpBox("Select a folder containing the image sequence (sorted by filename)", MessageType.Info);

        EditorGUILayout.BeginHorizontal();
        sourcePath = EditorGUILayout.TextField("Source Folder", sourcePath);
        if (GUILayout.Button("Browse", GUILayout.Width(60)))
        {
            string path = EditorUtility.OpenFolderPanel("Select Image Sequence Folder", "", "");
            if (!string.IsNullOrEmpty(path))
            {
                sourcePath = path;
            }
        }
        EditorGUILayout.EndHorizontal();

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
        if (string.IsNullOrEmpty(sourcePath))
        {
            EditorUtility.DisplayDialog("Error", "Please select a source folder.", "OK");
            return false;
        }

        string[] files = GetImageFiles();
        if (files.Length == 0)
        {
            EditorUtility.DisplayDialog("Error", "No supported image files found in the selected folder.", "OK");
            return false;
        }

        // Load first image to check dimensions
        Texture2D firstImage = LoadImage(files[0]);
        int width = firstImage.width;
        int height = firstImage.height;
        DestroyImmediate(firstImage);

        // Verify all images have the same dimensions
        for (int i = 1; i < files.Length; i++)
        {
            Texture2D img = LoadImage(files[i]);
            if (img.width != width || img.height != height)
            {
                DestroyImmediate(img);
                EditorUtility.DisplayDialog("Error",
                    $"All images must have the same dimensions. Expected {width}x{height}, but image {files[i]} is {img.width}x{img.height}",
                    "OK");
                return false;
            }
            DestroyImmediate(img);
        }

        return true;
    }

    private string[] GetImageFiles()
    {
        string[] files = System.IO.Directory.GetFiles(sourcePath, "*.*")
            .Where(file => file.ToLower().EndsWith(".png") || 
                          file.ToLower().EndsWith(".jpg") || 
                          file.ToLower().EndsWith(".jpeg"))
            .OrderBy(file => file)
            .ToArray();
        return files;
    }

    private Texture2D LoadImage(string path)
    {
        byte[] fileData = System.IO.File.ReadAllBytes(path);
        Texture2D tex = new Texture2D(2, 2);
        tex.LoadImage(fileData);
        return tex;
    }

    private void Generate3DTexture()
    {
        string[] files = GetImageFiles();
        if (files.Length == 0) return;

        Texture2D firstImage = LoadImage(files[0]);
        int width = firstImage.width;
        int height = firstImage.height;
        int depth = files.Length;
        DestroyImmediate(firstImage);

        // Create the 3D texture
        Texture3D texture3D = new Texture3D(width, height, depth, TextureFormat.RGBA32, false);
        texture3D.filterMode = filterMode;
        texture3D.wrapMode = wrapMode;

        // Prepare the color array
        Color[] colors = new Color[width * height * depth];

        // Copy the pixel data from each source image
        for (int z = 0; z < depth; z++)
        {
            Debug.Log($"Processing layer {z + 1} of {depth}: {System.IO.Path.GetFileName(files[z])}");
            Texture2D img = LoadImage(files[z]);
            Color[] imageColors = img.GetPixels();
            System.Array.Copy(imageColors, 0, colors, z * width * height, width * height);
            DestroyImmediate(img);
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
