#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"

#include "audiolink.cginc"
#include "aurora.cginc"
#include "clones.cginc"
#include "cnlohr.cginc"
#include "disinfo.cginc"
#include "downstairs_02.cginc"
#include "eyes.cginc"
#include "fog.cginc"
#include "gerstner.cginc"
#include "globals.cginc"
#include "halos.cginc"
#include "interpolators.cginc"
#include "iq_sdf.cginc"
#include "macros.cginc"
#include "math.cginc"
#include "motion.cginc"
#include "oklab.cginc"
#include "pbr.cginc"
#include "pbr_overlay.cginc"
#include "poi.cginc"
#include "shear_math.cginc"
#include "tone.cginc"
#include "tooner_scroll.cginc"
#include "trochoid_math.cginc"

#ifndef TOONER_LIGHTING
#define TOONER_LIGHTING

float3 Shade4PointLightsWrapped(
    float4 lightPosX, float4 lightPosY, float4 lightPosZ,
    float3 lightColor0, float3 lightColor1, float3 lightColor2, float3 lightColor3,
    float4 lightAttenSq,
    float3 pos, float3 normal,
    float wrapFactor)
{
    // Compute the difference between the vertex position and light positions
    float4 toLightX = lightPosX - pos.x;
    float4 toLightY = lightPosY - pos.y;
    float4 toLightZ = lightPosZ - pos.z;

    float4 lengthSq = 0;
    lengthSq += toLightX * toLightX;
    lengthSq += toLightY * toLightY;
    lengthSq += toLightZ * toLightZ;

    float4 ndotl = 0;
    ndotl += toLightX * normal.x;
    ndotl += toLightY * normal.y;
    ndotl += toLightZ * normal.z;
    
    // Apply wrapped lighting correction
		// https://www.iro.umontreal.ca/~derek/files/jgt_wrap_final.pdf
    //float4 wrapped = (ndotl + 1) * (ndotl + 1) * .25;
    float4 wrapped = pow(max(1E-4, (ndotl + wrapFactor) / (1 + wrapFactor)), 1 + wrapFactor);
    //float4 wrapped = pow((ndotl + 1) / (2), 2);
    float4 corr = rsqrt(lengthSq);
    ndotl = max(0, wrapped) * corr;

    // Compute attenuation
    float4 atten = 1.0 / (1.0 + lengthSq * lightAttenSq);
    float4 diff = ndotl * atten;

    // Compute final color
    return diff.x * lightColor0 +
      diff.y * lightColor1 +
      diff.z * lightColor2 +
      diff.w * lightColor3;
}

void getVertexLightColor(inout v2f i)
{
  #if defined(VERTEXLIGHT_ON)
  float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
  uint normals_mode = round(_Mesh_Normals_Mode);
  bool flat = (normals_mode == 0);
  float3 flat_normal = normalize(
    (1.0 / _Flatten_Mesh_Normals_Str) * i.normal +
    _Flatten_Mesh_Normals_Str * view_dir);
  i.vertexLightColor = Shade4PointLightsWrapped(
    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
    unity_LightColor[0].rgb,
    unity_LightColor[1].rgb,
    unity_LightColor[2].rgb,
    unity_LightColor[3].rgb,
    unity_4LightAtten0, i.worldPos, flat ? flat_normal : i.normal,
		1
  );
  #endif
}

v2f vert(appdata v)
{
#if defined(_DISCARD)
  if (_Discard_Enable_Dynamic) {
    return (v2f) (0.0 / 0.0);
  }
#endif

  v2f o;

  UNITY_INITIALIZE_OUTPUT(v2f, o);
  UNITY_SETUP_INSTANCE_ID(v);
  UNITY_TRANSFER_INSTANCE_ID(v, o);
  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
  //UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(v, o);

#if defined(_GIMMICK_BOX_DISCARD)
  if (_Gimmick_Box_Discard_Enable_Static) {
    float3 p = getCenterCamPos();
    float3 c1 = _Gimmick_Box_Discard_Corner_1;
    float3 c2 = _Gimmick_Box_Discard_Corner_2;
    bool inside = (p.x >= c1.x && p.x <= c2.x &&
        p.y >= c1.y && p.y <= c2.y &&
        p.z >= c1.z && p.z <= c2.z);
    if (_Gimmick_Box_Discard_Invert && !inside ||
        !_Gimmick_Box_Discard_Invert && inside) {
      return (v2f) (0.0 / 0.0);
    }
  }
#endif

  o.centerCamPos = getCenterCamPos();

#if defined(_GIMMICK_QUANTIZE_LOCATION)
  if (_Gimmick_Quantize_Location_Enable_Dynamic) {
    float q = _Gimmick_Quantize_Location_Precision /
      _Gimmick_Quantize_Location_Multiplier;
#if defined(_GIMMICK_QUANTIZE_LOCATION_AUDIOLINK)
    // christ what a fucking variable name
    if (_Gimmick_Quantize_Location_Audiolink_Enable_Dynamic &&
        AudioLinkIsAvailable()) {
      // x is lowest frequency, w is highest
      float4 bands = AudioLinkData(ALPASS_AUDIOLINK).xyzw;

      float e = q *= 1 + (bands.x + bands.y * 0.5) *
        _Gimmick_Quantize_Location_Audiolink_Strength * 0.1;
    }
#endif
    float3 v_new0 = floor(v.vertex * q) / q;
    float3 d = v_new0 - v.vertex;
    float3 v_new1 = v.vertex - d;
    bool flip_dir = (sign(dot(d, v.normal)) !=
        sign(_Gimmick_Quantize_Location_Direction));
    float3 v_q = lerp(v_new0, v_new1, flip_dir);
    float mask = _Gimmick_Quantize_Location_Mask.SampleLevel(linear_repeat_s,
        v.uv0.xy, /*lod=*/0);
    v.vertex.xyz = lerp(v.vertex.xyz, v_q, mask);
  }
#endif

#if defined(_TROCHOID)
  {
    o.objPos_pre_trochoid = v.vertex.xyz;
    v.vertex.xyz = cart_to_troch_map(v.vertex.xyz);
  }
#endif  // _TROCHOID
#if defined(_FACE_ME_WORLD_Y)
  if (_FaceMeWorldY_Enable_Dynamic) {
    // Undo object coordinate system rotation.
    float3x3 rotation = float3x3(
        normalize(unity_ObjectToWorld._m00_m10_m20),
        normalize(unity_ObjectToWorld._m01_m11_m21),
        normalize(unity_ObjectToWorld._m02_m12_m22));
    rotation = transpose(rotation);
    float3 unrotated = mul(transpose(rotation),
        v.vertex.xyz);
    float4 pos = mul(unity_ObjectToWorld,
        float4(unrotated, v.vertex.w));
    float3 unrotated_n = mul(transpose(rotation),
        v.normal);
    float3 n = UnityObjectToWorldNormal(unrotated_n);

    float3 origin = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;
    float3 view_dir = o.centerCamPos - origin;
    // Project onto xz plane
    n.y = 0;
    view_dir.y = 0;
    // Normalize
    n = normalize(n);
    view_dir = normalize(view_dir);
    // Calculate angles and rotate
    float ct = dot(view_dir, n);
    float3 n_cross_v = cross(view_dir, n);
    float st = length(n_cross_v);
    st *= sign(n_cross_v.y);
    float2x2 rot = float2x2(
        ct, -st,
        st, ct);
    pos.xz = mul(rot, pos.xz - origin.xz) + origin.xz;

    v.vertex = mul(unity_WorldToObject, pos);
    o.normal = view_dir;
  }
#endif

#if !defined(_SCROLL) && defined(_GIMMICK_SPHERIZE_LOCATION)
  if (_Gimmick_Spherize_Location_Enable_Dynamic) {
    float3 p = v.vertex.xyz;
    float r = _Gimmick_Spherize_Location_Radius;
    float s = _Gimmick_Spherize_Location_Strength;
    float l = length(p);
    p *= lerp(1, (r / l), s);
    v.vertex.xyz = p;
  }
#endif
#if !defined(_SCROLL) && defined(_GIMMICK_SHEAR_LOCATION)
  if (_Gimmick_Shear_Location_Enable_Dynamic) {
    float3 p = v.vertex.xyz;
    float3 sc = _Gimmick_Shear_Location_Strength.xyz;
    float3x3 shear_matrix = float3x3(
          sc.x, 0, 0,
          0, sc.y, 0,
          0, 0, sc.z);
    p = mul(shear_matrix, p);
    v.vertex.xyz = p;
  }
#endif
#if defined(_GIMMICK_GERSTNER_WATER)
  {
    GerstnerParams p = getGerstnerParams();
    v.vertex.xyz = gerstner_vert(v.vertex.xyz, p);
  }
#endif

  o.pos = UnityObjectToClipPos(v.vertex);
  o.worldPos = mul(unity_ObjectToWorld, v.vertex);
  o.objPos = v.vertex;

#if defined(_FACE_ME_WORLD_Y)
  if (!_FaceMeWorldY_Enable_Dynamic) {
    o.normal = UnityObjectToWorldNormal(v.normal);
  }
#else
  o.normal = UnityObjectToWorldNormal(v.normal);
#endif

  o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
  o.uv0 = v.uv0;
#if !defined(_OPTIMIZE_INTERPOLATORS)
  o.uv1 = v.uv1;
#if defined(LIGHTMAP_ON)
  o.uv2 = v.uv2 * unity_LightmapST.xy + unity_LightmapST.zw;
  UNITY_TRANSFER_LIGHTING(o, v.uv2);
#else
  o.uv2 = v.uv2;
  o.uv3 = v.uv3;
  o.uv4 = v.uv4;
  o.uv5 = v.uv5;
  o.uv6 = v.uv6;
  o.uv7 = v.uv7;
#endif
#endif  // _OPTIMIZE_INTERPOLATORS
#if defined(_MIRROR_UV_FLIP)
  if (_Mirror_UV_Flip_Enable_Dynamic) {
    bool in_mirror = isInMirror();
    o.uv0.x = lerp(o.uv0.x, 1 - o.uv0.x, in_mirror);
#if !defined(_OPTIMIZE_INTERPOLATORS)
    o.uv1.x = lerp(o.uv1.x, 1 - o.uv1.x, in_mirror);
    o.uv2.x = lerp(o.uv2.x, 1 - o.uv2.x, in_mirror);
    o.uv3.x = lerp(o.uv3.x, 1 - o.uv3.x, in_mirror);
    o.uv4.x = lerp(o.uv4.x, 1 - o.uv4.x, in_mirror);
    o.uv5.x = lerp(o.uv5.x, 1 - o.uv5.x, in_mirror);
    o.uv6.x = lerp(o.uv6.x, 1 - o.uv6.x, in_mirror);
    o.uv7.x = lerp(o.uv7.x, 1 - o.uv7.x, in_mirror);
#endif
  }
#endif
#if defined(SHADOWS_SCREEN)
  TRANSFER_SHADOW(o);
#endif

	float2 suv = o.pos * float2(0.5, 0.5 * _ProjectionParams.x);
  o.screenPos = TransformStereoScreenSpaceTex(suv + 0.5 * o.pos.w, o.pos.w);

  getVertexLightColor(o);
  UNITY_TRANSFER_FOG(o, o.pos);

  return o;
}

