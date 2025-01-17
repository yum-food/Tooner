#include "globals.cginc"
#include "math.cginc"

#ifndef __TROCHOID_MATH
#define __TROCHOID_MATH

#if defined(_TROCHOID)

#define TROCH_POSITION_SCALE 0.1
#define TROCH_Z_THETA_SCALE 0.0002
#define TROCH_EPSILON 1e-5

float3 cyl2_to_troch_map(float3 v)
{
  const float R = _Trochoid_R;
  const float r = _Trochoid_r;
  const float d = _Trochoid_d;
  const float rrrr = (R - r) * R / r;

  float rr_gcd = gcd(round(R), round(r));
  float rr_lcm = (R * r) / rr_gcd;
  float rr_lcm_factor = rr_lcm / R;
  float toff = _Time[0] * _Trochoid_Speed;

  float x =
      cos(v.x * rr_lcm_factor * R + toff * 2.3 + toff) * v.y * (R - r) * TROCH_POSITION_SCALE +
      cos(v.x * rr_lcm_factor * rrrr - toff * 2.9 + toff) * v.y * d * TROCH_POSITION_SCALE;
  float y =
      sin(v.x * rr_lcm_factor * R - toff * 3.1 + toff) * v.y * (R - r) * TROCH_POSITION_SCALE -
      sin(v.x * rr_lcm_factor * rrrr + toff * 3.7 + toff) * v.y * d * TROCH_POSITION_SCALE;
  float z =
      (v.x * v.y * rr_lcm_factor * R * TROCH_Z_THETA_SCALE +
      cos(v.x * rr_lcm_factor * R * 5 + toff * 4.1 + toff) * v.y * TROCH_POSITION_SCALE +
      //v.y * v.z);
      v.z);

  return float3(x, y, z);
}

float3 cyl_to_cyl2_map(float3 v)
{
  return float3(v.x * .5, pow(v.y, _Trochoid_Radius_Power) * _Trochoid_Radius_Scale, v.z * _Trochoid_Height_Scale);
}

float3 cart_to_cyl_map(float3 v)
{
  return float3(atan2(v.y, v.x), length(v.xy), v.z);
}

float3 cart_to_troch_map(float3 v)
{
  return cyl2_to_troch_map(cyl_to_cyl2_map(cart_to_cyl_map(v)));
}

float3x3 cart_to_troch_jacobian(float3 v)
{
  float epsilon = 1e-5;
  float3 df_dx = (cart_to_troch_map(v + float3(epsilon, 0, 0)) - cart_to_troch_map(v - float3(epsilon, 0, 0))) / (2 * epsilon);
  float3 df_dy = (cart_to_troch_map(v + float3(0, epsilon, 0)) - cart_to_troch_map(v - float3(0, epsilon, 0))) / (2 * epsilon);
  float3 df_dz = (cart_to_troch_map(v + float3(0, 0, epsilon)) - cart_to_troch_map(v - float3(0, 0, epsilon))) / (2 * epsilon);
  return transpose(float3x3(df_dx, df_dy, df_dz));
}

// Compute partial derivatives of trochoid function with respect to cylindrical coordinates
float3x3 cyl2_to_troch_jacobian(float3 v)
{
  const float R = _Trochoid_R;
  const float r = _Trochoid_r;
  const float d = _Trochoid_d;
  const float rrrr = (R - r) * R / r;

  float rr_gcd = gcd(round(R), round(r));
  float rr_lcm = (R * r) / rr_gcd;
  float rr_lcm_factor = rr_lcm / R;
  float toff = _Time[0] * _Trochoid_Speed;

#if 1
  float3 df_dt = float3(
    -R * rr_lcm_factor * sin(v.x * rr_lcm_factor * R + toff * 2.3 + toff) * v.y * (R - r) * TROCH_POSITION_SCALE +
    -rrrr * rr_lcm_factor * sin(v.x * rr_lcm_factor * rrrr - toff * 2.9 + toff) * v.y * d * TROCH_POSITION_SCALE,

    R * rr_lcm_factor * cos(v.x * rr_lcm_factor * R - toff * 3.1 + toff) * v.y * (R - r) * TROCH_POSITION_SCALE -
    rrrr * rr_lcm_factor * cos(v.x * rr_lcm_factor * rrrr + toff * 3.7 + toff) * v.y * d * TROCH_POSITION_SCALE,

    v.y * R * TROCH_Z_THETA_SCALE -
    R * rr_lcm_factor *5 * sin(v.x * rr_lcm_factor * R * 5 + toff * 4.1 + toff) * v.y * TROCH_POSITION_SCALE);
#else
  float3 df_dt = (cyl2_to_troch_map(v + float3(TROCH_EPSILON, 0, 0)) - cyl2_to_troch_map(v - float3(TROCH_EPSILON, 0, 0))) / (2 * TROCH_EPSILON);
#endif

#if 1
  float3 df_dr = float3(
    ((R - r) * rr_lcm_factor * cos(v.x * rr_lcm_factor * R + toff * 2.3) + d * rr_lcm_factor * cos((R - r) * v.x * rr_lcm_factor * R / r + toff * 2.9)) * TROCH_POSITION_SCALE,
    ((R - r) * rr_lcm_factor * sin(v.x * rr_lcm_factor * R + toff * 3.1) - d * rr_lcm_factor * sin((R - r) * v.x * rr_lcm_factor * R / r + toff * 3.7)) * TROCH_POSITION_SCALE,
    rr_lcm_factor * cos(v.x * rr_lcm_factor * R * 5 + toff * 4.1) * TROCH_POSITION_SCALE);
#else
  float3 df_dr = (cyl2_to_troch_map(v + float3(0, TROCH_EPSILON, 0)) - cyl2_to_troch_map(v - float3(0, TROCH_EPSILON, 0))) / (2 * TROCH_EPSILON);
#endif

#if 1
  float3 df_dz = float3(
    0,
    0,
    1);
#else
  float3 df_dz = (cyl2_to_troch_map(v + float3(0, 0, TROCH_EPSILON)) - cyl2_to_troch_map(v - float3(0, 0, TROCH_EPSILON))) / (2 * TROCH_EPSILON);
#endif

  float3x3 jacobian_cyl;
  jacobian_cyl[0] = df_dt;
  jacobian_cyl[1] = df_dr;
  jacobian_cyl[2] = df_dz;
  return transpose(jacobian_cyl);
}

