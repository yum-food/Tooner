#ifndef MOCHIE_STANDARD_SSR_INCLUDED
#define MOCHIE_STANDARD_SSR_INCLUDED

/*
 * MIT License
 *
 * Copyright (c) 2020 MochiesCode
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE
 * SOFTWARE.
 */

//-----------------------------------------------------------------------------------
// SCREEN SPACE REFLECTIONS
// 
// Original made by error.mdl, Toocanzs, and Xiexe.
// Reworked and updated by Mochie
//-----------------------------------------------------------------------------------

#if SSR_ENABLED

bool IsInMirror(){
  return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}

float3 GetBlurredGP(const sampler2D ssrg, const float2 texelSize, const float2 uvs, const float dim){
	float2 pixSize = 2/texelSize;
	float dimFloored = floor(dim);
	float center = floor(dim*0.5);
	float3 refTotal = float3(0,0,0);
	for (int i = 0; i < dimFloored; i++){
		for (int j = 0; j < dimFloored; j++){
			float4 refl = tex2Dlod(ssrg, float4(uvs.x + pixSize.x*(i-center), uvs.y + pixSize.y*(j-center),0,0));
			refTotal += refl.rgb;
		}
	}
	return refTotal/(dimFloored*dimFloored);
}

float4 ReflectRay(float3 reflectedRay, float3 rayDir, float _LRad, float _SRad, float _Step, float noise, const int maxIterations){

	#if UNITY_SINGLE_PASS_STEREO || defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
		half x_min = 0.5*unity_StereoEyeIndex;
		half x_max = 0.5 + 0.5*unity_StereoEyeIndex;
	#else
		half x_min = 0.0;
		half x_max = 1.0;
	#endif
	
	reflectedRay = mul(UNITY_MATRIX_V, float4(reflectedRay, 1));
	rayDir = mul(UNITY_MATRIX_V, float4(rayDir, 0));
	int totalIterations = 0;
	int direction = 1;
	float3 finalPos = 0;
	float step = _Step;
	float lRad = _LRad;
	float sRad = _SRad;

	for (int i = 0; i < maxIterations; i++){
		totalIterations = i;
		float4 spos = ComputeGrabScreenPos(mul(UNITY_MATRIX_P, float4(reflectedRay, 1)));
		float2 uvDepth = spos.xy / spos.w;
		UNITY_BRANCH
		if (uvDepth.x > x_max || uvDepth.x < x_min || uvDepth.y > 1 || uvDepth.y < 0){
			break;
		}

		float rawDepth = DecodeFloatRG(SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture,float4(uvDepth,0,0)));
		float linearDepth = Linear01Depth(rawDepth);
		float sampleDepth = -reflectedRay.z;
		float realDepth = linearDepth * _ProjectionParams.z;
		float depthDifference = abs(sampleDepth - realDepth);

		if (depthDifference < lRad){ 
			if (direction == 1){
				if(sampleDepth > (realDepth - sRad)){
					if(sampleDepth < (realDepth + sRad)){
						finalPos = reflectedRay;
						break;
					}
					direction = -1;
					step = step*0.1;
				}
			}
			else {
				if(sampleDepth < (realDepth + sRad)){
					direction = 1;
					step = step*0.1;
				}
			}
		}
		reflectedRay = reflectedRay + direction*step*rayDir;
		step += step*(0.025 + 0.005*noise);
		lRad += lRad*(0.025 + 0.005*noise);
		sRad += sRad*(0.025 + 0.005*noise);
	}
	return float4(finalPos, totalIterations);
}

float4 GetSSR(const float3 wPos, const float3 viewDir, float3 rayDir, const half3 faceNormal, float smoothness, float3 albedo, float metallic, float2 screenUVs, float4 screenPos){
	
	float FdotR = dot(faceNormal, rayDir.xyz);
	float roughness = 1-smoothness;

	UNITY_BRANCH
	if (IsInMirror() || FdotR < 0 || roughness > 0.65){
		return 0;
	}
	else {
		float4 noiseUvs = screenPos;
		noiseUvs.xy = (noiseUvs.xy * _GrabTexture_TexelSize.zw) / (_NoiseTexSSR_TexelSize.zw * noiseUvs.w);	
		float4 noiseRGBA = tex2Dlod(_NoiseTexSSR, float4(noiseUvs.xy,0,0));
		float noise = noiseRGBA.r;
		
		float3 reflectedRay = wPos + (_SSRHeight*_SSRHeight/FdotR + noise*_SSRHeight)*rayDir;
		float4 finalPos = ReflectRay(reflectedRay, rayDir, _SSRHeight, 0.02, _SSRHeight, noise, 50);
		float totalSteps = finalPos.w;
		finalPos.w = 1;
		
		if (!any(finalPos.xyz)){
			return 0;
		}
		
		float4 uvs = UNITY_PROJ_COORD(ComputeGrabScreenPos(mul(UNITY_MATRIX_P, finalPos)));
		uvs.xy = uvs.xy / uvs.w;

		#if UNITY_SINGLE_PASS_STEREO || defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
			float xfade = 1;
		#else
			float xfade = smoothstep(0, _EdgeFade, uvs.x) * smoothstep(1, 1-_EdgeFade, uvs.x); //Fade x uvs out towards the edges
		#endif
		float yfade = smoothstep(0, _EdgeFade, uvs.y)*smoothstep(1, 1-_EdgeFade, uvs.y); //Same for y
		// float lengthFade = smoothstep(1, 0, 2*(totalSteps / 50)-1);
		float smoothFade = smoothstep(0.65, 0.5, 1-smoothness);
		float reflectionAlpha = xfade * yfade * smoothFade; // * lengthFade;


		float4 reflection = 0;
		if (reflectionAlpha > 0){
			float blurFac = max(1,min(12, 12 * (-2)*(smoothness-1)));
			// if (blurFac > 1){
				reflection.rgb = GetBlurredGP(_GrabTexture, _GrabTexture_TexelSize.zw, uvs.xy, blurFac);
			// }
			// else {
			// 	reflection.rgb = tex2Dlod(_GrabTexture, float4(uvs.xy,0,0)).rgb;
			// }
			reflection.rgb = lerp(reflection.rgb, reflection.rgb*albedo.rgb,smoothstep(0, 1.75, metallic));
			reflection.a = reflectionAlpha;
		}

		return max(0,reflection);
	}	
}

#endif

#endif // MOCHIE_STANDARD_SSR_INCLUDED
