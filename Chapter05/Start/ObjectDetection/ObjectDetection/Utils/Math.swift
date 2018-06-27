//
//  Math.swift
//  ObjectDetection
//
//  Created by Joshua Newnham on 15/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit
import Accelerate
import CoreML


/**
 Clamp between min and max
 @param floor minimum value val can be
 @param ceiling maximum value val can be
 */
public func clamp(_ val:CGFloat, _ floor:CGFloat, _ ceiling:CGFloat) -> CGFloat{
    return min(max(val, floor), ceiling)
}

/**
 A sigmoid function is a mathematical function having a characteristic "S"-shaped curve or sigmoid curv
 https://en.wikipedia.org/wiki/Sigmoid_function
 @param x Scalar
 @return 1 / (1 + exp(-x))
 */
public func sigmoid(x: Float) -> Float {
    return 1 / (1 + exp(-x))
}

public func sigmoid(x: CGFloat) -> CGFloat {
    return 1 / (1 + exp(-x))
}

/**
 Softmax function; https://en.wikipedia.org/wiki/Softmax_function
 Source: https://github.com/jordenhill/Birdbrain/blob/master/Birdbrain/Math.swift
 @param z A vector z.
 @return A vector y = (e^z / sum(e^z))
 */
func softmax(z: [Float]) -> [Float] {
    let x = exp(x:sub(x:z, c: z.maxValue))
    
    return div(x:x, c: sum(x:x))
}

/**
 Perform an elementwise exponentiation on a vector;
 Source: https://github.com/jordenhill/Birdbrain/blob/master/Birdbrain/Math.swift
 @param x Vector x.
 @returns A vector containing x exponentiated elementwise.
 */
func exp(x: [Float]) -> [Float] {
    var results = [Float](repeating: 0.0, count: x.count)
    
    vvexpf(&results, x, [Int32(x.count)])
    
    return results
}

/**
 Subtract a scalar c from a vector x.
 Source: https://github.com/jordenhill/Birdbrain/blob/master/Birdbrain/Math.swift
 @param x Vector x.
 @param c Scalar c.
 @return A vector containing the difference of the scalar and the vector.
 */
public func sub(x: [Float], c: Float) -> [Float] {
    var result = (1...x.count).map{_ in c}
    
    catlas_saxpby(Int32(x.count), 1.0, x, 1, -1.0, &result, 1)
    
    return result
}

/**
 Multipliy a vector x by a scalar y
 Source: https://github.com/jordenhill/Birdbrain/blob/master/Birdbrain/Math.swift
 @param x Vector x.
 @parame c Scalar c.
 @return A vector containing x multiplied elementwise by vector c.
 */
public func mul(x: [Float], c: Float) -> [Float] {
    var result = [Float](x)
    
    cblas_sscal(Int32(x.count), c, &result, 1)
    
    return result
}

/**
 Divide a vector x by a scalar y
 Source: https://github.com/jordenhill/Birdbrain/blob/master/Birdbrain/Math.swift
 @param x Vector x.
 @parame c Scalar c.
 @return A vector containing x dvidided elementwise by vector c.
 */
public func div(x: [Float], c: Float) -> [Float] {
    let divisor = [Float](repeating: c, count: x.count)
    var result = [Float](repeating: 0.0, count: x.count)
    
    vvdivf(&result, x, divisor, [Int32(x.count)])
    
    return result
}

/**
 Compute the vector sum of a vector.
 Source: https://github.com/jordenhill/Birdbrain/blob/master/Birdbrain/Math.swift
 @param x Vector.
 @returns A single precision vector sum.
 */
public func sum(x: [Float]) -> Float {
    return cblas_sasum(Int32(x.count), x, 1)
}