// maxvertexcount == the number of vertices we create
#if defined(_CLONES)
[maxvertexcount(21)]
#else
[maxvertexcount(3)]
#endif
void geom(triangle v2f tri_in[3],
  uint pid: SV_PrimitiveID,
  inout TriangleStream<v2f> tri_out)
{
  v2f v0 = tri_in[0];
  v2f v1 = tri_in[1];
  v2f v2 = tri_in[2];

  float3 v0_objPos;
  float3 v1_objPos;
  float3 v2_objPos;

  const float pid_rand = rand((int) pid);

  float explode_phase = 0;
#if defined(_EXPLODE)
  float3 n = normalize(cross(v1.worldPos - v0.worldPos, v2.worldPos - v0.worldPos));
  float3 avg_pos;

  float3 n0 = v0.normal;
  float3 n1 = v1.normal;
  float3 n2 = v2.normal;

  explode_phase = _Explode_Phase;
  explode_phase = smoothstep(0, 1, explode_phase);
  explode_phase *= explode_phase;
  explode_phase *= 4;

  if (explode_phase > 1E-6) {
    float3 axis = normalize(float3(
          rand((int) ((v0.uv0.x + v0.uv0.y) * 1E9)) * 2 - 1,
          rand((int) ((v1.uv0.x + v1.uv0.y) * 1E9)) * 2 - 1,
          rand((int) ((v2.uv0.x + v2.uv0.y) * 1E9)) * 2 - 1));
    float3 np = BlendNormals(n, axis * explode_phase);

    v0.worldPos += np * explode_phase * pid_rand;
    v1.worldPos += np * explode_phase * pid_rand;
    v2.worldPos += np * explode_phase * pid_rand;

    v0_objPos = mul(unity_WorldToObject, float4(v0.worldPos, 1));
    v1_objPos = mul(unity_WorldToObject, float4(v1.worldPos, 1));
    v2_objPos = mul(unity_WorldToObject, float4(v2.worldPos, 1));

    float chrono = 0;
#if defined(_AUDIOLINK)
    if (AudioLinkIsAvailable()) {
      chrono = (AudioLinkDecodeDataAsUInt( ALPASS_CHRONOTENSITY  + uint2( 2, 1 ) ) % 1000000) / 1000000.0;
    }
#endif
    v0.worldPos += n * explode_phase * sin(_Time[2] + length(v0_objPos)*6 + chrono) * .01 + chrono * n * explode_phase * .2;
    v1.worldPos += n * explode_phase * sin(_Time[2] + length(v1_objPos)*6 + chrono) * .01 + chrono * n * explode_phase * .2;
    v2.worldPos += n * explode_phase * sin(_Time[2] + length(v2_objPos)*6 + chrono) * .01 + chrono * n * explode_phase * .2;

    avg_pos = (v0.worldPos + v1.worldPos + v2.worldPos) / 3;
    v0.worldPos -= avg_pos;
    v1.worldPos -= avg_pos;
    v2.worldPos -= avg_pos;

    v0.worldPos *= 1 + 2 * pid_rand;
    v1.worldPos *= 1 + 2 * pid_rand;
    v2.worldPos *= 1 + 2 * pid_rand;

    float theta = explode_phase * 3.14159 * 4 + explode_phase * (sin(_Time[1] * (1 + pid_rand) / 2.0 + pid_rand) + cos(_Time[1] * (1 + pid_rand) / 6.1 + pid_rand) * 2) * pid_rand * 2;
    float4 quat = get_quaternion(axis, theta);
    v0.worldPos = rotate_vector(v0.worldPos, quat);
    v1.worldPos = rotate_vector(v1.worldPos, quat);
    v2.worldPos = rotate_vector(v2.worldPos, quat);

    v0.worldPos += avg_pos;
    v1.worldPos += avg_pos;
    v2.worldPos += avg_pos;

    n = normalize(cross(v1.worldPos - v0.worldPos, v2.worldPos - v0.worldPos));
    v0.normal = n;
    v1.normal = n;
    v2.normal = n;

    // Omit geometry that's too close when exploded.
    /*
    if (_Explode_Phase > .05 && length(v0.worldPos - _WorldSpaceCameraPos) < .2) {
      return;
    }
    */

    v0_objPos = mul(unity_WorldToObject, float4(v0.worldPos, 1));
    v1_objPos = mul(unity_WorldToObject, float4(v1.worldPos, 1));
    v2_objPos = mul(unity_WorldToObject, float4(v2.worldPos, 1));

    // Apply transformed worldPos to other coordinate systems.
    if (_Explode_Phase > 1E-6) {
      v0.pos = UnityObjectToClipPos(v0_objPos);
      v1.pos = UnityObjectToClipPos(v1_objPos);
      v2.pos = UnityObjectToClipPos(v2_objPos);
    }
  }
#endif  // __EXPLODE
#if defined(_SCROLL)
  {
    float3 n = normalize(cross(v1.worldPos - v0.worldPos, v2.worldPos - v0.worldPos));
    float3 avg_pos = (v0.worldPos + v1.worldPos + v2.worldPos) / 3;
    v0.worldPos = applyScroll(v0.worldPos, n, avg_pos);
    v1.worldPos = applyScroll(v1.worldPos, n, avg_pos);
    v2.worldPos = applyScroll(v2.worldPos, n, avg_pos);

    float3 v0_objPos = mul(unity_WorldToObject, float4(v0.worldPos, 1));
    float3 v1_objPos = mul(unity_WorldToObject, float4(v1.worldPos, 1));
    float3 v2_objPos = mul(unity_WorldToObject, float4(v2.worldPos, 1));

#if defined(_GIMMICK_SPHERIZE_LOCATION)
  if (_Gimmick_Spherize_Location_Enable_Dynamic) {
    float r = _Gimmick_Spherize_Location_Radius;
    float s = _Gimmick_Spherize_Location_Strength;
    float l0 = length(v0_objPos);
    float l1 = length(v1_objPos);
    float l2 = length(v2_objPos);
    v0_objPos *= lerp(1, (r / l0), s);
    v1_objPos *= lerp(1, (r / l1), s);
    v2_objPos *= lerp(1, (r / l2), s);
  }
#endif
#if defined(_GIMMICK_SHEAR_LOCATION)
  if (_Gimmick_Shear_Location_Enable_Dynamic) {
    v0_objPos = mul(float3x3(
        _Gimmick_Shear_Location_Strength.x, 0, 0,
        0, _Gimmick_Shear_Location_Strength.y, 0,
        0, 0, _Gimmick_Shear_Location_Strength.z),
        v0_objPos);
    v1_objPos = mul(float3x3(
        _Gimmick_Shear_Location_Strength.x, 0, 0,
        0, _Gimmick_Shear_Location_Strength.y, 0,
        0, 0, _Gimmick_Shear_Location_Strength.z),
        v1_objPos);
    v2_objPos = mul(float3x3(
        _Gimmick_Shear_Location_Strength.x, 0, 0,
        0, _Gimmick_Shear_Location_Strength.y, 0,
        0, 0, _Gimmick_Shear_Location_Strength.z),
        v2_objPos);
  }
#endif
#if defined(_GIMMICK_SHEAR_LOCATION) || defined(_GIMMICK_SPHERIZE_LOCATION)
    v0.worldPos.xyz = mul(unity_ObjectToWorld, v0_objPos);
    v1.worldPos.xyz = mul(unity_ObjectToWorld, v1_objPos);
    v2.worldPos.xyz = mul(unity_ObjectToWorld, v2_objPos);
#endif

    v0.pos = UnityObjectToClipPos(v0_objPos);
    v1.pos = UnityObjectToClipPos(v1_objPos);
    v2.pos = UnityObjectToClipPos(v2_objPos);
  }
#endif
#if defined(_CLONES)
  v2f clone_verts[3] = {v0, v1, v2};
  add_clones(clone_verts, tri_out, pid_rand, explode_phase);
#endif  // _CLONES

  // Output transformed geometry.
  tri_out.Append(v0);
  tri_out.Append(v1);
  tri_out.Append(v2);
  tri_out.RestartStrip();
}

#if defined(_RORSCHACH) || defined(_GLITTER) || defined(_RIM_LIGHTING0_GLITTER) || defined(_RIM_LIGHTING1_GLITTER) || defined(_RIM_LIGHTING2_GLITTER) || defined(_RIM_LIGHTING3_GLITTER)
struct RorschachPBR {
  float4 albedo;
};
float rorschach_map_sdf(float3 p, float2 e, float3 period, float center_randomization, float speed)
{
  float r = _Rorschach_Radius * min(period.x, min(period.y, period.z));
  float st = sin(_Time[1] * speed * e.y * e.y + e.x * 3.14159265 * 2);
  r *= st;
  float3 o = float3(
    (e.x - 0.5) * period.x,
    (e.y - 0.5) * period.y,
    0);
  o *= center_randomization;
  return distance_from_sphere(p + o, r);
}

float rorschach_map_dr(
    float3 p,
    float3 period,
    float3 count,
    float center_randomization,
    float speed,
    out float3 which
    )
{
  which = round(p / period);
  // Direction to nearest neighboring cell.
  float3 min_d = p - period * which;
  float3 o = sign(min_d);

  float d = 1E9;
  float3 which_tmp = which;
  for (uint xi = 0; xi < 4; xi++)
  for (uint yi = 0; yi < 4; yi++)
  {
    float3 rid = which + float3(((float) xi) - 1, ((float) yi) - 1, 0) * o;
    float3 r = p - period * rid;
    float2 e = float2(
        rand3(rid / 100.0),
        rand3(rid / 100.0 + 1));
    float cur_d = rorschach_map_sdf(r, e, period, center_randomization, speed);
    which_tmp = cur_d < d ? rid : which;
    d = min(d, cur_d);
  }

  which = which_tmp;
  return d;
}

struct RorschachParams {
  float4 color;
  float count_x, count_y;
  float mask;
  float mask_invert;
  float quantization;
  float alpha_cutoff;
  float center_randomization;
  float speed;
};

RorschachPBR get_rorschach(float2 uv, RorschachParams p)
{
  RorschachPBR result;
  result.albedo = float4(0, 0, 0, 1);

  float3 ro = float3(uv.x - 0.5, uv.y - 0.5, 0);
  float3 rd = float3(0, 0, 1);

  float3 which;
  float3 period = float3(1 / (p.count_x+1), 1 / (p.count_y+1), 1);
  float3 count = float3(p.count_x, p.count_y, 1);
  float d = rorschach_map_dr(ro, period, count, p.center_randomization, p.speed, which);

  d *= max(p.count_x + 1, p.count_y + 1);

  d = 1 - d;
  d = saturate(d);

  // This also quantizes alpha. It isn't exactly intended, but it looks nice.
  if (p.quantization > 0) {
    d = round(d * p.quantization) / p.quantization;
  }

  float4 col = p.color * d;
  result.albedo = lerp(0, col, d > p.alpha_cutoff);

  float mask = p.mask;
  mask = p.mask_invert ? 1 - mask : mask;
  result.albedo *= mask;

  return result;
}

float get_glitter(float2 uv, float3 worldPos, float3 centerCamPos,
    float3 normal, float density, float amount, float speed,
    float mask, float angle, float power)
{
  // To increase amount: make count_{x,y} closer to each other
  // To increase density: make both numbers larger
  RorschachParams p;
  p.color = 1;
  p.count_x = density * amount;
  p.count_y = density * rcp(amount);
  p.mask = mask;
  p.mask_invert = 0;
  p.quantization = 1;
  p.alpha_cutoff = 0.5;
  p.center_randomization = 1;
  p.speed = speed;
  RorschachPBR result = get_rorschach(uv, p);

  float glitter = result.albedo.r;
  if (angle < 90) {
    float ndotl = abs(dot(normal, normalize(centerCamPos - worldPos)));
    float cutoff = cos((angle / 180) * 3.14159);

    glitter *= saturate(pow(ndotl / cutoff, power));
  }
  if (_Glitter_Vector_Mask_Enabled) {
    float3 mask_vector = _Glitter_Vector_Mask_Vector;
    float power = _Glitter_Vector_Mask_Power;
    float invert = _Glitter_Vector_Mask_Invert;
    float vector_mask = dot(normal, normalize(mask_vector));
    // Wrap ndotl
    vector_mask = (vector_mask + 1) / 2;
    vector_mask *= vector_mask;
    vector_mask = max(vector_mask, 0);
    vector_mask = invert ? 1 - vector_mask : vector_mask;
    glitter *= pow(vector_mask, power);
  }

  return glitter;

  /*
  // A regular divide here causes flickering. The leading guess is that NVIDIA
  // hardware implements the divide instruction slightly differently on
  // different cores.
  precise float idensity = rcp(density);
  float glitter = rand2(floor(uv * density) * idensity);

  float thresh = 1 - amount / 100;
  glitter = lerp(0, glitter, glitter > thresh);
  glitter = (glitter - thresh) / (1 - thresh);

  float b = sin(_Time[2] * speed / 2 + glitter*100);
  b = speed > 1E-6 ? b : 1;
  glitter = max(glitter, 0)*max(b, 0);

  glitter *= mask;

  glitter = clamp(glitter, 0, 1);

  if (angle < 90) {
    float ndotl = abs(dot(normal, normalize(_WorldSpaceCameraPos.xyz - worldPos)));
    float cutoff = cos((angle / 180) * 3.14159);

    glitter *= saturate(pow(ndotl / cutoff, power));
  }

  return glitter;
  */
}
#endif  // _GLITTER

float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent) * (binormalSign * unity_WorldTransformParams.w);
}

float2 matcap_distortion0(float2 matcap_uv) {
  float3 qvec = float3(matcap_uv * 2 - 1, 0);
  float t = _Time[0];
  float e = .4;
  float3 qaxis = normalize(float3(sin(t * 2.3) * e, sin(t * 2.9) * e * 1.2, 1));
  float qtheta = t;
  float4 quat = get_quaternion(qaxis, qtheta);
  matcap_uv *= ((rotate_vector(qvec, quat) + 1) / 2).xy * 1.3;
  return matcap_uv;
}

struct DecalParams {
    float4 color;
    texture2D tex;
    float4 tex_texelsize;
    float4 tex_st;
    texture2D roughness_tex;
    texture2D metallic_tex;
    float emission_strength;
    float angle;
    bool do_roughness;
    bool do_metallic;
    float alpha_multiplier;
    float round_alpha_multiplier;
    float mask;
    float uv_select;
    float tiling_mode;
    float base_color_mode;
    float sdf_threshold;
    float sdf_softness;
    float sdf_px_range;
    bool domain_warping;
    texture2D domain_warping_noise;
    float domain_warping_strength;
    float domain_warping_speed;
    float domain_warping_octaves;
    float domain_warping_scale;
};

