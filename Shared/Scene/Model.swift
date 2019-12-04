//
//  Model.swift
//  MetalByTutorilas
//
//  Created by RainZhong on 2019/10/25.
//  Copyright © 2019 RainZhong. All rights reserved.
//

import MetalKit

class Model: ModelNode{
    //let vertexBuffer: MTLBuffer
    let vertexBuffers: [MTKMeshBuffer]
    let piplineRenderState: MTLRenderPipelineState
    let submeshes: [MTKSubmesh]
    var colorIndex = -1
    var normalIndex = -1
    var roughnessIndex = -1
    var metallicIndex = -1
    
    func loadTexture(filename: String, extention ext:String, type: TextureType, collection: TextureCollection) {
        let texture: MTLTexture?
        do{
            texture = try TextureCollection.loadTexture(filename: filename, extension: ext)
        }catch let e{
            fatalError(e.localizedDescription)
        }
        
        updateTexture(texture: texture, collection: collection, type: type)
        
    }
    
    
    func loadTextureFromAsset(name:String, type: TextureType, collection: TextureCollection)
    {
        let texture: MTLTexture?
        do{
            texture = try TextureCollection.loadTextureFromAsset(name: name)
        }catch let e{
            fatalError(e.localizedDescription)
        }
        
        updateTexture(texture: texture, collection: collection, type: type)
    }
    
    private func updateTexture(texture: MTLTexture?, collection: TextureCollection, type: TextureType)
    {
        let index = collection.addTexture(texture: texture, type: type)
        
        switch type {
        case .Color:
            colorIndex = index
        case .Normal:
            normalIndex = index
        case .Roughness:
            roughnessIndex = index
        case .Metallic:
            metallicIndex = index
        default:
            break
        }
    }
    
    static func loadModel(fileName: String, withExtension ext: String, descriptor: MDLVertexDescriptor, device: MTLDevice)->MDLMesh
    {
        let allocator = MTKMeshBufferAllocator(device: device)
        guard let assetURL = Bundle.main.url(forResource: fileName, withExtension: ext) else {
            fatalError("\(fileName).\(ext) doesn't exist")
        }
        let mdlAsset = MDLAsset(url: assetURL, vertexDescriptor: descriptor, bufferAllocator: allocator)
        let obj = mdlAsset.object(at: 0) as! MDLMesh
        
        //添加切线与副切线到两个buffer中，其中顶点，uv以及normal已存在于buffer(0)中，加载时会进行计算
        //其中，新计算的切线会添加到之后的attribute中
        obj.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
        
        return obj
    }
    
    
    static var defaultVertexDescriptor: MDLVertexDescriptor{
        get{
            let vertexDescriptor = MDLVertexDescriptor()
            vertexDescriptor.attributes[Int(Position.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: Int(VertexBuffer.rawValue))
            vertexDescriptor.attributes[Int(Normal.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<SIMD3<Float>>.stride, bufferIndex: Int(VertexBuffer.rawValue))
            
            vertexDescriptor.attributes[Int(UV.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: 2 * MemoryLayout<SIMD3<Float>>.stride, bufferIndex: Int(VertexBuffer.rawValue))
            
            vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: 2 * MemoryLayout<SIMD3<Float>>.stride + MemoryLayout<SIMD2<Float>>.stride)
            
            return vertexDescriptor
            
        }
    }
    
    
    init(filename: String, extension ext: String, name: String, vertexFunc: String, fragmentFuc: String) {
        let obj = Model.loadModel(fileName: filename, withExtension: ext, descriptor: Model.defaultVertexDescriptor, device: Renderer.device)
        let mesh = try! MTKMesh(mesh: obj, device: Renderer.device)
        submeshes = mesh.submeshes
        vertexBuffers = mesh.vertexBuffers
        //vertexBuffer = mesh.vertexBuffers[0].buffer
        piplineRenderState = Model.makePipelineState(vertexDescriptor: mesh.vertexDescriptor, vertexFunc: vertexFunc, fragmentFuc: fragmentFuc)
        
        super.init()
        self.name = name
    }
    
    private static func makePipelineState(vertexDescriptor: MDLVertexDescriptor,vertexFunc: String, fragmentFuc: String)->MTLRenderPipelineState
    {
        let library = Renderer.library
        let vertexFunction = library?.makeFunction(name: vertexFunc)
        let fragmentFunction = library?.makeFunction(name: fragmentFuc)
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.sampleCount = 4
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
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
    
}
