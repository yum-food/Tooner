#ifndef __INTERPOLATORS_INC
#define __INTERPOLATORS_INC

#include "AutoLight.cginc"

#if defined(_OUTLINE_INTERPOLATORS)

struct appdata
{
  float4 vertex : POSITION;
  float3 normal : NORMAL;
  float2 uv : TEXCOORD0;
};

struct v2f
{
  float4 clipPos : POSITION;
  float2 uv : TEXCOORD0;
  float3 worldPos : TEXCOORD1;
  float3 normal : TEXCOORD2;
};

#else

struct appdata
{
  float4 position : POSITION;
  float2 uv : TEXCOORD0;
  float3 normal : NORMAL;
  float4 tangent : TANGENT;
};

struct v2f
{
  float4 clipPos : SV_POSITION;
  float2 uv : TEXCOORD0;
  float3 normal : TEXCOORD1;
  float4 tangent : TEXCOORD2;
  float3 worldPos : TEXCOORD3;

	SHADOW_COORDS(4)

  #if defined(VERTEXLIGHT_ON)
  float3 vertexLightColor : TEXCOORD5;
  #endif
};
#endif

#endif  // __INTERPOLATORS_INC

