#include <simd/simd.h>

#define MAX_LIGHT_COUNT 8

struct FrameConstants {
    simd_float4x4 viewMatrix;
    simd_float4x4 projectionMatrix;
    simd_float3 cameraPosition;
};

struct InstanceConstants {
    simd_float4x4 modelMatrix;
    simd_float3x3 normalMatrix;
};

typedef struct Light {
    simd_float3 direction;
    simd_float3 color;
} Light;

struct LightingConstants {
    Light lights[MAX_LIGHT_COUNT];
    unsigned int activeLightCount;
};

typedef struct MaterialConstants {
    simd_float3 specularColor;
    float shininess;
    float metalness;
} Material;
