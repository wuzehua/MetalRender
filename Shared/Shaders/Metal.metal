//
//  Metal.metal
//  MetalByTutorilas
//
//  Created by RainZhong on 2019/10/23.
//  Copyright © 2019 RainZhong. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "../Bridge/Common.h"

struct VertexIn{
    float3 position[[attribute(Position)]];
    float3 normal[[attribute(Normal)]];
    float2 uv[[attribute(UV)]];
    float3 tangent[[attribute(Tangent)]];
    float3 bitangent[[attribute(Bitangent)]];
};


struct VertexOut{
    float4 position[[position]];
    float3 shadePoint;
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


vertex VertexOut vertex_main(const VertexIn vertex_in[[stage_in]],
                          constant Uniforms& uniform [[buffer(UniformBuffer)]])
{
    float4 position = float4(vertex_in.position, 1.0);
    
    VertexOut out;
    
    out.normalWorld = (uniform.normalMatrix * float4(vertex_in.normal, 0.0)).xyz;
    out.tangentWorld = (uniform.normalMatrix * float4(vertex_in.tangent, 0.0)).xyz;
    out.bitangentWorld = (uniform.normalMatrix * float4(vertex_in.bitangent, 0.0)).xyz;
    out.position = uniform.projectionMatrix * uniform.viewMatrix * uniform.modelMatrix * position;
    
    out.shadePoint = (uniform.modelMatrix * position).xyz;
    out.uv = vertex_in.uv;
    
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float> normalMap[[texture(NormalTexture)]],
                              texture2d<float> colorTexture [[texture(ColorTexture)]],
                              constant PhongPointLight* lights [[buffer(LightBuffer)]],
                              constant FragmentUniform& uniform [[buffer(FragmentUniformBuffer)]]
                              )
{
    constexpr sampler textureSampler;
    float3 T = normalize(in.tangentWorld);
    float3 B = normalize(in.bitangentWorld);
    float3 N = normalize(in.normalWorld);
    
    float3x3 TBN = float3x3(T,B,N);
    float3 normalValue = normalMap.sample(textureSampler, in.uv).rgb * 2 - 1;
    
    
    float3 normal = normalize(TBN * normalValue);
    float3 color = float3(0.0);
    float3 modelColor = colorTexture.sample(textureSampler, in.uv).rgb;
    
    for(unsigned int i = 0;i < uniform.numOfLight;i++)
    {
        float3 l = normalize(lights[i].position - in.shadePoint);
        float distance = length(lights[i].position - in.shadePoint);
        float denominator = distance * distance + 1.0;
        
        float diff = max(dot(normal, l), 0.0);
        float3 diffuse = lights[i].diffuse * diff * lights[i].intensity / denominator;
        
        float3 v = normalize(uniform.cameraPosition - in.shadePoint);
        float3 h = normalize(v + l);
        
        float spec = pow(max(dot(h,normal),0.0), 32);
        float3 specular = lights[i].specular * spec * lights[i].intensity / denominator;
        
        color += (diffuse * modelColor + specular * float3(1.0));
        
    }
    
    //color += uniform.ambient * modelColor;
    
    return float4(color, 1);
}


fragment float4 pbr_fragment_main(VertexOut in [[stage_in]],
                                  texture2d<float> brdfLut[[texture(BRDFLut)]],
                                  texture2d<float> normalMap[[texture(NormalTexture)]],
                                  texture2d<float> colorTexture [[texture(ColorTexture)]],
                                  texture2d<float> roughnessTexture[[texture(Roughness)]],
                                  texture2d<float> metallicTexture[[texture(Metallic)]],
                                  texturecube<float> skybox[[texture(SkyboxCube)]],
                                  texturecube<float> skyboxEnvTexture [[texture(SkyboxEnv)]],
                                  constant PointLight* lights [[buffer(LightBuffer)]],
                                  constant FragmentUniform& uniform [[buffer(FragmentUniformBuffer)]])
{
    constexpr sampler textureSampler;
    float3 T = normalize(in.tangentWorld);
    float3 B = normalize(in.bitangentWorld);
    float3 N = normalize(in.normalWorld);
    
    float3x3 TBN = float3x3(T,B,N);
    float3 normalValue = normalMap.sample(textureSampler, in.uv).rgb * 2 - 1;
    
    
    float3 n = normalize(TBN * normalValue);
    float3 albedo = colorTexture.sample(textureSampler, in.uv).rgb;
    
    float metallic = metallicTexture.sample(textureSampler, in.uv).r;
    float roughness = roughnessTexture.sample(textureSampler, in.uv).r;
    
    //roughness = max(roughness, 0.1);
    
    float3 v = normalize(uniform.cameraPosition - in.shadePoint);
    
    float3 diffuse = mix(albedo, float3(0), metallic); //金属度越高，漫反射越少
    float3 specular = mix(float3(0.04), albedo, metallic); //金属度越高，反射光越接近本身颜色，非金属材质反射默认设置为0.04
    
    float3 L = float3(0);
    
    float3 lamber_diffuse = diffuse / M_PI_F;
    
    for(unsigned int i = 0;i < uniform.numOfLight;i++)
    {
        float3 l = lights[i].position - in.shadePoint;
        float dis = length(l);
        float denominator = dis * dis + 1;
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
    constexpr sampler IBLSpecSampler(filter::linear, mip_filter::linear);
    float3 specMipColor = skybox.sample(IBLSpecSampler, reflectDir, level(roughness * 10)).rgb;
    float NV = saturate(dot(n, v));
    float2 envBRDF = brdfLut.sample(IBLSpecSampler, float2(NV, roughness)).rg;
    
    float3 IBLSpecular = IBLKS * envBRDF.r + envBRDF.g;
    
    float3 IBL = IBLDiffuse + specMipColor * IBLSpecular;
    

    float3 color = IBL + L;
    color = color / (color + 1);
    color = pow(color, 1 / 2.2);
    return float4(color,1.0);
}