void applyDecalImpl(
    inout float4 albedo,
    inout float3 decal_emission,
    inout float roughness,
    inout float metallic,
    v2f i,
    DecalParams p)
{
  float2 d0_uv =
      ((get_uv_by_channel(i, p.uv_select) - 0.5) - p.tex_st.zw) * p.tex_st.xy + 0.5;

  if (abs(p.angle) > 1E-6) {
    float theta = p.angle * 2.0 * 3.14159265;
    float2x2 rot = float2x2(
        cos(theta), -sin(theta),
        sin(theta), cos(theta));
    d0_uv = mul(rot, d0_uv - 0.5) + 0.5;
  }
  d0_uv = (p.tiling_mode == 0) ? saturate(d0_uv) : d0_uv;

  float d0_uv_fwidth = -1;
  if (p.domain_warping) {
    p.domain_warping_octaves = min(p.domain_warping_octaves, 10);
    for (uint ii = 0; ii < p.domain_warping_octaves; ii++) {
      float2 warping_speed_vector = normalize(float2(97, 101));
      float2 noise = p.domain_warping_noise.SampleLevel(linear_repeat_s, d0_uv * p.domain_warping_scale + _Time[0] * p.domain_warping_speed * warping_speed_vector, 0);
      d0_uv += noise * p.domain_warping_strength;
    }
    d0_uv_fwidth = length(fwidth(d0_uv));
  }

  float4 d0_c = 0;
  if (p.base_color_mode == 0) {
    d0_c = p.tex.SampleBias(
        linear_repeat_s,
        d0_uv, _Global_Sample_Bias);
  } else if (p.base_color_mode == 1) {
    float sd = p.tex.SampleLevel(linear_repeat_s, d0_uv, 0);

    float2 screen_tex_size = 1 / fwidth(d0_uv);
    float2 cell_size_texels = p.tex_texelsize.zw;
    float2 unit_range = p.sdf_px_range / cell_size_texels;
    float screen_px_range = max(0.5 * dot(unit_range, screen_tex_size), p.sdf_px_range);

    float screen_px_distance = screen_px_range * (sd - p.sdf_threshold);
    float2 grid_res = p.tex_st.xy;
    float smooth_range = (sqrt(2) / sqrt(screen_px_range)) * p.sdf_softness;
    float op = smoothstep(-smooth_range, smooth_range, screen_px_distance);
    d0_c = saturate(op);
    // TODO mip-like filtering?
  }

  d0_c *= p.color;
  d0_c.a *= p.round_alpha_multiplier ? round(p.alpha_multiplier) : p.alpha_multiplier;
  // Manually apply tiling/clamping correction.
  float d0_in_range = 1;
  d0_in_range *= d0_uv.x > 0;
  d0_in_range *= d0_uv.x < 1;
  d0_in_range *= d0_uv.y > 0;
  d0_in_range *= d0_uv.y < 1;
  d0_in_range = (p.tiling_mode == 0) ? d0_in_range : 1;
  d0_c *= d0_in_range;
  d0_c *= p.mask;

  albedo.rgb = lerp(albedo.rgb, d0_c.rgb, d0_c.a);
  albedo.a = max(albedo.a, d0_c.a);
  decal_emission += d0_c.rgb * p.emission_strength * d0_c.a;

  if (p.do_roughness) {
    float4 d0_r = p.roughness_tex.SampleBias(linear_clamp_s, saturate(d0_uv), _Global_Sample_Bias);
    d0_r *= d0_in_range;
    roughness = lerp(roughness, d0_r, d0_r.a);
  }
  if (p.do_metallic) {
    float4 d0_m = p.metallic_tex.SampleBias(linear_clamp_s, saturate(d0_uv), _Global_Sample_Bias);
    d0_m *= d0_in_range;
    metallic = lerp(metallic, d0_m, d0_m.a);
  }
}

#define DECAL_PARAMS(n) \
  MERGE(d,n,_params).do_roughness = false; \
  MERGE(d,n,_params).do_metallic = false; \
  MERGE(d,n,_params).mask = 1; \
  MERGE(d,n,_params).color = MERGE(_Decal,n,_Color); \
  MERGE(d,n,_params).tex = MERGE(_Decal,n,_BaseColor); \
  MERGE(d,n,_params).tex_texelsize = MERGE(_Decal,n,_BaseColor_TexelSize); \
  MERGE(d,n,_params).tex_st = MERGE(_Decal,n,_BaseColor_ST); \
  MERGE(d,n,_params).roughness_tex = MERGE(_Decal,n,_Roughness); \
  MERGE(d,n,_params).metallic_tex = MERGE(_Decal,n,_Metallic); \
  MERGE(d,n,_params).emission_strength = MERGE(_Decal,n,_Emission_Strength); \
  MERGE(d,n,_params).angle = MERGE(_Decal,n,_Angle); \
  MERGE(d,n,_params).alpha_multiplier = MERGE(_Decal,n,_Alpha_Multiplier); \
  MERGE(d,n,_params).round_alpha_multiplier = MERGE(_Decal,n,_Round_Alpha_Multiplier); \
  MERGE(d,n,_params).uv_select = MERGE(_Decal,n,_UV_Select); \
  MERGE(d,n,_params).tiling_mode = MERGE(_Decal,n,_Tiling_Mode); \
  MERGE(d,n,_params).base_color_mode = MERGE(_Decal,n,_BaseColor_Mode); \
  MERGE(d,n,_params).sdf_threshold = MERGE(_Decal,n,_SDF_Threshold); \
  MERGE(d,n,_params).sdf_softness = MERGE(_Decal,n,_SDF_Softness); \
  MERGE(d,n,_params).sdf_px_range = MERGE(_Decal,n,_SDF_Px_Range); \
  MERGE(d,n,_params).domain_warping = MERGE(_Decal,n,_Domain_Warping_Enable_Static); \
  MERGE(d,n,_params).domain_warping_noise = MERGE(_Decal,n,_Domain_Warping_Noise); \
  MERGE(d,n,_params).domain_warping_strength = MERGE(_Decal,n,_Domain_Warping_Strength); \
  MERGE(d,n,_params).domain_warping_speed = MERGE(_Decal,n,_Domain_Warping_Speed); \
  MERGE(d,n,_params).domain_warping_octaves = MERGE(_Decal,n,_Domain_Warping_Octaves); \
  MERGE(d,n,_params).domain_warping_scale = MERGE(_Decal,n,_Domain_Warping_Scale);

#define SETUP_DECAL_BASE(n) \
  DecalParams MERGE(d,n,_params); \
  DECAL_PARAMS(n)

#define SETUP_DECAL_ROUGHNESS(n) \
  MERGE(d,n,_params).do_roughness = true;

#define SETUP_DECAL_METALLIC(n) \
  MERGE(d,n,_params).do_metallic = true;

#define SETUP_DECAL_MASK(n) \
  MERGE(d,n,_params).mask = MERGE(_Decal,n,_Mask).SampleLevel(linear_repeat_s, \
      get_uv_by_channel(i, MERGE(_Decal,n,_UV_Select)), 0); \
  MERGE(d,n,_params).mask = MERGE(_Decal,n,_Mask_Invert) ? 1.0 - MERGE(d,n,_params).mask : MERGE(d,n,_params).mask;

#define SETUP_DECAL_FINISH(n) \
  applyDecalImpl(albedo, decal_emission, roughness, metallic, i, MERGE(d,n,_params));

void applyDecal(inout float4 albedo,
    inout float roughness,
    inout float metallic,
    inout float3 decal_emission,
    v2f i)
{
#if defined(_DECAL0)
    SETUP_DECAL_BASE(0)
    #if defined(_DECAL0_ROUGHNESS)
        SETUP_DECAL_ROUGHNESS(0)
    #endif
    #if defined(_DECAL0_METALLIC)
        SETUP_DECAL_METALLIC(0)
    #endif
    #if defined(_DECAL0_MASK)
        SETUP_DECAL_MASK(0)
    #endif
    SETUP_DECAL_FINISH(0)
#endif

#if defined(_DECAL1)
    SETUP_DECAL_BASE(1)
    #if defined(_DECAL1_ROUGHNESS)
        SETUP_DECAL_ROUGHNESS(1)
    #endif
    #if defined(_DECAL1_METALLIC)
        SETUP_DECAL_METALLIC(1)
    #endif
    #if defined(_DECAL1_MASK)
        SETUP_DECAL_MASK(1)
    #endif
    SETUP_DECAL_FINISH(1)
#endif

#if defined(_DECAL2)
    SETUP_DECAL_BASE(2)
    #if defined(_DECAL2_ROUGHNESS)
        SETUP_DECAL_ROUGHNESS(2)
    #endif
    #if defined(_DECAL2_METALLIC)
        SETUP_DECAL_METALLIC(2)
    #endif
    #if defined(_DECAL2_MASK)
        SETUP_DECAL_MASK(2)
    #endif
    SETUP_DECAL_FINISH(2)
#endif

#if defined(_DECAL3)
    SETUP_DECAL_BASE(3)
    #if defined(_DECAL3_ROUGHNESS)
        SETUP_DECAL_ROUGHNESS(3)
    #endif
    #if defined(_DECAL3_METALLIC)
        SETUP_DECAL_METALLIC(3)
    #endif
    #if defined(_DECAL3_MASK)
        SETUP_DECAL_MASK(3)
    #endif
    SETUP_DECAL_FINISH(3)
#endif

#if defined(_DECAL4)
    SETUP_DECAL_BASE(4)
    #if defined(_DECAL4_ROUGHNESS)
        SETUP_DECAL_ROUGHNESS(4)
    #endif
    #if defined(_DECAL4_METALLIC)
        SETUP_DECAL_METALLIC(4)
    #endif
    #if defined(_DECAL4_MASK)
        SETUP_DECAL_MASK(4)
    #endif
    SETUP_DECAL_FINISH(4)
#endif

#if defined(_DECAL5)
    SETUP_DECAL_BASE(5)
    #if defined(_DECAL5_ROUGHNESS)
        SETUP_DECAL_ROUGHNESS(5)
    #endif
    #if defined(_DECAL5_METALLIC)
        SETUP_DECAL_METALLIC(5)
    #endif
    #if defined(_DECAL5_MASK)
        SETUP_DECAL_MASK(5)
    #endif
    SETUP_DECAL_FINISH(5)
#endif

#if defined(_DECAL6)
    SETUP_DECAL_BASE(6)
    #if defined(_DECAL6_ROUGHNESS)
        SETUP_DECAL_ROUGHNESS(6)
    #endif
    #if defined(_DECAL6_METALLIC)
        SETUP_DECAL_METALLIC(6)
    #endif
    #if defined(_DECAL6_MASK)
        SETUP_DECAL_MASK(6)
    #endif
    SETUP_DECAL_FINISH(6)
#endif

#if defined(_DECAL7)
    SETUP_DECAL_BASE(7)
    #if defined(_DECAL7_ROUGHNESS)
        SETUP_DECAL_ROUGHNESS(7)
    #endif
    #if defined(_DECAL7_METALLIC)
        SETUP_DECAL_METALLIC(7)
    #endif
    #if defined(_DECAL7_MASK)
        SETUP_DECAL_MASK(7)
    #endif
    SETUP_DECAL_FINISH(7)
#endif

#if defined(_DECAL8)
    SETUP_DECAL_BASE(8)
    #if defined(_DECAL8_ROUGHNESS)
        SETUP_DECAL_ROUGHNESS(8)
    #endif
    #if defined(_DECAL8_METALLIC)
        SETUP_DECAL_METALLIC(8)
    #endif
    #if defined(_DECAL8_MASK)
        SETUP_DECAL_MASK(8)
    #endif
    SETUP_DECAL_FINISH(8)
#endif

#if defined(_DECAL9)
    SETUP_DECAL_BASE(9)
    #if defined(_DECAL9_ROUGHNESS)
        SETUP_DECAL_ROUGHNESS(9)
    #endif
    #if defined(_DECAL9_METALLIC)
        SETUP_DECAL_METALLIC(9)
    #endif
    #if defined(_DECAL9_MASK)
        SETUP_DECAL_MASK(9)
    #endif
    SETUP_DECAL_FINISH(9)
#endif
}

#if defined(_PIXELLATE)
float2 pixellate_uv(int2 px_res, float2 uv)
{
  return floor(uv * px_res) / px_res;
}

float4 pixellate_color(int2 px_res, float2 uv, float4 c)
{
  float2 px_intra_uv = fmod(uv * px_res, 1.0);
  float2 px_extra_uv = floor(uv * px_res) / px_res;

  float2 px_uv = floor(uv * px_res) / px_res;
  if (px_intra_uv.y > 0.1 && px_intra_uv.y < 0.9) {
    if (px_intra_uv.x < 0.333) {
      c.xyz = float3(1, 0, 0);
    } else if (px_intra_uv.x < 0.666) {
      c.yxz = float3(1, 0, 0);
    } else {
      c.zxy = float3(1, 0, 0);
    }
    c *= 3;
  } else {
    c = 0;
  }

  return c;
}
#endif

