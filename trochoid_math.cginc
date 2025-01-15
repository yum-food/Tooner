#include "globals.cginc"
#include "math.cginc"

#ifndef __TROCHOID_MATH
#define __TROCHOID_MATH

#if defined(_TROCHOID)

#define TROCH_POSITION_SCALE 0.1
#define TROCH_Z_THETA_SCALE 0.0002
#define TROCH_EPSILON 1e-5

float3 cyl2_to_troch_map(float3 pos)
{
  float theta = pos.x;

  float R = _Trochoid_R;
  float r = _Trochoid_r;
  float d = _Trochoid_d;

  float x = ((R - r) * cos(theta * R) + d * cos((R - r) * theta * R / r)) * pos.y * TROCH_POSITION_SCALE;
  float y = ((R - r) * sin(theta * R) - d * sin((R - r) * theta * R / r)) * pos.y * TROCH_POSITION_SCALE;
  float z = (pos.z + cos(theta * R * 5) * TROCH_POSITION_SCALE + theta * R * TROCH_Z_THETA_SCALE) * pos.y;

  return float3(x, y, z);
}

float3 cyl_to_cyl2_map(float3 v)
{
  return float3(v.x, pow(v.y, _Trochoid_Radius_Power) * _Trochoid_Radius_Scale, v.z * _Trochoid_Height_Scale);
}

float3 cart_to_cyl_map(float3 v)
{
  return float3(atan2(v.y, v.x), length(v.xy), v.z);
}

// Compute partial derivatives of trochoid function with respect to cylindrical coordinates
float3x3 cyl2_to_troch_jacobian(float3 pos)
{
  float theta = pos.x;

  float R = _Trochoid_R;
  float r = _Trochoid_r;
  float d = _Trochoid_d;

#if 1
  float3 df_dt = float3(
    ((R * (r - R) *  (d * sin(R * theta * (R - r) / r) + r * sin(R * theta))) / r) * pos.y * TROCH_POSITION_SCALE,
    ((R * (r - R) * (-d * cos(R * theta * (R - r) / r) + r * cos(R * theta))) / r) * pos.y * TROCH_POSITION_SCALE,
    (-R * 5 * sin(theta * R * 5) * TROCH_POSITION_SCALE + R * TROCH_Z_THETA_SCALE) * pos.y);
  float3 df_dr = float3(
    ((R - r) * cos(theta * R) + d * cos((R - r) * theta * R / r)) * TROCH_POSITION_SCALE,
    ((R - r) * sin(theta * R) - d * sin((R - r) * theta * R / r)) * TROCH_POSITION_SCALE,
    (pos.z + cos(theta * R * 5) * TROCH_POSITION_SCALE + theta * R * TROCH_Z_THETA_SCALE));
  float3 df_dz = float3(
    0,
    0,
    pos.y);
#else
  float3 df_dt = (cyl2_to_troch_map(pos + float3(TROCH_EPSILON, 0, 0)) - cyl2_to_troch_map(pos - float3(TROCH_EPSILON, 0, 0))) / (2 * TROCH_EPSILON);
  float3 df_dr = (cyl2_to_troch_map(pos + float3(0, TROCH_EPSILON, 0)) - cyl2_to_troch_map(pos - float3(0, TROCH_EPSILON, 0))) / (2 * TROCH_EPSILON);
  float3 df_dz = (cyl2_to_troch_map(pos + float3(0, 0, TROCH_EPSILON)) - cyl2_to_troch_map(pos - float3(0, 0, TROCH_EPSILON))) / (2 * TROCH_EPSILON);
#endif
  float3x3 jacobian_cyl;
  jacobian_cyl[0] = df_dt;
  jacobian_cyl[1] = df_dr;
  jacobian_cyl[2] = df_dz;
  return transpose(jacobian_cyl);
}

