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
  float4 clipPos : POSITION;
  float2 uv : TEXCOORD0;
  float2 lmuv : TEXCOORD1;
  float3 worldPos : TEXCOORD2;
  float3 normal : TEXCOORD3;
};

#else

struct appdata
{
  float4 position : POSITION;
  float2 uv0 : TEXCOORD0;
  float2 uv1 : TEXCOORD1;
  float3 normal : NORMAL;
  float4 tangent : TANGENT;
};

struct v2f
{
  float4 clipPos : SV_POSITION;
  float2 uv : TEXCOORD0;
  float2 lmuv : TEXCOORD1;
  float3 normal : TEXCOORD2;
  float4 tangent : TEXCOORD3;
  float3 worldPos : TEXCOORD4;

  #if defined(VERTEXLIGHT_ON)
  float3 vertexLightColor : TEXCOORD5;
  #endif
};
#endif

#endif  // __INTERPOLATORS_INC

