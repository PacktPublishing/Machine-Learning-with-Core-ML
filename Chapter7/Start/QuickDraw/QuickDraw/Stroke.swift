//
//  Stroke.swift
//  QuickDraw
//
//  Created by Joshua Newnham on 13/01/2018.
//  Copyright © 2018 Method. All rights reserved.
//

import UIKit

import UIKit

class Stroke{
    // Points that make up the stroke
    var points : [CGPoint] = [CGPoint]()
    // Color of this stroke
    var color : UIColor!
    // Width of this stroke
    var width : CGFloat!
    
    /**
     Return the min point (min x, min y) that contains the users stroke
     */
    var minPoint : CGPoint{
        get{
            guard points.count > 0 else{
                return CGPoint(x: 0, y: 0)
            }
            
            let minX : CGFloat = points.map { (cp) -> CGFloat in
                return cp.x
                }.min() ?? 0
            
            let minY : CGFloat = points.map { (cp) -> CGFloat in
                return cp.y
                }.min() ?? 0
            
            return CGPoint(x: minX, y: minY)
        }
    }
    
    /**
     Return the max point (max x, max y) that contains the users stroke
     */
    var maxPoint : CGPoint{
        get{
            guard points.count > 0 else{
                return CGPoint(x: 0, y: 0)
            }
            
            let maxX : CGFloat = points.map { (cp) -> CGFloat in
                return cp.x
                }.max() ?? 0
            
            let maxY : CGFloat = points.map { (cp) -> CGFloat in
                return cp.y
                }.max() ?? 0
            
            return CGPoint(x: maxX, y: maxY)
        }
    }
    
    var path : CGPath{
        get{
            let path = CGMutablePath.init()
            if points.count > 0{
                for (idx, point) in self.points.enumerated(){
                    if idx == 0{
                        path.move(to: point)
                    } else{
                        path.addLine(to: point)
                    }
                }
            }
            
            return path
        }
    }
    
    init(startingPoint:CGPoint,
         color:UIColor=UIColor.black,
         width:CGFloat=10.0) {
        self.points.append(startingPoint)
        self.color = color
        self.width = width
    }
}
