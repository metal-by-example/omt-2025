#include <metal_stdlib>
using namespace metal;

#include "ShaderStructures.h"

struct VertexIn {
    float3 position  [[attribute(0)]];
    float3 normal    [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 normal;
    float2 texCoords;
};

[[vertex]]
VertexOut lit_model_vertex(VertexIn in [[stage_in]],
                           constant FrameConstants &frame [[buffer(8)]],
                           constant InstanceConstants &instance [[buffer(9)]])
{
    float4x4 viewProjectionMatrix = frame.projectionMatrix * frame.viewMatrix;

    float4 worldPosition = instance.modelMatrix * float4(in.position, 1.0f);

    VertexOut out;
    out.position = viewProjectionMatrix * worldPosition;
    out.worldPosition = worldPosition.rgb;
    out.normal = instance.normalMatrix * in.normal;
    out.texCoords = in.texCoords;
    return out;
}

[[fragment]]
float4 lit_model_fragment(VertexOut in [[stage_in]],
                         constant FrameConstants &frame [[buffer(8)]],
                         constant LightingConstants &lighting [[buffer(9)]],
                         constant MaterialConstants &material [[buffer(10)]],
                         texture2d<float, access::sample> baseColorTexture [[texture(0)]],
                         sampler textureSampler [[sampler(0)]])
{
    // Flip from USD's texture coordinate orientation to Metal's upper-left origin convention.
    // Cf. https://openusd.org/release/spec_usdpreviewsurface.html#texture-coordinate-orientation-in-usd
    float2 uv = float2(in.texCoords.x, 1.0f - in.texCoords.y);

    float3 baseColor = baseColorTexture.sample(textureSampler, uv).rgb;
    float3 diffuseColor = baseColor * (1.0h - material.metalness);
    float3 specularColor = material.specularColor;
    float3 N = float3(normalize(in.normal));

    float3 litColor {};
    for (size_t lightIndex = 0; lightIndex < lighting.activeLightCount; ++lightIndex) {
        Light light = lighting.lights[lightIndex];

        float3 L = normalize(-light.direction);
        float NdotL = saturate(dot(N, L));
        if (NdotL >= 0.0f) {
            float3 diffuseTerm = diffuseColor * light.color * NdotL;
            litColor += diffuseTerm;

            float specularExponent = material.shininess;
            float3 V = normalize(frame.cameraPosition - in.worldPosition);
            float3 R = reflect(-L, N);
            float RdotV = saturate(dot(R, V));
            float specularFactor = powr(RdotV, specularExponent);
            float3 specularTerm = specularColor * light.color * specularFactor;
            litColor += specularTerm;
        }
    }

    return float4(litColor, 1.0f);
}
