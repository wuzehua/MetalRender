//
//  Math.swift
//  MetalByTutorilas
//
//  Created by RainZhong on 2019/10/23.
//  Copyright © 2019 RainZhong. All rights reserved.
//

import simd
import GLKit

struct Uniforms {
    var modelMatrix = GLKMatrix4Identity
    var viewMatrix = GLKMatrix4Identity
    var projectionMatrix = GLKMatrix4Identity
    var normalMatrix = GLKMatrix4Identity
}


func radians(degree: Float)->Float{
    return degree * Float.pi / 180
}

func convertMatrix(matrix: GLKMatrix4)-> matrix_float4x4{
    let mat = matrix_float4x4(columns:
        (simd_make_float4(matrix.m00, matrix.m01, matrix.m02, matrix.m03),
         simd_make_float4(matrix.m10, matrix.m11, matrix.m12, matrix.m13),
         simd_make_float4(matrix.m20, matrix.m21, matrix.m22, matrix.m23),
         simd_make_float4(matrix.m30, matrix.m31, matrix.m32, matrix.m33)))
        
    
    return mat
}

extension GLKMatrix4{
    static func *(matrixA: GLKMatrix4, matrixB: GLKMatrix4)->GLKMatrix4{
        return GLKMatrix4Multiply(matrixA, matrixB)
    }
}


extension matrix_float4x4{
    init(translate: SIMD3<Float>){
        self = matrix_identity_float4x4
        self.columns.3.x = translate.x
        self.columns.3.y = translate.y
        self.columns.3.z = translate.z
    }
    
    init(scale: SIMD3<Float>) {
        self = matrix_identity_float4x4
        self.columns.0.x = scale.x
        self.columns.1.y = scale.y
        self.columns.2.z = scale.z
    }
    
    init(angle: Float, axis: SIMD3<Float>) {
        let matrix = GLKMatrix4MakeRotation(radians(degree: angle), axis.x, axis.y, axis.z)
        self = convertMatrix(matrix: matrix)
    }
    
    init(fov: Float, near: Float, far: Float, aspect: Float){
        let matrix = GLKMatrix4MakePerspective(fov, aspect, near, far)
        self = convertMatrix(matrix: matrix)
    }
  
    
    init(projectionFov fov: Float, near: Float, far: Float, aspect: Float, lhs: Bool = true) {
      let y = 1 / tan(fov * 0.5)
      let x = y / aspect
      let z = lhs ? far / (far - near) : far / (near - far)
      let X = SIMD4<Float>( x,  0,  0,  0)
      let Y = SIMD4<Float>( 0,  y,  0,  0)
      let Z = lhs ? SIMD4<Float>( 0,  0,  z, 1) : SIMD4<Float>( 0,  0,  z, -1)
      let W = lhs ? SIMD4<Float>( 0,  0,  z * -near,  0) : SIMD4<Float>( 0,  0,  z * near,  0)
      self.init()
      columns = (X, Y, Z, W)
    }
    
    init(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) {
      let z = normalize(eye - center)
      let x = normalize(cross(up, z))
      let y = cross(z, x)
      let w = SIMD3<Float>(dot(x, -eye), dot(y, -eye), dot(z, -eye))

      let X = SIMD4<Float>(x.x, y.x, z.x, 0)
      let Y = SIMD4<Float>(x.y, y.y, z.y, 0)
      let Z = SIMD4<Float>(x.z, y.z, z.z, 0)
      let W = SIMD4<Float>(w.x, w.y, w.z, 1)
      self.init()
      columns = (X, Y, Z, W)
        
    }

    
    func upLeft() -> matrix_float3x3 {
        let X = simd_make_float3(columns.0.x, columns.0.y, columns.0.z)
        let Y = simd_make_float3(columns.1.x, columns.1.y, columns.1.z)
        let Z = simd_make_float3(columns.2.x, columns.2.y, columns.2.z)
        return matrix_float3x3(columns: (X,Y,Z))
    }
    
}

