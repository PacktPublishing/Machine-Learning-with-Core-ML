//
//  VideoCapture.swift
//  LanguageTutor
//
//  Created by Joshua Newnham on 29/11/2017.
//  Copyright © 2017 Josh Newnham. All rights reserved.
//

import UIKit
import AVFoundation

public protocol VideoCaptureDelegate: class {
    func onFrameCaptured(videoCapture: VideoCapture, pixelBuffer:CVPixelBuffer?, timestamp:CMTime)
}

/**
 Class used to faciliate accessing each frame of the camera using the AVFoundation framework (and presenting
 the frames on a preview view)
 https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutput
 */
public class VideoCapture : NSObject{
    
    public weak var delegate: VideoCaptureDelegate?
    
    /**
     Frames Per Second; used to throttle capture rate
    */
    public var fps = 15
    
    /**
     An object that manages capture activity and coordinates the flow of data from input devices to capture outputs.
     We will be using it to perform real-time cpature; for this we will need to add the appropriate output (AVCaptureVideoDataOutput)
    */
    let captureSession = AVCaptureSession()
    
    let sessionQueue = DispatchQueue(label: "session queue")
    
    var lastTimestamp = CMTime()
    
    override init() {
        super.init()
        
    }
    
    func initCamera() -> Bool{
        // Indicate we're wanting to make configuration changes
        captureSession.beginConfiguration()
        
        // Set the quality level of the output
        captureSession.sessionPreset = AVCaptureSession.Preset.medium
        
        // Obtain access to the physical capture device and associated properties via the AVCaptureDevice
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            print("ERROR: no video devices available")
            return false
        }
        
        // Try and create a AVCaptureDeviceInput (sub-class of AVCaptureInput) to capture data from the camera (captureDevice)
        guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("ERROR: could not create AVCaptureDeviceInput")
            return false
        }
        
        // add the videoInput feed to the session
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        /*
         A capture output that records video and provides access to video frames for processing.
         This will provide us with uncompressed frames, passed via the delegate method captureOutput(_:didOutput:from:).
         */
        let videoOutput = AVCaptureVideoDataOutput()
        
        // Set pixel type (32bit RGBA, Grayscale etc)
        let settings: [String : Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        videoOutput.videoSettings = settings
        
        // Discard any frames that arrive if the dispatch queue is currently handling an existing one
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        // Set the deleagte to handle the arrival of new frames (along with the queue)
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
        // Add the output stream (if we can)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // We want the buffers to be in portrait orientation otherwise they are rotated by
        // 90 degrees (set this after addOutput:) has been called
        videoOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait
        
        // Commit configuration changes
        captureSession.commitConfiguration()
        
        return true
    }
    
    /**
     Start capturing frames
     This is a blocking call which can take some time, therefore you should perform session setup off
     the main queue to avoid blocking it.
    */
    public func asyncStartCapturing(completion: (() -> Void)? = nil){
        sessionQueue.async {
            if !self.captureSession.isRunning{
                // Invoke the startRunning of the captureSession to start the flow of data from the inputs to the outputs.
                // NB: The startRunning() method is the blocking call which can take some time, which is why it's run off the main queue
                self.captureSession.startRunning()
            }
            
            if let completion = completion{
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    /**
     Stop capturing frames
    */
    public func asyncStopCapturing(completion: (() -> Void)? = nil){
        sessionQueue.async {
            if self.captureSession.isRunning{
                self.captureSession.stopRunning()
            }
            
            if let completion = completion{
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension VideoCapture : AVCaptureVideoDataOutputSampleBufferDelegate{
    
    /**
     Called when a new video frame was written
    */
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let delegate = self.delegate else{ return }

        // Returns the earliest presentation timestamp of all the samples in a CMSampleBuffer
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        // Throttle capture rate based on assigned fps
        let elapsedTime = timestamp - lastTimestamp
        if elapsedTime >= CMTimeMake(1, Int32(fps)) {
            // update timestamp
            lastTimestamp = timestamp
            // get sample buffer's CVImageBuffer
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            // pass onto the assigned delegate
            delegate.onFrameCaptured(videoCapture: self,
                                     pixelBuffer:imageBuffer,
                                     timestamp: timestamp)
        }
    }
    
    /**
     Called when a frame is dropped
     */
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Ignore
    }
}
