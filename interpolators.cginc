#ifndef __INTERPOLATORS_INC
#define __INTERPOLATORS_INC

#include "AutoLight.cginc"

#if defined(_OUTLINE_INTERPOLATORS)

struct appdata
{
  float4 vertex : POSITION;
  float3 normal : NORMAL;
  float2 uv0 : TEXCOORD0;
  float2 uv1 : TEXCOORD1;
  float2 uv2 : TEXCOORD2;
  float2 uv3 : TEXCOORD3;

  UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
  float4 pos : SV_POSITION;
  float2 uv0 : TEXCOORD0;
  float2 uv1 : TEXCOORD1;
  float2 uv2 : TEXCOORD2;
  float2 uv3 : TEXCOORD3;
  #if defined(LIGHTMAP_ON)
  float2 lmuv : TEXCOORD4;
  #endif
  float3 worldPos : TEXCOORD5;
  float3 normal : TEXCOORD6;
  float3 objPos : TEXCOORD7;
  #if defined(SSR_ENABLED)
  float4 screenPos : TEXCOORD8;
  #endif

  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
};

#else

struct appdata
{
  float4 vertex : POSITION;
  float2 uv0 : TEXCOORD0;
  float2 uv1 : TEXCOORD1;
  float2 uv2 : TEXCOORD2;
  float2 uv3 : TEXCOORD3;
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
  float2 uv3 : TEXCOORD3;
  #if defined(LIGHTMAP_ON)
  float2 lmuv : TEXCOORD4;
  #endif
  float3 normal : TEXCOORD5;
  float4 tangent : TEXCOORD6;
  float3 worldPos : TEXCOORD7;
  float3 objPos : TEXCOORD8;

  SHADOW_COORDS(9)
  #if defined(VERTEXLIGHT_ON)
  float3 vertexLightColor : TEXCOORD10;
  #endif
  #if defined(SSR_ENABLED)
  float4 screenPos : TEXCOORD11;
  #endif

  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
};
#endif

#endif  // __INTERPOLATORS_INC

