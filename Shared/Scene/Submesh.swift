//
//  Submesh.swift
//  MetalRender
//
//  Created by RainZhong on 2019/12/28.
//  Copyright © 2019 RainZhong. All rights reserved.
//

import MetalKit
import simd

class Submesh{
    let submesh: MTKSubmesh
    struct TextureIndex {
        let color:Int
        let normal:Int
        let roughness:Int
        let metallic:Int
        let ao:Int
    }
    
    
    let textureIndex:TextureIndex
    let material: Material
    let pipelinestate: MTLRenderPipelineState!

    init(submesh: MTKSubmesh, mdlSubmesh: MDLSubmesh, collection: TextureCollection, descriptor: MTLRenderPipelineDescriptor, vertexFunction: String, fragmentFunction: String) {
      self.submesh = submesh
        print("\(mdlSubmesh.name) initialize")
      textureIndex = TextureIndex(material: mdlSubmesh.material, collection: collection)
        material = Material(material: mdlSubmesh.material)
        pipelinestate = Submesh.makePipelineState(renderPipelineDescriptor: descriptor, vertexFunction: vertexFunction, fragmentFunction: fragmentFunction, textureIndex: textureIndex)
    }
}

extension Submesh{
    
    static func makeFunctionConstants(textures: TextureIndex)
      -> MTLFunctionConstantValues {
        let functionConstants = MTLFunctionConstantValues()
        var property = textures.color != -1
        functionConstants.setConstantValue(&property, type: .bool, index: 0)
        property = textures.normal != -1
        functionConstants.setConstantValue(&property, type: .bool, index: 1)
        property = textures.roughness != -1
        functionConstants.setConstantValue(&property, type: .bool, index: 2)
        property = textures.metallic != -1
        functionConstants.setConstantValue(&property, type: .bool, index: 3)
        property = textures.ao != -1
        functionConstants.setConstantValue(&property, type: .bool, index: 4)

        return functionConstants
    }
    
    private static func makePipelineState(renderPipelineDescriptor: MTLRenderPipelineDescriptor, vertexFunction:String, fragmentFunction: String,textureIndex: TextureIndex)->MTLRenderPipelineState{
        
        let functionConstants = makeFunctionConstants(textures: textureIndex)
        
        renderPipelineDescriptor.vertexFunction = Renderer.library?.makeFunction(name: vertexFunction)
        do{
            renderPipelineDescriptor.fragmentFunction = try Renderer.library?.makeFunction(name: fragmentFunction, constantValues: functionConstants)
        }catch let e{
            fatalError(e.localizedDescription)
        }
        
        let pipelineState: MTLRenderPipelineState
        
        do{
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        }catch let e
        {
            fatalError(e.localizedDescription)
        }
        
        return pipelineState
    }
}

private extension Submesh.TextureIndex{
    init(material: MDLMaterial?, collection: TextureCollection) {
        func property(with semantic:MDLMaterialSemantic)->Int{
            guard let property = material?.property(with: semantic),
              property.type == .string,
              let filename = property.stringValue,
              let index = try? collection.loadTextureFromAsset(name: filename) else {
                return -1
            }
            return index
        }
        color = property(with: .baseColor)
        normal = property(with: .tangentSpaceNormal)
        roughness = property(with: .roughness)
        metallic = property(with: .metallic)
        ao = property(with: .ambientOcclusion)
    }
    
}


private extension Material{

    
    init(material: MDLMaterial?) {
        self.init()
        
        if material != nil{
            print("\(material!.name) material")
        }
        if let color = material?.property(with: .baseColor),
            color.type == .float3{
            albedo = color.float3Value
        }
        
        if let roughness = material?.property(with: .roughness),
            roughness.type == .float{
            self.roughness = roughness.floatValue
        }
        
        if let metallic = material?.property(with: .metallic),
            metallic.type == .float{
            self.metallic = metallic.floatValue
        }
    }
}
