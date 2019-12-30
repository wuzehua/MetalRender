//
//  Skybox.swift
//  MetalRender
//
//  Created by RainZhong on 2019/11/2.
//  Copyright © 2019 RainZhong. All rights reserved.
//

import MetalKit
import GLKit


class Skybox{
    
    let mesh:MTKMesh
    var skybox: MTLTexture?
    var skyboxEnv: MTLTexture?
    let pipelineState: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState?
    
    init(filename: String) {
        let cube = Primitive.makeCube(device: Renderer.device, size: 1, isSkybox: true)
        //let texture: MTLTexture?
        do{
            mesh = try MTKMesh(mesh: cube, device: Renderer.device)
            //texture = try TextureCollection.loadTextureFromAsset(name: filename)
        }catch let e
        {
            fatalError(e.localizedDescription)
        }
        
        skybox = Skybox.loadSkyboxTexture(name: filename)
        skyboxEnv = Skybox.loadCubeTexture(name: filename + "Env")
        
        pipelineState = Skybox.makePipelineState(vertexDescriptor: cube.vertexDescriptor)
        depthStencilState = Skybox.makeDepthStencilState()
    }
    
    init(filename: String,pipelineDescriptor: MTLRenderPipelineDescriptor) {
        let cube = Primitive.makeCube(device: Renderer.device, size: 1, isSkybox: true)
        //let texture: MTLTexture?
        do{
            mesh = try MTKMesh(mesh: cube, device: Renderer.device)
            //texture = try TextureCollection.loadTextureFromAsset(name: filename)
        }catch let e
        {
            fatalError(e.localizedDescription)
        }
        
        skybox = Skybox.loadSkyboxTexture(name: filename)
        skyboxEnv = Skybox.loadCubeTexture(name: filename + "Env")
        
        pipelineState = Skybox.makePipelineState(vertexDescriptor: cube.vertexDescriptor,pipelineDescriptor: pipelineDescriptor)
        depthStencilState = Skybox.makeDepthStencilState()
    }
    
    func render(renderEncoder: MTLRenderCommandEncoder, uniform: Uniforms)
    {
        renderEncoder.pushDebugGroup("Render Skybox")
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)
        
        var view = uniform.viewMatrix
        view = GLKMatrix4SetColumn(view, 3, GLKVector4Make(0, 0, 0, 1))
        var pvMatrix = uniform.projectionMatrix * view
        renderEncoder.setVertexBytes(&pvMatrix, length: MemoryLayout<GLKMatrix4>.stride, index: 1)
        
        renderEncoder.setFragmentTexture(skybox, index: Int(SkyboxCube.rawValue))
        
        let submesh = mesh.submeshes[0]
        
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: 0)
        
        renderEncoder.popDebugGroup()
    }
    
    private static func loadSkyboxTexture(name: String) -> MTLTexture?
    {
        var texture:MTLTexture?
        do{
            texture = try TextureCollection.loadTextureFromAsset(name: name)
        }catch let e
        {
            fatalError(e.localizedDescription)
        }
        
        return texture
    }
    
    private static func loadCubeTexture(name: String) -> MTLTexture?
    {
        var texture: MTLTexture?
        do{
            texture = try TextureCollection.loadCubeTextureFromAsset(name: name)
        }catch let e
        {
            fatalError(e.localizedDescription)
        }
        
        return texture
    }
    
    static func makePipelineState(vertexDescriptor: MDLVertexDescriptor, pipelineDescriptor: MTLRenderPipelineDescriptor)-> MTLRenderPipelineState
    {
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        
        let pipelineState: MTLRenderPipelineState
        
        do{
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }catch let e
        {
            fatalError(e.localizedDescription)
        }
        
        return pipelineState
    }
    
    
    static func makePipelineState(vertexDescriptor: MDLVertexDescriptor) -> MTLRenderPipelineState
    {
        let library = Renderer.library
        let vertexFunc = library?.makeFunction(name: "skybox_vertex")
        let fragmentFunc = library?.makeFunction(name: "skybox_fragment")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        //pipelineDescriptor.sampleCount = 4
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[1].pixelFormat = .rgba16Float
        pipelineDescriptor.colorAttachments[2].pixelFormat = .rgba16Float
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        let pipelineState: MTLRenderPipelineState
        
        do{
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }catch let e
        {
            fatalError(e.localizedDescription)
        }
        
        return pipelineState
    }
    
    static func makeDepthStencilState() -> MTLDepthStencilState?
    {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .lessEqual
        depthStencilDescriptor.isDepthWriteEnabled = true
        return Renderer.device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
    
}
