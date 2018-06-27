//
//  CGRect+Extension.swift
//  ObjectDetection
//
//  Created by Joshua Newnham on 15/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit

extension CGRect{
    
    var center : CGPoint{
        get{
            return CGPoint(x: self.origin.x + self.size.width/2,
                           y: self.origin.y + self.size.height/2)
        }
    }
    
    var area : CGFloat{
        get{
            return self.size.width * self.size.height
        }
    }
    
    /**
     Calcualte Intersection-over-Union of this rectangle and the other
    **/
    func computeIOU(other:CGRect) -> CGFloat{        
        //let iou = intersectionArea / unionArea
        let iou = self.intersection(other).area / self.union(other).area
        
        return iou
    }
    
}