float4 effect(inout v2f i, out float depth)
{
  ToonerData tdata;
  {
    float3 full_vec_eye_to_geometry = i.worldPos - _WorldSpaceCameraPos;
    float3 world_dir = normalize(i.worldPos - _WorldSpaceCameraPos);
    float perspective_divide = 1.0 / i.pos.w;
    float perspective_factor = length(full_vec_eye_to_geometry * perspective_divide);
    tdata.screen_uv = i.screenPos.xy * perspective_divide;
    tdata.screen_uv_round = floor(tdata.screen_uv * _ScreenParams.xy);
  }

#if defined(EXPERIMENT__CUSTOM_DEPTH)
  {
    float4 clip_pos = mul(UNITY_MATRIX_VP, float4(i.worldPos, 1.0));
    depth = clip_pos.z / clip_pos.w;
  }
#else
  depth = 0;
#endif

#if defined(_GIMMICK_UV_DOMAIN_WARPING)
  {
    float2 uv = i.uv0;
    for (uint ii = 0; ii < _Gimmick_UV_Domain_Warping_Octaves; ii++) {
      uv +=
        (_Gimmick_UV_Domain_Warping_Noise.SampleLevel(
          linear_repeat_s,
          (uv + _Time[0] * _Gimmick_UV_Domain_Warping_Speed) *
          _Gimmick_UV_Domain_Warping_Scale, 0) - 0.5) *
        _Gimmick_UV_Domain_Warping_Strength;
    }
    i.uv0 = uv;
  }
#endif

#if defined(_TROCHOID)
  {
    float3 my_pos;
    [branch]
    if (_Trochoid_Enable_Fragment_Normals) {
      my_pos = cart_to_troch_map(i.objPos_pre_trochoid.xyz);
    } else {
      my_pos = i.objPos.xyz;
    }
    float3 tan1 = ddx(my_pos);
    float3 tan2 = ddy(my_pos);
    float3 normal = cross(tan1, tan2);
    i.normal = -UnityObjectToWorldNormal(normal);
    i.tangent.xyz = UnityObjectToWorldDir(tan1);
  }
#endif

  const float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
  const float3 view_dir_c = normalize(i.centerCamPos - i.worldPos);
#define VIEW_DIR(center_eye_fix) (center_eye_fix == 1 ? view_dir_c : view_dir)
#define CAM_POS(center_eye_fix) (center_eye_fix == 1 ? i.centerCamPos : _WorldSpaceCameraPos.xyz)

  // Not necessarily normalized after interpolation.
  i.normal = normalize(i.normal);
  i.tangent.xyz = normalize(i.tangent.xyz - i.normal * dot(i.tangent.xyz, i.normal));
  //i.tangent.xyz = normalize(i.tangent.xyz);

#if defined(_UVSCROLL)
  float2 orig_uv = i.uv0;
  float uv_scroll_mask = round(_UVScroll_Mask.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias));
  i.uv0 += _Time[0] * float2(_UVScroll_U_Speed, _UVScroll_V_Speed) * uv_scroll_mask;
#endif

#if defined(_BASECOLOR_MAP)
  float4 albedo = _MainTex.SampleBias(GET_SAMPLER_PBR, UV_SCOFF(i, _MainTex_ST, 0), _Global_Sample_Bias);
  albedo *= _Color;
#else
  float4 albedo = _Color;
#endif  // _BASECOLOR_MAP

#if defined(_GIMMICK_GERSTNER_WATER)
#if defined(_EXPLODE)
  if (_Explode_Phase < 1E-6)
#endif
  {
    GerstnerParams p = getGerstnerParams();
    GerstnerFragResult r = gerstner_frag(i.objPos.xyz, p);
    i.normal = UnityObjectToWorldNormal(r.normal);
    i.tangent = float4(UnityObjectToWorldDir(r.tangent.xyz), r.tangent.w);
#if defined(_GIMMICK_GERSTNER_WATER_COLOR_RAMP)
    albedo.xyz *= r.color;
    albedo.w = 1;
#endif
  }
#endif

#if defined(_UVSCROLL)
  if (uv_scroll_mask) {
    float uv_scroll_alpha = _UVScroll_Alpha.SampleBias(linear_repeat_s, orig_uv, _Global_Sample_Bias);
    albedo.a *= uv_scroll_alpha;
  }
#endif

#if defined(_PIXELLATE)
  {
    const int2 px_res = int2(
        _Gimmick_Pixellate_Resolution_U,
        _Gimmick_Pixellate_Resolution_V);

    float2 uv = pixellate_uv(px_res, i.uv0);
    const float2 duv = float2(ddx(i.uv0.x), ddy(i.uv0.y)) / 16;
    float4 color = _Gimmick_Pixellate_Effect_Mask.SampleGrad(linear_clamp_s, uv, duv.x, duv.y);
    float2 fw = float2(fwidth(i.uv0.x), fwidth(i.uv0.y));
    float fwm = max(fw.x, fw.y);
    color.rgb *= albedo;
    float4 px_color = pixellate_color(px_res, i.uv0, color);
    albedo = lerp(albedo, px_color, pow(0.9, fwm * 100));
  }
#endif

#if defined(_RORSCHACH)
  float4 rorschach_albedo = 0;
  if (_Rorschach_Enable_Dynamic) {
    RorschachParams p;
    p.color = _Rorschach_Color;
    p.count_x = _Rorschach_Count_X;
    p.count_y = _Rorschach_Count_Y;
#if defined(_RORSCHACH_MASK)
    p.mask = _Rorschach_Mask.SampleLevel(linear_repeat_s, i.uv0.xy, /*lod=*/0);
    p.mask_invert = _Rorschach_Mask_Invert;
#else
    p.mask = 1;
    p.mask_invert = 0;
#endif
    p.quantization = _Rorschach_Quantization;
    p.alpha_cutoff = _Rorschach_Alpha_Cutoff;
    p.center_randomization = _Rorschach_Center_Randomization;
    p.speed = _Rorschach_Speed;
    rorschach_albedo = get_rorschach(i.uv0, p).albedo;
    albedo.rgb = rorschach_albedo.rgb * rorschach_albedo.a + albedo.rgb * (1 - rorschach_albedo.a);
    albedo.a = saturate(rorschach_albedo.a + albedo.a * (1 - rorschach_albedo.a));
  }
#endif

  PbrOverlay ov;
  getOverlayAlbedoRoughnessMetallic(ov, i);

#if defined(_NORMAL_MAP)
  // Use UVs to smoothly blend between fully detailed normals when close up and
  // flat normals when far away. If we don't do this, then we see moire effects
  // on e.g. striped normal maps.
  float3 raw_normal = UnpackScaleNormal(_BumpMap.SampleBias(GET_SAMPLER_PBR,
        UV_SCOFF(i, _BumpMap_ST, 0), _Global_Sample_Bias),
      _Tex_NormalStr);
#else
  float3 raw_normal = UnpackNormal(float4(0.5, 0.5, 1, 1));
#endif  // _NORMAL_MAP

  applyOverlayNormal(raw_normal, albedo, ov, i);

  float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
  // normalize is not necessary; result is already normalized
	float3 normal = float3(
		raw_normal.x * normalize(i.tangent) +
		raw_normal.y * normalize(binormal) +
		raw_normal.z * i.normal
	);

#if defined(_GIMMICK_HALO_00)
  {
    Halo00PBR pbr = halo00_march(i.worldPos, i.uv0);
    albedo = pbr.albedo;
    normal = pbr.normal;
  }
#endif

#if defined(_METALLIC_MAP)
  float metallic = _MetallicTex.SampleBias(GET_SAMPLER_PBR,
      UV_SCOFF(i, _MetallicTex_ST, 0), _Global_Sample_Bias)[round(_MetallicTexChannel)];
#else
  float metallic = _Metallic;
#endif
#if defined(_ROUGHNESS_MAP)
  float roughness = _RoughnessTex.SampleBias(GET_SAMPLER_PBR,
      UV_SCOFF(i, _RoughnessTex_ST, 0), _Global_Sample_Bias)[round(_RoughnessTexChannel)];
  if (_Roughness_Invert) {
    roughness = 1 - roughness;
  }
  roughness *= _Roughness;
#else
  float roughness = _Roughness;
#endif

#if defined(VERTEXLIGHT_ON)
  float4 vertex_light_color = float4(i.vertexLightColor, 1);
#else
  float4 vertex_light_color = float4(0, 0, 0, 1);
#endif

#if defined(_GIMMICK_EYES_00)
  {
    float3 eyes_normal = 0;
    float3 eyes_albedo = eyes00_march(i.uv0, eyes_normal).rgb;
    bool is_ray_hit = (eyes_albedo.r > 0 || eyes_albedo.g > 0 || eyes_albedo.b > 0);
    if (is_ray_hit) {
      float mask = _Gimmick_Eyes00_Effect_Mask.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
      albedo.rgb = lerp(eyes_albedo * 1.5, albedo.rgb * 20.0, mask);
      normal = eyes_normal;
    }
  }
#endif

#if defined(_GIMMICK_EYES_01)
  {
    Eyes01PBR pbr = eyes01_march(i);
    albedo = pbr.albedo;
  }
#endif


#if defined(_GIMMICK_EYES_02)
  float3 eyes02_normal = i.normal;
  bool eyes02_hit = eyes02_march(i.uv0, eyes02_normal);
  {
    albedo.rgb += eyes02_hit * _Gimmick_Eyes02_Albedo.rgb;
    normal = lerp(normal, eyes02_normal, eyes02_hit);
    roughness = lerp(roughness, _Gimmick_Eyes02_Roughness, eyes02_hit);
    metallic = lerp(metallic, _Gimmick_Eyes02_Metallic, eyes02_hit);
  }
#endif

#if defined(_MATCAP0) || defined(_MATCAP1) || defined(_RIM_LIGHTING0) || defined(_RIM_LIGHTING1) || defined(_RIM_LIGHTING2) || defined(_RIM_LIGHTING3)
  float3 matcap_emission = 0;
  float2 matcap_uv;
  {
    const float3 cam_normal = normalize(mul(UNITY_MATRIX_V, float4(normal, 0)));
    const float3 cam_view_dir = normalize(mul(UNITY_MATRIX_V, float4(view_dir, 0)));
    const float3 cam_refl = -reflect(cam_view_dir, cam_normal);
    float m = 2.0 * sqrt(
        cam_refl.x * cam_refl.x +
        cam_refl.y * cam_refl.y +
        (cam_refl.z + 1) * (cam_refl.z + 1));
    matcap_uv = cam_refl.xy / m + 0.5;
  }
  float2 matcap_uv_center;
  {
    const float3 cam_normal = normalize(mul(UNITY_MATRIX_V, float4(normal, 0)));
    const float3 cam_view_dir = normalize(mul(UNITY_MATRIX_V, float4(view_dir_c, 0)));
    const float3 cam_refl = -reflect(cam_view_dir, cam_normal);
    float m = 2.0 * sqrt(
        cam_refl.x * cam_refl.x +
        cam_refl.y * cam_refl.y +
        (cam_refl.z + 1) * (cam_refl.z + 1));
    matcap_uv_center = cam_refl.xy / m + 0.5;
  }
#endif

  float4 matcap_overwrite_mask = 0;
#if defined(_MATCAP0) || defined(_MATCAP1)
  {
#if defined(_MATCAP0)
    {
#if defined(_MATCAP0_MASK)
      float4 matcap_mask_raw = _Matcap0_Mask.SampleLevel(linear_repeat_s,
          get_uv_by_channel(i, _Matcap0_Mask_UV_Select), 0);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Matcap0_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif
#if defined(_MATCAP0_MASK2)
      {
        float4 matcap_mask2_raw = _Matcap0_Mask2.SampleLevel(linear_repeat_s,
            get_uv_by_channel(i, _Matcap0_Mask2_UV_Select), 0);
        float matcap_mask2 = matcap_mask2_raw.r;
        matcap_mask2 = _Matcap0_Mask2_Invert_Colors ? 1 - matcap_mask2 : matcap_mask2;
        matcap_mask2 *= _Matcap0_Mask2_Invert_Alpha ? 1 - matcap_mask2_raw.a : matcap_mask2_raw.a;
        matcap_mask *= matcap_mask2;
      }
#endif
#if defined(_MATCAP0_NORMAL)
      float3 matcap_normal = UnpackScaleNormal(
          _Matcap0Normal.SampleBias(linear_repeat_s,
            UV_SCOFF(i, _Matcap0Normal_ST, _Matcap0Normal_UV_Select),
            _Global_Sample_Bias + _Matcap0Normal_Mip_Bias),
          _Matcap0Normal_Str * _Matcap0MixFactor);
      raw_normal = MY_BLEND_NORMALS(raw_normal, matcap_normal, matcap_mask * _Matcap0MixFactor);
      normal = float3(
          raw_normal.x * i.tangent +
          raw_normal.y * binormal +
          raw_normal.z * i.normal
          );
      {
        const float3 cam_normal = normalize(mul(UNITY_MATRIX_V, float4(normal, 0)));
        const float3 cam_view_dir = normalize(mul(UNITY_MATRIX_V, float4(VIEW_DIR(_Matcap0_Center_Eye_Fix), 0)));
        const float3 cam_refl = -reflect(cam_view_dir, cam_normal);
        float m = 2.0 * sqrt(
            cam_refl.x * cam_refl.x +
            cam_refl.y * cam_refl.y +
            (cam_refl.z + 1) * (cam_refl.z + 1));
        matcap_uv = cam_refl.xy / m + 0.5;
      }
#endif

#if defined(_MATCAP0_DISTORTION0)
      float2 distort_uv = matcap_distortion0(matcap_uv);
      float2 matcap_uv = distort_uv;
#endif
      float3 matcap = _Matcap0.SampleBias(linear_repeat_s, matcap_uv, _Global_Sample_Bias) * _Matcap0Str;

      float q = _Matcap0Quantization;
      if (q > 0) {
        matcap = floor(matcap * q) / q;
      }

      int mode = round(_Matcap0Mode);
      switch (mode) {
        case 0:
          albedo.rgb += lerp(0, matcap, matcap_mask);
          matcap_emission += lerp(0, matcap, matcap_mask) * _Matcap0Emission;
          break;
        case 1:
          matcap_emission += lerp(0, matcap, matcap_mask) * _Matcap0Emission;
          albedo.rgb *= lerp(1, matcap, matcap_mask);
          break;
        case 2:
          matcap_overwrite_mask[0] = max(matcap_mask, matcap_overwrite_mask[0]);
          albedo.rgb = lerp(albedo.rgb, matcap, matcap_mask);
          matcap_emission = lerp(albedo.rgb, matcap, matcap_mask) * _Matcap0Emission;
          break;
        case 3:
          albedo.rgb -= lerp(0, matcap, matcap_mask);
          matcap_emission -= lerp(0, matcap, matcap_mask) * _Matcap0Emission;
          break;
        case 4:
          albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask) * _Matcap0Emission;
          break;
        case 5:
          albedo.rgb = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask) * _Matcap0Emission;
          break;
        default:
          break;
      }
    }
