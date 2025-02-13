#include "AutoLight.cginc"
#include "feature_macros.cginc"

#ifndef __INTERPOLATORS_INC
#define __INTERPOLATORS_INC

#if defined(_OUTLINE_INTERPOLATORS)

struct appdata
{
  float4 vertex : POSITION;
  float3 normal : NORMAL;
  float4 tangent : TANGENT;
  float2 uv0 : TEXCOORD0;
#if !defined(_OPTIMIZE_INTERPOLATORS)
  float2 uv1 : TEXCOORD1;
  float2 uv2 : TEXCOORD2;
  float2 uv3 : TEXCOORD3;
  float2 uv4 : TEXCOORD4;
  float2 uv5 : TEXCOORD5;
  float2 uv6 : TEXCOORD6;
  float2 uv7 : TEXCOORD7;
#endif

  UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
  linear noperspective centroid float4 pos : SV_POSITION;
  float2 uv0 : TEXCOORD0;
#if !defined(_OPTIMIZE_INTERPOLATORS)
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
#endif
#endif
  float2 fogCoord: TEXCOORD8;
  SHADOW_COORDS(9)
  float3 worldPos : TEXCOORD10;
  float3 normal : TEXCOORD11;
  float3 objPos : TEXCOORD12;
  float3 centerCamPos : TEXCOORD13;

  float2 screenPos : TEXCOORD14;

#if defined(_TROCHOID)
  float3 objPos_pre_trochoid : TEXCOORD15;
#endif

  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
};

#else  // _OUTLINE_INTERPOLATORS

struct appdata
{
  float4 vertex : POSITION;
  float2 uv0 : TEXCOORD0;
#if !defined(_OPTIMIZE_INTERPOLATORS)
  float2 uv1 : TEXCOORD1;
  float2 uv2 : TEXCOORD2;
  float2 uv3 : TEXCOORD3;
  float2 uv4 : TEXCOORD4;
  float2 uv5 : TEXCOORD5;
  float2 uv6 : TEXCOORD6;
  float2 uv7 : TEXCOORD7;
#endif
  float3 normal : NORMAL;
  float4 tangent : TANGENT;

  UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
  linear noperspective centroid float4 pos : SV_POSITION;
  float2 uv0 : TEXCOORD0;
#if !defined(_OPTIMIZE_INTERPOLATORS)
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
#endif
#endif
  float2 fogCoord: TEXCOORD8;
#if !defined(LIGHTMAP_ON)
  unityShadowCoord4 _ShadowCoord : TEXCOORD9;
#endif
  float3 normal : TEXCOORD10;
  float4 tangent : TEXCOORD11;
  float3 worldPos : TEXCOORD12;
  float3 objPos : TEXCOORD13;
  float3 centerCamPos : TEXCOORD14;

  float2 screenPos : TEXCOORD15;
  float4 grabPos : TEXCOORD16;

  #if defined(VERTEXLIGHT_ON)
  float3 vertexLightColor : TEXCOORD17;
  #endif

#if defined(_TROCHOID)
  float3 objPos_pre_trochoid : TEXCOORD18;
#endif

  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
};

#endif  // _OUTLINE_INTERPOLATORS
#endif  // __INTERPOLATORS_INC

