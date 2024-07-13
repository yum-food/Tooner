#ifndef __EYES_INC
#define __EYES_INC

#if defined(_GIMMICK_EYES_00)

float eyes00_distance_from_sphere(float3 p, float3 c, float r)
{
    return length(p - c) - r;
}

float eyes00_map(float3 p)
{
    float t = _Time.y;
    float theta = sin(_Time[0]) / 2;
    float2x2 rot = float2x2(
      cos(theta), -sin(theta),
      sin(theta), cos(theta));

    float dist = 1000 * 1000 * 1000;
    #define Y_STEPS 5
    for (int y = 0; y < Y_STEPS; y++)
    {
      const int yy = y - Y_STEPS/2;
      #define X_STEPS 5
      for (int x = 0; x < X_STEPS; x++)
      {
        const int xx = x - X_STEPS/2;
        float2 pp = float2(xx * 2, yy * 2);
        pp = mul(rot, pp);
        float radius = cos((x + y + _Time[0]) * 3.14159) * 0.5 + 1;
        float sphere = eyes00_distance_from_sphere(p, float3(pp.x, pp.y, 0.0), radius);
        dist = min(dist, sphere);
        dist += sin(5.0 * pp.x) * sin(5.0 * pp.y) * 0.5;
      }
    }

    return dist;
}

float3 eyes00_calc_normal(in float3 p)
{
    const float3 small_step = float3(0.0001, 0.0, 0.0);

    float gradient_x = eyes00_map(p + small_step.xyy) - eyes00_map(p - small_step.xyy);
    float gradient_y = eyes00_map(p + small_step.yxy) - eyes00_map(p - small_step.yxy);
    float gradient_z = eyes00_map(p + small_step.yyx) - eyes00_map(p - small_step.yyx);

    float3 normal = float3(gradient_x, gradient_y, gradient_z);

    return normalize(normal);
}

float3 __eyes00_march(float3 ro, float3 rd, inout float3 normal)
{
    float total_distance_traveled = 0.0;
    const float MINIMUM_HIT_DISTANCE = 0.001;
    const float MAXIMUM_TRACE_DISTANCE = 1000.0;

    #define EYES00_MARCH_STEPS 10
    float distance_to_closest;
    float3 current_position;
    for (int i = 0; i < EYES00_MARCH_STEPS; i++)
    {
        current_position = ro + total_distance_traveled * rd;

        distance_to_closest = eyes00_map(current_position);

        if (distance_to_closest < MINIMUM_HIT_DISTANCE) 
        {
          break;
        }

        if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE)
        {
            break;
        }
        total_distance_traveled += distance_to_closest;
    }

    if (distance_to_closest < MINIMUM_HIT_DISTANCE) {
      normal = eyes00_calc_normal(current_position);
      return float3(1.0, 1.0, 1.0);
    }

    return float3(0, 0, 0);
}

float4 eyes00_march(float2 uv, inout float3 normal)
{
    uv = uv * 2.0 - 1.0;

    float3 camera_position = float3(0.0, 0.0, -5.0);
    float3 ro = camera_position;
    float3 rd = float3(uv.x, uv.y, 1.0);

    float3 shaded_color = __eyes00_march(ro, rd, normal);

    return float4(shaded_color, 1.0);
}

#endif  // _EYES

#endif  // __EYES_INC

