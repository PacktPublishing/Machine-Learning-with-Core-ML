//
//  CGPoint+Extension.swift
//  ObjectDetection
//
//  Created by Joshua Newnham on 17/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit 

extension CGPoint{
    
    var length : CGFloat{
        get{
            return sqrt(self.x * self.x + self.y * self.y)
        }
    }
    
    var normalised : CGPoint{
        get{
            return CGPoint(x: self.x/self.length, y: self.y/self.length)
        }
    }
    
    func distance(other:CGPoint) -> CGFloat{
        let dx = (self.x - other.x)
        let dy = (self.y - other.y)
        
        return sqrt(dx*dx + dy*dy)
    }
    
    func dot(other:CGPoint) -> CGFloat{
        return (self.x * other.x) + (self.y * other.y)
    }
    
    static func -(left: CGPoint, right: CGPoint) -> CGPoint{
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
}
