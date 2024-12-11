#include "tone_iq.cginc"

#ifndef __TONE_INC
#define __TONE_INC

// This library contains a bunch of useful tonemapping curves.

// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
// cc0
float3 aces_filmic(float3 x) {
  float a = 2.51f;
  float b = 0.03f;
  float c = 2.43f;
  float d = 0.59f;
  float e = 0.14f;
  return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}

// Clamp x to [0, k].
// Assumes that x is already on [0, 1].
// Nice properties:
//  1. At x=0, the derivative is 1.
//  2. No transcendental ops, and branchless.

// This original attempt at a smooth minimum function has a problem:
//   f(x, k) = k * x / (x + k)
// As k -> inf, f(x, k) -> 1. We want f(x, k) -> k.
// Claude suggests this:
//  f(x, a, j) = j * (1 + a) * x / (1 + ax)
// At x=1:
//  f(1, a, j) = j * (1 + a) / (1 + a)
//             = j
// At infinity, we know that:
//  b * x / (x + b) -> 1
// So:
// f(x, a, j) = j * (1 + a) * x / (1 + ax)
//            = (j + ja) * x / (1 + ax)
//            = (jx + jax) / (1 + ax)
//            = jx / (1 + ax) + jax / (1 + ax)
//            = j (x / (1 + ax) + ax / (1 + ax))
// At infinity, this becomes:
//              j (1/a + 1)
// So if we want the limit to be k:
//  k       = j (1/a + 1)
//  k/j     = 1/a + 1
//  k/j - 1 = 1/a
//  a       = 1 / (k/j - 1)

// Smooth, analytic min function.
// Guarantees that x <= k for all positive x. At x=1, returns j.
// Caller must ensure that j < k.
float smooth_min(float x, float j, float k) {
  float a = 1 / (k / j - 1);
  return j * (1 + a) * x / (1 + a * x);
}
float3 smooth_min(float3 x, float j, float k) {
  float a = 1 / (k / j - 1);
  return j * (1 + a) * x / (1 + a * x);
}

float smooth_clamp(float x, float lo, float hi) {
  return smooth_max(smooth_min(x, (lo + (hi - lo)/2), hi), lo);
}

#endif  // __TONE_INC

