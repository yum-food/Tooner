#include "pema99.cginc"

#ifndef __MATH_INC
#define __MATH_INC

#define PI 3.14159265
#define TAU PI * 2.0
#define PHI 1.618033989

static const float BayerM4x4[16] = {
    0.0/15.0,   8.0/15.0,   2.0/15.0,   10.0/15.0,
    12.0/15.0,  4.0/15.0,   14.0/15.0,  6.0/15.0,
    3.0/15.0,   11.0/15.0,  1.0/15.0,   9.0/15.0,
    15.0/15.0,  7.0/15.0,   13.0/15.0,  5.0/15.0
};

// xdd
static const float BayerM8x8[64] = {
    0.0/63.0, 32.0/63.0,  8.0/63.0, 40.0/63.0,  2.0/63.0, 34.0/63.0, 10.0/63.0, 42.0/63.0,
   48.0/63.0, 16.0/63.0, 56.0/63.0, 24.0/63.0, 50.0/63.0, 18.0/63.0, 58.0/63.0, 26.0/63.0,
   12.0/63.0, 44.0/63.0,  4.0/63.0, 36.0/63.0, 14.0/63.0, 46.0/63.0,  6.0/63.0, 38.0/63.0,
   60.0/63.0, 28.0/63.0, 52.0/63.0, 20.0/63.0, 62.0/63.0, 30.0/63.0, 54.0/63.0, 22.0/63.0,
    3.0/63.0, 35.0/63.0, 11.0/63.0, 43.0/63.0,  1.0/63.0, 33.0/63.0,  9.0/63.0, 41.0/63.0,
   51.0/63.0, 19.0/63.0, 59.0/63.0, 27.0/63.0, 49.0/63.0, 17.0/63.0, 57.0/63.0, 25.0/63.0,
   15.0/63.0, 47.0/63.0,  7.0/63.0, 39.0/63.0, 13.0/63.0, 45.0/63.0,  5.0/63.0, 37.0/63.0,
   63.0/63.0, 31.0/63.0, 55.0/63.0, 23.0/63.0, 61.0/63.0, 29.0/63.0, 53.0/63.0, 21.0/63.0
};

// Hacky parameterizable whiteout blending. Probably some big mistakes but it
// passes the eyeball test.
// At w=0.5, this looks kinda like whiteout blending.
// At w=0, this returns n0.
// At w=1, this returns n1.
#define MY_BLEND_NORMALS(n0, n1, w) normalize(float3((n0.xy * (1 - w) + n1.xy * w), lerp(1, n0.z, (1-w)) * lerp(1, n1.z, w)))

float golden_lds(uint i)
{
  return glsl_mod(1.61803398875 * float(i), 1);
}

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

float dsaturate(float x, float k)
{
  return dmin(dmax(x, 0, k), 1, k);
}

float dclamp(float x, float lo, float hi, float k)
{
  return dmin(dmax(x, lo, k), hi, k);
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

float determinant(float3x3 m)
{
  return (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1])
            - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]))
            + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
}

float3x3 invert(float3x3 m)
{
  float det = determinant(m);

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

// Return largest number which divides into both 'a' and 'b'.
// Uses the Euclidean algorithm: repeatedly divide larger by smaller number.
uint gcd(uint a, uint b)
{
    #define GCD_MAX_ITER 24
    for (uint i = 0; i < GCD_MAX_ITER; i++) {
        if (b == 0) {
            return a;
        }
        a = a % b;
        // Swap a and b
        uint tmp = a;
        a = b;
        b = tmp;
    }
    return 1;
}

float wrapNoL(float NoL, float factor) {
    // Apply wrapped lighting correction
		// https://www.iro.umontreal.ca/~derek/files/jgt_wrap_final.pdf
    //float4 wrapped = (NoL + 1) * (NoL + 1) * .25;
    return pow(max(1E-4, (NoL + factor) / (1 + factor)), 1 + factor);
}

#endif  // __MATH_INC