float3x3 cyl_to_cyl2_jacobian(float3 pos)
{
  // f(x, y, z) = <x, (y^_Trochoid_Radius_Power) * _Trochoid_Radius_Scale, z * _Trochoid_Height_Scale>
#if 1
  float3 df_dx = float3(1, 0, 0);
  float3 df_dy = float3(0, _Trochoid_Radius_Power * pow(pos.y, _Trochoid_Radius_Power - 1) * _Trochoid_Radius_Scale, 0);
  float3 df_dz = float3(0, 0, _Trochoid_Height_Scale);
#else
  float3 df_dx = (cyl_to_cyl2_map(pos + float3(TROCH_EPSILON, 0, 0)) - cyl_to_cyl2_map(pos - float3(TROCH_EPSILON, 0, 0))) / (2 * TROCH_EPSILON);
  float3 df_dy = (cyl_to_cyl2_map(pos + float3(0, TROCH_EPSILON, 0)) - cyl_to_cyl2_map(pos - float3(0, TROCH_EPSILON, 0))) / (2 * TROCH_EPSILON);
  float3 df_dz = (cyl_to_cyl2_map(pos + float3(0, 0, TROCH_EPSILON)) - cyl_to_cyl2_map(pos - float3(0, 0, TROCH_EPSILON))) / (2 * TROCH_EPSILON);
#endif
  float3x3 jacobian_cyl_to_cyl2;
  jacobian_cyl_to_cyl2[0] = df_dx;
  jacobian_cyl_to_cyl2[1] = df_dy;
  jacobian_cyl_to_cyl2[2] = df_dz;
  return transpose(jacobian_cyl_to_cyl2);
}

// Compute partial derivatives of transform from cartesian to cylindrical coordinates
float3x3 cart_to_cyl_jacobian(float3 pos)
{
  // Compute partial derivatives of transform from cartesian to cylindrical coordinates
  // return float3(atan2(v.y, v.x), length(v.xy), v.z);
  // theta = atan2(y, x)
#if 1
  float3 dtheta_dcart = float3(
    -pos.y / dot(pos.xy, pos.xy),
    pos.x / dot(pos.xy, pos.xy),
    0);
#else
  float3 dtheta_dcart = (cart_to_cyl_map(pos + float3(TROCH_EPSILON, 0, 0)) - cart_to_cyl_map(pos - float3(TROCH_EPSILON, 0, 0))) / (2 * TROCH_EPSILON);
#endif

  // radius = (x^2 + y^2)^(1/2)
#if 1
  float3 dr_dcart = float3(
    pos.x / sqrt(pos.x * pos.x + pos.y * pos.y),
    pos.y / sqrt(pos.x * pos.x + pos.y * pos.y),
    0);
#else
  float3 dr_dcart = (cart_to_cyl_map(pos + float3(0, TROCH_EPSILON, 0)) - cart_to_cyl_map(pos - float3(0, TROCH_EPSILON, 0))) / (2 * TROCH_EPSILON);
#endif

#if 1
  float3 dz_dcart = float3(
    0,
    0,
    1);
#else
  float3 dz_dcart = (cart_to_cyl_map(pos + float3(0, 0, TROCH_EPSILON)) - cart_to_cyl_map(pos - float3(0, 0, TROCH_EPSILON))) / (2 * TROCH_EPSILON);
#endif
  float3x3 jacobian_cart_to_cyl;
  jacobian_cart_to_cyl[0] = dtheta_dcart;
  jacobian_cart_to_cyl[1] = dr_dcart;
  jacobian_cart_to_cyl[2] = dz_dcart;
  return transpose(jacobian_cart_to_cyl);
}

float3x3 invert(float3x3 m)
{
  float det = m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1])
            - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
            + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);

  float3x3 adj;
  adj[0][0] =  (m[1][1] * m[2][2] - m[1][2] * m[2][1]);
  adj[0][1] = -(m[0][1] * m[2][2] - m[0][2] * m[2][1]);
  adj[0][2] =  (m[0][1] * m[1][2] - m[0][2] * m[1][1]);
  
  adj[1][0] = -(m[1][0] * m[2][2] - m[1][2] * m[2][0]);
  adj[1][1] =  (m[0][0] * m[2][2] - m[0][2] * m[2][0]);
  adj[1][2] = -(m[0][0] * m[1][2] - m[0][2] * m[1][0]);
  
  adj[2][0] =  (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
  adj[2][1] = -(m[0][0] * m[2][1] - m[0][1] * m[2][0]);
  adj[2][2] =  (m[0][0] * m[1][1] - m[0][1] * m[1][0]);

  return adj * (1.0 / det);
}

#endif  // _TROCHOID

#endif  // __TROCHOID_MATH


