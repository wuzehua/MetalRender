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
    var camera: PerspectiveCamera!
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
        

        let gun = Model(filename: "tunnel", extension: "obj", name: "Tunnel", vertexFunc: "vertex_main", fragmentFuc: "pbr_fragment_main",collection: textureCollection)
        
        //gun.scale = [4,4,4]
        gun.position = [0,-2,2.5]

        
        models.append(gun)
        
        var light = PointLight()
        light.position = SIMD3<Float>(2.0,1.0,3.0)
        light.lightColor = SIMD3<Float>(1.0,1.0,1.0)
        light.intensity = 200
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
    
    func updateCameraPosition(diretion: Direction){
        camera.move(dir: diretion)
    }
    
}
