#ifndef __INTERPOLATORS_INC
#define __INTERPOLATORS_INC

#include "AutoLight.cginc"

#if defined(_OUTLINE_INTERPOLATORS)

struct appdata
{
  float4 vertex : POSITION;
  float3 normal : NORMAL;
  float2 uv0 : TEXCOORD0;
  float2 uv2 : TEXCOORD1;

  UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
  float4 pos : SV_POSITION;
  float2 uv0 : TEXCOORD0;
  float2 uv2 : TEXCOORD1;
  #if defined(LIGHTMAP_ON)
  float2 lmuv : TEXCOORD2;
  #endif
  float3 worldPos : TEXCOORD3;
  float3 normal : TEXCOORD4;
  float3 objPos : TEXCOORD5;
  #if defined(SSR_ENABLED)
  float4 screenPos                  : TEXCOORD6;
  #endif

  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
};

#else

struct appdata
{
  float4 vertex : POSITION;
  float2 uv0 : TEXCOORD0;
  float2 uv2 : TEXCOORD1;
  float3 normal : NORMAL;
  float4 tangent : TANGENT;

  UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
  float4 pos : SV_POSITION;
  float2 uv0 : TEXCOORD0;
  float2 uv2 : TEXCOORD1;
  #if defined(LIGHTMAP_ON)
  float2 lmuv : TEXCOORD2;
  #endif
  float3 normal : TEXCOORD3;
  float4 tangent : TEXCOORD4;
  float3 worldPos : TEXCOORD5;
  float3 objPos : TEXCOORD6;

  SHADOW_COORDS(7)
  #if defined(VERTEXLIGHT_ON)
  float3 vertexLightColor : TEXCOORD8;
  #endif
  #if defined(SSR_ENABLED)
  float4 screenPos                  : TEXCOORD9;
  #endif

  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
};
#endif

#endif  // __INTERPOLATORS_INC