#endif  // _MATCAP0
#if defined(_MATCAP1)
    {
#if defined(_MATCAP1_MASK)
      float4 matcap_mask_raw = _Matcap1_Mask.SampleLevel(linear_repeat_s,
          get_uv_by_channel(i, _Matcap1_Mask_UV_Select), 0);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Matcap1_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif
#if defined(_MATCAP1_MASK2)
      {
        float4 matcap_mask2_raw = _Matcap1_Mask2.SampleLevel(linear_repeat_s,
            get_uv_by_channel(i, _Matcap1_Mask2_UV_Select), 0);
        float matcap_mask2 = matcap_mask2_raw.r;
        matcap_mask2 = _Matcap1_Mask2_Invert_Colors ? 1 - matcap_mask2 : matcap_mask2;
        matcap_mask2 *= _Matcap1_Mask2_Invert_Alpha ? 1 - matcap_mask2_raw.a : matcap_mask2_raw.a;
        matcap_mask *= matcap_mask2;
      }
#endif
#if defined(_MATCAP1_NORMAL)
      float3 matcap_normal = UnpackScaleNormal(
          _Matcap1Normal.SampleBias(linear_repeat_s,
            UV_SCOFF(i, _Matcap1Normal_ST, _Matcap1Normal_UV_Select),
            _Global_Sample_Bias + _Matcap1Normal_Mip_Bias),
          _Matcap1Normal_Str * _Matcap1MixFactor);
      raw_normal = MY_BLEND_NORMALS(raw_normal, matcap_normal, matcap_mask * _Matcap1MixFactor);
      normal = float3(
          raw_normal.x * i.tangent +
          raw_normal.y * binormal +
          raw_normal.z * i.normal
          );
      {
        const float3 cam_normal = normalize(mul(UNITY_MATRIX_V, float4(normal, 0)));
        const float3 cam_view_dir = normalize(mul(UNITY_MATRIX_V, float4(VIEW_DIR(_Matcap1_Center_Eye_Fix), 0)));
        const float3 cam_refl = -reflect(cam_view_dir, cam_normal);
        float m = 2.0 * sqrt(
            cam_refl.x * cam_refl.x +
            cam_refl.y * cam_refl.y +
            (cam_refl.z + 1) * (cam_refl.z + 1));
        matcap_uv = cam_refl.xy / m + 0.5;
      }
#endif
#if defined(_MATCAP1_DISTORTION0)
      float2 distort_uv = matcap_distortion0(matcap_uv);
      float2 matcap_uv = distort_uv;
#endif
      float3 matcap = _Matcap1.SampleBias(linear_repeat_s, matcap_uv, _Global_Sample_Bias) * _Matcap1Str;

      float q = _Matcap1Quantization;
      if (q > 0) {
        matcap = floor(matcap * q) / q;
      }

      matcap_mask *= _Matcap1MixFactor;

      int mode = round(_Matcap1Mode);
      switch (mode) {
        case 0:
          albedo.rgb += lerp(0, matcap, matcap_mask);
          matcap_emission += lerp(0, matcap, matcap_mask) * _Matcap1Emission;
          break;
        case 1:
          matcap_emission += lerp(0, matcap, matcap_mask) * _Matcap1Emission;
          albedo.rgb *= lerp(1, matcap, matcap_mask);
          break;
        case 2:
          matcap_overwrite_mask[1] = max(matcap_mask, matcap_overwrite_mask[1]);
          albedo.rgb = lerp(albedo.rgb, matcap, matcap_mask);
          matcap_emission = lerp(albedo.rgb, matcap, matcap_mask) * _Matcap1Emission;
          break;
        case 3:
          albedo.rgb -= lerp(0, matcap, matcap_mask);
          matcap_emission -= lerp(0, matcap, matcap_mask) * _Matcap1Emission;
          break;
        case 4:
          albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask) * _Matcap1Emission;
          break;
        case 5:
          albedo.rgb = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask) * _Matcap1Emission;
          break;
        default:
          break;
      }
    }
#endif  // _MATCAP1
  }
#endif  // _MATCAP0 || _MATCAP1
  matcap_overwrite_mask = 1 - matcap_overwrite_mask;

  // TODO get rid of the pow. It's a hack to make matcap replace mode look
  // better with overlay tattoos.
  float overlay_glitter_mask;
  mixOverlayAlbedoRoughnessMetallic(albedo, roughness, metallic, ov,
      1 - pow((1 - min(matcap_overwrite_mask[0], matcap_overwrite_mask[1])), 8),
      overlay_glitter_mask);
#if defined(_DECAL0) || defined(_DECAL1) || defined(_DECAL2) || defined(_DECAL3) || defined(_DECAL4) || defined(_DECAL5) || defined(_DECAL6) || defined(_DECAL7) || defined(_DECAL8) || defined(_DECAL9)
  float3 decal_emission = 0;
  applyDecal(albedo, roughness, metallic, decal_emission, i);
#endif

#if defined(_RENDERING_CUTOUT)
  float frame = 0;
  if (AudioLinkIsAvailable()) {
    frame = ((float) AudioLinkData(ALPASS_GENERALVU + int2(1, 0)).x);
  } else {
    frame = floor(_Frame_Counter);
  }
#if defined(_RENDERING_CUTOUT_STOCHASTIC)
  float ar = rand2(i.uv0);
  clip(albedo.a - ar);
#elif defined(_RENDERING_CUTOUT_IGN)
  float ar = ign_anim(
      floor(tdata.screen_uv_round * _Rendering_Cutout_Noise_Scale) + _Rendering_Cutout_Ign_Seed,
      frame, _Rendering_Cutout_Ign_Speed);
  clip(albedo.a - ar);
#elif defined(_RENDERING_CUTOUT_NOISE_MASK)
  float ar = frac(
    _Rendering_Cutout_Noise_Mask.SampleLevel(point_repeat_s, tdata.screen_uv * _ScreenParams.xy * _Rendering_Cutout_Noise_Mask_TexelSize.xy, 0)
    + frame * PHI);
  //return float4(ar, ar, ar, 1);
  clip(albedo.a - ar);
#else
  clip(albedo.a - _Alpha_Cutoff);
#endif
  albedo.a = 1;
#endif

#if defined(_GIMMICK_AL_CHROMA_00)
  if (_Gimmick_AL_Chroma_00_Forward_Pass && AudioLinkIsAvailable()) {
    float3 c = AudioLinkData(ALPASS_CCSTRIP + uint2(0, 0)).rgb;
#if defined(_GIMMICK_AL_CHROMA_00_HUE_SHIFT)
    c = LRGBtoOKLCH(c);
    c[2] += _Gimmick_AL_Chroma_00_Hue_Shift_Theta * 2.0 * 3.14159265;
    c = OKLCHtoLRGB(c);
#endif
    albedo.rgb = lerp(albedo.rgb, c, _Gimmick_AL_Chroma_00_Forward_Blend);
  }
#endif

