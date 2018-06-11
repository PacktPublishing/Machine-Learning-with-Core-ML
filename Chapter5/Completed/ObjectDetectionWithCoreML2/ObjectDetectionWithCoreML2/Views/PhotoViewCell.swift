//
//  PhotoViewCell.swift
//  ObjectDetection
//
//  Created by Joshua Newnham on 14/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit

class PhotoViewCell : UICollectionViewCell{
    
    var searchResult : SearchResult?{
        didSet{
            guard let result = self.searchResult else {
                imageView.image = nil 
                return
            }
            
            imageView.image = result.image
        }
    }
    
    var imageView : UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView(frame: self.bounds)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds=true
        
        self.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = self.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
