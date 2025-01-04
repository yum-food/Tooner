#include "gerstner.cginc"

#ifndef __MOCHIE_SHADOW_CASTER_INC
#define __MOCHIE_SHADOW_CASTER_INC

// Source: https://github.com/cnlohr/shadertrixx?tab=readme-ov-file#shadowcasting
// MIT License
// 
// NOTE: Much content here is originally from others.  Content in third party
// folder may not be fully MIT-licensable. 
// 
// Copyright (c) 2021 cnlohr, et. al.
// 
// All other content in this repository falls under the following terms:
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#pragma multi_compile_instancing
#pragma multi_compile_shadowcaster
#include "UnityCG.cginc"
#include "globals.cginc"

struct appdata {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
  float2 uv : TEXCOORD0;
  
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f {
	float4 pos : SV_POSITION;
  float2 uv : TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID 
  UNITY_VERTEX_OUTPUT_STEREO
};

v2f vert (appdata v){
#if defined(_DISCARD)
  if (_Discard_Enable_Dynamic) {
    return (v2f) (0.0 / 0.0);
  }
#endif
#if !defined(_SCROLL) && defined(_GIMMICK_GERSTNER_WATER)
  {
    GerstnerParams p = getGerstnerParams();
    v.vertex.xyz = gerstner_vert(v.vertex.xyz, p);
  }
#endif
#if defined(_GIMMICK_FOG_00)
  {
    float3 ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
    float3 rd = normalize(ro - v.vertex.xyz);
    v.vertex.xyz = ro + rd * _Gimmick_Fog_00_Radius;
  }
#endif
	v2f o = (v2f)0;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
	TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
  o.uv = v.uv;
  return o;
}

float2 get_uv_by_channel(v2f i, uint which_channel) {
  switch (which_channel) {
    case 0:
      return i.uv0;
      break;
#if !defined(_OPTIMIZE_INTERPOLATORS)
    case 1:
      return i.uv1;
      break;
#if !defined(LIGHTMAP_ON)
    case 2:
      return i.uv2;
      break;
    case 3:
      return i.uv3;
      break;
    case 4:
      return i.uv4;
      break;
    case 5:
      return i.uv5;
      break;
    case 6:
      return i.uv6;
      break;
    case 7:
      return i.uv7;
      break;
#endif
#endif  // _OPTIMIZE_INTERPOLATORS
    default:
      return 0;
      break;
  }
}

#define UV_SCOFF(i, tex_st, which_channel) get_uv_by_channel(i, round(which_channel)) * (tex_st).xy + (tex_st).zw

float4 frag (v2f i) : SV_Target {
#if defined(_BASECOLOR_MAP)
  float4 albedo = _MainTex.SampleBias(GET_SAMPLER_PBR, UV_SCOFF(i, _MainTex_ST, 0), _Global_Sample_Bias);
  albedo *= _Color;
#else
  float4 albedo = _Color;
#endif  // _BASECOLOR_MAP
#if defined(_RENDERING_CUTOUT)
#if defined(_RENDERING_CUTOUT_STOCHASTIC)
  float ar = rand2(i.uv0);
  clip(albedo.a - ar);
#elif defined(_RENDERING_CUTOUT_IGN)
  float ar = ign_anim(
      floor(tdata.screen_uv_round * _Rendering_Cutout_Noise_Scale) + _Rendering_Cutout_Ign_Seed,
      floor(_Frame_Counter), _Rendering_Cutout_Ign_Speed);
  clip(albedo.a - ar);
#elif defined(_RENDERING_CUTOUT_NOISE_MASK)
  float ar = _Rendering_Cutout_Noise_Mask.SampleLevel(point_repeat_s, tdata.screen_uv * _ScreenParams.xy * _Rendering_Cutout_Noise_Mask_TexelSize.xy, 0);
  clip(albedo.a - ar);
#else
  clip(albedo.a - _Alpha_Cutoff);
#endif
  albedo.a = 1;
#endif
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
	return 0;
}

#endif  // __MOCHIE_SHADOW_CASTER_INC

