//
//  Camera.swift
//  MetalByTutorilas
//
//  Created by RainZhong on 2019/10/25.
//  Copyright © 2019 RainZhong. All rights reserved.
//

import GLKit

let sensitivity:Float = 0.05

class Camera: Node{
    var name: String
    var position: SIMD3<Float>
    var viewMatrix = GLKMatrix4Identity
    var projectionMatrix = GLKMatrix4Identity
    
    init(name: String, position: SIMD3<Float>){
        self.name = name
        self.position = position
    }
    
    func adjustView(size: CGSize){}
    func rotateCamera(trans: SIMD2<Float>){}
    func rotateAroundCneter(trans: SIMD2<Float>){}
    func zoom(deltaAngle: Float){}
}

class PerspectiveCamera: Camera{
    var fov: Float
    var up: SIMD3<Float>
    var direction: SIMD3<Float>
    var horizon: SIMD3<Float>
    var near: Float
    var far: Float
    let rawUp: SIMD3<Float>
    var yaw: Float = 90 //偏航角，绕rawUp转
    var pitch: Float = 0 //俯仰角，绕Horizon转
    var aspect: Float
    
    let rawDirec: SIMD3<Float>
    let rawHorizon: SIMD3<Float>
    
    override var position: SIMD3<Float>{
        willSet{
            let center = newValue + self.direction
            self.viewMatrix = GLKMatrix4MakeLookAt(newValue.x, newValue.y, newValue.z,
                                                   center.x, center.y, center.z,
                                                   self.up.x, self.up.y, self.up.z)
        }
    }
    
    
    init(fov: Float, up: SIMD3<Float>, position: SIMD3<Float>, center: SIMD3<Float>, aspect: Float, near: Float, far: Float)
    {
        self.fov = fov
        direction = normalize(center - position)
        horizon = normalize(cross(direction, up))
        self.up = cross(horizon, direction)
        rawUp = self.up
        self.near = near
        self.far = far
        
        rawDirec = direction
        rawHorizon = horizon
        self.aspect = aspect
        super.init(name: "Perspective Camera", position: position)
        viewMatrix = GLKMatrix4MakeLookAt(position.x, position.y, position.z, center.x, center.y, center.z, up.x, up.y, up.z)
        projectionMatrix = GLKMatrix4MakePerspective(radians(degree: fov), aspect, near, far)
        
    }
    
    override func adjustView(size: CGSize) {
        aspect = Float(size.width) / Float(size.height)
        projectionMatrix = GLKMatrix4MakePerspective(fov, aspect, near, far)
    }
    
    override func rotateCamera(trans: SIMD2<Float>) {
        let deltax = Float(trans.x) * sensitivity
        let deltay = Float(trans.y) * sensitivity
        
        yaw += deltax
        pitch += deltay
        
        if pitch > 80{
            pitch = 80
        }else if pitch < -80{
            pitch = -80
        }
        
        let rpitch = radians(degree: pitch)
        let ryaw = radians(degree: yaw)
        
        let x = cos(rpitch) * cos(ryaw) * rawHorizon
        let y = sin(rpitch) * rawUp
        let z = cos(rpitch) * sin(ryaw) * rawDirec
        
        direction = x + y + z
        
        direction = normalize(direction)
        horizon = normalize(cross(direction, rawUp))
        up = normalize(cross(horizon, direction))
        
        let center = position + direction
        
        viewMatrix = GLKMatrix4MakeLookAt(position.x, position.y, position.z, center.x, center.y, center.z, up.x, up.y, up.z)
    }
    
    override func zoom(deltaAngle: Float) {
        fov += deltaAngle
        
        if fov < 44
        {
            fov = 44
        }else if fov > 46{
            fov = 46
        }
        
        projectionMatrix = GLKMatrix4MakePerspective(fov, aspect, near, far)
        
    }
    
    override func rotateAroundCneter(trans: SIMD2<Float>) {
        let angle = acosf(dot(direction, rawUp))
        var dy = trans.y
        let dx = trans.x
        
        //防止direction与rawup在同一直线上造成锁
        if angle - trans.y >= 3
        {
            dy = angle - 3
        }
        
        if angle - trans.y <= 0.2
        {
            dy = angle - 0.2
        }
        
        var rotationMatrix = matrix_float4x4(angle: dy, axis: horizon)
        rotationMatrix = rotationMatrix * matrix_float4x4(angle: dx, axis: up)
        
        var tempPosition = SIMD4<Float>(position.x, position.y, position.z, 1)
        var tempDirection = SIMD4<Float>(direction.x,direction.y, direction.z, 0)
        
        tempPosition = rotationMatrix * tempPosition
        tempDirection = rotationMatrix * tempDirection
        
        position = SIMD3<Float>(tempPosition.x, tempPosition.y, tempPosition.z)
        direction = SIMD3<Float>(tempDirection.x, tempDirection.y, tempDirection.z)
        
        direction = normalize(direction)
        horizon = normalize(cross(direction, rawUp))
        up = normalize(cross(horizon, direction))
        
        let center = position + direction
        
        viewMatrix = GLKMatrix4MakeLookAt(position.x, position.y, position.z, center.x, center.y, center.z, up.x, up.y, up.z)
        
    }
}