#if defined(_RIM_LIGHTING0) || defined(_RIM_LIGHTING1) || defined(_RIM_LIGHTING2) || defined(_RIM_LIGHTING3)
  {
#if defined(_RIM_LIGHTING0)
    {
      float3 rl_view_dir = VIEW_DIR(_Rim_Lighting0_Center_Eye_Fix);
#if defined(_RIM_LIGHTING0_CUSTOM_VIEW_VECTOR)
      rl_view_dir.xz = normalize(_Rim_Lighting0_Custom_View_Vector).xz;
#endif
      float2 rl_uv;
      {
#if defined(_RIM_LIGHTING0_REFLECT_IN_WORLD)
        const float3 cam_normal = normal;
        const float3 cam_view_dir = rl_view_dir;
#else
        const float3 cam_normal = normalize(mul(UNITY_MATRIX_V, float4(normal, 0)));
        const float3 cam_view_dir = normalize(mul(UNITY_MATRIX_V, float4(rl_view_dir, 0)));
#endif
        const float3 cam_refl = -reflect(cam_view_dir, cam_normal);
        float m = 2.0 * sqrt(
            cam_refl.x * cam_refl.x +
            cam_refl.y * cam_refl.y +
            (cam_refl.z + 1) * (cam_refl.z + 1));
        rl_uv = cam_refl.xy / m + 0.5;
      }
      float rl = length(rl_uv - 0.5);
      rl = pow(2, -_Rim_Lighting0_Power * abs(rl - _Rim_Lighting0_Center));
      float q = _Rim_Lighting0_Quantization;
      if (q > 0) {
        rl = floor(rl * q) / q;
      }
      float3 matcap = rl * _Rim_Lighting0_Color * _Rim_Lighting0_Strength;
#if defined(_RIM_LIGHTING0_MASK)
      float4 matcap_mask_raw = _Rim_Lighting0_Mask.SampleBias(GET_SAMPLER_RL0,
          get_uv_by_channel(i, _Rim_Lighting0_Mask_UV_Select), _Global_Sample_Bias);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Rim_Lighting0_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif
#if defined(_RIM_LIGHTING0_MASK2)
      float4 matcap_mask2_raw = _Rim_Lighting0_Mask2.SampleBias(GET_SAMPLER_RL0,
          get_uv_by_channel(i, _Rim_Lighting0_Mask2_UV_Select), _Global_Sample_Bias);
      float matcap_mask2 = matcap_mask2_raw.r;
      matcap_mask2 = _Rim_Lighting0_Mask2_Invert_Colors ? 1 - matcap_mask2 : matcap_mask2;
      matcap_mask2 *= _Rim_Lighting0_Mask2_Invert_Alpha ? 1 - matcap_mask2_raw.a : matcap_mask2_raw.a;
      matcap_mask *= matcap_mask2;
#endif
#if defined(_MATCAP0)
        if (_Matcap0_Overwrite_Rim_Lighting_0) {
          matcap_mask *= matcap_overwrite_mask[0];
        }
#endif
#if defined(_MATCAP1)
        if (_Matcap1_Overwrite_Rim_Lighting_0) {
          matcap_mask *= matcap_overwrite_mask[1];
        }
#endif
#if defined(_RIM_LIGHTING0_POLAR_MASK)
        if (_Rim_Lighting0_PolarMask_Enabled) {
          float theta = atan2(rl_uv.y - 0.5, rl_uv.x - 0.5);
          float pmask_theta = _Rim_Lighting0_PolarMask_Theta;
          float pmask_pow = _Rim_Lighting0_PolarMask_Power;
          float d = glsl_mod((theta - pmask_theta) - PI, 2 * PI) - PI;
          float f = abs(1.0 / (1.0 + pow(abs(d), pmask_pow)));
          if (_Rim_Lighting0_Quantization > 0) {
            f = floor(f * _Rim_Lighting0_Quantization) / _Rim_Lighting0_Quantization;
          }
          matcap_mask *= f;
        }
#endif
#if defined(_RIM_LIGHTING0_GLITTER)
      float rl_glitter = get_glitter(
          get_uv_by_channel(i, round(_Rim_Lighting0_Glitter_UV_Select)),
          i.worldPos, CAM_POS(_Rim_Lighting0_Center_Eye_Fix), normal,
          _Rim_Lighting0_Glitter_Density,
          _Rim_Lighting0_Glitter_Amount, _Rim_Lighting0_Glitter_Speed,
          /*mask=*/1, /*angle=*/91, /*power=*/1);
      rl_glitter = floor(rl_glitter * _Rim_Lighting0_Glitter_Quantization) / _Rim_Lighting0_Glitter_Quantization;
      matcap_mask *= rl_glitter;
#endif
      int mode = round(_Rim_Lighting0_Mode);
      switch (mode) {
        case 0:
          albedo.rgb += lerp(0, matcap, matcap_mask);
          matcap_emission += lerp(0, matcap, matcap_mask) * _Rim_Lighting0_Emission;
          break;
        case 1:
          matcap_emission += albedo.rgb * lerp(0, matcap, matcap_mask) * _Rim_Lighting0_Emission;
          albedo.rgb *= lerp(1, matcap, matcap_mask);
          break;
        case 2:
          albedo.rgb = lerp(albedo.rgb, matcap, matcap_mask);
          matcap_emission = lerp(albedo.rgb, matcap, matcap_mask) * _Rim_Lighting0_Emission;
          break;
        case 3:
          albedo.rgb -= lerp(0, matcap, matcap_mask);
          matcap_emission -= lerp(0, matcap, matcap_mask) * _Rim_Lighting0_Emission;
          break;
        case 4:
          albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting0_Emission;
          break;
        case 5:
          albedo.rgb = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting0_Emission;
          break;
        default:
          break;
      }
    }
#endif  // _RIM_LIGHTING0
#if defined(_RIM_LIGHTING1)
    {
      float3 rl_view_dir = VIEW_DIR(_Rim_Lighting1_Center_Eye_Fix);
#if defined(_RIM_LIGHTING1_CUSTOM_VIEW_VECTOR)
      rl_view_dir.xz = normalize(_Rim_Lighting1_Custom_View_Vector).xz;
#endif
      float2 rl_uv;
      {
#if defined(_RIM_LIGHTING1_REFLECT_IN_WORLD)
        const float3 cam_normal = normal;
        const float3 cam_view_dir = rl_view_dir;
#else
        const float3 cam_normal = normalize(mul(UNITY_MATRIX_V, float4(normal, 0)));
        const float3 cam_view_dir = normalize(mul(UNITY_MATRIX_V, float4(rl_view_dir, 0)));
#endif
        const float3 cam_refl = -reflect(cam_view_dir, cam_normal);
        float m = 2.0 * sqrt(
            cam_refl.x * cam_refl.x +
            cam_refl.y * cam_refl.y +
            (cam_refl.z + 1) * (cam_refl.z + 1));
        rl_uv = cam_refl.xy / m + 0.5;
      }
      float rl = length(rl_uv - 0.5);
      rl = pow(2, -_Rim_Lighting1_Power * abs(rl - _Rim_Lighting1_Center));
      float q = _Rim_Lighting1_Quantization;
      if (q > 0) {
        rl = floor(rl * q) / q;
      }
      float3 matcap = rl * _Rim_Lighting1_Color * _Rim_Lighting1_Strength;
#if defined(_RIM_LIGHTING1_MASK)
      float4 matcap_mask_raw = _Rim_Lighting1_Mask.SampleBias(GET_SAMPLER_RL1,
          get_uv_by_channel(i, _Rim_Lighting1_Mask_UV_Select), _Global_Sample_Bias);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Rim_Lighting1_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif
#if defined(_RIM_LIGHTING1_MASK2)
      float4 matcap_mask2_raw = _Rim_Lighting1_Mask2.SampleBias(GET_SAMPLER_RL1,
          get_uv_by_channel(i, _Rim_Lighting1_Mask2_UV_Select), _Global_Sample_Bias);
      float matcap_mask2 = matcap_mask2_raw.r;
      matcap_mask2 = _Rim_Lighting1_Mask2_Invert_Colors ? 1 - matcap_mask2 : matcap_mask2;
      matcap_mask2 *= _Rim_Lighting1_Mask2_Invert_Alpha ? 1 - matcap_mask2_raw.a : matcap_mask2_raw.a;
      matcap_mask *= matcap_mask2;
#endif
#if defined(_MATCAP0)
        if (_Matcap0_Overwrite_Rim_Lighting_1) {
          matcap_mask *= matcap_overwrite_mask[0];
        }
#endif
#if defined(_MATCAP1)
        if (_Matcap1_Overwrite_Rim_Lighting_1) {
          matcap_mask *= matcap_overwrite_mask[1];
        }
#endif
#if defined(_RIM_LIGHTING1_POLAR_MASK)
        if (_Rim_Lighting1_PolarMask_Enabled) {
          float theta = atan2(rl_uv.y - 0.5, rl_uv.x - 0.5);
          float pmask_theta = _Rim_Lighting1_PolarMask_Theta;
          float pmask_pow = _Rim_Lighting1_PolarMask_Power;
          float d = glsl_mod((theta - pmask_theta) - PI, 2 * PI) - PI;
          float f = abs(1.0 / (1.0 + pow(abs(d), pmask_pow)));
          if (_Rim_Lighting1_Quantization > 0) {
            f = floor(f * _Rim_Lighting1_Quantization) / _Rim_Lighting1_Quantization;
          }
          matcap_mask *= f;
        }
#endif
#if defined(_RIM_LIGHTING1_GLITTER)
      float rl_glitter = get_glitter(
          get_uv_by_channel(i, round(_Rim_Lighting1_Glitter_UV_Select)),
          i.worldPos, CAM_POS(_Rim_Lighting1_Center_Eye_Fix), normal,
          _Rim_Lighting1_Glitter_Density,
          _Rim_Lighting1_Glitter_Amount, _Rim_Lighting1_Glitter_Speed,
          /*mask=*/1, /*angle=*/91, /*power=*/1);
      rl_glitter = floor(rl_glitter * _Rim_Lighting1_Glitter_Quantization) / _Rim_Lighting1_Glitter_Quantization;
      matcap_mask *= rl_glitter;
#endif
      int mode = round(_Rim_Lighting1_Mode);
      switch (mode) {
        case 0:
          albedo.rgb += lerp(0, matcap, matcap_mask);
          matcap_emission += lerp(0, matcap, matcap_mask) * _Rim_Lighting1_Emission;
          break;
        case 1:
          matcap_emission += albedo.rgb * lerp(0, matcap, matcap_mask) * _Rim_Lighting1_Emission;
          albedo.rgb *= lerp(1, matcap, matcap_mask);
          break;
        case 2:
          albedo.rgb = lerp(albedo.rgb, matcap, matcap_mask);
          matcap_emission = lerp(albedo.rgb, matcap, matcap_mask) * _Rim_Lighting1_Emission;
          break;
        case 3:
          albedo.rgb -= lerp(0, matcap, matcap_mask);
          matcap_emission -= lerp(0, matcap, matcap_mask) * _Rim_Lighting1_Emission;
          break;
        case 4:
          albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting1_Emission;
          break;
        case 5:
          albedo.rgb = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting1_Emission;
          break;
        default:
          break;
      }
    }
#endif  // _RIM_LIGHTING1
#if defined(_RIM_LIGHTING2)
    {
      float3 rl_view_dir = VIEW_DIR(_Rim_Lighting2_Center_Eye_Fix);
#if defined(_RIM_LIGHTING2_CUSTOM_VIEW_VECTOR)
      rl_view_dir.xz = normalize(_Rim_Lighting2_Custom_View_Vector).xz;
#endif
      float2 rl_uv;
      {
#if defined(_RIM_LIGHTING2_REFLECT_IN_WORLD)
        const float3 cam_normal = normal;
        const float3 cam_view_dir = rl_view_dir;
#else
        const float3 cam_normal = normalize(mul(UNITY_MATRIX_V, float4(normal, 0)));
        const float3 cam_view_dir = normalize(mul(UNITY_MATRIX_V, float4(rl_view_dir, 0)));
#endif
        const float3 cam_refl = -reflect(cam_view_dir, cam_normal);
        float m = 2.0 * sqrt(
            cam_refl.x * cam_refl.x +
            cam_refl.y * cam_refl.y +
            (cam_refl.z + 1) * (cam_refl.z + 1));
        rl_uv = cam_refl.xy / m + 0.5;
      }
      float rl = length(rl_uv - 0.5);
      rl = pow(2, -_Rim_Lighting2_Power * abs(rl - _Rim_Lighting2_Center));
      float q = _Rim_Lighting2_Quantization;
      if (q > 0) {
        rl = floor(rl * q) / q;
      }
      float3 matcap = rl * _Rim_Lighting2_Color * _Rim_Lighting2_Strength;
#if defined(_RIM_LIGHTING2_MASK)
      float4 matcap_mask_raw = _Rim_Lighting2_Mask.SampleBias(GET_SAMPLER_RL2,
          get_uv_by_channel(i, _Rim_Lighting2_Mask_UV_Select), _Global_Sample_Bias);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Rim_Lighting2_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif
#if defined(_RIM_LIGHTING2_MASK2)
      float4 matcap_mask2_raw = _Rim_Lighting2_Mask2.SampleBias(GET_SAMPLER_RL2,
          get_uv_by_channel(i, _Rim_Lighting2_Mask2_UV_Select), _Global_Sample_Bias);
      float matcap_mask2 = matcap_mask2_raw.r;
      matcap_mask2 = _Rim_Lighting2_Mask2_Invert_Colors ? 1 - matcap_mask2 : matcap_mask2;
      matcap_mask2 *= _Rim_Lighting2_Mask2_Invert_Alpha ? 1 - matcap_mask2_raw.a : matcap_mask2_raw.a;
      matcap_mask *= matcap_mask2;
#endif
#if defined(_MATCAP0)
        if (_Matcap0_Overwrite_Rim_Lighting_2) {
          matcap_mask *= matcap_overwrite_mask[0];
        }
#endif
#if defined(_MATCAP1)
        if (_Matcap1_Overwrite_Rim_Lighting_2) {
          matcap_mask *= matcap_overwrite_mask[1];
        }
#endif
#if defined(_RIM_LIGHTING2_POLAR_MASK)
        if (_Rim_Lighting2_PolarMask_Enabled) {
          float theta = atan2(rl_uv.y - 0.5, rl_uv.x - 0.5);
          float pmask_theta = _Rim_Lighting2_PolarMask_Theta;
          float pmask_pow = _Rim_Lighting2_PolarMask_Power;
          float d = glsl_mod((theta - pmask_theta) - PI, 2 * PI) - PI;
          float f = abs(1.0 / (1.0 + pow(abs(d), pmask_pow)));
          if (_Rim_Lighting2_Quantization > 0) {
            f = floor(f * _Rim_Lighting2_Quantization) / _Rim_Lighting2_Quantization;
          }
          matcap_mask *= f;
        }
#endif
#if defined(_RIM_LIGHTING2_GLITTER)
      float rl_glitter = get_glitter(
          get_uv_by_channel(i, round(_Rim_Lighting2_Glitter_UV_Select)),
          i.worldPos, CAM_POS(_Rim_Lighting2_Center_Eye_Fix), normal,
          _Rim_Lighting2_Glitter_Density,
          _Rim_Lighting2_Glitter_Amount, _Rim_Lighting2_Glitter_Speed,
          /*mask=*/1, /*angle=*/91, /*power=*/1);
      rl_glitter = floor(rl_glitter * _Rim_Lighting2_Glitter_Quantization) / _Rim_Lighting2_Glitter_Quantization;
      matcap_mask *= rl_glitter;
#endif
      int mode = round(_Rim_Lighting2_Mode);
      switch (mode) {
        case 0:
          albedo.rgb += lerp(0, matcap, matcap_mask);
          matcap_emission += lerp(0, matcap, matcap_mask) * _Rim_Lighting2_Emission;
          break;
        case 1:
          matcap_emission += albedo.rgb * lerp(0, matcap, matcap_mask) * _Rim_Lighting2_Emission;
          albedo.rgb *= lerp(1, matcap, matcap_mask);
          break;
        case 2:
          albedo.rgb = lerp(albedo.rgb, matcap, matcap_mask);
          matcap_emission = lerp(albedo.rgb, matcap, matcap_mask) * _Rim_Lighting2_Emission;
          break;
        case 3:
          albedo.rgb -= lerp(0, matcap, matcap_mask);
          matcap_emission -= lerp(0, matcap, matcap_mask) * _Rim_Lighting2_Emission;
          break;
        case 4:
          albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting2_Emission;
          break;
        case 5:
          albedo.rgb = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting2_Emission;
          break;
        default:
          break;
      }
    }
#endif  // _RIM_LIGHTING2
#if defined(_RIM_LIGHTING3)
    {
      float3 rl_view_dir = VIEW_DIR(_Rim_Lighting3_Center_Eye_Fix);
#if defined(_RIM_LIGHTING3_CUSTOM_VIEW_VECTOR)
      rl_view_dir.xz = normalize(_Rim_Lighting3_Custom_View_Vector).xz;
#endif
      float2 rl_uv;
      {
#if defined(_RIM_LIGHTING3_REFLECT_IN_WORLD)
        const float3 cam_normal = normal;
        const float3 cam_view_dir = rl_view_dir;
#else
        const float3 cam_normal = normalize(mul(UNITY_MATRIX_V, float4(normal, 0)));
        const float3 cam_view_dir = normalize(mul(UNITY_MATRIX_V, float4(rl_view_dir, 0)));
#endif
        const float3 cam_refl = -reflect(cam_view_dir, cam_normal);
        float m = 2.0 * sqrt(
            cam_refl.x * cam_refl.x +
            cam_refl.y * cam_refl.y +
            (cam_refl.z + 1) * (cam_refl.z + 1));
        rl_uv = cam_refl.xy / m + 0.5;
      }
      float rl = length(rl_uv - 0.5);
      rl = pow(2, -_Rim_Lighting3_Power * abs(rl - _Rim_Lighting3_Center));
      float q = _Rim_Lighting3_Quantization;
      if (q > 0) {
        rl = floor(rl * q) / q;
      }
      float3 matcap = rl * _Rim_Lighting3_Color * _Rim_Lighting3_Strength;
#if defined(_RIM_LIGHTING3_MASK)
      float4 matcap_mask_raw = _Rim_Lighting3_Mask.SampleBias(GET_SAMPLER_RL3,
          get_uv_by_channel(i, _Rim_Lighting3_Mask_UV_Select), _Global_Sample_Bias);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Rim_Lighting3_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;
#else
      float matcap_mask = 1;
#endif
#if defined(_RIM_LIGHTING3_MASK2)
      float4 matcap_mask2_raw = _Rim_Lighting3_Mask2.SampleBias(GET_SAMPLER_RL3,
          get_uv_by_channel(i, _Rim_Lighting3_Mask2_UV_Select), _Global_Sample_Bias);
      float matcap_mask2 = matcap_mask2_raw.r;
      matcap_mask2 = _Rim_Lighting3_Mask2_Invert_Colors ? 1 - matcap_mask2 : matcap_mask2;
      matcap_mask2 *= _Rim_Lighting3_Mask2_Invert_Alpha ? 1 - matcap_mask2_raw.a : matcap_mask2_raw.a;
      matcap_mask *= matcap_mask2;
#endif
#if defined(_MATCAP0)
        if (_Matcap0_Overwrite_Rim_Lighting_3) {
          matcap_mask *= matcap_overwrite_mask[0];
        }
#endif
#if defined(_MATCAP1)
        if (_Matcap1_Overwrite_Rim_Lighting_3) {
          matcap_mask *= matcap_overwrite_mask[1];
        }
#endif
#if defined(_RIM_LIGHTING3_POLAR_MASK)
        if (_Rim_Lighting3_PolarMask_Enabled) {
          float theta = atan2(rl_uv.y - 0.5, rl_uv.x - 0.5);
          float pmask_theta = _Rim_Lighting3_PolarMask_Theta;
          float pmask_pow = _Rim_Lighting3_PolarMask_Power;
          float d = glsl_mod((theta - pmask_theta) - PI, 2 * PI) - PI;
          float f = abs(1.0 / (1.0 + pow(abs(d), pmask_pow)));
          if (_Rim_Lighting3_Quantization > 0) {
            f = floor(f * _Rim_Lighting3_Quantization) / _Rim_Lighting3_Quantization;
          }
          matcap_mask *= f;
        }
#endif
#if defined(_RIM_LIGHTING3_GLITTER)
      float rl_glitter = get_glitter(
          get_uv_by_channel(i, round(_Rim_Lighting3_Glitter_UV_Select)),
          i.worldPos, CAM_POS(_Rim_Lighting3_Center_Eye_Fix), normal,
          _Rim_Lighting3_Glitter_Density,
          _Rim_Lighting3_Glitter_Amount, _Rim_Lighting3_Glitter_Speed,
          /*mask=*/1, /*angle=*/91, /*power=*/1);
      rl_glitter = floor(rl_glitter * _Rim_Lighting3_Glitter_Quantization) / _Rim_Lighting3_Glitter_Quantization;
      matcap_mask *= rl_glitter;
#endif
      int mode = round(_Rim_Lighting3_Mode);
      switch (mode) {
        case 0:
          albedo.rgb += lerp(0, matcap, matcap_mask);
          matcap_emission += lerp(0, matcap, matcap_mask) * _Rim_Lighting3_Emission;
          break;
        case 1:
          matcap_emission += albedo.rgb * lerp(0, matcap, matcap_mask) * _Rim_Lighting3_Emission;
          albedo.rgb *= lerp(1, matcap, matcap_mask);
          break;
        case 2:
          albedo.rgb = lerp(albedo.rgb, matcap, matcap_mask);
          matcap_emission = lerp(albedo.rgb, matcap, matcap_mask) * _Rim_Lighting3_Emission;
          break;
        case 3:
          albedo.rgb -= lerp(0, matcap, matcap_mask);
          matcap_emission -= lerp(0, matcap, matcap_mask) * _Rim_Lighting3_Emission;
          break;
        case 4:
          albedo.rgb = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, min(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting3_Emission;
          break;
        case 5:
          albedo.rgb = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask);
          matcap_emission = lerp(albedo.rgb, max(albedo.rgb, matcap), matcap_mask) * _Rim_Lighting3_Emission;
          break;
        default:
          break;
      }
    }
#endif  // _RIM_LIGHTING3
  }
