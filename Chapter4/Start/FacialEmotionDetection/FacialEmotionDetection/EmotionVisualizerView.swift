//
//  EmotionVisualizerView.swift
//  FacialEmotionDetection
//
//  Created by Joshua Newnham on 03/03/2018.
//  Copyright © 2018 PacktPub. All rights reserved.
//

import UIKit

class EmotionVisualizerView: UIView {
    
    var currentEmotions : [String:Double]?
    
    var targetEmotions : [String:Double]?
    
    var barColors : [String:UIColor]?
    
    /** spacing between bars */
    var barSpacing : CGFloat = 1.0{
        didSet{
            if self.animTimer == nil{
                self.setNeedsDisplay()
            }
        }
    }
    
    var margin = CGSize(width: 10, height: 10){
        didSet{
            if self.animTimer == nil{
                self.setNeedsDisplay()
            }
        }
    }
    
    var padding = CGSize(width: 5, height: 5){
        didSet{
            if self.animTimer == nil{
                self.setNeedsDisplay()
            }
        }
    }
    
    var chartBackgroundColor : UIColor = UIColor.clear{
        didSet{
            if self.animTimer == nil{
                self.setNeedsDisplay()
            }
        }
    }
    
    var valueFontSize : CGFloat = 8{
        didSet{
            if self.animTimer == nil{
                self.setNeedsDisplay()
            }
        }
    }
    
    var valueFontColor : UIColor = UIColor.gray{
        didSet{
            if self.animTimer == nil{
                self.setNeedsDisplay()
            }
        }
    }
    
    var labelFontSize : CGFloat = 16{
        didSet{
            if self.animTimer == nil{
                self.setNeedsDisplay()
            }
        }
    }
    
    var labelFontColor : UIColor = UIColor.gray{
        didSet{
            if self.animTimer == nil{
                self.setNeedsDisplay()
            }
        }
    }
    
    var animTimer: Timer?
    
    var barColorHigh  = UIColor(red:217, green:94, blue:89, alpha:0.5){
        didSet{
            if self.animTimer == nil{
                self.setNeedsDisplay()
            }
        }
    }
    
    var barColorMedium = UIColor(red:142, green:161, blue:202, alpha:0.5){
        didSet{
            if self.animTimer == nil{
                self.setNeedsDisplay()
            }
        }
    }
    
    var barColorLow  = UIColor(red:163, green:163, blue:163, alpha:0.5){
        didSet{
            if self.animTimer == nil{
                self.setNeedsDisplay()
            }
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func update(labelConference:[String:Double]){
        
        if self.currentEmotions == nil{
            self.initEmotions(initialValues:labelConference)
        } else{
            self.targetEmotions = labelConference
        }
        
        if self.animTimer == nil{
            self.startAnim()
        }
    }
    
    private func initEmotions(initialValues:[String:Double]){
        self.currentEmotions = [String:Double]()
        self.targetEmotions = initialValues
        self.barColors = [String:UIColor]()
        
        self.targetEmotions?.keys.forEach({ (emotionLabel) in
            self.currentEmotions![emotionLabel] = 0.0
            self.barColors![emotionLabel] = self.barColorLow
        })
    }
}

// MARK: - Drawing method

extension EmotionVisualizerView{
    
    override public func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else{
            return;
        }
        
        self.animateCurrentEmotions()
        
        ctx.setFillColor(self.backgroundColor!.cgColor)
        ctx.fill(rect)
        
        guard let predictions = self.currentEmotions else{ return }
        
        let insetRect = CGRect(x: self.margin.width,
                               y: self.margin.height,
                               width: rect.width - (self.margin.width * 2),
                               height: rect.height - (self.margin.height * 2))
        
        ctx.setFillColor(self.chartBackgroundColor.cgColor)
        ctx.fill(insetRect)
        
        ctx.saveGState()
        ctx.translateBy(x: insetRect.origin.x, y: insetRect.origin.y)
        
        // calculate dimensions for each bar
        let barHeight = insetRect.height - padding.height
        let barWidth = (insetRect.width - (padding.width * 2) - (CGFloat(predictions.count) * barSpacing)) / CGFloat(predictions.count)
        
        // font
        let valueParagraphStyle = NSMutableParagraphStyle()
        valueParagraphStyle.alignment = .center
        
        let labelParagraphStyle = NSMutableParagraphStyle()
        labelParagraphStyle.alignment = .left
        
        let labelAttrs = [NSAttributedStringKey.font: UIFont(name: "HelveticaNeue-Thin", size: self.labelFontSize)!,
                          NSAttributedStringKey.paragraphStyle: labelParagraphStyle,
                          NSAttributedStringKey.foregroundColor : self.labelFontColor]
        
        // assuming predictions are in the range of 0-1 (where 1 is 100%) i.e. already normalised
        var ox = padding.width
        for (k, v) in predictions{
            // dimensions of bar
            let w = barWidth
            let x = ox
            let h = CGFloat(v) * barHeight
            let y = insetRect.height - h - padding.height - self.valueFontSize
            
            // draw label
            ctx.saveGState()
            
            ctx.rotate(by: -CGFloat.pi/2)
            
            k.draw(
                with:CGRect(x: -(y + h - 5), y: x+w/3, width: 100, height: w),
                options: .usesLineFragmentOrigin,
                attributes: labelAttrs,
                context: nil)
            
            ctx.restoreGState()
            
            // bar color
            let currentC = self.barColors![k]!
            let targetC = self.getBarColor(label:k, value:v)
            self.barColors![k] = UIColor.lerp(src: currentC, target: targetC, t: 0.1)
            ctx.setFillColor(self.barColors![k]!.cgColor)
            
            // draw rect
            ctx.fill(CGRect(x: x, y: y, width: w, height: h))
            
            // udpate offset
            ox += barWidth
            ox += barSpacing
        }
        
        ctx.restoreGState()
    }
    
    private func getBarColor(label:String, value:Double) -> UIColor{
        if value >= 0.5{
            return self.barColorHigh
        }

        if value >= 0.3{
            return self.barColorMedium
        }

        return self.barColorLow
    }
}

// MARK: - Animation methods

extension EmotionVisualizerView{
    
    public func startAnim(){
        animTimer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(EmotionVisualizerView.onAnimTimer),
            userInfo: nil,
            repeats: true)
    }
    
    public func stopAnim(){
        if let animTimer = self.animTimer{
            animTimer.invalidate()
        }
        self.animTimer = nil
    }
    
    @objc func onAnimTimer(){
        self.setNeedsDisplay()
    }
    
    private func animateCurrentEmotions(){
        // keep track of the differences between target and current values
        var distance : Double = 0.0
        
        // animate current values towards their corresponding targets
        if let targets = self.targetEmotions, let destination = self.currentEmotions{
            for (k,targetValue) in targets{
                let currentValue = destination[k] ?? 0
                let newValue = currentValue + (targetValue - currentValue) * 0.1
                self.currentEmotions![k] = newValue
                
                let difference = (newValue - targetValue)
                distance += (difference * difference)
                
                //print("\(k) \(targetValue) \(currentValue)")
            }
            
            // stop animation if reached target
            if sqrt(distance) <= 0.1{
                self.stopAnim()
            }
        }
    }
}
