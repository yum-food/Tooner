#include "interpolators.cginc"
#include "globals.cginc"
#include "math.cginc"

#ifndef __CLONES_INC
#define __CLONES_INC

#if defined(_CLONES)

void rotate_triangle(inout v2f tri_in[3], const float pid_rand, const float phase)
{
  if (phase < 1E-6) {
    return;
  }

  float3 avg_pos = (tri_in[0].worldPos + tri_in[1].worldPos + tri_in[2].worldPos) * .33333333;
  tri_in[0].worldPos -= avg_pos;
  tri_in[1].worldPos -= avg_pos;
  tri_in[2].worldPos -= avg_pos;

  if (phase > 1E-6) {
    float theta = phase * 3.14159 * 4 + phase * (sin(_Time[1] * (1 + pid_rand) * 0.5 + pid_rand) + cos(_Time[1] * (1 + pid_rand) * .16393442 + pid_rand) * 2) * pid_rand * 2;
    float3 axis = normalize(float3(
          rand((int) ((tri_in[0].uv0.x + tri_in[0].uv0.y + pid_rand) * 1E9)) * 2 - 1,
          rand((int) ((tri_in[1].uv0.x + tri_in[1].uv0.y + pid_rand) * 1E9)) * 2 - 1,
          rand((int) ((tri_in[2].uv0.x + tri_in[2].uv0.y + pid_rand) * 1E9)) * 2 - 1));
    float4 quat = get_quaternion(axis, theta);
    tri_in[0].worldPos = rotate_vector(tri_in[0].worldPos, quat);
    tri_in[1].worldPos = rotate_vector(tri_in[1].worldPos, quat);
    tri_in[2].worldPos = rotate_vector(tri_in[2].worldPos, quat);
  }

  tri_in[0].worldPos *= _Clones_Scale.xyz;
  tri_in[1].worldPos *= _Clones_Scale.xyz;
  tri_in[2].worldPos *= _Clones_Scale.xyz;

  tri_in[0].worldPos += avg_pos;
  tri_in[1].worldPos += avg_pos;
  tri_in[2].worldPos += avg_pos;

  float3 v0_objPos = mul(unity_WorldToObject, float4(tri_in[0].worldPos, 1));
  float3 v1_objPos = mul(unity_WorldToObject, float4(tri_in[1].worldPos, 1));
  float3 v2_objPos = mul(unity_WorldToObject, float4(tri_in[2].worldPos, 1));

  // Perf hack: Normal gets normalized in fragment shader anyway xdd
  // TODO add a toggle to normalize in fragment or not; and use it to gate this
  // optimization.
  float3 n = cross(tri_in[1].worldPos - tri_in[0].worldPos, tri_in[2].worldPos - tri_in[0].worldPos);
  tri_in[0].normal = n;
  tri_in[1].normal = n;
  tri_in[2].normal = n;

  tri_in[0].pos = UnityObjectToClipPos(v0_objPos);
  tri_in[1].pos = UnityObjectToClipPos(v1_objPos);
  tri_in[2].pos = UnityObjectToClipPos(v2_objPos);

  tri_in[0].objPos = v0_objPos;
  tri_in[1].objPos = v1_objPos;
  tri_in[2].objPos = v2_objPos;
}

void add_clones(in v2f clone_verts[3], inout TriangleStream<v2f> tri_out,
    float pid_rand, float explode_phase)
{
  if (_Clones_dx < 1E-6 &&
      _Clones_dy < 1E-6 &&
      _Clones_dz < 1E-6) {
    return;
  }

#if 0
  float factor = _Tess_Factor;
  if (_Clones_Dist_Cutoff > 0 && length(_WorldSpaceCameraPos - clone_verts[0].worldPos) > _Clones_Dist_Cutoff) {
    factor = 1;
  }
#endif

  uint n_clones = (uint) round(_Clones_Count);
  for (uint i = 0; i < (uint) n_clones; i++) {
    v2f mod_verts[3] = clone_verts;
    float3 offset = i;
    offset = ((offset % 2) * 2 - 1) * (((offset) * 0.5) + 1) *
      float3(_Clones_dx, _Clones_dy, _Clones_dz);
    for (uint j = 0; j < 3; j++) {
#if 0
      float3 objPos = mul(unity_WorldToObject, float4(mod_verts[j].worldPos, 1)).xyz;
      objPos += offset;
      mod_verts[j].worldPos = mul(unity_ObjectToWorld, float4(objPos, 1)).xyz;
#else
      mod_verts[j].worldPos += offset;
#endif
    }
#if 1
    rotate_triangle(mod_verts, rand(pid_rand+i), /*phase=*/1);
#else
    mod_verts[0].objPos = mul(unity_WorldToObject, float4(mod_verts[0].worldPos, 1));
    mod_verts[1].objPos = mul(unity_WorldToObject, float4(mod_verts[1].worldPos, 1));
    mod_verts[2].objPos = mul(unity_WorldToObject, float4(mod_verts[2].worldPos, 1));
    mod_verts[0].pos = UnityObjectToClipPos(mod_verts[0].objPos);
    mod_verts[1].pos = UnityObjectToClipPos(mod_verts[1].objPos);
    mod_verts[2].pos = UnityObjectToClipPos(mod_verts[2].objPos);
#endif
    tri_out.Append(mod_verts[0]);
    tri_out.Append(mod_verts[1]);
    tri_out.Append(mod_verts[2]);
    tri_out.RestartStrip();
  }
}

#endif  // _CLONES
#endif  // __CLONES_INC

