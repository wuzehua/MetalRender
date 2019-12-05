//
//  Scene.swift
//  MetalRender
//
//  Created by RainZhong on 2019/12/5.
//  Copyright © 2019 RainZhong. All rights reserved.
//

import Foundation
import MetalKit
import GLKit

class Scene {
    var camera: Camera!
    var models:[Model] = []
    var lights:[PointLight] = []
    var skybox:Skybox!
    var textureCollection = TextureCollection()
    var vertexUniform = Uniforms()
    var fragmentUniform = FragmentUniform()
    
    init(){
        setupTest()
    }
    
    func setupTest() {
        camera = PerspectiveCamera(fov: 45, up: [0,1,0], position: [0,0,3], center: [0,0,0], aspect: 1, near: 0.01, far: 100)
        
        let valve = Model(filename: "Valve", extension: "obj", name: "Valve", vertexFunc: "vertex_main", fragmentFuc: "pbr_fragment_main")
        valve.scale = [2.5,2.5,2.5]
        valve.rotate = (-.pi / 2, [1,0,0])
        valve.position = [0,-0.5,0]
        valve.loadTextureFromAsset(name: "ValveColor", type: .Color, collection: textureCollection)
        valve.loadTextureFromAsset(name: "ValveNormal", type: .Normal, collection: textureCollection)
        valve.loadTextureFromAsset(name: "ValveRoughness", type: .Roughness, collection: textureCollection)
        valve.loadTextureFromAsset(name: "ValveMetallic", type: .Metallic, collection: textureCollection)
        
        let barrel = Model(filename: "Barrel", extension: "obj", name: "Barrel", vertexFunc: "vertex_main", fragmentFuc: "pbr_fragment_main")
        barrel.scale = [0.1,0.1,0.1]
        barrel.rotate = (-.pi / 2, [1,0,0])
        barrel.position = [0,-0.5,0]
        barrel.loadTextureFromAsset(name: "BarrelColor", type: .Color, collection: textureCollection)
        barrel.loadTextureFromAsset(name: "BarrelNormal", type: .Normal, collection: textureCollection)
        barrel.loadTextureFromAsset(name: "BarrelRoughness", type: .Roughness, collection: textureCollection)
        barrel.loadTextureFromAsset(name: "BarrelMetallic", type: .Metallic, collection: textureCollection)

        let gun = Model(filename: "gun", extension: "obj", name: "Gun", vertexFunc: "vertex_main", fragmentFuc: "pbr_fragment_main")

        gun.loadTextureFromAsset(name: "GunColor", type: .Color, collection: textureCollection)
        gun.loadTextureFromAsset(name: "GunNormal", type: .Normal, collection: textureCollection)
        gun.loadTextureFromAsset(name: "GunRoughness", type: .Roughness, collection: textureCollection)
        gun.loadTextureFromAsset(name: "GunMetallic", type: .Metallic, collection: textureCollection)
        
        models.append(gun)
        models.append(valve)
        models.append(barrel)
        
        var light = PointLight()
        light.position = SIMD3<Float>(2.0,0.0,0.0)
        light.lightColor = SIMD3<Float>(1.0,1.0,1.0)
        light.intensity = 5
        lights.append(light)
        
        fragmentUniform.numOfLight = UInt32(lights.count)
        
        skybox = Skybox(filename: "SkyboxMap")
        
        if TextureCollection.brdfLut == nil{
            do{
                TextureCollection.brdfLut = try TextureCollection.loadTextureFromAsset(name: "Lut")
            }catch let e
            {
                fatalError(e.localizedDescription)
            }
        }
        
    }
    
    func renderTest(renderEncoder: MTLRenderCommandEncoder, index: Int){
        var inversable = true
        vertexUniform.projectionMatrix = camera.projectionMatrix
        vertexUniform.viewMatrix = camera.viewMatrix
        vertexUniform.modelMatrix = models[index].modelMatrix
        vertexUniform.normalMatrix = GLKMatrix4Transpose(GLKMatrix4Invert(vertexUniform.modelMatrix, &inversable))
        
        fragmentUniform.cameraPosition = camera.position
        
        models[index].render(renderEncoder: renderEncoder, textureCollection: textureCollection, renderFunc:{
                renderEncoder.setVertexBytes(&vertexUniform, length: MemoryLayout<Uniforms>.stride, index: Int(UniformBuffer.rawValue))
                renderEncoder.setFragmentBytes(&lights, length: MemoryLayout<PhongPointLight>.stride * lights.count, index: Int(LightBuffer.rawValue))
                renderEncoder.setFragmentBytes(&fragmentUniform, length: MemoryLayout<FragmentUniform>.stride, index:   Int(FragmentUniformBuffer.rawValue))
                renderEncoder.setFragmentTexture(TextureCollection.brdfLut, index: Int(BRDFLut.rawValue))
                renderEncoder.setFragmentTexture(skybox.skyboxEnv, index: Int(SkyboxEnv.rawValue))
                renderEncoder.setFragmentTexture(skybox.skybox, index: Int(SkyboxCube.rawValue))
            }
        )
        
        skybox.render(renderEncoder: renderEncoder, uniform: vertexUniform)
    }
    
    func adjustView(size: CGSize){
        camera.adjustView(size: size)
        vertexUniform.projectionMatrix = camera.projectionMatrix
    }
    
}
