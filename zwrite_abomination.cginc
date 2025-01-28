#include "UnityCG.cginc"

#include "globals.cginc"
#include "iq_sdf.cginc"
#include "interpolators.cginc"

#ifndef __ZWRITE_ABOMINATION_INC
#define __ZWRITE_ABOMINATION_INC

#if defined(_GIMMICK_ZWRITE_ABOMINATION)

struct ZWriteAbominationPBR {
  float3 worldPos;
  float3 normal;
  float4 albedo;
  float metallic;
  float roughness;
  float depth;
};

#define BODY_PART_BODY 0
#define BODY_PART_LENS 1
#define BODY_PART_EYE_WHITE 2
#define BODY_PART_PUPIL 3
#define BODY_PART_ARM 4
#define BODY_PART_LEG 5
#define BODY_PART_MOUTH 6
#define BODY_PART_DENIM 7
#define BODY_PART_DENIM_STRAP 7
#define BODY_PART_EYE_STRAP 8

float zwrite_abomination_map(float3 p, out uint body_part) {
    float epsilon = 1E-4;
    float d;

    // Capsule representing body
    {
        float body_half_height = _Gimmick_ZWrite_Abomination_Body_Half_Height;
        float body_radius = _Gimmick_ZWrite_Abomination_Body_Radius;
        float body_d = distance_from_capsule(p, float3(0, -body_half_height, 0), float3(0, body_half_height, 0), body_radius);
        body_part = BODY_PART_BODY;
        d = body_d;
    }

    // Capsule representing denim
    {
        float3 denim_center = _Gimmick_ZWrite_Abomination_Denim_Center;
        float3 pp = p - denim_center;
        float denim_half_height = _Gimmick_ZWrite_Abomination_Denim_Half_Height;
        float denim_radius = _Gimmick_ZWrite_Abomination_Denim_Radius;
        float denim_d = distance_from_capsule(pp, float3(0, -denim_half_height, 0), float3(0, denim_half_height, 0), denim_radius);
        body_part = denim_d < d ? BODY_PART_DENIM : body_part;
        d = min(d, denim_d);
    }

    // Torus representing denim strap
    {
        float3 strap_center = _Gimmick_ZWrite_Abomination_Denim_Strap_Center;
        float3 pp = p;
        pp.x = abs(pp.x);
        pp -= strap_center;
        // Rotate about z axis
        float theta = _Gimmick_ZWrite_Abomination_Denim_Strap_Z_Theta;
        float2x2 rot = float2x2(float2(cos(theta), -sin(theta)), float2(sin(theta), cos(theta)));
        pp.xy = mul(rot, pp.xy);
        pp = pp.zyx;

        float strap_theta = _Gimmick_ZWrite_Abomination_Denim_Strap_Theta;
        float strap_ra = _Gimmick_ZWrite_Abomination_Denim_Strap_RA;
        float strap_rb = _Gimmick_ZWrite_Abomination_Denim_Strap_RB;
        float strap_d = distance_from_capped_torus(pp, float2(sin(strap_theta), cos(strap_theta)), strap_ra, strap_rb);
        body_part = strap_d < d ? BODY_PART_DENIM_STRAP : body_part;
        d = min(d, strap_d);
    }

    // Metal ring around the eye
    {
        float3 eye_center = _Gimmick_ZWrite_Abomination_Eye_Center;
        float3 pp = (p - eye_center).xzy;
        float lens_radius = _Gimmick_ZWrite_Abomination_Lens_Radius;
        float lens_depth = _Gimmick_ZWrite_Abomination_Lens_Depth;
        float lens_thickness = _Gimmick_ZWrite_Abomination_Lens_Thickness;
        float lens_d0 = distance_from_capped_cylinder(pp, lens_depth, lens_radius);
        // TODO do we need a capped cylinder? Can we use a more efficient SDF to cut out the middle?
        float lens_d1 = distance_from_capped_cylinder(pp, lens_depth + 0.1, lens_radius - lens_thickness);
        float lens_d = op_sub(lens_d1, lens_d0);
        body_part = lens_d < d ? BODY_PART_LENS : body_part;
        d = min(d, lens_d);

        // White of eye
        float eye_white_d = distance_from_capped_cylinder(pp, lens_depth * 0.5, lens_radius - lens_thickness * 0.5);
        body_part = eye_white_d < d ? BODY_PART_EYE_WHITE : body_part;
        d = min(d, eye_white_d);

        // Pupil
        float pupil_d = length(pp) - _Gimmick_ZWrite_Abomination_Pupil_Radius;
        body_part = pupil_d < d ? BODY_PART_PUPIL : body_part;
        d = min(d, pupil_d);
    }

    // Strap holding metal ring to head
    {
        float3 pp = p;
        pp.y -= _Gimmick_ZWrite_Abomination_Eye_Center.y;
        float strap_d = distance_from_capped_cylinder(pp, _Gimmick_ZWrite_Abomination_Lens_Strap_Height, _Gimmick_ZWrite_Abomination_Body_Radius * 1.001);
        body_part = strap_d < d ? BODY_PART_EYE_STRAP : body_part;
        d = min(d, strap_d);
    }

    // Mouth
    {
        float3 mouth_center = _Gimmick_ZWrite_Abomination_Mouth_Center;
        float3 pp = p;
        pp -= mouth_center;
        pp.y = -pp.y;
        float theta = _Gimmick_ZWrite_Abomination_Mouth_Theta;
        float ra = _Gimmick_ZWrite_Abomination_Mouth_RA;
        float rb = _Gimmick_ZWrite_Abomination_Mouth_RB;
        float mouth_d = distance_from_capped_torus(pp, float2(sin(theta), cos(theta)), ra, rb);
        body_part = mouth_d < d ? BODY_PART_MOUTH : body_part;
        d = min(d, mouth_d);
    }

    // Arms
    {
        float3 arm_center = _Gimmick_ZWrite_Abomination_Arm_Center;
        float3 pp = p;
        pp.x = abs(pp.x);  // Symmetrize along x axis
        pp -= arm_center;
        float arm_radius = _Gimmick_ZWrite_Abomination_Arm_Radius;
        float arm_half_length = _Gimmick_ZWrite_Abomination_Arm_Half_Length;
        float arm_d = distance_from_capsule(pp, float3(-arm_half_length, 0, 0), float3(arm_half_length, 0, 0), arm_radius);
        body_part = arm_d < d ? BODY_PART_ARM : body_part;
        d = min(d, arm_d);
    }

    // Legs
    {
        float3 leg_center = _Gimmick_ZWrite_Abomination_Leg_Center;
        float3 pp = p.yxz;
        pp.y = abs(pp.y);  // Symmetrize
        pp -= leg_center;
        float leg_radius = _Gimmick_ZWrite_Abomination_Leg_Radius;
        float leg_half_length = _Gimmick_ZWrite_Abomination_Leg_Half_Length;
        float leg_d = distance_from_capsule(pp, float3(-leg_half_length, 0, 0), float3(leg_half_length, 0, 0), leg_radius);
        body_part = leg_d < d ? BODY_PART_LEG : body_part;
        d = min(d, leg_d);
    }

    return d;
}

