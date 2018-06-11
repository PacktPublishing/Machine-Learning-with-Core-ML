//
//  StyleTransferViewController.swift
//  StyleTransfer
//
//  Created by Joshua Newnham on 22/04/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit
import Vision
import AVFoundation
import CoreImage

protocol StyleTransferViewControllerDelegate : class{
    func onStyleTransferViewDismissed(sender:StyleTransferViewController)
}

class StyleTransferViewController: UIViewController {
    
    /**
     Presents the image (stylized image if a style has been applied)
    */
    weak var imageView : UIImageView?
    
    weak var activityIndicatorView : UIActivityIndicatorView?
    
    weak var delegate : StyleTransferViewControllerDelegate?
    
    var styleImages  = [UIImage]()
    
    var styleImageButtonSize : CGSize?
    
    /**
     Content image that we will use as the input for our model
    */
    var contentImage : CIImage?{
        didSet{
            if let imageView = self.imageView,
                let contentImage = self.contentImage{
                imageView.image = contentImage.toUIImage()
            }
        }
    }
    
    var isProgressingImage : Bool{
        get{
            guard let activityIndicatorView = self.activityIndicatorView else{
                return false
            }
            
            return !activityIndicatorView.isAnimating
        }
    }
    
    /**
     Utility class encapsulating methods for data pre-processing
     */
    let imageProcessor : ImageProcessor = ImageProcessor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initUI()
        
        imageProcessor.delegate = self
    }
    
    private func stylizeContentImage(){
        guard let contentImage = self.contentImage else{
            return
        }
        
        // create and add a blur effect
        let effect = UIBlurEffect(style: .regular)
        let visualEffectsView = UIVisualEffectView(effect: effect)
        visualEffectsView.tag = 99
        visualEffectsView.frame = self.view.bounds
        visualEffectsView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(visualEffectsView)
        
        if let activityIndicatorView = self.activityIndicatorView{
            self.view.bringSubview(toFront: activityIndicatorView)
            activityIndicatorView.startAnimating()
        }
        
        self.imageProcessor.processImage(ciImage: contentImage)
    }
}

// MARK: - ImageProcessorDelegate

extension StyleTransferViewController : ImageProcessorDelegate{
    
    func onImageProcessorCompleted(status: Int, stylizedImage:CGImage?){
        guard status > 0, let stylizedImage = stylizedImage else{
            return
        }
        
        // Stop animating activity indiactor
        self.activityIndicatorView?.stopAnimating()
        
        // Remove blur
        guard let effectView = self.view.viewWithTag(99) else { return }
        effectView.removeFromSuperview()
        
        // Update image
        self.imageView?.image = UIImage(cgImage: stylizedImage)
    }
}

// MARK: - UI

extension StyleTransferViewController{
    
    func initUI(){
        self.view.backgroundColor = UIColor.white
        
        // load style images
        let imagesNames = [
            "van_cogh", "van_cogh_selected",
            "hokusai", "hokusai_selected",
            "andy_warhol", "andy_warhol_selected",
            "picasso", "picasso_selected"]
        
        for i in stride(from: 0, to: imagesNames.count, by: 2){
            let imageSrc = imagesNames[i]
            let imageSelectedSrc = imagesNames[i+1]
            
            guard let image = UIImage(named: imageSrc),
                let imageSelected = UIImage(named: imageSelectedSrc) else{
                    fatalError("\(imageSrc) or \(imageSelectedSrc) not available")
            }
            
            self.styleImages.append(image)
            self.styleImages.append(imageSelected)
            
            if styleImageButtonSize == nil{
                styleImageButtonSize = CGSize(width: self.view.bounds.width * 0.3,
                                         height: self.view.bounds.width * 0.3 * (image.size.height/image.size.width))
            }
        }
        
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionViewLayout.itemSize = CGSize(width: styleImageButtonSize!.width,
                                               height: styleImageButtonSize!.height)
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: CGRect(x: 0,
                                                            y: self.view.bounds.height-styleImageButtonSize!.height,
                                                            width: self.view.bounds.width,
                                                            height: styleImageButtonSize!.height),
                                              collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(StyleViewCell.self, forCellWithReuseIdentifier: "StyleViewCell")
        self.view.addSubview(collectionView)
        collectionView.reloadData()
        
        let imageView = UIImageView(frame: CGRect(
            origin: self.view.bounds.origin,
            size: CGSize(width: self.view.bounds.width,
                         height: self.view.bounds.height - (styleImageButtonSize!.height))))
        self.view.addSubview(imageView)
        
        imageView.topAnchor.constraint(equalTo: self.view.topAnchor,
                                         constant: 0).isActive = true
        imageView.leftAnchor.constraint(equalTo: self.view.leftAnchor,
                                          constant: 0).isActive = true
        imageView.rightAnchor.constraint(equalTo: self.view.rightAnchor,
                                           constant: 0).isActive = true
        
        self.imageView = imageView
        self.imageView?.contentMode = .scaleAspectFill
        
        // Close button
        let closeButtonImage = UIImage(named: "close_button")
        let closeButtonSize = CGSize(width: self.view.bounds.width * 0.05,
                                    height: self.view.bounds.width * 0.05 * (closeButtonImage!.size.height / closeButtonImage!.size.width))
        let closeButton = UIButton(frame:
            CGRect(x: closeButtonSize.width,
                   y: UIApplication.shared.statusBarFrame.height + (closeButtonSize.width * 0.5),
                   width: closeButtonSize.width,
                   height: closeButtonSize.height))
        self.view.addSubview(closeButton)
        closeButton.setImage(closeButtonImage, for: .normal)
        closeButton.addTarget(self,
                             action: #selector(StyleTransferViewController.onCloseButtonTapped(_:)), for: .touchUpInside)
        
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicatorView.center = self.view.center
        activityIndicatorView.hidesWhenStopped = true
        view.addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView
        
        if let contentImage = self.contentImage{
            imageView.image = UIImage(ciImage:contentImage) 
        }
    }
    
    @objc func onCloseButtonTapped(_ sender:UIButton){
        self.dismiss(animated: false) {
            self.delegate?.onStyleTransferViewDismissed(sender: self)
        }
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate

extension StyleTransferViewController : UICollectionViewDataSource, UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.styleImages.count / 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StyleViewCell", for: indexPath) as! StyleViewCell
        let imageIndex = indexPath.row * 2
        cell.image = styleImages[imageIndex]
        cell.selectedImage = styleImages[imageIndex+1]
        cell.imageStyle = ImageProcessor.ImageStyle(rawValue: indexPath.row+1)!
        cell.isSelected = imageProcessor.style == cell.imageStyle
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool{
        let cell = collectionView.cellForItem(at: indexPath) as! StyleViewCell
        return !cell.isSelected
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        imageProcessor.style = (collectionView.cellForItem(at: indexPath) as! StyleViewCell).imageStyle
        self.stylizeContentImage()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath){
        // Restore image to it's original state
        imageProcessor.style = .None
        imageView?.image = UIImage(ciImage: contentImage!)
    }
}


