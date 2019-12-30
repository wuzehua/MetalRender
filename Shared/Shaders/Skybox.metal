//
//  Skybox.metal
//  MetalRender
//
//  Created by RainZhong on 2019/11/2.
//  Copyright © 2019 RainZhong. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "../Bridge/Common.h"

struct VertexIn{
    float4 position[[attribute(0)]];
};

struct VertexOut{
    float4 position [[position]];
    float3 point;
};

struct GBufferOut{
    float4 color[[color(0)]];
    float4 normal[[color(1)]];
    float4 position[[color(2)]];
    float4 roughness[[color(3)]];
};

vertex VertexOut skybox_vertex(const VertexIn in [[stage_in]],
                               constant float4x4& pvMatrix [[buffer(1)]])
{
    VertexOut out;
    out.position = (pvMatrix * in.position).xyww;
    out.point = in.position.xyz;
    return out;
}

fragment half4 skybox_fragment(const VertexOut in [[stage_in]],
                                texturecube<half> skyboxCube [[texture(SkyboxCube)]])
{
    constexpr sampler sample(filter::linear, mip_filter::linear);
    half4 color = skyboxCube.sample(sample, in.point,level(0.95));
    return color;
}


fragment GBufferOut skybox_gbuffer_frag(const VertexOut in [[stage_in]],
                                        texturecube<half> skyboxCube [[texture(SkyboxCube)]])
{
    constexpr sampler sample(filter::linear, mip_filter::linear);
    half4 color = skyboxCube.sample(sample, in.point);
    GBufferOut out;
    out.color = float4(color);
    out.normal = float4(0);
    out.position = float4(0);
    out.roughness = float4(0);
    return out;
}

