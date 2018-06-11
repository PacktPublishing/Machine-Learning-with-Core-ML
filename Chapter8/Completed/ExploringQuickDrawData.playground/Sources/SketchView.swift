//
//  SketchView
//
//  Created by Joshua Newnham on 13/01/2018.
//  Copyright © 2018 Method. All rights reserved.
//

import UIKit

public class SketchView: UIControl {

    // Color used to fill (clear) the canvas
    public var clearColor : UIColor = UIColor.white

    // Array of sketches to be drawn
    public var sketches = [Sketch]()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Remove all items from the sketches Array and request the view to be re-drawn
    public func removeAllSketches(){
        self.sketches.removeAll()
        self.setNeedsDisplay()
    }
}

// MARK: - Drawing

extension SketchView{
    
    public override func draw(_ rect: CGRect) {
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
