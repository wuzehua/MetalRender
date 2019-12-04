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
