#ifndef __TEXTURE_MACROS_INC
#define __TEXTURE_MACROS_INC

#include "interpolators.cginc"

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

#if defined(_PBR_SAMPLER_LINEAR_REPEAT)
#define GET_SAMPLER_PBR linear_repeat_s
#elif defined(_PBR_SAMPLER_LINEAR_CLAMP)
#define GET_SAMPLER_PBR linear_clamp_s
#elif defined(_PBR_SAMPLER_POINT_REPEAT)
#define GET_SAMPLER_PBR point_repeat_s
#elif defined(_PBR_SAMPLER_POINT_CLAMP)
#define GET_SAMPLER_PBR point_clamp_s
#elif defined(_PBR_SAMPLER_BILINEAR_REPEAT)
#define GET_SAMPLER_PBR bilinear_repeat_s
#elif defined(_PBR_SAMPLER_BILINEAR_CLAMP)
#define GET_SAMPLER_PBR bilinear_clamp_s
#else
#define GET_SAMPLER_PBR bilinear_clamp_s
#endif

#if defined(_PBR_OVERLAY0_SAMPLER_LINEAR_REPEAT)
#define GET_SAMPLER_OV0 linear_repeat_s
#elif defined(_PBR_OVERLAY0_SAMPLER_LINEAR_CLAMP)
#define GET_SAMPLER_OV0 linear_clamp_s
#elif defined(_PBR_OVERLAY0_SAMPLER_POINT_REPEAT)
#define GET_SAMPLER_OV0 point_repeat_s
#elif defined(_PBR_OVERLAY0_SAMPLER_POINT_CLAMP)
#define GET_SAMPLER_OV0 point_clamp_s
#elif defined(_PBR_OVERLAY0_SAMPLER_BILINEAR_REPEAT)
#define GET_SAMPLER_OV0 bilinear_repeat_s
#elif defined(_PBR_OVERLAY0_SAMPLER_BILINEAR_CLAMP)
#define GET_SAMPLER_OV0 bilinear_clamp_s
#else
#define GET_SAMPLER_OV0 linear_clamp_s
#endif

#if defined(_PBR_OVERLAY1_SAMPLER_LINEAR_REPEAT)
#define GET_SAMPLER_OV1 linear_repeat_s
#elif defined(_PBR_OVERLAY1_SAMPLER_LINEAR_CLAMP)
#define GET_SAMPLER_OV1 linear_clamp_s
#elif defined(_PBR_OVERLAY1_SAMPLER_POINT_REPEAT)
#define GET_SAMPLER_OV1 point_repeat_s
#elif defined(_PBR_OVERLAY1_SAMPLER_POINT_CLAMP)
#define GET_SAMPLER_OV1 point_clamp_s
#elif defined(_PBR_OVERLAY1_SAMPLER_BILINEAR_REPEAT)
#define GET_SAMPLER_OV1 bilinear_repeat_s
#elif defined(_PBR_OVERLAY1_SAMPLER_BILINEAR_CLAMP)
#define GET_SAMPLER_OV1 bilinear_clamp_s
#else
#define GET_SAMPLER_OV1 linear_clamp_s
#endif

#if defined(_PBR_OVERLAY2_SAMPLER_LINEAR_REPEAT)
#define GET_SAMPLER_OV2 linear_repeat_s
#elif defined(_PBR_OVERLAY2_SAMPLER_LINEAR_CLAMP)
#define GET_SAMPLER_OV2 linear_clamp_s
#elif defined(_PBR_OVERLAY2_SAMPLER_POINT_REPEAT)
#define GET_SAMPLER_OV2 point_repeat_s
#elif defined(_PBR_OVERLAY2_SAMPLER_POINT_CLAMP)
#define GET_SAMPLER_OV2 point_clamp_s
#elif defined(_PBR_OVERLAY2_SAMPLER_BILINEAR_REPEAT)
#define GET_SAMPLER_OV2 bilinear_repeat_s
#elif defined(_PBR_OVERLAY2_SAMPLER_BILINEAR_CLAMP)
#define GET_SAMPLER_OV2 bilinear_clamp_s
#else
#define GET_SAMPLER_OV2 linear_clamp_s
#endif

#if defined(_PBR_OVERLAY3_SAMPLER_LINEAR_REPEAT)
#define GET_SAMPLER_OV3 linear_repeat_s
#elif defined(_PBR_OVERLAY3_SAMPLER_LINEAR_CLAMP)
#define GET_SAMPLER_OV3 linear_clamp_s
#elif defined(_PBR_OVERLAY3_SAMPLER_POINT_REPEAT)
#define GET_SAMPLER_OV3 point_repeat_s
#elif defined(_PBR_OVERLAY3_SAMPLER_POINT_CLAMP)
#define GET_SAMPLER_OV3 point_clamp_s
#elif defined(_PBR_OVERLAY3_SAMPLER_BILINEAR_REPEAT)
#define GET_SAMPLER_OV3 bilinear_repeat_s
#elif defined(_PBR_OVERLAY3_SAMPLER_BILINEAR_CLAMP)
#define GET_SAMPLER_OV3 bilinear_clamp_s
#else
#define GET_SAMPLER_OV3 linear_clamp_s
#endif

