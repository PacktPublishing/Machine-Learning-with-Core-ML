//
//  SketchView.swift
//  QuickDraw
//
//  Created by Joshua Newnham on 21/12/2017.
//  Copyright © 2017 Method. All rights reserved.
//

import UIKit

class SketchView: UIControl {
    
    // Color used to fill (clear) the canvas
    var clearColor : UIColor = UIColor.white
    
    // The color assigned to the stroke
    var strokeColor : UIColor = UIColor.black
    
    // The width assigned to the stroke
    var strokeWidth : CGFloat = 1.0
    
    // Array of sketches to be drawn
    var sketches = [Sketch]()
    
    /**
     Current sketch is the last sketch of the sketches array; therefore assigning
     a sketch to this property will replace the last item of the sketches array
     (or add one if the array is empty)
    */
    var currentSketch : Sketch?{
        get{
            return self.sketches.count > 0 ? self.sketches.last : nil
        }
        set{
            if let newValue = newValue{
                if self.sketches.count > 0{
                    self.sketches[self.sketches.count-1] = newValue
                } else{
                    self.sketches.append(newValue)
                }
            } else if self.sketches.count > 0{
                self.sketches.removeLast()
            }
            
            self.setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Remove all items from the sketches Array and request the view to be re-drawn 
    func removeAllSketches(){
        self.sketches.removeAll()
        self.setNeedsDisplay()
    }
}

// MARK: - Drawing

extension SketchView{        
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else{ return }
        
        // clearn the view
        self.clearColor.setFill()
        UIRectFill(self.bounds)
        
        // iterate over all sketches and have
        // them draw themselves
        for sketch in self.sketches{
            sketch.draw(context: context)
        }
    }
}

// MARK: - Touch methods

extension SketchView{
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool{
        // return true to indicate we want to continue tracking
        return true
    }
    
    override func continueTracking(_ touch: UITouch?, with event: UIEvent?) -> Bool {
        // return true to indicate we want to continue tracking
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        
    }
    
    override func cancelTracking(with event: UIEvent?) {        
    }
}
