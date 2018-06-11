//
//  StyleViewCell.swift
//  StyleTransfer
//
//  Created by Joshua Newnham on 23/04/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit

class StyleViewCell : UICollectionViewCell{
    
    weak var imageView : UIImageView?
    
    var imageStyle = ImageProcessor.ImageStyle.None 
    
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

extension StyleViewCell{
    
    func initUI(){
        self.backgroundColor = UIColor.clear
        
        let imageView = UIImageView(frame: self.bounds)
        imageView.contentMode = .scaleAspectFill
        self.contentView.addSubview(imageView)
        self.imageView = imageView
        
        // force update 
        self.isSelected = self.isSelected ? true : false
    }
    
}
