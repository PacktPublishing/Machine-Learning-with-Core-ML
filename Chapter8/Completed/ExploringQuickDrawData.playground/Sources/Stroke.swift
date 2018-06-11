//
//  Stroke.swift
//
//  Created by Joshua Newnham on 13/01/2018.
//  Copyright © 2018 Method. All rights reserved.
//

import UIKit

public class Stroke : NSObject, NSCopying{
    // Points that make up the stroke
    public var points : [CGPoint] = [CGPoint]()
    // Color of this stroke
    public var color : UIColor!
    // Width of this stroke
    public var width : CGFloat!
    
    /**
     Return the min point (min x, min y) that contains the users stroke
     */
    public var minPoint : CGPoint{
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
    public var maxPoint : CGPoint{
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
    
    public var path : CGPath{
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
    
    public init(startingPoint:CGPoint,
         color:UIColor=UIColor.black,
         width:CGFloat=2.0) {
        self.points.append(startingPoint)
        self.color = color
        self.width = width
    }
    
    public func copy(with zone: NSZone? = nil) -> Any{
        let copy = Stroke(startingPoint:self.points.first!,
                          color:self.color,
                          width:self.width)

        for i in 1..<self.points.count{
            copy.points.append(self.points[i])
        }

        return copy
    }
}
