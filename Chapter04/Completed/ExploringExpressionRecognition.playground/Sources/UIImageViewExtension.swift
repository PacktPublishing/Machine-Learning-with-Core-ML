import UIKit

public extension UIImageView{
    
    public func drawPath(pathPoints:[CGPoint],
                         closePath:Bool = true,
                         color:UIColor = UIColor.red,
                         lineWidth:CGFloat=3.0,
                         vFlip:Bool = false){
        guard let currentImage = self.image else{
            fatalError("No image set")
        }
        
        // Create a context of the starting image size and set it as the current one
        UIGraphicsBeginImageContext(currentImage.size)
        
        // Get the current context
        guard let context = UIGraphicsGetCurrentContext() else{
            return
        }
        
        if vFlip{
            context.translateBy(x: 0, y: currentImage.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
        }
        
        // Draw the starting image in the current context as background
        currentImage.draw(at: CGPoint.zero)
        
        // Setup Stroke
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        // Draw path
        context.move(to: pathPoints.first!)
        for i in 1..<pathPoints.count{
            context.addLine(to: pathPoints[i])
        }
        if closePath{
            context.closePath()
        }
        
        context.drawPath(using: .stroke)
        
        // Create image from context and end the image context
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Update the views UIImage
        self.image = newImage
    }
    
    public func drawCircle(center:CGPoint,
                           radius:CGFloat = 3.0,
                           color:UIColor = UIColor.red,
                           lineWidth:CGFloat=3.0,
                           vFlip:Bool = false){
        guard let currentImage = self.image else{
            fatalError("No image set")
        }
        
        // Create a context of the starting image size and set it as the current one
        UIGraphicsBeginImageContext(currentImage.size)
        
        // Get the current context
        guard let context = UIGraphicsGetCurrentContext() else{
            return
        }
        
        if vFlip{
            context.translateBy(x: 0, y: currentImage.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
        }
        
        // Draw the starting image in the current context as background
        currentImage.draw(at: CGPoint.zero)
        
        // Setup Stroke
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        // Draw ellipse
        context.addEllipse(in: CGRect(
            x: center.x - radius/2,
            y: center.y - radius/2,
            width: radius * 2,
            height:radius * 2))
        
        context.drawPath(using: .stroke)
        
        // Create image from context and end the image context
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Update the views UIImage
        self.image = newImage
    }
    
    public func drawRect(rect:CGRect,
                         color:UIColor = UIColor.red,
                         lineWidth:CGFloat=3.0,
                         vFlip:Bool = false){
        guard let currentImage = self.image else{
            fatalError("No image set")
        }
        
        // Create a context of the starting image size and set it as the current one
        UIGraphicsBeginImageContext(currentImage.size)
        
        // Get the current context
        guard let context = UIGraphicsGetCurrentContext() else{
            return
        }
        
        if vFlip{
            context.translateBy(x: 0, y: currentImage.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
        }
        
        // Draw the starting image in the current context as background
        currentImage.draw(at: CGPoint.zero)
        
        // Setup Stroke
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        // Draw rectangle
        context.addRect(rect)
        context.drawPath(using: .stroke)
        
        // Create image from context and end the image context
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Update the views UIImage
        self.image = newImage
    }
}
