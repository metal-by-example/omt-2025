#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position  [[attribute(0)]];
    float3 normal    [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 normal;
    float2 texCoords;
};

struct FrameConstants {
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
};

struct InstanceConstants {
    float4x4 modelMatrix;
};

[[vertex]]
VertexOut basic_model_vertex(VertexIn in [[stage_in]],
                             constant FrameConstants &frame [[buffer(8)]],
                             constant InstanceConstants &instance [[buffer(9)]])
{
    float4x4 MVP = frame.projectionMatrix * frame.viewMatrix * instance.modelMatrix;

    VertexOut out;
    out.position = MVP * float4(in.position, 1.0f);
    out.texCoords = in.texCoords;
    return out;
}

[[fragment]]
float4 basic_model_fragment(VertexOut in [[stage_in]],
                           texture2d<float, access::sample> baseColorTexture [[texture(0)]],
                           sampler textureSampler [[sampler(0)]])
{
    // Flip from USD's texture coordinate orientation to Metal's upper-left origin convention.
    // Cf. https://openusd.org/release/spec_usdpreviewsurface.html#texture-coordinate-orientation-in-usd
    float2 uv = float2(in.texCoords.x, 1.0f - in.texCoords.y);
    
    float4 baseColor = baseColorTexture.sample(textureSampler, uv);
    return float4(baseColor.rgb, baseColor.a);
}
