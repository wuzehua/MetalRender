//
//  Model.swift
//  MetalByTutorilas
//
//  Created by RainZhong on 2019/10/25.
//  Copyright © 2019 RainZhong. All rights reserved.
//

import MetalKit

class Model: ModelNode{
    
    let vertexBuffers: [MTKMeshBuffer]
    //let piplineRenderState: MTLRenderPipelineState
    let submeshes:[Submesh]

    init(filename: String, extension ext: String, name: String, renderPipelineDescriptor: MTLRenderPipelineDescriptor, collection:TextureCollection,vertexFunction:String, fragmentFunction:String) {
        let mdlMesh = Model.loadModel(fileName: filename, withExtension: ext, descriptor: Model.defaultVertexDescriptor, device: Renderer.device)
        let mesh = try! MTKMesh(mesh: mdlMesh, device: Renderer.device)
        
        vertexBuffers = mesh.vertexBuffers
        
        renderPipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
        submeshes = mdlMesh.submeshes?.enumerated().compactMap{ index, submesh in
            (submesh as? MDLSubmesh).map{
                Submesh(submesh: mesh.submeshes[index], mdlSubmesh: $0, collection: collection,descriptor: renderPipelineDescriptor, vertexFunction: vertexFunction, fragmentFunction: fragmentFunction)
        }
        } ?? []
        
        super.init()
        self.name = name
        
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
    
    
    
    func render(renderEncoder: MTLRenderCommandEncoder, textureCollection: TextureCollection, renderFunc:()->Void){
        
        renderEncoder.pushDebugGroup("Render \(name)")
        
        renderFunc()
        
        for (index, buffer) in vertexBuffers.enumerated() {
            renderEncoder.setVertexBuffer(buffer.buffer, offset: 0, index: index)
        }
        
        
        for submesh in submeshes{
            var material = submesh.material
            renderEncoder.setRenderPipelineState(submesh.pipelinestate)
            renderEncoder.setFragmentTexture(textureCollection.getTexture(index: submesh.textureIndex.normal), index: Int(NormalTexture.rawValue))
            renderEncoder.setFragmentTexture(textureCollection.getTexture(index: submesh.textureIndex.color), index: Int(ColorTexture.rawValue))
            renderEncoder.setFragmentTexture(textureCollection.getTexture(index: submesh.textureIndex.roughness), index: Int(Roughness.rawValue))
            renderEncoder.setFragmentTexture(textureCollection.getTexture(index: submesh.textureIndex.metallic), index: Int(Metallic.rawValue))
            renderEncoder.setFragmentTexture(textureCollection.getTexture(index: submesh.textureIndex.ao), index: Int(AOTexture.rawValue))
            renderEncoder.setFragmentBytes(&material, length: MemoryLayout<Material>.size, index: Int(MaterialBuffer.rawValue))
            
            let mesh = submesh.submesh
            renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                indexCount: mesh.indexCount,
                                                indexType: mesh.indexType,
                                                indexBuffer: mesh.indexBuffer.buffer,
                                                indexBufferOffset: mesh.indexBuffer.offset)
        }
        
        renderEncoder.popDebugGroup()
        
    }
    
}
