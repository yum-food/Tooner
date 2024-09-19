#include "pema99.cginc"

#ifndef __MATH_INC
#define __MATH_INC

float4 qmul(float4 q1, float4 q2)
{
  return float4(
      q2.xyz * q1.w + q1.xyz * q2.w + cross(q1.xyz, q2.xyz),
      q1.w * q2.w - dot(q1.xyz, q2.xyz)
      );
}

// Vector rotation with a quaternion
// http://mathworld.wolfram.com/Quaternion.html
float3 rotate_vector(float3 v, float4 r)
{
  float4 r_c = r * float4(-1, -1, -1, 1);
  return qmul(r, qmul(float4(v, 0), r_c)).xyz;
}

float4 get_quaternion(float3 axis_normal, float theta) {
  return float4(
      axis_normal * sin(theta / 2), cos(theta / 2));
}

// Differentiable approximation of the standard `max` function.
float dmax(float a, float b, float k)
{
  return log2(exp2(k * a) + exp2(k * b)) / k;
}

// Differentiable approximation of the standard `min` function.
float dmin(float a, float b, float k)
{
  return -1.0 * dmax(-1.0 * a, -1.0 * b, k);
}

float dabs(float a, float k)
{
  return log2(exp2(k * a) + exp2(-1.0 * k * a));
}

float rand(uint seed) {
  seed = seed * 747796405 + 2891336453;
  uint result = ((seed >> ((seed >> 28) + 4)) ^ seed) * 277803737;
  result = (result >> 22) ^ result;
  return result / 4294967295.0;
}

// Generate a random number on [0, 1].
float rand2(float2 p)
{
  return frac(sin(dot(p,
          float2(12.9898, 78.233)))
      * 43758.5453123);
}

// Generate a random number on [0, 1].
float rand3(float3 p)
{
  return glsl_mod(sin(dot(p, float3(151.0, 157.0, 163.0))) * 997.0, 1.0);
}

float length2(float2 p)
{
  return p.x * p.x + p.y * p.y;
}

// 3 dimensional value noise. `p` is assumed to be a point inside a unit cube.
// Theory: https://en.wikipedia.org/wiki/Value_noise
float vnoise3d(float3 p)
{
  float3 pu = floor(p);
  float3 pv = glsl_mod(frac(p), 1.0);

  // Assign random numbers to the corner of a cube.
  float n000 = rand3(pu + float3(0,0,0));
  float n001 = rand3(pu + float3(0,0,1));
  float n010 = rand3(pu + float3(0,1,0));
  float n011 = rand3(pu + float3(0,1,1));
  float n100 = rand3(pu + float3(1,0,0));
  float n101 = rand3(pu + float3(1,0,1));
  float n110 = rand3(pu + float3(1,1,0));
  float n111 = rand3(pu + float3(1,1,1));

  float n00 = lerp(n000, n001, pv.z);
  float n01 = lerp(n010, n011, pv.z);
  float n10 = lerp(n100, n101, pv.z);
  float n11 = lerp(n110, n111, pv.z);

  float n0 = lerp(n00, n01, pv.y);
  float n1 = lerp(n10, n11, pv.y);
  
  float n = lerp(n0, n1, pv.x);

  return n;
}

float fbm(float3 p, const int n_octaves, float w)
{
  float g = exp2(-w);
  float a = 1.0;
  float p_scale = 1.0;

  float res = 0.0;
  for (int i = 0; i < n_octaves; i++) {
    res += a * vnoise3d(p * p_scale);

    p_scale /= w;
    a *= g;
  }
  return res;
}

#endif  // __MATH_INC

