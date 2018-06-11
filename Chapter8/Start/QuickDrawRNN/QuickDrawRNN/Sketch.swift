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

class StrokeSketch : Sketch{
    
    public var label : String?
    
    var strokes = [Stroke]()
    
    var scale : CGFloat = 1.0
    
    var currentStroke : Stroke?{
        get{
            return strokes.count > 0 ? strokes.last : nil
        }
    }
    
    /**
     Return the min point (min x, min y) that contains the users stroke
     */
    public var minPoint : CGPoint{
        get{
            guard strokes.count > 0 else{
                return CGPoint(x: 0, y: 0)
            }
            
            let minPoints = strokes.map { (stroke) -> CGPoint in
                return CGPoint(x:stroke.minPoint.x * self.scale,
                               y:stroke.minPoint.y * self.scale)
            }
            
            let minX : CGFloat = minPoints.map { (cp) -> CGFloat in
                return cp.x
                }.min() ?? 0
            
            let minY : CGFloat = minPoints.map { (cp) -> CGFloat in
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
            guard strokes.count > 0 else{
                return CGPoint(x: 0, y: 0)
            }
            
            let maxPoints = strokes.map { (stroke) -> CGPoint in
                return CGPoint(x:stroke.maxPoint.x * self.scale,
                               y:stroke.maxPoint.y * self.scale)
            }
            
            let maxX : CGFloat = maxPoints.map { (cp) -> CGFloat in
                return cp.x
                }.max() ?? 0
            
            let maxY : CGFloat = maxPoints.map { (cp) -> CGFloat in
                return cp.y
                }.max() ?? 0
            
            return CGPoint(x: maxX, y: maxY)
        }
    }
    
    /** Returning the bounding box that encapsulates the users sketch **/
    public var boundingBox : CGRect{
        get{
            let minPoint = self.minPoint
            let maxPoint = self.maxPoint
            
            let size = CGSize(width: maxPoint.x - minPoint.x,
                              height: maxPoint.y - minPoint.y)
            
            // add some arbitrary padding
            let paddingSize = CGSize(width: 5,
                                     height: 5)
            
            return CGRect(x: minPoint.x - paddingSize.width,
                          y: minPoint.y - paddingSize.height,
                          width: size.width + (paddingSize.width * 2),
                          height: size.height + (paddingSize.height * 2))
        }
    }
    
    public var center : CGPoint{
        get{
            let bbox = self.boundingBox
            return CGPoint(x:bbox.origin.x + bbox.size.width/2,
                           y:bbox.origin.y + bbox.size.height/2)
        }
        set{
            let previousCenter = self.center
            let newCenter = newValue
            let translation = CGPoint(x:newCenter.x - previousCenter.x,
                                      y:newCenter.y - previousCenter.y)
            for stroke in self.strokes{
                for i in 0..<stroke.points.count{
                    stroke.points[i] = CGPoint(
                        x:stroke.points[i].x + translation.x,
                        y:stroke.points[i].y + translation.y)
                }
            }
        }
    }
    
    public init() {
        
    }
    
    public func draw(context:CGContext){
        UIGraphicsPushContext(context)
        
        context.scaleBy(x: self.scale, y: self.scale)
        
        self.drawStrokes(context:context)
        
        UIGraphicsPopContext()
    }
    
    public func drawStrokes(context:CGContext){
        for stroke in self.strokes{
            self.drawStroke(context: context, stroke: stroke)
        }
    }
    
    private func drawStroke(context:CGContext, stroke:Stroke){
        stroke.color.setStroke()
        context.setStrokeColor(stroke.color.cgColor)
        context.setLineWidth(stroke.width)
        context.addPath(stroke.path)
        context.drawPath(using: .stroke)
    }
    
    public func exportSketch(size:CGSize?=nil) -> CIImage?{
        let boundingBox = self.boundingBox
        let targetSize = size ?? CGSize(
            width: max(boundingBox.width, boundingBox.height),
            height: max(boundingBox.width, boundingBox.height))
        
        var scale : CGFloat = 1.0
        
        if boundingBox.width > boundingBox.height{
            scale = targetSize.width / (boundingBox.width)
        } else{
            scale = targetSize.height / (boundingBox.height)
        }
        
        guard boundingBox.width > 0, boundingBox.height > 0 else{
            return nil
        }
        
        UIGraphicsBeginImageContextWithOptions(targetSize, true, 1.0)
        
        guard let context = UIGraphicsGetCurrentContext() else{
            return nil
        }
        
        UIGraphicsPushContext(context)
        
        UIColor.white.setFill()
        context.fill(CGRect(x: 0, y: 0,
                            width: targetSize.width, height: targetSize.height))
        
        context.scaleBy(x: scale, y: scale)
        
        let scaledSize = CGSize(width: boundingBox.width * scale, height: boundingBox.height * scale)
        
        context.translateBy(x: -boundingBox.origin.x + (targetSize.width - scaledSize.width)/2,
                            y: -boundingBox.origin.y + (targetSize.height - scaledSize.height)/2)
        
        self.drawStrokes(context: context)
        
        UIGraphicsPopContext()
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else{
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()
        
        return image.ciImage != nil ? image.ciImage : CIImage(cgImage: image.cgImage!)
    }
    
    public func addStroke(stroke:Stroke){
        self.strokes.append(stroke)
    }
}

class ImageSketch : Sketch{
    
    var image : UIImage!
    
    var size : CGSize!
    
    var origin : CGPoint!
    
    var label : String!
    
    var boundingBox : CGRect{
        get{
            return CGRect(origin: self.origin, size: self.size)
        }
    }
    
    var center : CGPoint{
        get{
            let bbox = self.boundingBox
            return CGPoint(x:bbox.origin.x + bbox.size.width/2,
                           y:bbox.origin.y + bbox.size.height/2)
        } set{
            self.origin = CGPoint(x:newValue.x - self.size.width/2,
                                  y:newValue.y - self.size.height/2)
        }
    }
    
    init(image:UIImage, origin:CGPoint, size:CGSize, label: String) {
        self.image = image
        self.size = size
        self.label = label
        self.origin = origin
    }
    
    func draw(context:CGContext){
        self.image.draw(in: self.boundingBox)
    }
    
    func exportSketch(size:CGSize?) -> CIImage?{
        guard let ciImage = CIImage(image: self.image) else{
            return nil
        }
        
        if self.image.size.width == self.size.width && self.image.size.height == self.size.height{
            return ciImage
        } else{
            return ciImage.resize(size: self.size)
        }
    }
}

extension StrokeSketch : NSCopying{
    
    public func copy(with zone: NSZone? = nil) -> Any{
        let copy = StrokeSketch()
        copy.scale = self.scale
        copy.label = self.label
        
        for stroke in self.strokes{
            copy.addStroke(stroke:stroke.copy() as! Stroke)
        }
        
        return copy
    }
}
