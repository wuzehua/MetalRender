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
    var lightBuffer:MTLBuffer!
    var skybox:Skybox!
    var textureCollection = TextureCollection()
    var lightsCount: UInt32 = 0
    
    
    init(renderPiplineDescriptor: MTLRenderPipelineDescriptor, skyboxDescriptor: MTLRenderPipelineDescriptor, vertexFunction:String, fragmentFunction: String){
        setupTest(renderPiplineDescriptor: renderPiplineDescriptor, skyboxDescriptor: skyboxDescriptor,vertexFunction:vertexFunction, fragmentFunction:fragmentFunction)
    }
    
    func setupTest(renderPiplineDescriptor: MTLRenderPipelineDescriptor, skyboxDescriptor: MTLRenderPipelineDescriptor,
                   vertexFunction:String, fragmentFunction:String) {
        
        let valve = Model(filename: "spaceStation", extension: "obj", name: "SpaceStation", renderPipelineDescriptor: renderPiplineDescriptor,collection:textureCollection, vertexFunction:vertexFunction, fragmentFunction:fragmentFunction)
        
        valve.scale = [0.1,0.1,0.1]
        
//        let ninja = Model(filename: "ninja", extension: "obj", name: "Ninja", renderPipelineDescriptor: renderPiplineDescriptor, collection: textureCollection, vertexFunction: vertexFunction, fragmentFunction: fragmentFunction)
//        ninja.scale = [3,3,3]
//        ninja.rotate = (Float.pi, [0,1,0])
//        ninja.position = [0,0,3]
//        
//        models.append(ninja)
        models.append(valve)
        
        skybox = Skybox(filename: "SkyboxMap", pipelineDescriptor: skyboxDescriptor)
        sharedSetUp()
    }
    
    func sharedSetUp(){
        camera = PerspectiveCamera(fov: 45, up: [0,1,0], position: [0,2,3], center: [0,2,0], aspect: 1, near: 0.01, far: 150)
        var lights:[PointLight] = []
        var light = PointLight()
        light.position = SIMD3<Float>(0,1.0,0.0)
        light.lightColor = SIMD3<Float>(1.0,1.0,1.0)
        light.intensity = 150
        light.radius = 5
        lights.append(light)
        
        lightBuffer = Renderer.device.makeBuffer(bytes: lights, length: MemoryLayout<PointLight>.stride * lights.count, options: [])
        lightsCount = UInt32(lights.count)
        
        //fragmentUniform.numOfLight = UInt32(lights.count)
        
        
        
        if TextureCollection.brdfLut == nil{
            do{
                TextureCollection.brdfLut = try TextureCollection.loadTextureFromAsset(name: "Lut")
            }catch let e
            {
                fatalError(e.localizedDescription)
            }
        }
    }
    
    
    func adjustView(size: CGSize){
        camera.adjustView(size: size)
        //vertexUniform.projectionMatrix = camera.projectionMatrix
    }
    
    func updateCameraPosition(diretion: Direction){
        camera.move(dir: diretion)
    }
    
}
