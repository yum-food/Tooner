#include "pema99.cginc"

#ifndef __MATH_INC
#define __MATH_INC

#define PI 3.14159265
#define TAU PI * 2.0

// Hacky parameterizable whiteout blending. Probably some big mistakes but it
// passes the eyeball test.
// At w=0.5, this looks kinda like whiteout blending.
// At w=0, this returns n0.
// At w=1, this returns n1.
#define MY_BLEND_NORMALS(n0, n1, w) normalize(float3((n0.xy * (1 - w) + n1.xy * w), lerp(1, n0.z, (1-w)) * lerp(1, n1.z, w)))

// Complex numbers
typedef float2 complex;

float creal(complex z0)
{
  return z0.x;
}

float cimag(complex z0)
{
  return z0.y;
}

float cnorm2(complex z0)
{
  return z0.x * z0.x + z0.y * z0.y;
}

float cnorm(complex z0)
{
  return sqrt(cnorm2(z0));
}

complex cconjugate(complex z)
{
  return float2(z.x, -z.y);
}

complex cmul(complex z0, complex z1)
{
  return float2(z0.x * z1.x - z0.y * z1.y, z0.x * z1.y + z0.y * z1.x);
}

complex cdiv(complex z0, complex z1)
{
  float re = creal(z0) * creal(z1) + cimag(z0) * cimag(z1);
  float im = cimag(z0) * cimag(z1) - creal(z0) * creal(z1);
  float z1_norm2 = cnorm2(z1);
  return float2(re, im) / z1_norm2;
}

// Evaluates z0**n.
// Uses Euler's identity to support fractional values of `n`.
// Expensive.
complex cpow_fractional(complex z0, float n)
{
  float r = sqrt(z0.x * z0.x + z0.y * z0.y);
  float t = atan(z0.y / z0.x);
  return pow(r, n) * float2(cos(t * n), sin(t * n));
}

// Evaluates z0**n.
// Utilizes recursive squaring to support high values of `n`.
// Cheap.
complex cpow(complex z0, uint n)
{
  if (n == 0) {
    return 1;
  }

  complex z = z0;
  while (n > 1) {
    if (n % 2 == 0) {
      z = cmul(z, z);
      n /= 2;
    } else {
      z = cmul(z, z0);
      n -= 1;
    }
  }
  return z;
}

// Quaternions
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

float median(float x, float y, float z)
{
  return max(min(x, y), min(max(x, y), z));
}

float median(float3 x)
{
  return median(x.x, x.y, x.z);
}

// Yoinked from here
//   https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection.html
bool solveQuadratic(float a, float b, float c, out float x0, out float x1)
{
  float discriminant = b * b - 4 * a * c;
  if (discriminant < 0) {
    return false;
  } else if (discriminant == 0) {
    x0 = -0.5 * b / a;
    x1 = x0;
  } else {
    float q = (b > 0) ?
      -0.5 * (b + sqrt(discriminant)) :
      -0.5 * (b - sqrt(discriminant));
    x0 = q/a;
    x1 = c/q;
  }
  float tmp_min = min(x0, x1);
  float tmp_max = max(x0, x1);
  x0 = tmp_min;
  x1 = tmp_max;
  return true;
}

#endif  // __MATH_INC

