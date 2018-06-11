//
//  StrokeRNNExtension.swift
//  QuickDrawRNN
//
//  Created by Joshua Newnham on 18/02/2018.
//  Copyright © 2018 PacktPub. All rights reserved.
//

import UIKit

/*:
 Line simplification using Ramer–Douglas–Peucker algorithm;
 https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm
 https://commons.wikimedia.org/wiki/File%3ADouglas-Peucker_animated.gif
 */
extension Stroke{
    
    /**
     Perform line simplification using Ramer-Douglas-Peucker algorithm
     */
    public func simplify(epsilon:CGFloat=3.0) -> Stroke{
        
        var simplified: [CGPoint] = [self.points.first!]
        
        self.simplifyDPStep(points: self.points,
                            first: 0, last: self.points.count-1,
                            tolerance: epsilon * epsilon,
                            simplified: &simplified)
        
        simplified.append(self.points.last!)
        
        let copy = self.copy() as! Stroke
        copy.points = simplified
        
        return copy
    }
    
    func simplifyDPStep(points:[CGPoint],
                        first:Int,
                        last:Int,
                        tolerance:CGFloat,
                        simplified: inout [CGPoint]){
        
        var maxSqDistance = tolerance
        var index = 0
        
        for i in first + 1..<last{
            let sqDist = CGPoint.getSquareSegmentDistance(
                p0: points[i],
                p1: points[first],
                p2: points[last])
            
            if sqDist > maxSqDistance {
                maxSqDistance = sqDist
                index = i
            }
        }
        
        if maxSqDistance > tolerance{
            if index - first > 1 {
                simplifyDPStep(points: points,
                               first: first,
                               last: index,
                               tolerance: tolerance,
                               simplified: &simplified)
            }
            
            simplified.append(points[index])
            
            if last - index > 1{
                simplifyDPStep(points: points,
                               first: index,
                               last: last,
                               tolerance: tolerance,
                               simplified: &simplified)
            }
        }
    }
}
