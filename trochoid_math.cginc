#include "globals.cginc"
#include "math.cginc"

#ifndef __TROCHOID_MATH
#define __TROCHOID_MATH

#if defined(_TROCHOID)

float3 trochoid_map(float theta, float r0, float3 vert_z)
{
  r0 *= r0;
  r0 *= 100;

  float R = _Trochoid_R;
  float r = _Trochoid_r;
  float d = _Trochoid_d;

  theta *= max(R, r);
  float theta_t = theta + _Time[2];

  float x = (R - r) * cos(theta_t) + d * cos((R - r) * theta_t / r);
  float y = (R - r) * sin(theta_t) - d * sin((R - r) * theta_t / r);
  float z = vert_z + cos(theta_t * 5) * .1 + theta * .0002;

  float3 result = float3(x, y, z) * r0;
  result.xy *= 0.1;
  return result;
}

float trochoid_normal(float3 objPos, float2 uv)
{
  float theta = uv.x * TAU;
  float r0 = length(objPos.xyz);

  float x = objPos.x;
  float y = objPos.y;
  float z = objPos.z;

  float e = 5E-2;
  float small_step = 1E-2 * e;
  float du_dt = (trochoid_map(theta + small_step, r0, z) - trochoid_map(theta - small_step, r0, z)) / small_step;
  small_step = 1E-4 * e;
  float du_dr = (trochoid_map(theta, r0 + small_step, z) - trochoid_map(theta, r0 - small_step, z)) / small_step;
  small_step = 1E-5 * e;
  float du_dz = (trochoid_map(theta, r0, z + small_step) - trochoid_map(theta, r0, z - small_step)) / small_step;

  // U(T(x, y, z), R(x, y, z), Z(x, y, z))
  // T(x, y, z) = atan2(y, x)
  // R(x, y, z) = length(float3(x, y, z))
  // Z(x, y, z) = z
  // U(a, b, c) = trochoid_map(a, b, c)
  // dU/dx = dU/dT dT/dx + dU/dR dR/dx + dU/dZ dZ/dx
  // dU/dy = dU/dT dT/dy + dU/dR dR/dy + dU/dZ dZ/dy
  // dU/dz = dU/dT dT/dz + dU/dR dR/dz + dU/dZ dZ/dz
  // dT/dx = d/dx atan2(y, x) = -y / (x**2 + y**2)
  // dT/dy = d/dx atan2(y, x) = x / (x**2 + y**2)
  // dT/dz = d/dz atan2(y, x) = 0
  // dR/dx = d/dx sqrt(x**2 + y**2 + z**2) = x / sqrt(x**2 + y**2 + z**2)
  // dR/dy = d/dy sqrt(x**2 + y**2 + z**2) = y / sqrt(x**2 + y**2 + z**2)
  // dR/dz = d/dy sqrt(x**2 + y**2 + z**2) = z / sqrt(x**2 + y**2 + z**2)
  // dZ/dx = 0
  // dZ/dy = 0
  // dZ/dz = 1
  float xy_norm = sqrt(x * x + y * y);
  float dt_dx = -y / xy_norm;
  float dt_dy = x / xy_norm;
  float dt_dz = 0;
  float xyz_norm = sqrt(x * x + y * y + z * z);
  float dr_dx = x / xyz_norm;
  float dr_dy = y / xyz_norm;
  float dr_dz = z / xyz_norm;
  float dz_dx = 0;
  float dz_dy = 0;
  float dz_dz = 1;

  float3 normal =
    normalize(
        float3(
          du_dt * dt_dx + du_dr * dr_dx + du_dz * dz_dx,
          du_dt * dt_dy + du_dr * dr_dy + du_dz * dz_dy,
          du_dt * dt_dz + du_dr * dr_dz + du_dz * dz_dz));
  return UnityObjectToWorldNormal(normal);
}

#endif  // _TROCHOID

#endif  // __TROCHOID_MATH

