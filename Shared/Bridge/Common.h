//
//  Common.h
//  MetalRender
//
//  Created by RainZhong on 2019/10/30.
//  Copyright © 2019 RainZhong. All rights reserved.
//

#ifndef Common_h
#define Common_h

#import <simd/simd.h>

typedef enum {
    Position = 0,
    Normal = 1,
    UV = 2,
    Tangent = 3,
    Bitangent = 4
} AttributesIndex;

typedef enum {
    ColorTexture = 0,
    NormalTexture = 1,
    Roughness = 2,
    Metallic = 3,
    SkyboxCube = 4,
    SkyboxEnv = 5,
    BRDFLut = 6,
    PositionTexture = 7,
    SSAOTexture = 8,
    ImageTexture = 9,
    RoughnessTexture = 10,
    AOTexture = 11
} TextureIndex;

typedef enum {
    VertexBuffer = 0,
    UVBuffer = 1,
    UniformBuffer = 11,
    LightBuffer = 12,
    FragmentUniformBuffer = 13
} BufferIndex;

typedef struct {
    vector_float3 position;
    vector_float3 lightColor;
    vector_float3 diffuse; //漫反射
    vector_float3 specular; //镜面反射
    float intensity; //光照强度
} PhongPointLight;

typedef struct {
    vector_float3 position;
    vector_float3 lightColor;
    float intensity;
    float radius;
} PointLight;


typedef struct {
    unsigned int numOfLight;
    //vector_float3 ambient; //环境光
    vector_float3 cameraPosition;
} FragmentUniform;


#endif /* Common_h */