float3x3 cyl_to_cyl2_jacobian(float3 v)
{
  // f(x, y, z) = <x, (y^_Trochoid_Radiu1_Power) * _Trochoid_Radius_Scale, z * _Trochoid_Height_Scale>
#if 1
  float3 df_dx = float3(1, 0, 0);
  float3 df_dy = float3(0, _Trochoid_Radius_Power * pow(v.y, _Trochoid_Radius_Power - 1) * _Trochoid_Radius_Scale, 0);
  float3 df_dz = float3(0, 0, _Trochoid_Height_Scale);
#else
  float3 df_dx = (cyl_to_cyl2_map(v + float3(TROCH_EPSILON, 0, 0)) - cyl_to_cyl2_map(v - float3(TROCH_EPSILON, 0, 0))) / (2 * TROCH_EPSILON);
  float3 df_dy = (cyl_to_cyl2_map(v + float3(0, TROCH_EPSILON, 0)) - cyl_to_cyl2_map(v - float3(0, TROCH_EPSILON, 0))) / (2 * TROCH_EPSILON);
  float3 df_dz = (cyl_to_cyl2_map(v + float3(0, 0, TROCH_EPSILON)) - cyl_to_cyl2_map(v - float3(0, 0, TROCH_EPSILON))) / (2 * TROCH_EPSILON);
#endif
  float3x3 jacobian_cyl_to_cyl2;
  jacobian_cyl_to_cyl2[0] = df_dx;
  jacobian_cyl_to_cyl2[1] = df_dy;
  jacobian_cyl_to_cyl2[2] = df_dz;
  return transpose(jacobian_cyl_to_cyl2);
}

// Compute partial derivatives of transform from cartesian to cylindrical coordinates
float3x3 cart_to_cyl_jacobian(float3 v)
{
  // Compute partial derivatives of transform from cartesian to cylindrical coordinates
  // return float3(atan2(v.y, v.x), length(v.xy), v.z);
  // theta = atan2(y, x)
#if 1
  float3 dtheta_dcart = float3(
    -v.y / dot(v.xy, v.xy),
    v.x / dot(v.xy, v.xy),
    0);
#else
  float3 dtheta_dcart = (cart_to_cyl_map(v + float3(TROCH_EPSILON, 0, 0)) - cart_to_cyl_map(v - float3(TROCH_EPSILON, 0, 0))) / (2 * TROCH_EPSILON);
#endif

  // radius = (x^2 + y^2)^(1/2)
#if 1
  float3 dr_dcart = float3(
    v.x / sqrt(v.x * v.x + v.y * v.y),
    v.y / sqrt(v.x * v.x + v.y * v.y),
    0);
#else
  float3 dr_dcart = (cart_to_cyl_map(v + float3(0, TROCH_EPSILON, 0)) - cart_to_cyl_map(v - float3(0, TROCH_EPSILON, 0))) / (2 * TROCH_EPSILON);
#endif

#if 1
  float3 dz_dcart = float3(
    0,
    0,
    1);
#else
  float3 dz_dcart = (cart_to_cyl_map(v + float3(0, 0, TROCH_EPSILON)) - cart_to_cyl_map(v - float3(0, 0, TROCH_EPSILON))) / (2 * TROCH_EPSILON);
#endif
  float3x3 jacobian_cart_to_cyl;
  jacobian_cart_to_cyl[0] = dtheta_dcart;
  jacobian_cart_to_cyl[1] = dr_dcart;
  jacobian_cart_to_cyl[2] = dz_dcart;
  return transpose(jacobian_cart_to_cyl);
}

#endif  // _TROCHOID

#endif  // __TROCHOID_MATH
