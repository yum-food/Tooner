#ifndef __SHEAR_MATH_INC
#define __SHEAR_MATH_INC

#if defined(_GIMMICK_SHEAR_LOCATION)

void getMeshRendererMatrices(bool invert, out float3x3 rot_fix,
    out float4x4 ts_fix) {
  if (_Gimmick_Shear_Location_Mesh_Renderer_Fix) {
    float3 theta = float3(
        _Gimmick_Shear_Location_Mesh_Renderer_Rotation.x,
        _Gimmick_Shear_Location_Mesh_Renderer_Rotation.y,
        _Gimmick_Shear_Location_Mesh_Renderer_Rotation.z);
    theta = invert ? -theta : theta;
    float3x3 rotate_x = float3x3(
        1, 0, 0,
        0, cos(theta.x), -sin(theta.x),
        0, sin(theta.x), cos(theta.x));
    float3x3 rotate_y = float3x3(
        cos(theta.y), 0, sin(theta.y),
        0, 1, 0,
        -sin(theta.y), 0, cos(theta.y));
    float3x3 rotate_z = float3x3(
        cos(theta.z), -sin(theta.z), 0,
        sin(theta.z), cos(theta.z), 0,
        0, 0, 1);
    rot_fix = invert ?
      mul(rotate_x, mul(rotate_y, rotate_z)) :
      mul(rotate_z, mul(rotate_y, rotate_x));
    float3 scale = float3(
        _Gimmick_Shear_Location_Mesh_Renderer_Scale.x,
        _Gimmick_Shear_Location_Mesh_Renderer_Scale.y,
        _Gimmick_Shear_Location_Mesh_Renderer_Scale.z);
    scale = invert ? 1 / scale : scale;
    float3 offset = float3(
        _Gimmick_Shear_Location_Mesh_Renderer_Offset.x,
        _Gimmick_Shear_Location_Mesh_Renderer_Offset.y,
        _Gimmick_Shear_Location_Mesh_Renderer_Offset.z);
    offset = invert ? -offset : offset;
    ts_fix = float4x4(
        scale.x, 0, 0, offset.x,
        0, scale.y, 0, offset.y,
        0, 0, scale.z, offset.z,
        0, 0, 0, 1);
  } else {
    rot_fix = float3x3(
        1, 0, 0,
        0, 1, 0,
        0, 0, 1);
    ts_fix = float4x4(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1);
  }
}

#endif  // _GIMMICK_SHEAR_LOCATION

#endif  // __SHEAR_MATH_INC

