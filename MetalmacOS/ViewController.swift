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
    
    var renderer: RendererDeffer?
    let scrollSensity:CGFloat = 0.1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let metalView = view as? MTKView else {
            fatalError("Metal View is not set up")
        }
        
        renderer = RendererDeffer(metalView: metalView)
        
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
        //renderer?.modelIndex = ((renderer?.modelIndex ?? 0) + 1) % (renderer?.scene.models.count ?? 1)
    }
    
    override func keyDown(with event: NSEvent) {
        //print("keydown \(event.keyCode)")
        var direction = Direction.None
        
        switch event.keyCode {
        case 0:
            direction = .Left
        case 1:
            direction = .Back
        case 2:
            direction = .Right
        case 0x0D:
            direction = .Forward
        case 0x7E:
            direction = .Up
        case 0x7D:
            direction = .Down
        default:
            break
        }
        
        renderer?.direction = direction
        renderer?.moving = true
        
    }
    
    override func keyUp(with event: NSEvent) {
        //print("keyup \(event.keyCode)")
        renderer?.direction = .None
        renderer?.moving = false
    }
    
    override func awakeFromNib() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown){ (aEvent) -> NSEvent? in
            self.keyDown(with: aEvent)
            return aEvent
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyUp){
            (aEvent) -> NSEvent? in
            self.keyUp(with: aEvent)
            return aEvent
        }
        
    }

}



