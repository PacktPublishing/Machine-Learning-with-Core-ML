
import UIKit
import CoreML

public class HeatmapView : UIView{
    
    public var paddingX : CGFloat = 30{
        didSet{
            setNeedsDisplay()
        }
    }
    
    public var paddingY : CGFloat = 30{
        didSet{
            setNeedsDisplay()
        }
    }
    
    public var spacingX : CGFloat = 2{
        didSet{
            setNeedsDisplay()
        }
    }
    
    public var spacingY : CGFloat = 2{
        didSet{
            setNeedsDisplay()
        }
    }
    
    var startColor = UIColor(red: 255, green: 255, blue: 255){
        didSet{
            setNeedsDisplay()
        }
    }
    
    var endColor = UIColor(red: 77, green: 115, blue: 174){
        didSet{
            setNeedsDisplay()
        }
    }
    
    var xAxisTitle : String?
    
    var yAxisTitle : String?
    
    public var images : [UIImage]?{
        didSet{
            setNeedsDisplay()
        }
    }
    
    public var data : [[Double]]?{
        didSet{
            setNeedsDisplay()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public init(frame: CGRect, images:[UIImage], data:[[Double]]) {
        super.init(frame: frame)
        self.images = images
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
        ctx.setFillColor(UIColor(red:255, green:255, blue:255).cgColor)
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
        
        if let data = self.data, data.count > 0, data[0].count > 0,
            let images = self.images, images.count > 0{
            // Obtain the max value
            var maxVal = Double.leastNormalMagnitude
            
            for r in 0..<data.count{
                for c in 0..<data.count{
                    maxVal = max(data[r][c], maxVal)
                }
            }
            
            let rows = data.count
            let cols = data[0].count
            
            // Dimensions (wxh) for each cell
            let w = plotRect.size.width/CGFloat(cols+1) - self.spacingX * CGFloat(cols+1)
            let h = plotRect.size.height/CGFloat(rows+1) - self.spacingY * CGFloat(rows+1)
            
            let dim = min(w, h)
            
            // draw images
            for i in 0..<images.count{
                let colFrame = CGRect(
                    x:CGFloat(i + 1) * (dim + self.spacingX),
                    y:0,
                    width:dim,
                    height:dim)
                
                let rowFrame = CGRect(
                    x:0,
                    y:CGFloat(i + 1) * (dim + self.spacingY),
                    width:dim,
                    height:dim)
                
                images[i].draw(in:colFrame)
                images[i].draw(in:rowFrame)
            }
            
            for r in 0..<data.count{
                for c in 0..<data.count{
                    let val = data[r][c]
                    let t = 1.0 - CGFloat(val/maxVal)
                    let color = UIColor.lerp(
                        start:self.startColor,
                        end:self.endColor,
                        t:t)
                    ctx.setFillColor(color.cgColor)
                    
                    let rect = CGRect(x: CGFloat(c) * (dim + self.spacingX) + (dim + self.spacingX),
                                      y: CGFloat(r) * (dim + self.spacingY) + (dim + self.spacingX),
                                      width: dim, height: dim)
                    ctx.fill(rect)
                }
            }
        }
        
        ctx.restoreGState()
    }
}
