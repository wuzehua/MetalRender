//
//  ViewController.swift
//  MetalmacOS
//
//  Created by RainZhong on 2019/11/8.
//  Copyright © 2019 RainZhong. All rights reserved.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {
    
    var renderer: Renderer?
    let scrollSensity:CGFloat = 0.1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let metalView = view as? MTKView else {
            fatalError("Metal View is not set up")
        }
        
        renderer = Renderer(metalView: metalView)
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func scrollWheel(with event: NSEvent) {
        renderer?.zoom(deltaAngle: Float(event.deltaY * scrollSensity))
    }
    
    override func mouseDragged(with event: NSEvent) {
        let translation = SIMD2<Float>(Float(event.deltaX), Float(event.deltaY))
        renderer?.rotateCamera(trans: translation)
    }
    
    override func rightMouseDown(with event: NSEvent) {
        renderer?.modelIndex = ((renderer?.modelIndex ?? 0) + 1) % (renderer?.scene.models.count ?? 1)
    }

}



