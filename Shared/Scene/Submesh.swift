//
//  Submesh.swift
//  MetalRender
//
//  Created by RainZhong on 2019/12/28.
//  Copyright © 2019 RainZhong. All rights reserved.
//

import MetalKit

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
    
    init(submesh: MTKSubmesh, mdlSubmesh: MDLSubmesh, collection: TextureCollection) {
      self.submesh = submesh
      textureIndex = TextureIndex(material: mdlSubmesh.material, collection: collection)
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
