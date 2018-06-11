import UIKit

/**
 Metadata for a specified type of datapoint (associated via the tag)
 */
public struct DataPointStyle{
    public var size : CGFloat = 2
    public var color : CGColor = UIColor.black.cgColor
    
    public init(size:CGFloat=2, color:CGColor = UIColor.black.cgColor){
        self.size = size
        self.color = color
    }
}

/**
 Simple plotter
 */
public class ScatterPlotView : UIView{
    
    var paddingX : CGFloat = 30
    
    var paddingY : CGFloat = 30
    
    var xAxisTitle : String?
    
    var yAxisTitle : String?
    
    public var styles = ["default": DataPointStyle(
        size: 5,
        color: UIColor(red:87, green:114, blue:216).cgColor)]
    
    var scatterDataPoints = [DataPoint]()
    
    var lineDataPoints = [DataPoint]()
    
    public var lineCount : Int{
        get{
            return lineDataPoints.count == 0 ? 0 : Int(lineDataPoints.count / 2)
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
     Add a line pair to the plot; only the first style will be used (pointA)
     and the other ignored (pointB)
     */
    public func line(pointA:DataPoint, pointB:DataPoint){
        lineDataPoints.append(pointA)
        lineDataPoints.append(pointB)
        
        // refresh view
        setNeedsDisplay()
    }
    
    public func scatter(_ dataPoints:[DataPoint]){
        self.scatterDataPoints.append(contentsOf: dataPoints)
        
        // refresh view
        setNeedsDisplay()
    }
    
    public func scatter(_ dataPoints:DataPoint ...){
        self.scatterDataPoints.append(contentsOf: dataPoints)
        
        // refresh view
        setNeedsDisplay()
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
        ctx.setFillColor(UIColor(red:234, green:234, blue:242).cgColor)
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
        
        drawScatter(rect: CGRect(x:0, y:0,
                                 width:plotRect.width,
                                 height:plotRect.height),ctx: ctx)
        
        drawLine(rect: CGRect(x:0, y:0,
                              width:plotRect.width,
                              height:plotRect.height),ctx: ctx)
        
        ctx.restoreGState()
        
    }
    
    func drawLine(rect : CGRect, ctx : CGContext){
        if(lineDataPoints.count == 0){
            return
        }
        
        let scale = self.calcDrawingRectScale(rect:rect)
        
        // remove stroke color
        ctx.setStrokeColor(UIColor.clear.cgColor)
        
        for i in stride(from: 0, to: lineDataPoints.count, by: 2){
            let dp1 = lineDataPoints[i]
            let dp2 = lineDataPoints[i+1]
            
            let x1 = dp1.x * scale.x
            let y1 = rect.height - (dp1.y * scale.y)
            
            let x2 = dp2.x * scale.x
            let y2 = rect.height - (dp2.y * scale.y)
            
            let style = self.styles[dp1.tag] ?? self.styles["default"]
            ctx.setStrokeColor(style!.color)
            ctx.setLineWidth(style!.size)
            
            ctx.beginPath()
            
            ctx.move(to: CGPoint(x: x1, y: y1))
            ctx.addLine(to: CGPoint(x: x2, y: y2))
            
            ctx.strokePath()
        }
        
    }
    
    func drawScatter(rect : CGRect, ctx : CGContext){
        if(scatterDataPoints.count == 0){
            return
        }
        
        // remove stroke color
        ctx.setStrokeColor(UIColor.clear.cgColor)
        
        let scale = self.calcDrawingRectScale(rect:rect)
        
        // iterate through all styles
        for (key, style) in self.styles{
            // get all associated data points
            let dps = scatterDataPoints.filter{ $0.tag == key }
            
            ctx.beginPath()
            
            // update fill color
            ctx.setFillColor(style.color)
            
            // draw each data point belonging to this style
            for dp in dps{
                let x = dp.x * scale.x
                var y = dp.y * scale.y
                // invert y
                y = rect.height - y
                // create containing rect
                let dpRect = CGRect(x: x - style.size/2,
                                    y: y - style.size/2,
                                    width: style.size,
                                    height: style.size)
                
                ctx.fillEllipse(in: dpRect)
            }
            
            ctx.fillPath()
        }
    }
    
    func calcDrawingRectScale(rect:CGRect) -> (x:CGFloat, y:CGFloat){
        // find min and max x values
        let minX = scatterDataPoints.map { $0.x }.min() ?? 0
        let maxX = scatterDataPoints.map { $0.x }.max() ?? 0
        
        // find min and max x values
        let minY = scatterDataPoints.map { $0.y }.min() ?? 0
        let maxY = scatterDataPoints.map { $0.y }.max() ?? 0
        
        let scaleX = rect.width / (maxX - minX)
        let scaleY = rect.height / (maxY - minY)
        
        return (x:scaleX, y:scaleY)
    }
}
