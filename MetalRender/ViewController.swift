//
//  ViewController.swift
//  MetalRender
//
//  Created by RainZhong on 2019/10/27.
//  Copyright © 2019 RainZhong. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {

    @IBOutlet weak var slector: UISegmentedControl!
    var renderer: Renderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        guard let metalView = view as? MTKView else {
            fatalError("Metal View is not set up")
        }
        
        renderer = Renderer(metalView: metalView)
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(gesture:)))
        metalView.addGestureRecognizer(panRecognizer)
        metalView.addGestureRecognizer(pinchRecognizer)
        
    }
    @IBAction func forwardTouchDown(_ sender: UIButton) {
        var direction = Direction.None
        switch sender.titleLabel?.text {
        case "back":
            direction = .Back
        case "forward":
            direction = .Forward
        case "left":
            direction = .Left
        case "right":
            direction = .Right
        case "up":
            direction = .Up
        case "down":
            direction = .Down
        default:
            break
        }
        renderer?.direction = direction
        if direction != .None{
            renderer?.moving = true
        }
    }
    
    @IBAction func stopMoving(_ sender: UIButton) {
        renderer?.direction = .None
        renderer?.moving = false
    }
    
    @IBAction func changeModel(_ sender: UISegmentedControl) {
        //renderer?.modelIndex = sender.selectedSegmentIndex
    }
    
}


extension ViewController{
    
    static var currentScale: Float = 1.0
    
    @objc func handlePan(gesture: UIPanGestureRecognizer){
        let translation = SIMD2<Float>(Float(gesture.translation(in: gesture.view).x),
                                 Float(gesture.translation(in: gesture.view).y))
        
        renderer?.rotateCamera(trans: translation)
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    @objc func handlePinch(gesture: UIPinchGestureRecognizer){
        renderer?.zoom(deltaAngle: ViewController.currentScale - Float(gesture.scale))
        ViewController.currentScale = Float(gesture.scale)
        
        if gesture.state == .ended{
            ViewController.currentScale = 1.0
        }
        
    }
}

