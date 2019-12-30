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


class RendererDeffer: Renderer{
    
    
    var moving = false
    var direction = Direction.None
    
    
    var currentVertexUniform = 0
    var currentFragmentUniform = 0
    
    var depthStencilState: MTLDepthStencilState!
    
    var albedoTexture: MTLTexture!
    var positionTexture: MTLTexture!
    var normalTexture: MTLTexture!
    var roughnessTexture: MTLTexture!
    var depthTexture: MTLTexture!
    
    var vertexUniform = Uniforms()
    var fragmentUniform = FragmentUniform()
    
    var vertexUniforms = [Uniforms](repeating: Uniforms(), count: Renderer.numOfBuffer)
    var fragmentUniforms = [FragmentUniform](repeating: FragmentUniform(), count: Renderer.numOfBuffer)
    
    let dispatchQueue = DispatchQueue(label: "Queue", attributes: .concurrent)
    var semaphore: DispatchSemaphore
    
    var gBufferRenderPassDescriptor: MTLRenderPassDescriptor!
    
    var defferRenderPipelineState: MTLRenderPipelineState!

    var scene: Scene!
    
    var quadVertices: [Float] = [
         -1.0,1.0,
         1.0, -1.0,
         -1.0, -1.0,
         -1.0,  1.0,
         1.0,  1.0,
         1.0, -1.0,
       ]

       var quadTexCoords: [Float] = [
         0.0, 0.0,
         1.0, 1.0,
         0.0, 1.0,
         0.0, 0.0,
         1.0, 0.0,
         1.0, 1.0
       ]
    
    override init(metalView: MTKView) {
        
        semaphore = DispatchSemaphore(value: Renderer.numOfBuffer)
        
        super.init(metalView: metalView)
        
        //quadVertexBuffer = Renderer.device.makeBuffer(bytes: quadVertices, length: MemoryLayout<SIMD2<Float>>.stride * quadVertices.count, options: [])
        //quadUVBuffer = Renderer.device.makeBuffer(bytes: quadTexCoords, length: MemoryLayout<SIMD2<Float>>.stride * quadTexCoords.count, options: [])
        
        //scene = Scene()
        scene = Scene(renderPiplineDescriptor: buildGBufferRenderPipelineDescriptor(), skyboxDescriptor: buildSkyboxRenderPipelineDescriptor(),vertexFunction: "vertex_gbuffer", fragmentFunction: "fragment_gbuffer")
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        depthStencilState = Renderer.device.makeDepthStencilState(descriptor: depthDescriptor)!
        
        buildGbufferRenderPassDescriptor(size: metalView.drawableSize)
        buildDefferRenderPipelineState()
        
        fragmentUniform.numOfLight = scene.lightsCount

        metalView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        metalView.delegate = self
        metalView.preferredFramesPerSecond = 60
        mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
        metalView.framebufferOnly = false
        //metalView.enableSetNeedsDisplay = true
    }

    //创建纹理
    private func buildTexture(pixelFormat: MTLPixelFormat, size: CGSize, label: String) -> MTLTexture {
           
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: Int(size.width), height: Int(size.height), mipmapped: false)
           
        descriptor.usage = [.shaderRead,.renderTarget]
        descriptor.storageMode = .private
           
        guard let texture = Renderer.device.makeTexture(descriptor: descriptor) else {
            fatalError()
        }
           
