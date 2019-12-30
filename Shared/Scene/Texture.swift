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
    
    var textures:[MTLTexture] = []
    var textureTable:[String: Int] = [:]
    static var brdfLut: MTLTexture? = nil
    
    func getTexture(index:Int)-> MTLTexture?{
        if index < 0 || index >= textures.count{
            return nil
        }
        
        return textures[index]
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
        let options:[MTKTextureLoader.Option: Any] = [.textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue),
        .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue)]
        
        return try textureLoader.newTexture(name: name, scaleFactor: 1.0, bundle: Bundle.main, options: options)
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
    
    func addTexture(texture: MTLTexture?) -> Int {
        if texture == nil{
            return -1
        }else{
            textures.append(texture!)
            return textures.count - 1
        }
    }
    
    
    func loadTextureFromAsset(name: String) throws -> Int{
        let index = textureTable[name]
        if index == nil{
            let texture = try TextureCollection.loadTextureFromAsset(name: name)
            let i = addTexture(texture: texture)
            if i != -1{
                textureTable[name] = i
            }
            return i
        }else{
            print("\(name) is already loaded!")
            return index!
        }
    }
    
}
