//
//  EffectViewController.swift
//  ActionShot
//
//  Created by Joshua Newnham on 31/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit
import Vision
import AVFoundation
import CoreImage

protocol EffectsViewControllerDelegate : class{
    func onEffectsViewDismissed(sender:EffectsViewController)
}

class EffectsViewController: UIViewController {
    
    /**
     Presents the image (stylized image if a style has been applied)
     */
    weak var imageView : UIImageView?
    
    weak var activityIndicatorView : UIActivityIndicatorView?
    
    weak var delegate : EffectsViewControllerDelegate?
    
    var imageProcessor : ImageProcessor!
    
    var isProgressingImage : Bool{
        get{
            guard let activityIndicatorView = self.activityIndicatorView else{
                return false
            }
            
            return !activityIndicatorView.isAnimating
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initUI()
        
        self.imageProcessor.delegate = self
        
        self.showEffectAndActivityIndicator()
        
        self.imageProcessor.processFrames()
    }
    
    /** Look busy **/
    private func showEffectAndActivityIndicator(){
        // create and add a blur effect
        let effect = UIBlurEffect(style: .regular)
        let visualEffectsView = UIVisualEffectView(effect: effect)
        visualEffectsView.tag = 99
        visualEffectsView.frame = self.view.bounds
        visualEffectsView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(visualEffectsView)
        
        // Start animating the activity indicator
        if let activityIndicatorView = self.activityIndicatorView{
            self.view.bringSubview(toFront: activityIndicatorView)
            activityIndicatorView.startAnimating()
        }
    }
}

// MARK: - ImageProcessorDelegate

extension EffectsViewController : ImageProcessorDelegate{
    
    /* Called when a frame has finished being processed */
    func onImageProcessorFinishedProcessingFrame(
        status:Int,
        processedFrames:Int,
        framesRemaining:Int){
        
        print("\(#function) \(processedFrames) \(framesRemaining)")
        
        if framesRemaining == 0 && !self.imageProcessor.isProcessingImage{
            self.imageProcessor.compositeFrames()
        }
    }
    
    /* Called when composition is complete */
    func onImageProcessorFinishedComposition(status:Int, image:CIImage?){
        // Stop animating activity indiactor
        self.activityIndicatorView?.stopAnimating()
        
        // Remove blur
        guard let effectView = self.view.viewWithTag(99) else { return }
        effectView.removeFromSuperview()
        
        // Update image
        if let image = image{
            self.imageView?.image = UIImage(ciImage: image)
        } else{
            self.imageView?.image = nil
        }
    }
}

// MARK: - UI

extension EffectsViewController{
    
    func initUI(){
        self.view.backgroundColor = UIColor.white
        
        let imageView = UIImageView(frame: CGRect(
            origin: self.view.bounds.origin,
            size: CGSize(width: self.view.bounds.width,
                         height: self.view.bounds.height)))
        self.view.addSubview(imageView)
        
        imageView.topAnchor.constraint(equalTo: self.view.topAnchor,
                                       constant: 0).isActive = true
        imageView.leftAnchor.constraint(equalTo: self.view.leftAnchor,
                                        constant: 0).isActive = true
        imageView.rightAnchor.constraint(equalTo: self.view.rightAnchor,
                                         constant: 0).isActive = true
        
        imageView.contentMode = .scaleAspectFit
        self.imageView = imageView
        
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
                              action: #selector(EffectsViewController.onCloseButtonTapped(_:)), for: .touchUpInside)
        
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicatorView.center = self.view.center
        activityIndicatorView.hidesWhenStopped = true
        view.addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView
    }
    
    @objc func onCloseButtonTapped(_ sender:UIButton){
        self.dismiss(animated: false) {
            self.delegate?.onEffectsViewDismissed(sender: self)
        }
    }
}
