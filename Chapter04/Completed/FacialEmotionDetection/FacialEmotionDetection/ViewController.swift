//
//  ViewController.swift
//  FacialEmotionDetection
//
//  Created by Joshua Newnham on 26/02/2018.
//  Copyright © 2018 PacktPub. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class ViewController: UIViewController {
    
    /**
     Reference to our views CapturePreviewView (Camera stream)
     */
    @IBOutlet weak var previewView: CapturePreviewView!
    
    /**
     Reference to our view responsible for displaying the current users emotion
     */
    @IBOutlet weak var viewVisualizer: EmotionVisualizerView!
    
    /*
     Label notifying the user no face was detected (prompting them to face the camera towards their, or someone elses, face.
     */
    @IBOutlet weak var statusLabel: UILabel!
    
    /**
     Utility class that encapsulates setting up and tearing down the video capture; we'll start recording
     and assign the ViewController as a delegate to receive captured images from the video stream.
     */
    let videoCapture : VideoCapture = VideoCapture()
    
    /**
     Utility class encapsulating methods for data pre-processing
     */
    let imageProcessor : ImageProcessor = ImageProcessor()

    let model = ExpressionRecognitionModelRaw()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoCapture.delegate = self
        
        videoCapture.asyncInit { (success) in
            if success{
                // Assign the capture session instance being previewed
                (self.previewView.layer as! AVCaptureVideoPreviewLayer).session = self.videoCapture.captureSession
                // You use the videoGravity property to influence how content is viewed relative to the layer bounds;
                // in this case setting it to full the screen while respecting the aspect ratio.
                (self.previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravity.resizeAspectFill
                
                self.videoCapture.startCapturing()
            } else{
                fatalError("Failed to init VideoCapture")
            }
        }
        
        imageProcessor.delegate = self
    }
}

// MARK: - VideoCaptureDelegate

extension ViewController : VideoCaptureDelegate{
    
    func onFrameCaptured(
        videoCapture: VideoCapture,
        pixelBuffer:CVPixelBuffer?,
        timestamp:CMTime){
        // Unwrap the parameter pixxelBuffer; exit early if nil
        guard let pixelBuffer = pixelBuffer else{
            print("WARNING: onFrameCaptured; null pixelBuffer")
            return
        }
        
        // extract faces
        self.imageProcessor.getFaces(
            pixelBuffer: pixelBuffer)
    }
}

// MARK: - ImageProcessorDelegate

extension ViewController : ImageProcessorDelegate{
    
    func onImageProcessorCompleted(
        status: Int,
        faces:[MLMultiArray]?){
        guard let faces = faces else{ return }
        
        self.statusLabel.isHidden = faces.count > 0
        
        guard faces.count > 0 else{
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            for faceData in faces{
                
                let prediction = try? self.model
                    .prediction(image: faceData)
                
                if let classPredictions =
                    prediction?.classLabelProbs{
                    DispatchQueue.main.sync {
                        self.viewVisualizer.update(
                            labelConference: classPredictions
                        )
                    }
                }
            }
        }
    }
}

