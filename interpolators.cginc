#include "AutoLight.cginc"

#ifndef __INTERPOLATORS_INC
#define __INTERPOLATORS_INC

#if defined(_OUTLINE_INTERPOLATORS)

struct appdata
{
  float4 vertex : POSITION;
  float3 normal : NORMAL;
  float2 uv0 : TEXCOORD0;
  float2 uv1 : TEXCOORD1;
  float2 uv2 : TEXCOORD2;
  float2 uv3 : TEXCOORD3;
  float2 uv4 : TEXCOORD4;
  float2 uv5 : TEXCOORD5;
  float2 uv6 : TEXCOORD6;
  float2 uv7 : TEXCOORD7;

  UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
  float4 pos : SV_POSITION;
  float2 uv0 : TEXCOORD0;
  float2 uv1 : TEXCOORD1;
  float2 uv2 : TEXCOORD2;
#if defined(LIGHTMAP_ON)
  UNITY_LIGHTING_COORDS(3, 4)
#else
  float2 uv3 : TEXCOORD3;
  float2 uv4 : TEXCOORD4;
  float2 uv5 : TEXCOORD5;
  float2 uv6 : TEXCOORD6;
  float2 uv7 : TEXCOORD7;
  SHADOW_COORDS(8)
#endif
  float3 worldPos : TEXCOORD9;
  float3 normal : TEXCOORD10;
  float3 objPos : TEXCOORD11;
  float3 centerCamPos : TEXCOORD12;

  float4 screenPos : TEXCOORD13;

  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
};

#else  // _OUTLINE_INTERPOLATORS

struct appdata
{
  float4 vertex : POSITION;
  float2 uv0 : TEXCOORD0;
  float2 uv1 : TEXCOORD1;
  float2 uv2 : TEXCOORD2;
  float2 uv3 : TEXCOORD3;
  float2 uv4 : TEXCOORD4;
  float2 uv5 : TEXCOORD5;
  float2 uv6 : TEXCOORD6;
  float2 uv7 : TEXCOORD7;
  float3 normal : NORMAL;
  float4 tangent : TANGENT;

  UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
  float4 pos : SV_POSITION;
  float2 uv0 : TEXCOORD0;
  float2 uv1 : TEXCOORD1;
  float2 uv2 : TEXCOORD2;
#if defined(LIGHTMAP_ON)
  UNITY_LIGHTING_COORDS(3, 4)
#else
  float2 uv3 : TEXCOORD3;
  float2 uv4 : TEXCOORD4;
  float2 uv5 : TEXCOORD5;
  float2 uv6 : TEXCOORD6;
  float2 uv7 : TEXCOORD7;
  SHADOW_COORDS(8)
#endif
  float3 normal : TEXCOORD9;
  float4 tangent : TEXCOORD10;
  float3 worldPos : TEXCOORD11;
  float3 objPos : TEXCOORD12;
  float3 centerCamPos : TEXCOORD13;

  float4 screenPos : TEXCOORD14;

  #if defined(VERTEXLIGHT_ON)
  float3 vertexLightColor : TEXCOORD15;
  #endif

  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
};

#endif  // _OUTLINE_INTERPOLATORS
#endif  // __INTERPOLATORS_INC

