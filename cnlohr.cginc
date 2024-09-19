#include "globals.cginc"

#ifndef __CNLOHR_INC
#define __CNLOHR_INC

/*
 * MIT License
 *
 * NOTE: Much content here is originally from others.  Content in third party
 * folder may not be fully MIT-licensable. 
 *
 * Copyright (c) 2021 cnlohr, et. al.
 *
 * All other content in this repository falls under the following terms:
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

// Source:
// https://github.com/cnlohr/shadertrixx?tab=readme-ov-file#eye-center-position
bool isMirror() { return _VRChatMirrorMode != 0; }

// Source:
// https://github.com/cnlohr/shadertrixx?tab=readme-ov-file#eye-center-position
float3 getCenterCamPos() {
#if defined(USING_STEREO_MATRICES)
  return (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]) / 2;
#else
  return isMirror() ? _VRChatMirrorCameraPos : _WorldSpaceCameraPos.xyz;
#endif
}

#endif  // __CNLOHR_INC
