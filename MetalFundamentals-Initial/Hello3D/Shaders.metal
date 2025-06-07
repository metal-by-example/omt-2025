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
    // TODO: Your code, step 1 (combine transforms to produce the MVP matrix)
    float4x4 MVP;

    VertexOut out;
    out.position = MVP * float4(in.position, 1.0f);
    out.texCoords = in.texCoords;
    return out;
}

[[fragment]]
float4 basic_model_fragment(VertexOut in [[stage_in]],
                            texture2d<float> baseColorTexture [[texture(0)]],
                            sampler textureSampler [[sampler(0)]])
{
    float2 uv = float2(in.texCoords.x, 1.0f - in.texCoords.y);

    // TODO: Your code, step 2 (sample from the color texture instead)
    float4 baseColor = float4(1.0f, 1.0f, 1.0f, 1.0f);

    return baseColor;
}
