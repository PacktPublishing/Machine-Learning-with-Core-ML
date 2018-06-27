//
//  CGPointRNNExtensions.swift
//  QuickDrawRNN
//
//  Created by Joshua Newnham on 18/02/2018.
//  Copyright © 2018 PacktPub. All rights reserved.
//

import UIKit

extension CGPoint{
    
    public static func getSquareSegmentDistance(
        p0:CGPoint,
        p1:CGPoint,
        p2:CGPoint) -> CGFloat{
        let x0 = p0.x, y0 = p0.y
        var x1 = p1.x, y1 = p1.y
        let x2 = p2.x, y2 = p2.y
        var dx = x2 - x1
        var dy = y2 - y1
        
        if dx != 0.0 && dy != 0.0{
            let numerator = (x0 - x1) * dx + (y0 - y1) * dy
            let denom = dx * dx + dy * dy
            let t =  numerator / denom
            
            if t > 1.0{
                x1 = x2
                y1 = y2
            } else{
                x1 += dx * t
                y1 += dy * t
            }
        }
        
        dx = x0 - x1
        dy = y0 - y1
        
        return dx * dx + dy * dy
    }
}
