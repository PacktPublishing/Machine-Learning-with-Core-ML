//
//  Sketch.swift
//  QuickDraw
//
//  Created by Joshua Newnham on 04/01/2018.
//  Copyright © 2018 Method. All rights reserved.
//

import UIKit

protocol Sketch : class{
    
    var boundingBox : CGRect{ get }
    
    var center : CGPoint{ get set }
    
    func draw(context:CGContext)
    
    func exportSketch(size:CGSize?) -> CIImage?
}