#endif  // _RIM_LIGHTING0 || _RIM_LIGHTING1 || _RIM_LIGHTING2 || _RIM_LIGHTING3

#if defined(_GIMMICK_LETTER_GRID)
  float3 gimmick_letter_grid_emission = 0;
  {
    int2 cell_pos;
    int2 font_res = int2(round(_Gimmick_Letter_Grid_Tex_Res_X), round(_Gimmick_Letter_Grid_Tex_Res_Y)); 
    int2 grid_res = int2(round(_Gimmick_Letter_Grid_Res_X), round(_Gimmick_Letter_Grid_Res_Y)); 
    float2 cell_uv;  // uv within each letter cell

    float4 scoff = _Gimmick_Letter_Grid_UV_Scale_Offset;
    float2 uv = ((get_uv_by_channel(i, _Gimmick_Letter_Grid_UV_Select) - 0.5) - scoff.zw) * scoff.xy + 0.5;
    bool in_box = getBoxLoc(uv,
        /*bottom_left=*/0,
        /*top_right=*/1,
        /*res=*/grid_res,
        /*padding=*/_Gimmick_Letter_Grid_Padding,
        cell_pos, cell_uv);

    float n_glyphs = font_res.x * font_res.y;
    float cell_rand = rand2(cell_pos);
    float c = glsl_mod(cell_pos.y * grid_res.x + cell_pos.x + cell_rand * n_glyphs + _Time[3], n_glyphs);
    float3 msd = renderInBox(c, uv, cell_uv, _Gimmick_Letter_Grid_Texture, font_res).rgb;
    float sd = median(msd);
    float px_range = 2;  // determined by msdf-atlas-gen.exe; 2 is default
    float2 unit_range = px_range / 1024;
    float2 screen_tex_size = 1 / fwidth(cell_uv);
    float screen_px_range = max(0.5 * dot(unit_range, screen_tex_size), 1.0);
    float screen_px_distance = screen_px_range * (sd - 0.5);
    float op = saturate(screen_px_distance + 0.5);
    op = saturate(floor(op * 4));

    float4 grid_color = _Gimmick_Letter_Grid_Color;

#if defined(_GIMMICK_LETTER_GRID_COLOR_WAVE)
    {
      float2 c = grid_res/2;
      float d = floor(length(cell_pos - c));
      d *= _Gimmick_Letter_Grid_Color_Wave_Frequency;

      float3 col = LRGBtoOKLCH(grid_color.rgb);
      col[2] += d - _Time[3] * _Gimmick_Letter_Grid_Color_Wave_Speed;
      col = OKLCHtoLRGB(col);
      grid_color.rgb = col;
    }
#endif  // _GIMMICK_LETTER_GRID_COLOR_WAVE
#if defined(_GIMMICK_LETTER_GRID_RIM_LIGHTING)
    {
      float theta = atan2(length(cross(MATCAP_VIEW_DIR(), normal)), dot(MATCAP_VIEW_DIR(), normal));
      float rl = abs(theta) / PI;  // on [0, 1]
      rl = pow(2, -_Gimmick_Letter_Grid_Rim_Lighting_Power * abs(rl - _Gimmick_Letter_Grid_Rim_Lighting_Center));
      float q = _Gimmick_Letter_Grid_Rim_Lighting_Quantization;
      if (q > 0) {
        rl = floor(rl * q) / q;
      }

      float4 matcap_mask_raw = _Gimmick_Letter_Grid_Rim_Lighting_Mask.SampleBias(GET_SAMPLER_RL3,
          get_uv_by_channel(i, _Gimmick_Letter_Grid_Rim_Lighting_Mask_UV_Select), _Global_Sample_Bias);
      float matcap_mask = matcap_mask_raw.r;
      matcap_mask = (bool) round(_Gimmick_Letter_Grid_Rim_Lighting_Mask_Invert) ? 1 - matcap_mask : matcap_mask;
      matcap_mask *= matcap_mask_raw.a;

      op *= rl * matcap_mask;
    }
#endif  // GIMMICK_LETTER_GRID_RIM_LIGHTING

    albedo = lerp(albedo, grid_color, op * in_box);
    metallic = lerp(metallic, _Gimmick_Letter_Grid_Metallic, op * in_box);
    //metallic = lerp(metallic, glsl_mod(_Time[3], 1.0), op * in_box);
    roughness = lerp(roughness, _Gimmick_Letter_Grid_Roughness, op * in_box);
    gimmick_letter_grid_emission = _Gimmick_Letter_Grid_Color * _Gimmick_Letter_Grid_Emission * op * in_box;
  }
#endif  // _GIMMICK_LETTER_GRID

#if defined(_GIMMICK_LETTER_GRID_2)
  float3 gimmick_letter_grid_2_emission = 0;
#if defined(_GIMMICK_LETTER_GRID_2_MASK)
  float mask = _Gimmick_Letter_Grid_2_Mask.SampleLevel(linear_repeat_s, get_uv_by_channel(i, 0), 0);
#else
  float mask = 1;
#endif
  {
    int2 cell_pos;
    int2 font_res = int2(round(_Gimmick_Letter_Grid_2_Tex_Res_X), round(_Gimmick_Letter_Grid_2_Tex_Res_Y));
    int2 grid_res = int2(round(_Gimmick_Letter_Grid_2_Res_X), round(_Gimmick_Letter_Grid_2_Res_Y));
    float2 cell_uv;  // uv within each letter cell

    float4 scoff = _Gimmick_Letter_Grid_2_UV_Scale_Offset;
    float2 uv = ((get_uv_by_channel(i, 0) - 0.5) - scoff.zw) * scoff.xy + 0.5;

    bool in_box = getBoxLoc(uv,
        /*bottom_left=*/0,
        /*top_right=*/1,
        /*res=*/grid_res,
        /*padding=*/_Gimmick_Letter_Grid_2_Padding,
        cell_pos, cell_uv);

    // Extract char from _Gimmick_Letter_Grid_2_Data_Row_0 et al using cell_pos.
    cell_pos.y = (grid_res.y - cell_pos.y) - 1;
    float c = lerp(
      lerp(
        _Gimmick_Letter_Grid_2_Data_Row_0[cell_pos.x],
        _Gimmick_Letter_Grid_2_Data_Row_1[cell_pos.x],
        cell_pos.y),
      lerp(
        _Gimmick_Letter_Grid_2_Data_Row_2[cell_pos.x],
        _Gimmick_Letter_Grid_2_Data_Row_3[cell_pos.x],
        cell_pos.y - 2),
      cell_pos.y/2);
    c += _Gimmick_Letter_Grid_2_Global_Offset;

    float3 msd = renderInBox(c, uv, cell_uv, _Gimmick_Letter_Grid_2_Texture, font_res).rgb;
    float sd = median(msd);
    // screenPxRange()
    float screen_px_range;
    {
      float2 tex_size = float2(_Gimmick_Letter_Grid_2_Texture_TexelSize.zw);
      float2 real_cell_size = floor(tex_size / grid_res);  // size of cell in texels
      float2 unit_range = _Gimmick_Letter_Grid_2_Screen_Px_Range / real_cell_size;
      // fwidth(x) = abs(abs(ddx(x)) + abs(ddy(x)))
      // 1 / fwidth(cell_uv)
      //   = 1 / abs(abs(ddx(cell_uv)) + abs(ddy(cell_uv)))
      // This is just the manhattan length of the triangle with edges
      //   ddx(cell_uv.x) and ddy(cell_uv.x).
      // In other words, an approximation of the gradient of cell_uv.x.

      // fwidth is an approximation showing how much cell_uv changes per pixel.
      // By inverting it, we get an approximation of how many pixels are
      // spanned by the whole texture, if it was rendered with this pixel's
      // properties.
      float2 screen_tex_size = 1 / fwidth(cell_uv);

      screen_px_range = max(0.5 * dot(unit_range, screen_tex_size), _Gimmick_Letter_Grid_2_Min_Screen_Px_Range);
    }
    float screen_px_distance = screen_px_range * (sd - _Gimmick_Letter_Grid_2_Alpha_Threshold);
    float smooth_range = (length(grid_res) / sqrt(screen_px_range)) * _Gimmick_Letter_Grid_2_Blurriness;
    float op = smoothstep(-smooth_range, smooth_range, screen_px_distance);
    op *= mask;
    //op = floor(op);

    albedo = lerp(albedo, _Gimmick_Letter_Grid_2_Color, op * in_box);
    metallic = lerp(metallic, _Gimmick_Letter_Grid_2_Metallic, op * in_box);
    roughness = lerp(roughness, _Gimmick_Letter_Grid_2_Roughness, op * in_box);
    gimmick_letter_grid_2_emission = _Gimmick_Letter_Grid_2_Color * _Gimmick_Letter_Grid_2_Emission * op * in_box;
  }
