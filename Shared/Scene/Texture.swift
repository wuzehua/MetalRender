//
//  Texture.swift
//  MetalRender
//
//  Created by RainZhong on 2019/10/29.
//  Copyright © 2019 RainZhong. All rights reserved.
//

import MetalKit

enum TextureType{
    case Color
    case Normal
    case Roughness
    case Metallic
    case Displacement
}

class TextureCollection{
    
    var colorTextures:[MTLTexture] = []
    var normalTextures:[MTLTexture] = []
    var roughnessTextures:[MTLTexture] = []
    var metallicTextures:[MTLTexture] = []
    
    func getTexture(index: Int, type: TextureType)-> MTLTexture?
    {
        if index < 0{
            return nil
        }
        
        var result:MTLTexture? = nil
        
        switch type {
        case .Color:
            if index < colorTextures.count
            {
                result = colorTextures[index]
            }
        case .Normal:
            if index < normalTextures.count
            {
                result = normalTextures[index]
            }
        case .Roughness:
            if index < roughnessTextures.count
            {
                result = roughnessTextures[index]
            }
        case .Metallic:
            if index < metallicTextures.count
            {
                result = metallicTextures[index]
            }
        default:
            break
        }
        
        return result
    }
    
    static func loadTexture(filename: String, extension ext: String) throws -> MTLTexture?
    {
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
            print("Failed to load \(filename).\(ext)\n Try to load from assets.")
            return try textureLoader.newTexture(name: filename, scaleFactor: 1.0, bundle: Bundle.main, options: nil)
        }
        
        let options:[MTKTextureLoader.Option: Any] = [.origin: MTKTextureLoader.Origin.bottomLeft,
                                                      .SRGB: false]
        
        let texture = try textureLoader.newTexture(URL: url, options: options)
        print("\(filename).\(ext) successfully loaded!")
        return texture
    }
    
    static func loadTextureFromAsset(name: String) throws -> MTLTexture?
    {
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        print("Load \(name) from Assets")
        return try textureLoader.newTexture(name: name, scaleFactor: 1.0, bundle: Bundle.main, options: nil)
    }
    
    static func loadCubeTextureFromAsset(name: String) throws -> MTLTexture?
    {
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        print("Load \(name) from Assets")
        if let texture = MDLTexture(cubeWithImagesNamed: [name])
        {
            let options:[MTKTextureLoader.Option: Any] = [.origin: MTKTextureLoader.Origin.topLeft,
            .SRGB: false]
            
            return try textureLoader.newTexture(texture: texture, options: options)
        }
        
        return try textureLoader.newTexture(name: name, scaleFactor: 1.0, bundle: Bundle.main, options: nil)
    }
    
    
    func addTexture(texture: MTLTexture?, type: TextureType) -> Int {
        if texture == nil
        {
            return -1
        }
        
        var result = 0
        switch type {
        case .Color:
            colorTextures.append(texture!)
            result = colorTextures.count - 1
        case .Normal:
            normalTextures.append(texture!)
            result = normalTextures.count - 1
        case .Roughness:
            roughnessTextures.append(texture!)
            result = roughnessTextures.count - 1
        case .Metallic:
            metallicTextures.append(texture!)
            result = metallicTextures.count - 1
        default:
            result = -1
        }
        return result
    
    }
    
}
