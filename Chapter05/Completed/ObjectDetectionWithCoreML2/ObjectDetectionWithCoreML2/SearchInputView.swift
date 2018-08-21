//
//  SearchInputView.swift
//  ObjectDetection
//
//  Created by Joshua Newnham on 13/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit

class SearchInputView : UIControl{
    
    var selectedDetectableObject : DetectableObject?
    
    var searchBoxes = [ObjectBounds]()
    
    var normalisedSearchBoxes : [ObjectBounds]{
        get{
            return searchBoxes.map({ (ob) -> ObjectBounds in
                let nsize = CGSize(
                    width: ob.size.width / self.frame.width,
                    height: ob.size.height / self.frame.height)
                
                let norigin = CGPoint(
                    x: ob.origin.x / self.frame.width,
                    y: ob.origin.y / self.frame.height)
                
                return ObjectBounds(
                    object: ob.object,
                    origin: norigin,
                    size: nsize)
            })
        }
    }
    
    // Color used to fill (clear) the canvas
    var clearColor : UIColor = UIColor.white
    // Color used to draw the borders of the view
    var borderColor : UIColor = UIColor.lightGray
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

// MARK: - Public methods

extension SearchInputView{
    
    /** Remove last rectangle **/
    func undo(){
        guard searchBoxes.count > 0 else { return }
        
        searchBoxes.removeLast()
        self.setNeedsDisplay()
    }
    
}

// MARK: - Drawing

extension SearchInputView{
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else{ return }
        
        // clearn the view
        // Set up some generic parameters used for both, drawing the bounds and rectangle
        context.setFillColor(self.clearColor.cgColor)
        context.setStrokeColor(self.borderColor.cgColor)
        context.setLineWidth(0.5)
        context.addRect(self.bounds)
        context.drawPath(using: .fillStroke)
        
        self.drawSearchBoxes(context:context, rect:rect)
    }
    
    private func drawSearchBoxes(context:CGContext, rect:CGRect){
        for searchBox in self.searchBoxes{
            self.drawSearchBox(context:context, rect:rect, searchBox:searchBox)
        }
    }
    
    private func drawSearchBox(context:CGContext, rect:CGRect, searchBox:ObjectBounds){
        let color = DetectableObject.getColor(classIndex:searchBox.object.classIndex)
     
        // Set up some generic parameters used for both, drawing the bounds and rectangle
        context.setFillColor(color.cgColor)
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(2)
        
        // Draw rect
        context.addRect(searchBox.bounds)
        context.drawPath(using: .stroke)
        
        // Draw label
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attrs = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Thin", size: 16)!, NSAttributedString.Key.paragraphStyle: paragraphStyle]
        
        let label = NSString(string: searchBox.object.label)
        let stringBounds = label.boundingRect(with: searchBox.size, options: [], attributes: attrs, context: nil)
        let labelBounds = CGRect(x: searchBox.bounds.origin.x,
                                 y: searchBox.bounds.origin.y - stringBounds.size.height,
                                 width: stringBounds.size.width,
                                 height: stringBounds.size.height)
        context.addRect(labelBounds)
        context.drawPath(using: .fillStroke)
        
        context.setStrokeColor(UIColor.white.cgColor)
        label.draw(in: labelBounds, withAttributes: attrs)
    }
}

// MARK: - Touch methods

extension SearchInputView{
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool{
        // obtain the point of touch relative to this view
        let point = touch.location(in: self)
        
        guard let detectableObject = self.selectedDetectableObject else{
            return false
        }
        
        // Add new search box
        let searchBox = ObjectBounds(object: detectableObject,
                                     origin: point,
                                     size: CGSize.zero)
        
        self.searchBoxes.append(searchBox)
        
        // request the view to redraw itself
        self.setNeedsDisplay()
        
        // notify target of action (target-action pattern)
        self.sendActions(for: UIControl.Event.editingDidBegin)
        
        // return true to indicate we want to continue tracking
        return true
    }
    
    override func continueTracking(_ touch: UITouch?, with event: UIEvent?) -> Bool {
        guard self.searchBoxes.count > 0, let touch = touch else{
            return false
        }
        
        // Obtain the point of touch relative to this view
        let point = touch.location(in: self)
        
        // Update size of current search box
        let idx = self.searchBoxes.count - 1
        let minXY = CGPoint(x: min(point.x, self.searchBoxes[idx].origin.x),
                             y: min(point.y, self.searchBoxes[idx].origin.y))
        
        let maxXY = CGPoint(x: max(point.x, self.searchBoxes[idx].origin.x),
                            y: max(point.y, self.searchBoxes[idx].origin.y))
        
        let size = CGSize(width: maxXY.x - minXY.x, height: maxXY.y - minXY.y)
        
        self.searchBoxes[idx].origin = minXY
        self.searchBoxes[idx].size = size
        
        // request the view to redraw itself
        self.setNeedsDisplay()
        
        // notify target of action (target-action pattern)
        self.sendActions(for: UIControl.Event.editingChanged)
        
        // return true to indicate we want to continue tracking
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        guard self.searchBoxes.count > 0, let touch = touch else{
            return
        }
        
        // obtain the point of touch relative to this view
        let point = touch.location(in: self)
        
        // Update size of current search box
        let idx = self.searchBoxes.count - 1
        let minXY = CGPoint(x: min(point.x, self.searchBoxes[idx].origin.x),
                            y: min(point.y, self.searchBoxes[idx].origin.y))
        
        let maxXY = CGPoint(x: max(point.x, self.searchBoxes[idx].origin.x),
                            y: max(point.y, self.searchBoxes[idx].origin.y))
        
        let size = CGSize(width: maxXY.x - minXY.x, height: maxXY.y - minXY.y)
        
        self.searchBoxes[idx].origin = minXY
        self.searchBoxes[idx].size = size
        
        // request the view to redraw itself
        self.setNeedsDisplay()
        
        // notify target of action (target-action pattern)
        self.sendActions(for: UIControl.Event.editingDidEnd)
    }
    
    override func cancelTracking(with event: UIEvent?) {
        // request the view to redraw itself
        self.setNeedsDisplay()
        
        // notify target of action (target-action pattern)
        self.sendActions(for: UIControl.Event.editingDidEnd)
    }
}
