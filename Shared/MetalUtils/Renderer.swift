//
//  Renderer.swift
//  Metal
//
//  Created by RainZhong on 2019/10/23.
//  Copyright © 2019 RainZhong. All rights reserved.
//

import Foundation
import MetalKit
import GLKit


class Renderer: NSObject{
    
    static var device: MTLDevice!
    static var commandQueue:MTLCommandQueue!
    static var library: MTLLibrary?
    static var colorPixelFormat: MTLPixelFormat!
    
    var modelIndex = 0
    var timer: Float = 0
    var uniforms = Uniforms()
    var camera: Camera!
    var models: [Model] = []
    var depthStencilState: MTLDepthStencilState!
    var lights:[PointLight] = []
    var fragmentUniforms = FragmentUniform()
    var textureCollection = TextureCollection()
    var skybox: Skybox
    var brdfLut: MTLTexture?
    
    init(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("GPU is not supported")
        }
        
        metalView.device = device
        metalView.depthStencilPixelFormat = .depth32Float
        
        Renderer.device = device
        Renderer.commandQueue = device.makeCommandQueue()!
        Renderer.library = device.makeDefaultLibrary()
        Renderer.colorPixelFormat = metalView.colorPixelFormat
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor)!
        
        
        camera = PerspectiveCamera(fov: 45, up: [0,1,0], position: [0,0,3], center: [0,0,0], aspect: 1, near: 0.01, far: 100)
        
        uniforms.viewMatrix = camera.viewMatrix
        
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
        
//        light.position = SIMD3<Float>(-2.0,0.0,0.0)
//        lights.append(light)
//        
//        light.position = SIMD3<Float>(-2.0,1.0,0.0)
//        lights.append(light)
//        
//        light.position = SIMD3<Float>(2.0,1.0,0.0)
//        lights.append(light)
        
        //fragmentUniforms.ambient = SIMD3<Float>(0.01,0.01,0.01)
        fragmentUniforms.numOfLight = UInt32(lights.count)
        
        skybox = Skybox(filename: "SkyboxMap")
        do{
            brdfLut = try TextureCollection.loadTextureFromAsset(name: "Lut")
        }catch let e
        {
            fatalError(e.localizedDescription)
        }
        
        super.init()

        metalView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        metalView.delegate = self
        metalView.preferredFramesPerSecond = 120
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
        metalView.framebufferOnly = false
        //metalView.enableSetNeedsDisplay = true
    }
    
    func rotateCamera(trans: SIMD2<Float>)
    {
        //camera.rotateCamera(trans: trans)
        camera.rotateAroundCneter(trans: trans)
    }
    
    func zoom(deltaAngle: Float){
        camera.zoom(deltaAngle: deltaAngle)
    }
    
}

extension Renderer: MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        camera.adjustView(size: size)
        uniforms.projectionMatrix = camera.projectionMatrix
    }
    
    func draw(in view: MTKView) {
        
        view.sampleCount = 4
        
        guard let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        view.depthStencilPixelFormat = .depth32Float
        
        let model = models[modelIndex]
        
        
        
        var inversable = true
//        timer += 0.01
//        model.rotate = (timer, [0,0.5,0])
        
        uniforms.projectionMatrix = camera.projectionMatrix
        uniforms.viewMatrix = camera.viewMatrix
        uniforms.modelMatrix = model.modelMatrix
        uniforms.normalMatrix = GLKMatrix4Transpose(GLKMatrix4Invert(uniforms.modelMatrix, &inversable))
        
        fragmentUniforms.cameraPosition = camera.position
        
        renderEncoder.setDepthStencilState(depthStencilState)
        
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: Int(UniformBuffer.rawValue))
        
        renderEncoder.setRenderPipelineState(model.piplineRenderState)
        
        for (index, buffer) in model.vertexBuffers.enumerated() {
            renderEncoder.setVertexBuffer(buffer.buffer, offset: 0, index: index)
        }
        
        
        renderEncoder.setFragmentBytes(&lights, length: MemoryLayout<PhongPointLight>.stride * lights.count, index: Int(LightBuffer.rawValue))
        renderEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniform>.stride, index: Int(FragmentUniformBuffer.rawValue))
        
        
        
        renderEncoder.setFragmentTexture(brdfLut, index: Int(BRDFLut.rawValue))
        renderEncoder.setFragmentTexture(textureCollection.getTexture(index: model.normalIndex, type: .Normal), index: Int(NormalTexture.rawValue))
        renderEncoder.setFragmentTexture(textureCollection.getTexture(index: model.colorIndex, type: .Color), index: Int(ColorTexture.rawValue))
        renderEncoder.setFragmentTexture(textureCollection.getTexture(index: model.roughnessIndex, type: .Roughness), index: Int(Roughness.rawValue))
        renderEncoder.setFragmentTexture(textureCollection.getTexture(index: model.metallicIndex, type: .Metallic), index: Int(Metallic.rawValue))
        renderEncoder.setFragmentTexture(skybox.skyboxEnv, index: Int(SkyboxEnv.rawValue))
        renderEncoder.setFragmentTexture(skybox.skybox, index: Int(SkyboxCube.rawValue))
        
        
        for submesh in model.submeshes{
            
            renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                indexCount: submesh.indexCount,
                                                indexType: submesh.indexType,
                                                indexBuffer: submesh.indexBuffer.buffer,
                                                indexBufferOffset: submesh.indexBuffer.offset)
        }
        
        
        skybox.render(renderEncoder: renderEncoder, uniform: uniforms)
        
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
    
    
    
}
