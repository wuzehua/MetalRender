//
//  Primitive.swift
//  MetalByTutorilas
//
//  Created by RainZhong on 2019/10/23.
//  Copyright © 2019 RainZhong. All rights reserved.
//

import Foundation
import MetalKit

class Primitive {
    class func makeCube(device: MTLDevice, size: Float, isSkybox: Bool)-> MDLMesh {
        let allocator = MTKMeshBufferAllocator(device: device)
        let cube = MDLMesh(boxWithExtent: [size,size,size],
                           segments: [1,1,1],
                           inwardNormals: isSkybox,
                           geometryType: .triangles,
                           allocator: allocator)
        return cube
    }
    
    
    class func makeSphere(device: MTLDevice, radius: Float, segment: UInt32)-> MDLMesh{
        let allocator = MTKMeshBufferAllocator(device: device)
        let sphere = MDLMesh(sphereWithExtent: [radius,radius,radius],
                             segments: [segment,segment],
                             inwardNormals: false,
                             geometryType: .triangles,
                             allocator: allocator)
        return sphere
    }
    
    class func loadObj(device: MTLDevice, vertexDescriptor:MDLVertexDescriptor, fileName: String)-> MDLMesh {
        let allocator = MTKMeshBufferAllocator(device: device)
        guard let assetURL = Bundle.main.url(forResource: fileName, withExtension: "obj") else {
            fatalError("\(fileName).obj doesn't exist")
        }
        let mdlAsset = MDLAsset(url: assetURL, vertexDescriptor: vertexDescriptor, bufferAllocator: allocator)
        let obj = mdlAsset.object(at: 0) as! MDLMesh
        return obj
    }
}
