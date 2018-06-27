//
//  ViewController.swift
//  StyleTransfer
//
//  Created by Joshua Newnham on 19/04/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class CameraViewController: UIViewController {

    /**
     Reference to our views CapturePreviewView (Camera stream)
     */
    weak var previewView: CapturePreviewView?        
   
    /**
     Utility class that encapsulates setting up and tearing down the video capture; we'll start recording
     and assign the ViewController as a delegate to receive captured images from the video stream.
     */
    let videoCapture : VideoCapture = VideoCapture()
    
    /**
     If the camera is not support (simulator) then use the image picker as
     a substitute.
    */
    let imagePicker = UIImagePickerController()
    
    /**
     Set when the 'Action Button' is tapped; when true the next frame
     will be passed to the StyleTransferViewController
    */
    var requestedCapture : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        
        videoCapture.delegate = self
        
        startCamera()
    }
    
    func startCamera(){
        videoCapture.asyncInit { (success) in
            if success{
                // Assign the capture session instance being previewed
                (self.previewView?.layer as! AVCaptureVideoPreviewLayer).session = self.videoCapture.captureSession
                // You use the videoGravity property to influence how content is viewed relative to the layer bounds;
                // in this case setting it to full the screen while respecting the aspect ratio.
                (self.previewView?.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravity.resizeAspectFill
                
                self.videoCapture.startCapturing()
            } else{
                print("Failed to init VideoCapture")
            }
        }
    }
    
    func stopCamera(){
        videoCapture.stopCapturing()
    }
}

// MARK: - VideoCaptureDelegate

extension CameraViewController : VideoCaptureDelegate{
    
    func onFrameCaptured(
        videoCapture: VideoCapture,
        pixelBuffer:CVPixelBuffer?,
        timestamp:CMTime){
        // Unwrap the parameter pixxelBuffer; exit early if nil
        guard let pixelBuffer = pixelBuffer else{
            print("WARNING: onFrameCaptured; null pixelBuffer")
            return
        }
        
        if requestedCapture{
            requestedCapture = false
            stopCamera()
            showStyleTransferView(image: CIImage(cvPixelBuffer: pixelBuffer))
        }
    }
}

// MARK: UIImagePickerControllerDelegate

extension CameraViewController : UIImagePickerControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]){
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else{
            return
        }
        self.dismiss(animated: true, completion: { () -> Void in
            if let cgImage = image.cgImage{
                let ciImage = CIImage(cgImage: cgImage)
                self.showStyleTransferView(image: ciImage)
            }
        })
    }
    
    func imagePickerControllerDidCancel(_: UIImagePickerController){
        dismiss(animated: true, completion: nil)
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, pickedImage: UIImage?) {
    }
}

//  MARK: - UI

extension CameraViewController{
    
    func initUI() {
        // Create preview view (where our camera frames will be rendered to)
        let previewView = CapturePreviewView(frame: self.view.bounds)
        self.view.addSubview(previewView)        
        
        previewView.topAnchor.constraint(equalTo: self.view.topAnchor,
                                              constant: 0).isActive = true
        previewView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,
                                              constant: 0).isActive = true
        previewView.leftAnchor.constraint(equalTo: self.view.leftAnchor,
                                                 constant: 0).isActive = true
        previewView.rightAnchor.constraint(equalTo: self.view.rightAnchor,
                                               constant: 0).isActive = true
        self.previewView = previewView
        
        // Create action button (used for taken the photo)
        let actionButtonSize = CGSize(width: self.view.bounds.width * 0.2,
                                      height: self.view.bounds.width * 0.2)
        let actionButton = UIButton(frame:
            CGRect(x: self.view.frame.width/2 - actionButtonSize.width/2,
                   y: self.view.frame.height - (actionButtonSize.height + actionButtonSize.height * 0.3) ,
                   width: actionButtonSize.width,
                   height: actionButtonSize.height))
        self.view.addSubview(actionButton)
        actionButton.setImage(UIImage(named: "action_button"), for: .normal)
        actionButton.addTarget(self,
                               action: #selector(CameraViewController.onActionButtonTapped(_:)),
                               for: .touchUpInside)
        
        // Create flip camera button
        let flipButtonImage = UIImage(named: "camera_flip_button")
        let flipButtonSize = CGSize(width: self.view.bounds.width * 0.075,
                                    height: self.view.bounds.width * 0.075 * (flipButtonImage!.size.height / flipButtonImage!.size.width))
        let flipButton = UIButton(frame:
            CGRect(x: self.view.bounds.width - (flipButtonSize.width * 2.0),
                   y: UIApplication.shared.statusBarFrame.height + (flipButtonSize.width * 0.5),
                   width: flipButtonSize.width,
                   height: flipButtonSize.height))
        self.view.addSubview(flipButton)
        flipButton.setImage(flipButtonImage, for: .normal)
        flipButton.addTarget(self,
                             action: #selector(CameraViewController.onFlipCameraButtonTapped(_:)), for: .touchUpInside)                
    }
    
    @objc func onActionButtonTapped(_ sender:UIButton){
        if self.videoCapture.isCapturing{
            requestedCapture = true
        } else{
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
                
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary;
                imagePicker.allowsEditing = false
                
                self.present(imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    @objc func onFlipCameraButtonTapped(_ sender:UIButton){
        stopCamera()
        
        videoCapture.cameraPostion =
            videoCapture.cameraPostion == AVCaptureDevice.Position.front ?
                AVCaptureDevice.Position.back : AVCaptureDevice.Position.front
        
        startCamera()
    }
    
    func showStyleTransferView(image:CIImage){
        let styleTransferCV = StyleTransferViewController()
        
        styleTransferCV.delegate = self
        styleTransferCV.modalPresentationStyle = .overCurrentContext
        
        present(styleTransferCV, animated: false) {
            styleTransferCV.contentImage = image
        }
    }
}

// MARK: - StyleTransferViewControllerDelegate

extension CameraViewController : UINavigationControllerDelegate, StyleTransferViewControllerDelegate{
    
    func onStyleTransferViewDismissed(sender:StyleTransferViewController){
        self.startCamera()
    }
    
}
