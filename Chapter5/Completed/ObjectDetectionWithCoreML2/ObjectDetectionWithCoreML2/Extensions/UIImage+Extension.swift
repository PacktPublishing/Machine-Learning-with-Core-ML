//
//  UIImage+Extension.swift
//  ObjectDetection
//
//  Created by Joshua Newnham on 16/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit

extension UIImage{
    
    func annoatedImage(detectedObjects:[ObjectBounds]) -> UIImage?{
    
        // Create a context of the starting image size and set it as the current one
        UIGraphicsBeginImageContext(self.size)
        
        // Draw the starting image in the current context as background
        self.draw(at: CGPoint.zero)
        
        // Get the current context
        let context = UIGraphicsGetCurrentContext()!
        
        for detectedObject in detectedObjects{
            self.annoatedImageWithDetectedObject(context: context, detectedObject: detectedObject)
        }
        
        // Save the context as a new UIImage
        let annoatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Resturn modified image
        return annoatedImage
    }
    
    private func annoatedImageWithDetectedObject(context:CGContext, detectedObject:ObjectBounds){
        // scale size
        let size = CGSize(width: detectedObject.size.width * self.size.width,
                          height: detectedObject.size.height * self.size.height)
        // scale origin
        let origin = CGPoint(x: detectedObject.origin.x * self.size.width,
                             y: detectedObject.origin.y * self.size.height)
        
        let bounds = CGRect(origin: origin, size: size)
        
        let color = DetectableObject.getColor(classIndex:detectedObject.object.classIndex)
        
        // Calculate a scale that will be used to define the line width and font size (based on values
        // set during design time)
        let scale = min(self.size.width, self.size.height) / 416
        
        // Set up some generic parameters used for both, drawing the bounds and rectangle
        context.setFillColor(color.cgColor)
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(2 * scale)
        
        // Draw rect
        context.addRect(bounds)
        context.drawPath(using: .stroke)
        
        // Draw label
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attrs = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Thin", size: 16 * scale)!, NSAttributedString.Key.paragraphStyle: paragraphStyle]
        
        let label = NSString(string: detectedObject.object.label)
        let stringBounds = label.boundingRect(with: bounds.size, options: [], attributes: attrs, context: nil)
        let labelBounds = CGRect(x: bounds.origin.x,
                                 y: bounds.origin.y - stringBounds.size.height,
                                 width: stringBounds.size.width,
                                 height: stringBounds.size.height)
        context.addRect(labelBounds)
        context.drawPath(using: .fillStroke)
        
        context.setStrokeColor(UIColor.white.cgColor)
        label.draw(in: labelBounds, withAttributes: attrs)
    }
}
