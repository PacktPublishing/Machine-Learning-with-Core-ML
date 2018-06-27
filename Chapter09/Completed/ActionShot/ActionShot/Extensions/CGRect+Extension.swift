//
//  CGRect+Extension.swift
//  ActionShot
//
//  Created by Joshua Newnham on 02/06/2018.
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
}