        texture.label = label
        return texture
    }
    
    
    private func buildGBufferTexture(size: CGSize){
        depthTexture = buildTexture(pixelFormat: .depth32Float, size: size, label: "Depth")
        albedoTexture = buildTexture(pixelFormat: .bgra8Unorm, size: size, label: "Color")
        normalTexture = buildTexture(pixelFormat: .rgba16Float, size: size, label: "Normal")
        positionTexture = buildTexture(pixelFormat: .rgba16Float, size: size, label: "Position")
        roughnessTexture = buildTexture(pixelFormat: .rgba16Float, size: size, label: "Roughness")
    }
    
    
    private func buildSkyboxRenderPipelineDescriptor() -> MTLRenderPipelineDescriptor{
        let library = Renderer.library
        let vertexFunc = library?.makeFunction(name: "skybox_vertex")
        let fragmentFunc = library?.makeFunction(name: "skybox_gbuffer_frag")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[1].pixelFormat = .rgba16Float
        pipelineDescriptor.colorAttachments[2].pixelFormat = .rgba16Float
        pipelineDescriptor.colorAttachments[3].pixelFormat = .rgba16Float
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        return pipelineDescriptor
    }
    
    private func buildGBufferRenderPipelineDescriptor() ->MTLRenderPipelineDescriptor{
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[1].pixelFormat = .rgba16Float
        descriptor.colorAttachments[2].pixelFormat = .rgba16Float
        descriptor.colorAttachments[3].pixelFormat = .rgba16Float
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.label = "GBuffer State"
        
        //descriptor.vertexFunction = Renderer.library?.makeFunction(name: "vertex_gbuffer")
        //descriptor.fragmentFunction = Renderer.library?.makeFunction(name: "fragment_gbuffer")
        
        return descriptor
    }
    
    
    private func buildGbufferRenderPassDescriptor(size: CGSize){
        gBufferRenderPassDescriptor = MTLRenderPassDescriptor()
        buildGBufferTexture(size: size)
        let textures: [MTLTexture] = [albedoTexture, normalTexture, positionTexture,roughnessTexture]
        
        for (index, texture) in textures.enumerated(){
            gBufferRenderPassDescriptor.setUpColorAttachment(index: index, texture: texture)
        }
        
        gBufferRenderPassDescriptor.setUpDepthAttachment(texture: depthTexture, clearDepth: 1)
    }
    
    
    private func buildDefferRenderPipelineState(){
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.label = "Deffer Render Pipeline"
        
        descriptor.vertexFunction = Renderer.library?.makeFunction(name: "deffer_vertex_main")
        descriptor.fragmentFunction = Renderer.library?.makeFunction(name: "deffer_fragment_main")
        
        do{
            defferRenderPipelineState = try Renderer.device.makeRenderPipelineState(descriptor: descriptor)
        }catch let e{
            fatalError(e.localizedDescription)
        }
    }
    
    
    
    private func renderGBufferPass(renderEncoder: MTLRenderCommandEncoder){
        var inversable = true
               
        renderEncoder.pushDebugGroup("GBuffer Render Pass")
        renderEncoder.label = "GBuffer Encoder"
               
        renderEncoder.setDepthStencilState(depthStencilState)
               
        //vertexUniform.projectionMatrix = scene.camera.projectionMatrix
        //vertexUniform.viewMatrix = scene.camera.viewMatrix

        vertexUniforms[currentVertexUniform].projectionMatrix = scene.camera.projectionMatrix
        vertexUniforms[currentVertexUniform].viewMatrix = scene.camera.viewMatrix
               
        for model in scene.models{
            //vertexUniform.modelMatrix = model.modelMatrix
            //vertexUniform.normalMatrix = GLKMatrix4Transpose(GLKMatrix4Invert(model.modelMatrix, &inversable))
            vertexUniforms[currentVertexUniform].modelMatrix = model.modelMatrix
            vertexUniforms[currentVertexUniform].normalMatrix = GLKMatrix4InvertAndTranspose(model.modelMatrix, &inversable)
            model.render(renderEncoder: renderEncoder, textureCollection: scene.textureCollection, renderFunc: {
                renderEncoder.setVertexBytes(&vertexUniforms[currentVertexUniform], length: MemoryLayout<Uniforms>.stride, index: Int(UniformBuffer.rawValue))
            
            })
        }
        
               
        scene.skybox.render(renderEncoder: renderEncoder, uniform: vertexUniforms[currentVertexUniform])
        currentVertexUniform = (currentVertexUniform + 1) % Renderer.numOfBuffer
               
        renderEncoder.popDebugGroup()
        renderEncoder.endEncoding()
    }
    
    private func renderDefferPass(renderEncoder: MTLRenderCommandEncoder){
        renderEncoder.pushDebugGroup("Deffer Pass")
        renderEncoder.setRenderPipelineState(defferRenderPipelineState)
        
        
        //fragmentUniform.cameraPosition = scene.camera.position
        
        fragmentUniforms[currentFragmentUniform].cameraPosition = scene.camera.position
        fragmentUniforms[currentFragmentUniform].numOfLight = scene.lightsCount
        
        renderEncoder.setVertexBytes(&quadVertices, length: MemoryLayout<Float>.size * quadVertices.count, index: Int(VertexBuffer.rawValue))
        renderEncoder.setVertexBytes(&quadTexCoords, length: MemoryLayout<Float>.size * quadTexCoords.count, index: Int(UVBuffer.rawValue))
        //renderEncoder.setVertexBuffer(quadVertexBuffer, offset: 0, index: Int(VertexBuffer.rawValue))
        //renderEncoder.setVertexBuffer(quadUVBuffer, offset: 0, index: Int(UVBuffer.rawValue))
        
        //renderEncoder.setFragmentBytes(&defferUniform, length: MemoryLayout<DefferUniform>.size, index: Int(FragmentUniformBuffer.rawValue))
        
        renderEncoder.setFragmentBytes(&fragmentUniforms[currentFragmentUniform], length: MemoryLayout<FragmentUniform>.size, index: Int(FragmentUniformBuffer.rawValue))
        
        //renderEncoder.setFragmentBytes(&(scene.lights), length: MemoryLayout<PointLight>.size * scene.lights.count, index: Int(LightBuffer.rawValue))
        renderEncoder.setFragmentBuffer(scene.lightBuffer, offset: 0, index: Int(LightBuffer.rawValue))
        
        renderEncoder.setFragmentTexture(positionTexture, index: Int(PositionTexture.rawValue))
        renderEncoder.setFragmentTexture(normalTexture, index: Int(NormalTexture.rawValue))
        renderEncoder.setFragmentTexture(albedoTexture, index: Int(ColorTexture.rawValue))
        //renderEncoder.setFragmentTexture(ssaoBlurTexture, index: Int(SSAOTexture.rawValue))
        renderEncoder.setFragmentTexture(TextureCollection.brdfLut, index: Int(BRDFLut.rawValue))
        renderEncoder.setFragmentTexture(roughnessTexture, index: Int(RoughnessTexture.rawValue))
        renderEncoder.setFragmentTexture(scene.skybox.skybox, index: Int(SkyboxCube.rawValue))
        renderEncoder.setFragmentTexture(scene.skybox.skyboxEnv, index: Int(SkyboxEnv.rawValue))
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: quadVertices.count / 2)
        
        currentFragmentUniform = (currentFragmentUniform + 1) % Renderer.numOfBuffer
        
        renderEncoder.popDebugGroup()
        renderEncoder.endEncoding()
    }
    
    
    func rotateCamera(trans: SIMD2<Float>)
    {
        //scene.camera.rotateAroundCneter(trans: trans)
        scene.camera.rotateCamera(trans: trans)
    }
    
    func zoom(deltaAngle: Float){
        scene.camera.zoom(deltaAngle: deltaAngle)
    }
    

    override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        scene.adjustView(size: size)
        buildGBufferTexture(size: size)
        buildGbufferRenderPassDescriptor(size: size)
    }
    
    override func draw(in view: MTKView) {
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        if moving{
            scene.updateCameraPosition(diretion: direction)
        }
        
        
        guard let offScreenCommandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let gBufferEncoder = offScreenCommandBuffer.makeRenderCommandEncoder(descriptor: gBufferRenderPassDescriptor) else {
            return
        }
        
        view.depthStencilPixelFormat = .depth32Float
        renderGBufferPass(renderEncoder: gBufferEncoder)
        offScreenCommandBuffer.commit()
        
        guard let descriptor = view.currentRenderPassDescriptor,
            let onScreenCommandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let renderEncoder = onScreenCommandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        //renderEncoder.setDepthStencilState(depthStencilState)
        //scene.renderTest(renderEncoder: renderEncoder, index: modelIndex)
        renderDefferPass(renderEncoder: renderEncoder)

        
        //renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }

        onScreenCommandBuffer.present(drawable)
        
//        offScreenCommandBuffer.enqueue()
//        onScreenCommandBuffer.enqueue()
//
//        dispatchQueue.async(execute: offScreenCommandBuffer.commit)
//
//        weak var sem = semaphore
//        dispatchQueue.async {
//            onScreenCommandBuffer.addCompletedHandler { _ in
//                sem?.signal()
//            }
//            onScreenCommandBuffer.commit()
//        }
//        __dispatch_barrier_sync(dispatchQueue) {}
        onScreenCommandBuffer.addCompletedHandler{ _ in
            self.semaphore.signal()
        }
        
        onScreenCommandBuffer.commit()
        
    }
    
    
}


private extension MTLRenderPassDescriptor{
    func setUpDepthAttachment(texture: MTLTexture, clearDepth: Double) {
        depthAttachment.texture = texture
        depthAttachment.loadAction = .clear
        depthAttachment.clearDepth = clearDepth
    }
    
    func setUpColorAttachment(index: Int, texture: MTLTexture){
        let attachment: MTLRenderPassColorAttachmentDescriptor = colorAttachments[index]
        attachment.texture = texture
        attachment.loadAction = .clear
        attachment.storeAction = .store
        attachment.clearColor = MTLClearColorMake(0, 0, 0, 1)
    }
    
}
