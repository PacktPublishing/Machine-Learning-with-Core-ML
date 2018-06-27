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

class ViewController: UIViewController {

    @IBOutlet var previewView:CapturePreviewView!
    @IBOutlet var classifiedLabel:UILabel!
    
    /**
     Utility class that encapsulates setting up and tearing down the video capture; we'll start recording
     and assign the ViewController as a delegate to receive captured images from the video stream.
     */
    let videoCapture : VideoCapture = VideoCapture()
    
    // Used for rendering image processing results and performing image analysis. Here we use
    // it for rendering out scaled and cropped captured frames in preparation for our model.
    let context = CIContext()
    
    let model = Inceptionv3()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.videoCapture.delegate = self
        
        if self.videoCapture.initCamera(){
            // Assign the capture session instance being previewed
            (self.previewView.layer as! AVCaptureVideoPreviewLayer).session = self.videoCapture.captureSession
            // You use the videoGravity property to influence how content is viewed relative to the layer bounds;
            // in this case setting it to full the screen while respecting the aspect ratio.
            (self.previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            self.videoCapture.asyncStartCapturing()
        } else{
            fatalError("Failed to init VideoCapture")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - VideoCaptureDelegate

extension ViewController : VideoCaptureDelegate{
    
    func onFrameCaptured(videoCapture: VideoCapture, pixelBuffer:CVPixelBuffer?, timestamp:CMTime){
        // Unwrap the parameter pixxelBuffer; exit early if nil
        guard let pixelBuffer = pixelBuffer else{ return }

        // Prepare our image for our model (resizing)
        guard let scaledPixelBuffer = CIImage(cvImageBuffer: pixelBuffer)
            .resize(size: CGSize(width: 299, height: 299))
            .toPixelBuffer(context: context) else{ return }

        // Try to make a prediction
        let prediction = try? self.model.prediction(image:scaledPixelBuffer)

        // Update label
        DispatchQueue.main.sync {
            classifiedLabel.text = prediction?.classLabel ?? "Unknown"
        }
    }
}

