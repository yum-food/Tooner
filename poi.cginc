#ifndef __POI_INC
#define __POI_INC

/*
MIT License

Copyright (c) 2023 Poiyomi Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

static const float Epsilon = 1e-10;
float3 RGBtoHCV(in float3 RGB)
{
  // Based on work by Sam Hocevar and Emil Persson
  float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0 / 3.0) : float4(RGB.gb, 0.0, -1.0 / 3.0);
  float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
  float C = Q.x - min(Q.w, Q.y);
  float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
  return float3(H, C, Q.x);
}

float3 RGBtoHSV(in float3 RGB)
{
  float3 HCV = RGBtoHCV(RGB);
  float S = HCV.y / (HCV.z + Epsilon);
  return float3(HCV.x, S, HCV.z);
}

float3 HUEtoRGB(in float H)
{
  float R = abs(H * 6 - 3) - 1;
  float G = 2 - abs(H * 6 - 2);
  float B = 2 - abs(H * 6 - 4);
  return saturate(float3(R, G, B));
}

float3 HSVtoRGB(in float3 HSV)
{
  float3 RGB = HUEtoRGB(HSV.x);
  return ((RGB - 1) * HSV.y + 1) * HSV.z;
}

float shEvaluateDiffuseL1Geomerics_local(float L0, float3 L1, float3 n)
{
  // average energy
  float R0 = max(0, L0);

  // avg direction of incoming light
  float3 R1 = 0.5f * L1;

  // directional brightness
  float lenR1 = length(R1);

  // linear angle between normal and direction 0-1
  //float q = 0.5f * (1.0f + dot(R1 / lenR1, n));
  //float q = dot(R1 / lenR1, n) * 0.5 + 0.5;
  float q = dot(normalize(R1), n) * 0.5 + 0.5;
  q = saturate(q); // Thanks to ScruffyRuffles for the bug identity.

  // power for q
  // lerps from 1 (linear) to 3 (cubic) based on directionality
  float p = 1.0f + 2.0f * lenR1 / R0;

  // dynamic range constant
  // should vary between 4 (highly directional) and 0 (ambient)
  float a = (1.0f - lenR1 / R0) / (1.0f + lenR1 / R0);

  return R0 * (a + (1.0f - a) * (p + 1.0f) * pow(q, p));
}

half3 BetterSH9(half4 normal)
{
  float3 indirect;
  float3 L0 = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) + float3(unity_SHBr.z, unity_SHBg.z, unity_SHBb.z) / 3.0;
  indirect.r = shEvaluateDiffuseL1Geomerics_local(L0.r, unity_SHAr.xyz, normal.xyz);
  indirect.g = shEvaluateDiffuseL1Geomerics_local(L0.g, unity_SHAg.xyz, normal.xyz);
  indirect.b = shEvaluateDiffuseL1Geomerics_local(L0.b, unity_SHAb.xyz, normal.xyz);
  indirect = max(0, indirect);
  indirect += SHEvalLinearL2(normal);
  return indirect;
}

float calculateluminance(float3 color)
{
  return color.r * 0.299 + color.g * 0.587 + color.b * 0.114;
}

float3 getPoiLightingDirect(float3 normal) {
  float3 magic = max(BetterSH9(normalize(unity_SHAr + unity_SHAg + unity_SHAb)), 0);
  float3 normalLight = _LightColor0.rgb + BetterSH9(float4(0, 0, 0, 1));

  float magiLumi = calculateluminance(magic);
  float normaLumi = calculateluminance(normalLight);
  float maginormalumi = magiLumi + normaLumi;

  float magiratio = magiLumi / maginormalumi;
  float normaRatio = normaLumi / maginormalumi;

  float target = calculateluminance(magic * magiratio + normalLight * normaRatio);
  float3 properLightColor = magic + normalLight;
  float properLuminance = calculateluminance(magic + normalLight);
  return properLightColor * max(0.0001, (target / properLuminance));
}

float3 getPoiLightingIndirect() {
  return BetterSH9(float4(0, 0, 0, 1));
}

inline half Dither8x8Bayer(int x, int y)
{
  // Premultiplied by 1/64
  const half dither[ 64 ] = {
    0.015625, 0.765625, 0.203125, 0.953125, 0.06250, 0.81250, 0.25000, 1.00000,
    0.515625, 0.265625, 0.703125, 0.453125, 0.56250, 0.31250, 0.75000, 0.50000,
    0.140625, 0.890625, 0.078125, 0.828125, 0.18750, 0.93750, 0.12500, 0.87500,
    0.640625, 0.390625, 0.578125, 0.328125, 0.68750, 0.43750, 0.62500, 0.37500,
    0.046875, 0.796875, 0.234375, 0.984375, 0.03125, 0.78125, 0.21875, 0.96875,
    0.546875, 0.296875, 0.734375, 0.484375, 0.53125, 0.28125, 0.71875, 0.46875,
    0.171875, 0.921875, 0.109375, 0.859375, 0.15625, 0.90625, 0.09375, 0.84375,
    0.671875, 0.421875, 0.609375, 0.359375, 0.65625, 0.40625, 0.59375, 0.34375
  };
  int r = y * 8 + x;
  return dither[r];
}

half calcDither(half2 grabPos)
{
  return Dither8x8Bayer(glsl_mod(grabPos.x, 8), glsl_mod(grabPos.y, 8));
}


#endif  // __POI_INC
