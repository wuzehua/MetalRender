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
    var depthStencilState: MTLDepthStencilState!

    var scene: Scene
    
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
        
        scene = Scene()
        
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
        scene.camera.rotateAroundCneter(trans: trans)
    }
    
    func zoom(deltaAngle: Float){
        scene.camera.zoom(deltaAngle: deltaAngle)
    }
    
}

extension Renderer: MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        scene.adjustView(size: size)
    }
    
    func draw(in view: MTKView) {
        
        
        guard let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        view.depthStencilPixelFormat = .depth32Float
        
        renderEncoder.setDepthStencilState(depthStencilState)
        scene.renderTest(renderEncoder: renderEncoder, index: modelIndex)
        

        
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
    
    
    
}
