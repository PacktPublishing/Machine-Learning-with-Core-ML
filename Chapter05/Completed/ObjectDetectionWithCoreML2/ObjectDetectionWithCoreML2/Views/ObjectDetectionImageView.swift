//
//  SearchResultImageView.swift
//  ObjectDetection
//
//  Created by Joshua Newnham on 14/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit

protocol ObjectDetectionImageViewDelegate : class {
    func onObjectDetectionImageViewDismissed(view:ObjectDetectionImageView)
}

class ObjectDetectionImageView : UIImageView{
    
    weak var delegate : ObjectDetectionImageViewDelegate?
    
    var searchResult : SearchResult?{
        didSet{
            if let searchResult = self.searchResult{
                self.image = searchResult.image.annoatedImage(detectedObjects: searchResult.detectedObjects)
            } else{
                self.image = nil
            }
        }
    }
    
    var fromFrame : CGRect?
    
    var toFrame : CGRect?
    
    var tapGestureRecognizer : UITapGestureRecognizer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(ObjectDetectionImageView.onTapGestureDetected))
        
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.isEnabled = false
        addGestureRecognizer(tapGestureRecognizer)
        
        self.tapGestureRecognizer = tapGestureRecognizer
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func onTapGestureDetected() {
        self.hide()
    }
    
    func show(searchResult:SearchResult, from:CGRect, to:CGRect){
        self.searchResult = searchResult
        self.fromFrame = from
        self.toFrame = to
        
        self.alpha = 0.0
        self.isHidden = false
        self.isUserInteractionEnabled = true
        self.tapGestureRecognizer?.isEnabled = true
        self.frame = self.fromFrame!
        
        UIView.animate(
            withDuration: 0.4,
            delay: 0.0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.2,
            options: [],
            animations: {
                self.alpha = 1.0
                self.frame = self.toFrame!
        }, completion: { (completed) in
            self.setNeedsDisplay()
        })
    }
    
    func hide(){
        
        UIView.animate(
            withDuration: 0.2,
            delay: 0.0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.2,
            options: [],
            animations: {
                self.alpha = 0.0
                self.frame = self.fromFrame!
        }, completion: { (completed) in
            self.isHidden = true
            self.tapGestureRecognizer?.isEnabled = false
            self.isUserInteractionEnabled = false
            
            self.setNeedsDisplay()
            
            self.delegate?.onObjectDetectionImageViewDismissed(view: self)
        })
    }
}
