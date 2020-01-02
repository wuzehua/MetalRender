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

    var renderer: RendererDeffer?
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        leftButton.titleLabel?.layer.opacity = 0
        rightButton.titleLabel?.layer.opacity = 0
        upButton.titleLabel?.layer.opacity = 0
        downButton.titleLabel?.layer.opacity = 0
        forwardButton.titleLabel?.layer.opacity = 0
        backButton.titleLabel?.layer.opacity = 0
        
        guard let metalView = view as? MTKView else {
            fatalError("Metal View is not set up")
        }
        
        renderer = RendererDeffer(metalView: metalView)
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(gesture:)))
        metalView.addGestureRecognizer(panRecognizer)
        metalView.addGestureRecognizer(pinchRecognizer)
        
    }
    @IBAction func forwardTouchDown(_ sender: UIButton) {
        var direction = Direction.None
        switch sender.titleLabel?.text {
        case "b":
            direction = .Back
        case "f":
            direction = .Forward
        case "l":
            direction = .Left
        case "r":
            direction = .Right
        case "u":
            direction = .Up
        case "d":
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