#endif  // _GIMMICK_LETTER_GRID


#if defined(_OKLAB)
  // Do hue shift in perceptually uniform color space so it doesn't look like
  // shit.
 float oklab_mask = _OKLAB_Mask.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
 if (_OKLAB_Mask_Invert) {
   oklab_mask = 1 - oklab_mask;
 }
 if (oklab_mask > 0.01 &&
     (_OKLAB_Hue_Shift > 1E-6 ||
      abs(_OKLAB_Chroma_Shift) > 1E-6 ||
      abs(_OKLAB_Lightness_Shift) > 1E-6)) {
   float3 c = albedo.rgb;
   c = LRGBtoOKLCH(c);
   c.x += _OKLAB_Lightness_Shift;
   c.y += _OKLAB_Chroma_Shift;
   c.z += _OKLAB_Hue_Shift;
   c = OKLCHtoLRGB(c);
   albedo.rgb = c;
 }
#endif

#if defined(_HSV0)
 {
   float hsv_mask = _HSV0_Mask.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
   if (_HSV0_Mask_Invert) {
     hsv_mask = 1 - hsv_mask;
   }
   if (hsv_mask > 0.01 &&
       (_HSV0_Hue_Shift > 1E-6 ||
        abs(_HSV0_Sat_Shift) > 1E-6 ||
        abs(_HSV0_Val_Shift) > 1E-6)) {
     float3 c = albedo.rgb;
     c = RGBtoHSV(c);
     c += float3(_HSV0_Hue_Shift, _HSV0_Sat_Shift, _HSV0_Val_Shift);
     c.x = glsl_mod(c.x, 1.0);
     c.yz = saturate(c.yz);
     c = HSVtoRGB(c);
     albedo.rgb = c;
   }
 }
#endif

#if defined(_HSV1)
 {
   float hsv_mask = _HSV1_Mask.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
   if (_HSV1_Mask_Invert) {
     hsv_mask = 1 - hsv_mask;
   }
   if (hsv_mask > 0.01 &&
       (_HSV1_Hue_Shift > 1E-6 ||
        abs(_HSV1_Sat_Shift) > 1E-6 ||
        abs(_HSV1_Val_Shift) > 1E-6)) {
     float3 c = albedo.rgb;
     c = RGBtoHSV(c);
     c += float3(_HSV1_Hue_Shift, _HSV1_Sat_Shift, _HSV1_Val_Shift);
     c.x = glsl_mod(c.x, 1.0);
     c.yz = saturate(c.yz);
     c = HSVtoRGB(c);
     albedo.rgb = c;
   }
 }
#endif

#if defined(_HSV2)
 {
   float hsv_mask = _HSV2_Mask.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
   if (_HSV2_Mask_Invert) {
     hsv_mask = 1 - hsv_mask;
   }
   if (hsv_mask > 0.01 &&
       (_HSV2_Hue_Shift > 1E-6 ||
        abs(_HSV2_Sat_Shift) > 1E-6 ||
        abs(_HSV2_Val_Shift) > 1E-6)) {
     float3 c = albedo.rgb;
     c = RGBtoHSV(c);
     c += float3(_HSV2_Hue_Shift, _HSV2_Sat_Shift, _HSV2_Val_Shift);
     c.x = glsl_mod(c.x, 1.0);
     c.yz = saturate(c.yz);
     c = HSVtoRGB(c);
     albedo.rgb = c;
   }
 }
#endif

#if defined(_AMBIENT_OCCLUSION)
  float ao = _Ambient_Occlusion.SampleBias(linear_repeat_s,
      UV_SCOFF(i, _Ambient_Occlusion_ST, /*uv_channel=*/0),
      _Global_Sample_Bias);
  ao = 1 - (1 - ao) * _Ambient_Occlusion_Strength;
#else
  float ao = 1;
#endif

  float3 diffuse_contrib = 0;
#if defined(_GIMMICK_FOG_00)
  {
    Fog00PBR pbr = getFog00(i, tdata);
    albedo = pbr.albedo;
    depth = pbr.depth;
#if defined(_RENDERING_TRANSPARENT) || defined(_RENDERING_TRANSCLIPPING)
    albedo.rgb *= albedo.a;
#endif
    return albedo;
  }
#endif
#if defined(_GIMMICK_FOG_01)
  if (!round(_Gimmick_Fog_01_Overlay_Mode)) {
    Fog01PBR fog_01_pbr = getFog01(i, tdata);
    albedo = fog_01_pbr.albedo;
    depth = fog_01_pbr.depth;
#if defined(_RENDERING_TRANSPARENT) || defined(_RENDERING_TRANSCLIPPING)
    albedo.rgb *= albedo.a;
#endif
    return albedo;
  }
#endif
#if defined(_GIMMICK_AURORA)
  {
    AuroraPBR pbr = getAurora(i);
    albedo = pbr.albedo;
    depth = pbr.depth;
    diffuse_contrib += pbr.diffuse;
  }
#endif

#if defined(_GIMMICK_FLAT_COLOR)
  if (round(_Gimmick_Flat_Color_Enable_Dynamic)) {
    albedo = _Gimmick_Flat_Color_Color;
    normal = i.normal;
  }
#endif
#if defined(_GLITTER)
  float3 glitter_color_unlit;
  {
    float glitter_mask =
      _Glitter_Mask.SampleLevel(linear_repeat_s, i.uv0, /*lod=*/0);
    glitter_mask *= min(matcap_overwrite_mask[0], matcap_overwrite_mask[1]);
    glitter_mask *= overlay_glitter_mask;
    float glitter = get_glitter(
        get_uv_by_channel(i, round(_Glitter_UV_Select)),
        i.worldPos, i.centerCamPos, normal,
        _Glitter_Density, _Glitter_Amount, _Glitter_Speed,
        glitter_mask, _Glitter_Angle, _Glitter_Power);
        glitter_color_unlit = glitter * _Glitter_Color;
  }
  albedo.rgb += glitter_color_unlit * _Glitter_Brightness_Lit;
#endif

#if defined(_GIMMICK_DS2)
  Gimmick_DS2_Output ds2 = (Gimmick_DS2_Output)0;
  // TODO if these remain mutually exclusive, we should use an enum + switch
  switch (round(_Gimmick_DS2_Choice)) {
    case 0:
      ds2 = Gimmick_DS2_00(i);
      break;
    case 1:
      ds2 = Gimmick_DS2_01(i);
      break;
    case 2:
      ds2 = Gimmick_DS2_02(i);
      break;
    case 3:
      ds2 = Gimmick_DS2_03(i);
      break;
    case 10:
      ds2 = Gimmick_DS2_10(i);
      break;
    case 11:
      ds2 = Gimmick_DS2_11(i, tdata);
      break;
    default:
      ds2 = (Gimmick_DS2_Output)0;
      break;
  }
  float ds2_mask = _Gimmick_DS2_Mask.SampleLevel(linear_clamp_s, i.uv0, 0);
  albedo = ds2.albedo * _Gimmick_DS2_Albedo_Factor * ds2_mask;
  normal = ds2.normal;
  metallic = ds2.metallic * ds2_mask;
  roughness = ds2.roughness;
  i.worldPos = ds2.worldPos;
  {
    float4 clip_pos = mul(UNITY_MATRIX_VP, float4(ds2.worldPos, 1.0));
    depth = clip_pos.z / clip_pos.w;
  }
#endif

  float4 lit = getLitColor(vertex_light_color, albedo, i.worldPos, normal,
      metallic, 1.0 - roughness, i.uv0, ao, /*enable_direct=*/true,
      diffuse_contrib, i, tdata);

#if defined(_GIMMICK_FLAT_COLOR)
  if (round(_Gimmick_Flat_Color_Enable_Dynamic)) {
#if defined(_RENDERING_CUTOUT)
#if defined(_RENDERING_CUTOUT_STOCHASTIC)
    float ar = rand2(i.uv0);
    clip(albedo.a - ar);
#else
    clip(albedo.a - _Alpha_Cutoff);
#endif
    albedo.a = 1;
#endif
    return float4(lit.rgb +
        _Gimmick_Flat_Color_Emission * _Global_Emission_Factor,
        albedo.a);
  }
#endif

  float4 result = lit;
#if defined(_MATCAP0) || defined(_MATCAP1) || defined(_RIM_LIGHTING0) || defined(_RIM_LIGHTING1)
  result.rgb += matcap_emission * _Global_Emission_Factor;
#endif
#if defined(_DECAL0) || defined(_DECAL1) || defined(_DECAL2) || defined(_DECAL3) || defined(_DECAL4) || defined(_DECAL5) || defined(_DECAL6) || defined(_DECAL7) || defined(_DECAL8) || defined(_DECAL9)
  result.rgb += decal_emission * _Global_Emission_Factor;
#endif
#if defined(_GLITTER)
  result.rgb += glitter_color_unlit * _Glitter_Brightness;
#endif
#if defined(_GIMMICK_DS2)
  result = ds2.fog + result * (1 - ds2.fog.a);
  result.rgb += ds2.emission * _Gimmick_DS2_Emission_Factor * ds2_mask;
#endif

#if defined(_GIMMICK_FOG_01)
  if (round(_Gimmick_Fog_01_Overlay_Mode)) {
    float4 fog_color = apply_fog(
      length(i.worldPos.xyz - getCenterCamPos()),
      _Gimmick_Fog_01_Density,
      normalize(i.worldPos.xyz - getCenterCamPos()),
      _Gimmick_Fog_01_Sun_Direction,
      _Gimmick_Fog_01_Sun_Color,
      _Gimmick_Fog_01_Sun_Exponent,
      _Gimmick_Fog_01_Sun_Color_2_Enable,
      _Gimmick_Fog_01_Sun_Color_2,
      _Gimmick_Fog_01_Sun_Exponent_2,
      _Gimmick_Fog_01_Color
    );
    result.xyz = fog_color * fog_color.a + result * (1 - fog_color.a);
  }
#endif

#if defined(_ACES_FILMIC)
  result.rgb = aces_filmic(max(result.rgb, 0));
#endif

  // This version exists for compatibility with the Bakery lightmapper. We
  // specifically need to expose _EmissionMap and _EmissionColor.
#if defined(_EMISSION)
  {
    float3 emission = _EmissionMap.SampleBias(linear_repeat_s, i.uv0, _Global_Sample_Bias);
    result.rgb += emission * _EmissionColor * _Global_Emission_Factor;
  }
#endif
#if defined(_EMISSION0)
  {
    float3 emission = _Emission0Tex.SampleBias(linear_repeat_s, get_uv_by_channel(i, round(_Emission0_UV_Select)), _Global_Sample_Bias);
    result.rgb += emission * _Emission0Color *
      _Global_Emission_Factor * _Emission0Multiplier;
  }
#endif
#if defined(_EMISSION1)
  {
    float3 emission = _Emission1Tex.SampleBias(linear_repeat_s, get_uv_by_channel(i, round(_Emission1_UV_Select)), _Global_Sample_Bias);
    result.rgb += emission * _Emission1Color *
      _Global_Emission_Factor * _Emission1Multiplier;
  }
#endif
#if defined(_RORSCHACH)
  result.rgb += rorschach_albedo.rgb * _Rorschach_Emission_Strength;
#endif
#if defined(_GIMMICK_LETTER_GRID)
  result.rgb += gimmick_letter_grid_emission;
#endif
#if defined(_GIMMICK_LETTER_GRID_2)
  result.rgb += gimmick_letter_grid_2_emission;
#endif

#if defined(_EXPLODE) && defined(_AUDIOLINK)
  if (AudioLinkIsAvailable() && _Explode_Phase > 1E-6) {
    float4 al_color =
      AudioLinkData(
          ALPASS_CCLIGHTS +
          uint2(uint(i.uv0.x * 8) + uint(i.uv0.y * 16) * 8, 0 )).rgba;
    result = lerp(result, al_color, _Explode_Phase * _Explode_Phase);
  }
#endif
#if defined(_RENDERING_TRANSPARENT) || defined(_RENDERING_TRANSCLIPPING)
  result.rgb *= result.a;
#endif
  result.rgb += getOverlayEmission(ov, i) * _Global_Emission_Factor;
  result.rgb += _Global_Emission_Additive_Factor * albedo.rgb;

  return result;
}

fixed4 frag(v2f i
#if defined(EXPERIMENT__CUSTOM_DEPTH)
, out float depth: SV_DepthGreaterEqual
#endif
    ) : SV_Target
{
#if !defined(EXPERIMENT__CUSTOM_DEPTH)
  float depth;
#endif
  UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);
  UNITY_SETUP_INSTANCE_ID(i);
  UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

/*
#if defined(_TROCHOID)
  float3x3 vector_mover = cyl2_to_troch_jacobian(i.objPos_pre_trochoid);
  float det = determinant(vector_mover);
  det = saturate(abs(det));
  return float4(det, det, det, 1);
#endif
*/

  return effect(i, depth);
}

#endif  // TOONER_LIGHTING

