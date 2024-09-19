// !! AI ARTIFACT !!
// This code was originally generated by Claude 3.5 Sonnet.
// I wanted to write this tooling like I want a fucking hole in the head so I
// kindly asked Claude to write it for me. It's shitty and poorly designed, but
// it works well enough for my purposes.
// It has been slightly tweaked by me, and validated on *this* codebase. It is
// provided with no warranty.
using UnityEngine;
using UnityEditor;
using System.IO;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Linq;

public class ShaderInliner : EditorWindow
{
	private string inputShaderPath;
	private string outputShaderPath;

	[MenuItem("Tools/yum_food/Shader Inliner")]
	public static void ShowWindow()
	{
		GetWindow<ShaderInliner>("Shader Inliner");
	}

	private void OnGUI()
	{
		GUILayout.Label("Shader Inliner", EditorStyles.boldLabel);

		inputShaderPath = EditorGUILayout.TextField("Input Shader Path", inputShaderPath);
		if (GUILayout.Button("Select Input Shader"))
		{
			inputShaderPath = EditorUtility.OpenFilePanel("Select Shader", "", "shader");
		}

		if (GUILayout.Button("Inline Shader"))
		{
			if (string.IsNullOrEmpty(inputShaderPath))
			{
				EditorUtility.DisplayDialog("Error", "Please select an input shader.", "OK");
				return;
			}

			InlineShader();
		}
	}

	private void InlineShader()
	{
		string shaderContent = File.ReadAllText(inputShaderPath);
		string inlinedShader = ProcessShader(shaderContent, Path.GetDirectoryName(inputShaderPath));

		string fileName = Path.GetFileNameWithoutExtension(inputShaderPath);
		outputShaderPath = Path.Combine(Path.GetDirectoryName(inputShaderPath), $"{fileName}_inlined.shader");
		File.WriteAllText(outputShaderPath, inlinedShader);

		AssetDatabase.Refresh();
		EditorUtility.DisplayDialog("Success", $"Inlined shader saved to:\n{outputShaderPath}", "OK");
	}

	private string ProcessShader(string content, string basePath)
	{
		// Update shader name
		content = Regex.Replace(content, @"Shader\s+""(.+?)""", match =>
				{
				string shaderName = match.Groups[1].Value;
				return $"Shader \"{shaderName}_inlined\"";
				});

		// Process each Pass independently
		content = Regex.Replace(content, @"(CGPROGRAM.*?ENDCG)", match =>
				{
				return ProcessPass(match.Value, basePath);
				}, RegexOptions.Singleline);

		// Check for mismatched preprocessor macros in the entire shader
		CheckMismatchedMacros(content);

		return content;
	}

	private string ProcessPass(string passContent, string basePath)
	{
		HashSet<string> includedFiles = new HashSet<string>();

		string pattern = @"#include\s+""(.+?)""";
		return Regex.Replace(passContent, pattern, match =>
				{
				string includePath = match.Groups[1].Value;
				string fullPath = Path.Combine(basePath, includePath);

				if (File.Exists(fullPath))
				{
				if (!includedFiles.Contains(fullPath))
				{
				includedFiles.Add(fullPath);
				string includeContent = File.ReadAllText(fullPath);
				return ProcessInclude(includeContent, Path.GetDirectoryName(fullPath), includedFiles);
				}
				else
				{
				return "// Already included in this pass: " + includePath;
				}
				}
				else
				{
				Debug.LogWarning($"Include file not found: {fullPath}");
				return match.Value;
				}
				});
	}

	private string ProcessInclude(string content, string basePath, HashSet<string> includedFiles)
	{
		string pattern = @"#include\s+""(.+?)""";
		return Regex.Replace(content, pattern, match =>
				{
				string includePath = match.Groups[1].Value;
				string fullPath = Path.Combine(basePath, includePath);

				if (File.Exists(fullPath))
				{
				if (!includedFiles.Contains(fullPath))
				{
				includedFiles.Add(fullPath);
				string includeContent = File.ReadAllText(fullPath);
				return ProcessInclude(includeContent, Path.GetDirectoryName(fullPath), includedFiles);
				}
				else
				{
				return "// Already included in this pass: " + includePath;
				}
				}
				else
				{
				Debug.LogWarning($"Include file not found: {fullPath}");
				return match.Value;
				}
				});
	}

	private void CheckMismatchedMacros(string content)
	{
		var stack = new Stack<string>();
		var lines = content.Split('\n');
		var macroPattern = @"^\s*#(if|ifdef|ifndef|elif|else|endif|if\s+defined)";

		for (int i = 0; i < lines.Length; i++)
		{
			var line = lines[i].Trim();
			var match = Regex.Match(line, macroPattern);

			if (match.Success)
			{
				var directive = match.Groups[1].Value;

				switch (directive)
				{
					case "if":
					case "ifdef":
					case "ifndef":
					case "if defined":
						stack.Push(directive);
						break;
					case "elif":
						if (stack.Count == 0 || (stack.Peek() != "if" && stack.Peek() != "elif"))
						{
							Debug.LogError($"Mismatched #elif at line {i + 1}");
						}
						else
						{
							stack.Pop();
							stack.Push("elif");
						}
						break;
					case "else":
						if (stack.Count == 0 || (stack.Peek() != "if" && stack.Peek() != "elif"))
						{
							Debug.LogError($"Mismatched #else at line {i + 1}");
						}
						else
						{
							stack.Pop();
							stack.Push("else");
						}
						break;
					case "endif":
						if (stack.Count == 0)
						{
							Debug.LogError($"Mismatched #endif at line {i + 1}");
						}
						else
						{
							stack.Pop();
						}
						break;
				}
			}
		}

		if (stack.Count > 0)
		{
			Debug.LogError($"Unclosed preprocessor directives: {string.Join(", ", stack)}");
		}
	}
}

