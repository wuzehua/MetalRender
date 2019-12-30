//
//  Renderer.swift
//  SSAO
//
//  Created by RainZhong on 2019/12/27.
//  Copyright © 2019 RainZhong. All rights reserved.
//

import Foundation
import MetalKit

class Renderer: NSObject, MTKViewDelegate{
    
    static let numOfBuffer = 3
    static var device: MTLDevice!
    static var commandQueue:MTLCommandQueue!
    static var library: MTLLibrary?
    static var colorPixelFormat: MTLPixelFormat!
    
    init(metalView: MTKView){
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("GPU is not supported")
        }
        
        
        metalView.device = device
        metalView.depthStencilPixelFormat = .depth32Float
        
        Renderer.device = device
        Renderer.commandQueue = device.makeCommandQueue()!
        Renderer.library = device.makeDefaultLibrary()
        Renderer.colorPixelFormat = metalView.colorPixelFormat
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize){}
    func draw(in view: MTKView){}
}
