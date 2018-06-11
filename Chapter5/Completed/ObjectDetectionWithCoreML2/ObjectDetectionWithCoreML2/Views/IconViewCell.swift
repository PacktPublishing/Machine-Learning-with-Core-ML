//
//  IconViewCell.swift
//  ObjectDetection
//
//  Created by Joshua Newnham on 13/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit

class IconViewCell : UICollectionViewCell{
    
    weak var imageView : UIImageView?
    
    var index : Int = -1 
    
    override var isSelected : Bool{
        didSet{
            if isSelected{
                self.imageView?.image = self.selectedImage
            } else{
                self.imageView?.image = self.image
            }
        }
    }
    
    var image : UIImage?{
        didSet{
            if let image = self.image, !isSelected{
                self.imageView?.image = image
            }
        }
    }
    
    var selectedImage : UIImage?{
        didSet{
            if let selectedImage = self.selectedImage, isSelected{
                self.imageView?.image = selectedImage
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        self.initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initUI()
    }
}

// MARK: - UI

extension IconViewCell{
    
    func initUI(){
        self.backgroundColor = UIColor.clear
        
        let padding = self.bounds.width * 0.1
        let imageViewBounds = CGRect(x: self.bounds.origin.x + padding,
                                     y: self.bounds.origin.y + padding,
                                     width: self.bounds.size.width - (padding * 2),
                                     height: self.bounds.size.height - (padding * 2))
        let imageView = UIImageView(frame: imageViewBounds)
        imageView.contentMode = .scaleAspectFit
        self.contentView.addSubview(imageView)
        self.imageView = imageView
        
        // force update
        self.isSelected = self.isSelected ? true : false
    }
    
}
