#ifndef __CLONES_INC
#define __CLONES_INC

#if defined(_CLONES)

#include "interpolators.cginc"
#include "globals.cginc"

void add_clones(in v2f clone_verts[3], inout TriangleStream<v2f> tri_out)
{
  if (_Clones_dx < 1E-6) {
    return;
  }

  uint n_clones = (uint) round(_Clones_Count);
  for (uint i = 0; i < (uint) n_clones; i++) {
    for (uint j = 0; j < 3; j++) {
      v2f ii = clone_verts[j];
      float3 objPos = mul(unity_WorldToObject, float4(ii.worldPos, 1)).xyz;
      float offset = i;
      offset = ((offset % 2) * 2 - 1) * (((offset) / 2) + 1) * _Clones_dx;
      objPos.x += offset;
      ii.worldPos = mul(unity_ObjectToWorld, float4(objPos, 1)).xyz;
      ii.clipPos = UnityObjectToClipPos(objPos);
      tri_out.Append(ii);
    }
    tri_out.RestartStrip();
  }
}

#endif  // _CLONES

#endif  // __CLONES_INC

