//
//  ViewController.swift
//  LanguageTutor
//
//  Created by Joshua Newnham on 28/11/2017.
//  Copyright © 2017 Josh Newnham. All rights reserved.
//

import UIKit
import CoreVideo
import AVFoundation
import Vision

class ViewController: UIViewController {

    @IBOutlet var previewView:CapturePreviewView!
    @IBOutlet var classifiedLabel:UILabel!
    
    /**
     Utility class that encapsulates setting up and tearing down the video capture; we'll start recording
     and assign the ViewController as a delegate to receive captured images from the video stream.
    */
    let videoCapture : VideoCapture = VideoCapture()
    
    /**
     An image analysis request that uses a Core ML model to process images; the processing is determined by the associated MLModel.
    */
    var request: VNCoreMLRequest!
    
    let model = Inceptionv3()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        videoCapture.delegate = self 
        
        videoCapture.asyncInit { (success) in
            if success{
                // Assign the capture session instance being previewed
                (self.previewView.layer as! AVCaptureVideoPreviewLayer).session = self.videoCapture.captureSession
                // You use the videoGravity property to influence how content is viewed relative to the layer bounds;
                // in this case setting it to full the screen while respecting the aspect ratio.
                (self.previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravity.resizeAspectFill
                
                if self.initVision(){
                    self.videoCapture.startCapturing()
                } else{
                    fatalError("Unable to init Vision")
                }
            } else{
                fatalError("Failed to init VideoCapture")
            }
        }
    }
    
    /**
     Initilise the MLModel's Vision Reuqest; return true is successful otherwise false.
    */
    private func initVision() -> Bool{
        // Try and create a container for our CoreML model which will be used with Vision requests
        guard let visionModel = try? VNCoreMLModel(for:model.model) else{ return false }
        
        // Create the CoreML request
        request = VNCoreMLRequest(model: visionModel, completionHandler:onVisionRequestComplete)
        request.imageCropAndScaleOption = .centerCrop
        
        return true
    }
}

// MARK: - VideoCaptureDelegate

extension ViewController : VideoCaptureDelegate{
    
    func onFrameCaptured(videoCapture: VideoCapture, pixelBuffer:CVPixelBuffer?, timestamp:CMTime){
        // Unwrap the parameter pixxelBuffer; exit early if nil
        guard let pixelBuffer = pixelBuffer else{ return }
        
        // Create the Handler which will be responsible for the processing of this image.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
}

// MARK: - VisionRequest callback

extension ViewController{
    
    func onVisionRequestComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNClassificationObservation]{
            // The observations appear to be sorted by confidence already, so we
            // take the top 5 and map them to an array of (String, Double) tuples.
            let label = observations[0].identifier // associated label
            let confidence = observations[0].confidence // confidence (in the range of 0.0-1.0)
            
            // Update label
            DispatchQueue.main.sync {
                classifiedLabel.text = confidence >= 0.5 ? label : "Unknown"
            }
        }
    }
}

