//
//  MixHDR.metal
//  MetalRender
//
//  Created by RainZhong on 2020/1/2.
//  Copyright © 2020 RainZhong. All rights reserved.
//

#include <metal_stdlib>
#include "../Bridge/Common.h"
using namespace metal;

kernel void hdr_mix(texture2d<float, access::read> defferTexture[[texture(ColorTexture)]],
                    texture2d<float, access::read> brightTexture[[texture(BrightTexture)]],
                    texture2d<float, access::write> output[[texture(ImageTexture)]],
                    uint2 gid[[thread_position_in_grid]])
{
    //float exposure = 2.0;
    float3 hdrColor = defferTexture.read(gid).xyz;
    float3 brightness = brightTexture.read(gid).xyz;
    float3 color = hdrColor + brightness;
    color = color / (color + 1);
    //color = float3(1.0) - exp(-color * exposure);
    color = pow(color, 1 / 2.2);
    output.write(float4(color,1), gid);
}
