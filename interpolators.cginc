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
};

struct v2f
{
  float4 vertex : SV_POSITION;
  float2 uv : TEXCOORD0;
  #if defined(LIGHTMAP_ON)
  float2 lmuv : TEXCOORD1;
  #endif
  float3 worldPos : TEXCOORD2;
  float3 normal : TEXCOORD3;
  float3 objPos : TEXCOORD4;
  #if defined(SSR_ENABLED)
  float4 screenPos                  : TEXCOORD5;
  #endif
};

#else

struct appdata
{
  float4 vertex : POSITION;
  float2 uv0 : TEXCOORD0;
  float2 uv1 : TEXCOORD1;
  float3 normal : NORMAL;
  float4 tangent : TANGENT;
};

struct v2f
{
  float4 vertex : SV_POSITION;
  float2 uv : TEXCOORD0;
  #if defined(LIGHTMAP_ON)
  float2 lmuv : TEXCOORD1;
  #endif
  float3 normal : TEXCOORD2;
  float4 tangent : TEXCOORD3;
  float3 worldPos : TEXCOORD4;
  float3 objPos : TEXCOORD5;

  SHADOW_COORDS(6)
  #if defined(VERTEXLIGHT_ON)
  float3 vertexLightColor : TEXCOORD7;
  #endif
  #if defined(SSR_ENABLED)
  float4 screenPos                  : TEXCOORD8;
  #endif
};
#endif

#endif  // __INTERPOLATORS_INC

