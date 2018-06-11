//
//  Array+Extension.swift
//  ObjectDetection
//
//  Created by Joshua Newnham on 15/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import Foundation
import Accelerate

extension Array where Element == Float{
    
    /**
     @return index of the largest element in the array
    **/
    var argmax : Int {
        get{
            precondition(self.count > 0)
            
            let maxValue = self.maxValue
            for i in 0..<self.count{
                if self[i] == maxValue{
                    return i
                }
            }
            return -1 
        }
    }
    
    /**
     Find the maximum value in array 
    */
    var maxValue : Float{
        get{
            let len = vDSP_Length(self.count)
            
            var max: Float = 0
            vDSP_maxv(self, 1, &max, len)
            
            return max
        }
    }
}
