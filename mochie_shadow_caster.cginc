#include "UnityCG.cginc"

#include "atrix256.cginc"
#include "audiolink.cginc"
#include "gerstner.cginc"
#include "globals.cginc"
#include "pbr_overlay.cginc"
#include "interpolators.cginc"
#include "trochoid_math.cginc"

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

v2f vert (appdata v){
#if defined(_DISCARD)
  if (_Discard_Enable_Dynamic) {
    return (v2f) (0.0 / 0.0);
  }
#endif
#if defined(_GIMMICK_ZWRITE_ABOMINATION)
  return (v2f) (0.0 / 0.0);
#endif
#if defined(_GIMMICK_BOX_DISCARD)
  if (_Gimmick_Box_Discard_Enable_Static) {
    float3 p = getCenterCamPos();
    float3 c1 = _Gimmick_Box_Discard_Corner_1;
    float3 c2 = _Gimmick_Box_Discard_Corner_2;
    bool inside = (p.x >= c1.x && p.x <= c2.x &&
        p.y >= c1.y && p.y <= c2.y &&
        p.z >= c1.z && p.z <= c2.z);
    if (_Gimmick_Box_Discard_Invert && !inside ||
        !_Gimmick_Box_Discard_Invert && inside) {
      return (v2f) (0.0 / 0.0);
    }
  }
#endif
#if defined(_TROCHOID)
  {
    v.vertex.xyz = cart_to_troch_map(v.vertex.xyz);
  }
#endif  // _TROCHOID
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
  o.uv0 = v.uv0;
  o.worldPos = mul(unity_ObjectToWorld, v.vertex);

	float2 suv = o.pos * float2(0.5, 0.5 * _ProjectionParams.x);
  o.screenPos = TransformStereoScreenSpaceTex(suv + 0.5 * o.pos.w, o.pos.w);

  return o;
}

float4 frag (v2f i) : SV_Target {
  ToonerData tdata;
  {
    float3 full_vec_eye_to_geometry = i.worldPos - _WorldSpaceCameraPos;
    float3 world_dir = normalize(i.worldPos - _WorldSpaceCameraPos);
    float perspective_divide = 1.0 / i.pos.w;
    float perspective_factor = length(full_vec_eye_to_geometry * perspective_divide);
    tdata.screen_uv = i.screenPos.xy * perspective_divide;
    tdata.screen_uv_round = floor(tdata.screen_uv * _ScreenParams.xy);
  }

#if defined(_BASECOLOR_MAP)
  float4 albedo = _MainTex.SampleBias(GET_SAMPLER_PBR, UV_SCOFF(i, _MainTex_ST, 0), _Global_Sample_Bias);
  albedo *= _Color;
#else
  float4 albedo = _Color;
#endif  // _BASECOLOR_MAP

  PbrOverlay ov;
  getOverlayAlbedoRoughnessMetallic(ov, i);
  float roughness = 0;
  float metallic = 0;
  float overlay_glitter_mask;
  float one = 1;
  mixOverlayAlbedoRoughnessMetallic(albedo, roughness, metallic, ov, one, overlay_glitter_mask);

#if defined(_RENDERING_CUTOUT)
#if defined(_FRAME_COUNTER)
  float frame = floor(_Frame_Counter);
#else
  float frame = 0;
  if (AudioLinkIsAvailable()) {
    frame = ((float) AudioLinkData(ALPASS_GENERALVU + int2(1, 0)).x);
  }
#endif  // _FRAME_COUNTER
#if defined(_RENDERING_CUTOUT_STOCHASTIC)
  float ar = rand2(i.uv0);
  clip(albedo.a - ar);
#elif defined(_RENDERING_CUTOUT_IGN)
  float ar = ign(floor(tdata.screen_uv_round * _Rendering_Cutout_Noise_Scale) + _Rendering_Cutout_Ign_Seed);
  ar = frac(ar + frame * PHI * _Rendering_Cutout_Speed);
  clip(albedo.a - ar);
#elif defined(_RENDERING_CUTOUT_NOISE_MASK)
  float ar = _Rendering_Cutout_Noise_Mask.SampleLevel(point_repeat_s,
      tdata.screen_uv * _ScreenParams.xy *
      _Rendering_Cutout_Noise_Mask_TexelSize.xy, 0);
  ar = frac(ar + frame * PHI * _Rendering_Cutout_Speed);
  clip(albedo.a - ar);
#else
  clip(albedo.a - _Alpha_Cutoff);
#endif
  albedo.a = 1;
#endif  // _RENDERING_CUTOUT

	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
	return 0;
}

#endif  // __MOCHIE_SHADOW_CASTER_INC

