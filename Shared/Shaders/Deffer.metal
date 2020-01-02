//
//  Deffer.metal
//  SSAO
//
//  Created by RainZhong on 2019/12/28.
//  Copyright © 2019 RainZhong. All rights reserved.
//

#include <metal_stdlib>
#include "../Bridge/Common.h"
using namespace metal;

struct VertexOut{
    float4 position[[position]];
    float2 uv;
};

struct DefferOut{
    float4 color[[color(0)]];
    float4 bright[[color(1)]];
};

//法线分布函数
float D_TR_GXX(float NH, float roughness)
{
    float alpha = roughness * roughness;
    float alphaS = alpha * alpha;
    float temp = NH * NH * (alphaS - 1) + 1;
    float denominator = M_PI_F * temp * temp;
    return alphaS / denominator;
}

//几何函数
float G_Schlick_GGX(float3 n, float3 v, float k)
{
    float numerator = saturate(dot(n, v));
    float denominator = numerator * (1 - k) + k;
    return numerator / denominator;
}

float Smith_G(float3 n, float3 v, float3 l, float roughness)
{
    float r = roughness + 1;
    float k = r * r / 8;
    float G1 = G_Schlick_GGX(n, v, k); //观察方向的几何遮蔽
    float G2 = G_Schlick_GGX(n, l, k); //光线方向的几何阴影
    return G1 * G2;
}

//菲涅尔近似,反射因子
float3 Fresnel_Schlick(float3 h, float3 v, float3 F0)
{
    float HV = saturate(dot(h, v));
    float t = (-5.55473 * HV - 6.98316) * HV;
    return F0 + (1 - F0) * exp2(t);
    //return F0 + (1 - F0) * pow(1 - HV, 5);
}

float3 Fresnel_Schlick_Roughness(float3 n, float3 v, float3 F0, float roughness)
{
    float NV = saturate(dot(n, v));
    float t = (-5.55473 * NV - 6.98316) * NV;
    return F0 + (max(float3(1 - roughness), F0) - F0) * exp2(t);
}

float pow4(float a){
    return a * a * a * a;
}




vertex VertexOut deffer_vertex_main(constant float2* quadVertices[[buffer(VertexBuffer)]],
                                  constant float2* uv[[buffer(UVBuffer)]],
                                  uint id[[vertex_id]])
{
    VertexOut out;
    out.position = float4(quadVertices[id],0,1);
    out.uv = uv[id];
    return out;
}

fragment DefferOut deffer_fragment_main(VertexOut in[[stage_in]],
                                     texture2d<float> positionTexture[[texture(PositionTexture)]],
                                     texture2d<float> normalTexture[[texture(NormalTexture)]],
                                     texture2d<float> albedoTexture[[texture(ColorTexture)]],
                                     texture2d<float> roughnessTexture[[texture(RoughnessTexture)]],
                                     texture2d<float> brdfLut[[texture(BRDFLut)]],
                                     texturecube<float> skybox[[texture(SkyboxCube)]],
                                     texturecube<float> skyboxEnvTexture [[texture(SkyboxEnv)]],
                                     constant PointLight* lights [[buffer(LightBuffer)]],
                                     constant FragmentUniform& uniform [[buffer(FragmentUniformBuffer)]]
                                   )
{
    
    constexpr sampler textureSampler(min_filter::linear, mag_filter::linear);
    DefferOut out;
    float3 n = normalTexture.sample(textureSampler, in.uv).xyz;
    float3 albedo = albedoTexture.sample(textureSampler, in.uv).xyz;
    if(n.x == 0 && n.y == 0 && n.z == 0){
        out.color = float4(albedo,1);
        out.bright = float4(0);
        return out;
    }
    
    float3 shadePoint = positionTexture.sample(textureSampler, in.uv).xyz;
    float3 rm = roughnessTexture.sample(textureSampler, in.uv).xyz;
    float roughness = rm.x;
    float metallic = rm.y;
    float ao = rm.z;
    
    //float roughness = 0.1;
    //float metallic = 0.9;
    
    float3 v = normalize(uniform.cameraPosition - shadePoint);
    
    //float3 diffuse = mix(albedo, float3(0), metallic); //金属度越高，漫反射越少
    float3 specular = mix(float3(0.04), albedo, metallic); //金属度越高，反射光越接近本身颜色，非金属材质反射默认设置为0.04
    
    float3 L = float3(0);
       
    float3 lamber_diffuse = specular / M_PI_F;
    
    for(unsigned int i = 0;i < uniform.numOfLight; ++i)
    {
        //float3 lightPosition = (uniform.viewMatrix * float4(lights[i].position,1)).xyz;
        float3 l = lights[i].position - shadePoint;
        float dis = length(l);
        
        //if(dis > lights[i].radius){
        //    continue;
        //}
        
        float denominator = dis * dis + 1;
        //float falloffnumerator = saturate( 1 - pow4(dis / lights[i].radius));
        l = normalize(l);
        
        float3 h = normalize(v + l);
        
        float NH = saturate(dot(n, h));
        
        float3 radience = lights[i].lightColor * lights[i].intensity / denominator;
        
        float3 F = Fresnel_Schlick(h, v, specular);
        float D = D_TR_GXX(NH, roughness);
        float G = Smith_G(n, v, l, roughness);
        
        float temp = 4 * saturate(dot(n,l)) * saturate(dot(n, v));
        temp = max(temp, 0.001);
        
        
        float3 spec = D * G * F / temp;
        
        float3 kd = 1 - F;
        kd *= 1 - metallic;
        
        L += (kd * lamber_diffuse + spec) * radience * saturate(dot(l,n));
        
    }
    
    //IBL
    float3 IBLKS = Fresnel_Schlick_Roughness(n, v, specular, roughness);
    float3 IBLKD = float3(1) - IBLKS;
    IBLKD *= 1.0 - metallic;
    
    
    float3 IBLDiffuse = IBLKD * skyboxEnvTexture.sample(textureSampler, n).rgb * albedo;
    
    float3 reflectDir = reflect(-v, n);
    //float3 reflectDir = (uniform.invViewMatrix * float4(reflect(-v, n),0)).xyz;
    constexpr sampler IBLSpecSampler(filter::linear, mip_filter::linear);
    float3 specMipColor = skybox.sample(IBLSpecSampler, reflectDir, level(roughness * 10)).rgb;
    float NV = saturate(dot(n, v));
    float2 envBRDF = brdfLut.sample(IBLSpecSampler, float2(NV, roughness)).rg;
    
    float3 IBLSpecular = IBLKS * envBRDF.r + envBRDF.g;
    
    float3 IBL = IBLDiffuse + specMipColor * IBLSpecular;
    
    
    
    float3 color = (IBL + L) * ao;
    //color = color / (color + 1);
    color = pow(color, 2.2);
    out.color = float4(color,1);
    
    float bright = dot(color, float3(0.2126,0.7152,0.0722));
    
    out.bright = bright > 1 ? float4(color,1) : float4(0);
    
    
    return out;
}
