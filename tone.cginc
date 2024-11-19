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
float3 smooth_min(float3 x, float k) {
  // Derivation of `b` from `k`:
  //  f(x, b) = b * x / (x + b)
  //  We want f(1, b) = k.
  //  In other words, we want the max value the function can take on [0, 1] to
  //  be k.
  //   k = f(1, b)
  //     = b / (1 + b)
  //   b = k * (1 + b)
  //     = k + kb
  //   1 = k/b + k
  //   1 - k = k/b
  //   1/(1-k) = b/k
  //   b = k/(1-k)
  float e = 1E-4;
  k = min(1-e, k);
  float b = k/(1-k);
  return b * x / (x + b);
}
float smooth_min(float x, float k) {
  float e = 1E-4;
  k = min(1-e, k);
  float b = k/(1-k);
  return b * x / (x + b);
}
float smooth_clamp(float x, float lo, float hi) {
  return smooth_max(smooth_min(x, hi), lo);
}

#endif  // __TONE_INC

