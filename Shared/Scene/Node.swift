//
//  Node.swift
//  MetalByTutorilas
//
//  Created by RainZhong on 2019/10/25.
//  Copyright © 2019 RainZhong. All rights reserved.
//

import GLKit
import simd

protocol Node {
    var name:String {get set}
    var position: SIMD3<Float>{get set}
}

class ModelNode: Node{
    var name = "Unkown"
    var position: SIMD3<Float> = [0,0,0]
    var scale: SIMD3<Float> = [1,1,1]
    var rotate: (Float, SIMD3<Float>) = (0, [0,0,1])
    
    var modelMatrix: GLKMatrix4{
        let T = GLKMatrix4MakeTranslation(position.x, position.y, position.z)
        let R = GLKMatrix4MakeRotation(rotate.0, rotate.1.x, rotate.1.y, rotate.1.z)
        let S = GLKMatrix4MakeScale(scale.x, scale.y, scale.z)
        return T * R * S
    }
    
}
