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
	v2f o = (v2f)0;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
	TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
  o.uv = v.uv;
  return o;
}

float4 frag (v2f i) : SV_Target {
#if defined(_BASECOLOR_MAP)
  float iddx = ddx(i.uv.x);
  float iddy = ddx(i.uv.y);
  float4 albedo = _MainTex.SampleGrad(linear_repeat_s, i.uv, iddx, iddy);
  albedo *= _Color;
#else
  float4 albedo = _Color;
#endif  // _BASECOLOR_MAP
#if defined(_RENDERING_CUTOUT)
  clip(albedo.a - _Alpha_Cutoff);
#endif
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
	return 0;
}

#endif  // __MOCHIE_SHADOW_CASTER_INC

