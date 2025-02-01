#ifndef __AUDIOLINK
#define __AUDIOLINK

#if defined (_GIMMICK_QUANTIZE_LOCATION_AUDIOLINK) || defined(_GIMMICK_AL_CHROMA_00) || defined(_GIMMICK_FOG_00) || defined(_RENDERING_CUTOUT) || defined(_GIMMICK_DS2)
#define TOONER_AUDIOLINK_AVAILABLE
#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
#else
#endif
#endif  // __AUDIOLINK