// TODO tetrahedral normals
float3 zwrite_abomination_normal(float3 p) {
    float3 epsilon = float3(1, 0, 0) * _Gimmick_ZWrite_Abomination_Normal_Epsilon;
    uint body_part;
    return normalize(float3(
        zwrite_abomination_map(p + epsilon.xyy, body_part) - zwrite_abomination_map(p - epsilon.xyy, body_part),
        zwrite_abomination_map(p + epsilon.yxy, body_part) - zwrite_abomination_map(p - epsilon.yxy, body_part),
        zwrite_abomination_map(p + epsilon.yyx, body_part) - zwrite_abomination_map(p - epsilon.yyx, body_part)
    ));
}

ZWriteAbominationPBR zwrite_abomination(in v2f i)
{
  float3 cam_pos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
  float3 rd = normalize(i.objPos - cam_pos);
  float3 ro = cam_pos + rd * _Gimmick_ZWrite_Abomination_Initial_Step_Size;

  // TODO raytrace ro near the object

  const float MIN_HIT_DIST = _Gimmick_ZWrite_Abomination_Min_Hit_Dist;
  const float MAX_DIST = 1;
  const uint MARCH_STEPS = _Gimmick_ZWrite_Abomination_March_Steps;
  float total_dist = 0;
  float d;
  uint body_part;
  for (uint ii = 0; ii < MARCH_STEPS; ++ii) {
    float3 p = ro + rd * total_dist;
    d = zwrite_abomination_map(p, body_part);
    if (d < MIN_HIT_DIST) {
      break;
    }
    total_dist += d;
  }

  ZWriteAbominationPBR pbr;
  if (d < MIN_HIT_DIST) {
    float3 p = ro + rd * total_dist;
    pbr.worldPos = mul(unity_ObjectToWorld, float4(p, 1.0)).xyz;

    float3 c = 1;
    c = (body_part == BODY_PART_BODY) ? _Gimmick_ZWrite_Abomination_Skin_Color : c;
    c = (body_part == BODY_PART_ARM) ? _Gimmick_ZWrite_Abomination_Skin_Color : c;
    c = (body_part == BODY_PART_LEG) ? _Gimmick_ZWrite_Abomination_Skin_Color : c;
    c = (body_part == BODY_PART_LENS) ? _Gimmick_ZWrite_Abomination_Lens_Color : c;
    c = (body_part == BODY_PART_EYE_WHITE) ? 1 : c;
    c = (body_part == BODY_PART_PUPIL) ? 0 : c;
    c = (body_part == BODY_PART_MOUTH) ? 0 : c;
    c = (body_part == BODY_PART_DENIM) ? _Gimmick_ZWrite_Abomination_Denim_Color : c;
    c = (body_part == BODY_PART_DENIM_STRAP) ? _Gimmick_ZWrite_Abomination_Denim_Color : c;
    c = (body_part == BODY_PART_EYE_STRAP) ? _Gimmick_ZWrite_Abomination_Lens_Strap_Color : c;

    float metallic = 0;
    metallic = (body_part == BODY_PART_BODY) ? _Gimmick_ZWrite_Abomination_Skin_Metallic : metallic;
    metallic = (body_part == BODY_PART_ARM) ? _Gimmick_ZWrite_Abomination_Skin_Metallic : metallic;
    metallic = (body_part == BODY_PART_LEG) ? _Gimmick_ZWrite_Abomination_Skin_Metallic : metallic;
    metallic = (body_part == BODY_PART_LENS) ? _Gimmick_ZWrite_Abomination_Lens_Metallic : metallic;
    metallic = (body_part == BODY_PART_EYE_WHITE) ? 0 : metallic;
    metallic = (body_part == BODY_PART_PUPIL) ? 0 : metallic;
    metallic = (body_part == BODY_PART_MOUTH) ? 0 : metallic;
    metallic = (body_part == BODY_PART_DENIM) ? _Gimmick_ZWrite_Abomination_Denim_Metallic : metallic;
    metallic = (body_part == BODY_PART_DENIM_STRAP) ? _Gimmick_ZWrite_Abomination_Denim_Metallic : metallic;
    metallic = (body_part == BODY_PART_EYE_STRAP) ? _Gimmick_ZWrite_Abomination_Lens_Strap_Metallic : metallic;

    float roughness = 0;
    roughness = (body_part == BODY_PART_BODY) ? _Gimmick_ZWrite_Abomination_Skin_Roughness : roughness;
    roughness = (body_part == BODY_PART_ARM) ? _Gimmick_ZWrite_Abomination_Skin_Roughness : roughness;
    roughness = (body_part == BODY_PART_LEG) ? _Gimmick_ZWrite_Abomination_Skin_Roughness : roughness;
    roughness = (body_part == BODY_PART_LENS) ? _Gimmick_ZWrite_Abomination_Lens_Roughness : roughness;
    roughness = (body_part == BODY_PART_EYE_WHITE) ? 0 : roughness;
    roughness = (body_part == BODY_PART_PUPIL) ? 0 : roughness;
    roughness = (body_part == BODY_PART_MOUTH) ? 1 : roughness;
    roughness = (body_part == BODY_PART_DENIM) ? _Gimmick_ZWrite_Abomination_Denim_Roughness : roughness;
    roughness = (body_part == BODY_PART_DENIM_STRAP) ? _Gimmick_ZWrite_Abomination_Denim_Roughness : roughness;
    roughness = (body_part == BODY_PART_EYE_STRAP) ? _Gimmick_ZWrite_Abomination_Lens_Strap_Roughness : roughness;

    pbr.albedo = float4(c, 1);
    pbr.metallic = metallic;
    pbr.roughness = roughness;
    pbr.normal = UnityObjectToWorldNormal(zwrite_abomination_normal(p));
    float4 clip_pos = mul(UNITY_MATRIX_VP, float4(mul(unity_ObjectToWorld, float4(p, 1.0))));
    pbr.depth = clip_pos.z / clip_pos.w;
  } else {
    pbr.worldPos = i.worldPos;
    pbr.albedo = 0;
    pbr.metallic = 0;
    pbr.roughness = 1;
    pbr.normal = i.normal;
    pbr.depth = -1E6;
  }

  return pbr;
}

#endif  // _GIMMICK_ZWRITE_ABOMINATION
#endif  // __ZWRITE_ABOMINATION_INC
