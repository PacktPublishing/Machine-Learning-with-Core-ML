//
//  UIColorExtension.swift
//  FacialEmotionDetection
//
//  Created by Joshua Newnham on 09/03/2018.
//  Copyright © 2018 PacktPub. All rights reserved.
//

import UIKit 

/**
 Simple extension of the color
 */
extension UIColor {
    
    public convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat=1.0) {
        
        self.init(red: CGFloat(red)/255,
                  green: CGFloat(green)/255,
                  blue: CGFloat(blue)/255,
                  alpha: alpha)
    }
    
    func getRGBA() -> [CGFloat]{
        var red : CGFloat = 0.0, green : CGFloat = 0.0, blue : CGFloat = 0.0, alpha : CGFloat = 0.0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue, alpha]
    }
    
    /**
     Linear interpolation between two colors 
    */
    static func lerp(src:UIColor, target:UIColor, t:CGFloat) -> UIColor{
        let srcComponents = src.getRGBA()
        let targetComponents = target.getRGBA()
        
        let color = UIColor(
            red: srcComponents[0] + (targetComponents[0]-srcComponents[0]) * t,
            green: srcComponents[1] + (targetComponents[1]-srcComponents[1]) * t,
            blue: srcComponents[2] + (targetComponents[2]-srcComponents[2]) * t,
            alpha: srcComponents[3] + (targetComponents[3]-srcComponents[3]) * t)
        
        return color
    }
}
