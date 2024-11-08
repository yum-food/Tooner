#ifndef __FOG_LTCGI_INC
#define __FOG_LTCGI_INC

#if defined(_GIMMICK_FOG_00)

#define LTCGI_SPECULAR_OFF
#define LTCGI_ALWAYS_LTC_DIFFUSE
#define LTCGI_FAST_SAMPLING

#include "Third_Party/at.pimaker.ltcgi/Shaders/LTCGI_structs.cginc"

#undef LTCGI_AVATAR_MODE

struct ltcgi_acc {
  float3 diffuse;
};

void ltcgi_cb_diffuse(inout ltcgi_acc acc, in ltcgi_output output);

#define LTCGI_V2_CUSTOM_INPUT ltcgi_acc
#define LTCGI_V2_DIFFUSE_CALLBACK ltcgi_cb_diffuse

// modified exponential impulse from here: https://iquilezles.org/articles/functions/
float reshape_intensity(float x) {
  x = saturate(x*4);
  return (2*x*exp(1-2*x))*.1;
}

#include "Third_Party/at.pimaker.ltcgi/Shaders/LTCGI.cginc"
void ltcgi_cb_diffuse(inout ltcgi_acc acc, in ltcgi_output output) {
  // Intensity varies from 0 to 1.
	acc.diffuse += reshape_intensity(output.intensity) * output.color;
}
#endif  // _GIMMICK_FOG_00

#endif  // __FOG_LTCGI_INC
