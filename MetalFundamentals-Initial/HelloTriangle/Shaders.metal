
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

[[vertex]]
VertexOut triangle_vertex(device float2 const *positions [[buffer(0)]],
                          device float3 const *colors [[buffer(1)]],
                          uint vid [[vertex_id]])
{
    VertexOut out{};
    out.position = float4(positions[vid], 0.0f, 1.0f);
    out.color = float4(colors[vid], 1.0f);
    return out;
}

[[fragment]]
float4 triangle_fragment(VertexOut in [[stage_in]]) {
    return in.color;
}
