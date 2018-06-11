import UIKit
import Accelerate
import CoreML

public class HistogramView : UIView{
    
    var paddingX : CGFloat = 30
    
    var paddingY : CGFloat = 30
    
    var xAxisTitle : String?
    
    var yAxisTitle : String?
    
    public var data : MLMultiArray?{
        didSet{
            setNeedsDisplay()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public init(frame: CGRect, data:MLMultiArray) {
        super.init(frame: frame)
        self.data = data 
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
        
        ctx.setStrokeColor(UIColor.black.cgColor)
        
        
        let plotRect = CGRect(x: paddingX,
                              y: paddingY,
                              width: rect.width - (paddingX * 2),
                              height: rect.height - (paddingY * 2))
        
        // fill in background of plot
        ctx.setFillColor(UIColor(red:250, green:250, blue:250).cgColor)
        ctx.fill(plotRect)
        
        // draw grid
        // set style of grid
        UIColor.white.setStroke()
        ctx.setLineWidth(1)
        
        // draw lines of grid
        for x in stride(from: plotRect.minX, to: plotRect.maxX, by: plotRect.width/5){
            
            ctx.move(to: CGPoint(x:x, y:plotRect.minY))
            ctx.addLine(to: CGPoint(x:x, y:plotRect.maxY))
            ctx.strokePath()
        }
        
        for y in stride(from: plotRect.minY, to: plotRect.maxY, by: plotRect.height/5){
            
            ctx.move(to: CGPoint(x:plotRect.minX, y:y))
            ctx.addLine(to: CGPoint(x:plotRect.maxX, y:y))
            ctx.strokePath()
        }
        
        // draw y-axis
        ctx.move(to: CGPoint(x:plotRect.origin.x, y:plotRect.origin.y))
        ctx.setLineWidth(2)
        ctx.addLine(to: CGPoint(x:plotRect.origin.x, y:plotRect.maxY))
        ctx.strokePath()
        
        // draw y-axis
        ctx.move(to: CGPoint(x:plotRect.origin.x, y:plotRect.maxY))
        ctx.setLineWidth(2)
        ctx.addLine(to: CGPoint(x:plotRect.maxX, y:plotRect.maxY))
        ctx.strokePath()
        
        // draw data points
        ctx.saveGState()
        ctx.translateBy(x: plotRect.origin.x, y: plotRect.origin.y)
        
        let barColor = UIColor(red: 77, green: 115, blue: 174)
        ctx.setFillColor(barColor.cgColor)
        
        if let data = self.data, data.count > 0{
            var maxVal = Double.leastNormalMagnitude
            for i in 0..<data.count{
                maxVal = max(Double(data[i]), maxVal)
            }
            let hScale = CGFloat(plotRect.size.height)/CGFloat(maxVal)
            let w = CGFloat(plotRect.size.width) / CGFloat(data.count)
            var cX : CGFloat = 0
            for i in 0..<data.count{
                let scaledData = CGFloat(truncating:data[i]) * hScale
                ctx.fill(CGRect(
                    x: cX,
                    y: plotRect.size.height - scaledData,
                    width: w,
                    height: scaledData))
                cX = cX + w
            }
        }
        
        ctx.restoreGState()
    }
}