#if defined(_RIM_LIGHTING0_SAMPLER_LINEAR_REPEAT)
#define GET_SAMPLER_RL0 linear_repeat_s
#elif defined(_RIM_LIGHTING0_SAMPLER_LINEAR_CLAMP)
#define GET_SAMPLER_RL0 linear_clamp_s
#elif defined(_RIM_LIGHTING0_SAMPLER_POINT_REPEAT)
#define GET_SAMPLER_RL0 point_repeat_s
#elif defined(_RIM_LIGHTING0_SAMPLER_POINT_CLAMP)
#define GET_SAMPLER_RL0 point_clamp_s
#elif defined(_RIM_LIGHTING0_SAMPLER_BILINEAR_REPEAT)
#define GET_SAMPLER_RL0 bilinear_repeat_s
#elif defined(_RIM_LIGHTING0_SAMPLER_BILINEAR_CLAMP)
#define GET_SAMPLER_RL0 bilinear_clamp_s
#else
#define GET_SAMPLER_RL0 linear_clamp_s
#endif

#if defined(_RIM_LIGHTING1_SAMPLER_LINEAR_REPEAT)
#define GET_SAMPLER_RL1 linear_repeat_s
#elif defined(_RIM_LIGHTING1_SAMPLER_LINEAR_CLAMP)
#define GET_SAMPLER_RL1 linear_clamp_s
#elif defined(_RIM_LIGHTING1_SAMPLER_POINT_REPEAT)
#define GET_SAMPLER_RL1 point_repeat_s
#elif defined(_RIM_LIGHTING1_SAMPLER_POINT_CLAMP)
#define GET_SAMPLER_RL1 point_clamp_s
#elif defined(_RIM_LIGHTING1_SAMPLER_BILINEAR_REPEAT)
#define GET_SAMPLER_RL1 bilinear_repeat_s
#elif defined(_RIM_LIGHTING1_SAMPLER_BILINEAR_CLAMP)
#define GET_SAMPLER_RL1 bilinear_clamp_s
#else
#define GET_SAMPLER_RL1 linear_clamp_s
#endif

#if defined(_RIM_LIGHTING2_SAMPLER_LINEAR_REPEAT)
#define GET_SAMPLER_RL2 linear_repeat_s
#elif defined(_RIM_LIGHTING2_SAMPLER_LINEAR_CLAMP)
#define GET_SAMPLER_RL2 linear_clamp_s
#elif defined(_RIM_LIGHTING2_SAMPLER_POINT_REPEAT)
#define GET_SAMPLER_RL2 point_repeat_s
#elif defined(_RIM_LIGHTING2_SAMPLER_POINT_CLAMP)
#define GET_SAMPLER_RL2 point_clamp_s
#elif defined(_RIM_LIGHTING2_SAMPLER_BILINEAR_REPEAT)
#define GET_SAMPLER_RL2 bilinear_repeat_s
#elif defined(_RIM_LIGHTING2_SAMPLER_BILINEAR_CLAMP)
#define GET_SAMPLER_RL2 bilinear_clamp_s
#else
#define GET_SAMPLER_RL2 linear_clamp_s
#endif

#if defined(_RIM_LIGHTING3_SAMPLER_LINEAR_REPEAT)
#define GET_SAMPLER_RL3 linear_repeat_s
#elif defined(_RIM_LIGHTING3_SAMPLER_LINEAR_CLAMP)
#define GET_SAMPLER_RL3 linear_clamp_s
#elif defined(_RIM_LIGHTING3_SAMPLER_POINT_REPEAT)
#define GET_SAMPLER_RL3 point_repeat_s
#elif defined(_RIM_LIGHTING3_SAMPLER_POINT_CLAMP)
#define GET_SAMPLER_RL3 point_clamp_s
#elif defined(_RIM_LIGHTING3_SAMPLER_BILINEAR_REPEAT)
#define GET_SAMPLER_RL3 bilinear_repeat_s
#elif defined(_RIM_LIGHTING3_SAMPLER_BILINEAR_CLAMP)
#define GET_SAMPLER_RL3 bilinear_clamp_s
#else
#define GET_SAMPLER_RL3 linear_clamp_s
#endif

#endif  // __TEXTURE_MACROS_INC

