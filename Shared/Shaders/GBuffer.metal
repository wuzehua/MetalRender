//
//  Deffer.metal
//  SSAO Fragment Deffer
//
//  Created by RainZhong on 2019/12/27.
//  Copyright © 2019 RainZhong. All rights reserved.
//

#include <metal_stdlib>
#include "../Bridge/Common.h"

using namespace metal;

constant bool hasColorTexture [[function_constant(0)]];
constant bool hasNormalTexture [[function_constant(1)]];
constant bool hasRoughnessTexture [[function_constant(2)]];
constant bool hasMetallicTexture [[function_constant(3)]];
constant bool hasAOTexture [[function_constant(4)]];

struct VertexIn{
    float3 position[[attribute(Position)]];
    float3 normal[[attribute(Normal)]];
    float2 uv[[attribute(UV)]];
    float3 tangent[[attribute(Tangent)]];
    float3 bitangent[[attribute(Bitangent)]];
};

struct VertexOut{
    float4 position[[position]];
    float4 shadePoint;
    float3 normalWorld;
    float2 uv;
    float3 tangentWorld;
    float3 bitangentWorld;
};

struct Uniforms{
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4x4 normalMatrix;
};



struct GBufferOut{
    float4 albedo[[color(0)]];
    float4 normal[[color(1)]];
    float4 position[[color(2)]];
    float4 roughness[[color(3)]];
};

vertex VertexOut vertex_gbuffer(const VertexIn vertex_in[[stage_in]],
                          constant Uniforms& uniform [[buffer(UniformBuffer)]])
{
    float4 position = float4(vertex_in.position, 1.0);
    
    VertexOut out;
    
    out.normalWorld = (uniform.normalMatrix * float4(vertex_in.normal, 0.0)).xyz;
    out.tangentWorld = (uniform.normalMatrix * float4(vertex_in.tangent, 0.0)).xyz;
    out.bitangentWorld = (uniform.normalMatrix * float4(vertex_in.bitangent, 0.0)).xyz;
    out.position = uniform.projectionMatrix * uniform.viewMatrix * uniform.modelMatrix * position;
    
    out.shadePoint = uniform.modelMatrix * position;
    out.uv = vertex_in.uv;
    
    
    return out;
}


[[early_fragment_tests]]
fragment GBufferOut fragment_gbuffer(VertexOut in[[stage_in]],
                                     texture2d<float> normalMap[[texture(NormalTexture), function_constant(hasNormalTexture)]],
                                     texture2d<float> colorTexture [[texture(ColorTexture), function_constant(hasColorTexture)]],
                                     texture2d<float> roughnessTexture[[texture(Roughness), function_constant(hasRoughnessTexture)]],
                                     texture2d<float> metallicTexture[[texture(Metallic), function_constant(hasMetallicTexture)]],
                                     texture2d<float> aoTexture[[texture(AOTexture), function_constant(hasAOTexture)]]
                                     )
{
    constexpr sampler textureSampler(min_filter::linear, mag_filter::linear);
    float3 T = normalize(in.tangentWorld);
    float3 B = normalize(in.bitangentWorld);
    float3 N = normalize(in.normalWorld);
    
    GBufferOut out;
    
    float3x3 TBN = float3x3(T,B,N);
    float3 normalValue;
    if(hasNormalTexture){
        normalValue = normalMap.sample(textureSampler, in.uv).rgb * 2 - 1;
        normalValue = TBN * normalValue;
    }else{
        normalValue = in.normalWorld;
    }
    
    float3 n = normalize(normalValue);
    
    if(hasColorTexture){
        out.albedo = colorTexture.sample(textureSampler, in.uv);
    }else{
        out.albedo = float4(1);
    }
    out.normal = float4(n,0);
    out.position = in.shadePoint;
    
    if(hasRoughnessTexture){
        out.roughness.x = roughnessTexture.sample(textureSampler, in.uv).r;
    }else{
        out.roughness.x = 0.9;
    }
    
    if(hasMetallicTexture){
        out.roughness.y = metallicTexture.sample(textureSampler, in.uv).r;
    }else{
        out.roughness.y = 0.9;
    }
    
    if(hasAOTexture){
        out.roughness.z = aoTexture.sample(textureSampler, in.uv).r;
    }else{
        out.roughness.z = 1;
    }
    
    return out;
}
