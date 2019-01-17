import UIKit

public class DigitView : UIView{
    
    public enum Mode{
        case alpha, heat
    }
    
    public var cols : Int = 28{
        didSet{
            pixels.removeAll()
            setNeedsDisplay()
        }
    }
    
    public var rows : Int = 28{
        didSet{
            pixels.removeAll()
            setNeedsDisplay()
        }
    }
    
    public var mode : Mode = Mode.alpha
    
    var pixels : [UInt8] = [UInt8]()
    
    public func setPixels(pixels: [UInt8]){
        if(pixels.count != rows * cols){
            return
        }
        
        self.pixels.removeAll()
        self.pixels.append(contentsOf: pixels)
        
        setNeedsDisplay()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else{
            return;
        }
        
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(rect)
        
        // calculate rect size
        let pixelSize = CGSize(width: rect.width / CGFloat(cols),
                               height: rect.height / CGFloat(rows))
        
        let padding = CGSize(width: (pixelSize.width * 0.05),
                             height: (pixelSize.height * 0.05))
        
        for row in 0..<rows{
            for col in 0..<cols{
                let pixelRect = CGRect(x: CGFloat(col) * pixelSize.width,
                                       y: CGFloat(row) * pixelSize.height,
                                       width: pixelSize.width,
                                       height: pixelSize.height).insetBy(
                                        dx: padding.width,
                                        dy: padding.height)
                
                let pixelIndex = col + row * cols
                if(pixelIndex < pixels.count){
                    let pixel = CGFloat(Float(pixels[pixelIndex]))
                    if mode == Mode.alpha{
                        let alpha = 1.0 - pixel/255 // invert 
                        let pixelColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: alpha)
                        ctx.setFillColor(pixelColor.cgColor)
                    } else{
                        //let colourIntensity = 1.0 - pixel/255.0 // invert
                        var colourIntensity = pixel/255.0 // invert
                        
                        colourIntensity = colourIntensity > 0.5 ?
                            colourIntensity : 0.0
                        let pixelColor = UIColor(red: 0.0,
                                                 green: 0.0,
                                                 blue: colourIntensity,
                                                 alpha: 1.0)
                        ctx.setFillColor(pixelColor.cgColor)
                    }
                } else{
                    let pixelColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                    ctx.setFillColor(pixelColor.cgColor)
                }
                
                ctx.fill(pixelRect)
                
            }
        }
        
    }
}
