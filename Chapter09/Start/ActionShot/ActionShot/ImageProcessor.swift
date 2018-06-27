//
//  ImageProcessor.swift
//  ActionShot
//
//  Created by Joshua Newnham on 31/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit
import Vision
import CoreML
import CoreImage

protocol ImageProcessorDelegate : class{
    /* Called when a frame has finished being processed */
    func onImageProcessorFinishedProcessingFrame(
        status:Int, processedFrames:Int, framesRemaining:Int)
    /* Called when composition is complete */
    func onImageProcessorFinishedComposition(
        status:Int, image:CIImage?)
}

class ImageProcessor{
    
    weak var delegate : ImageProcessorDelegate?
    
    lazy var model : VNCoreMLModel = {
        do{
            let model = try VNCoreMLModel(
                for: small_unet().model
            )
            return model
        } catch{
            fatalError("Failed to create VNCoreMLModel")
        }
    }()
    
    /**
     Any segmentation that has an area less that this (relative to the frame size)
     is ignored
     **/
    var minMaskArea:CGFloat = 0.005
    /* Size our model is expected */
    var targetSize = CGSize(width: 448, height: 448)
    /* Making accessing data thread safe */
    let lock = NSLock()
    /* Holds the original frames */
    var frames = [CIImage]()
    /* Processed frames i.e. resize and crop */
    var processedImages = [CIImage]()
    /* Processed frames i.e. segmentations */
    var processedMasks = [CIImage]()
    /* Are we currently processing */
    private var _processingImage = false
    
    init(){
        
    }
}

// MARK: - Frame sink

extension ImageProcessor{
    
    /* Thread safe accessor for _processingImage */
    var isProcessingImage : Bool{
        get{
            self.lock.lock()
            defer {
                self.lock.unlock()
            }
            return _processingImage
        }
        set(value){
            self.lock.lock()
            _processingImage = value
            self.lock.unlock()
        }
    }
    /* Thread safe bool that returns true if another frame is available to be processed */
    var isFrameAvailable : Bool{
        get{
            self.lock.lock()
            let frameAvailable =
                    self.frames.count > 0
            self.lock.unlock()
            return frameAvailable
        }
    }
    
    public func addFrame(frame:CIImage){
        self.lock.lock()
        self.frames.append(frame)
        self.lock.unlock()
    }
    
    public func getNextFrame() -> CIImage?{
        self.lock.lock()
        let frame = self.frames.removeFirst()
        self.lock.unlock()
        return frame
    }
    
    public func reset(){
        self.lock.lock()
        self.frames.removeAll()
        self.processedImages.removeAll()
        self.processedMasks.removeAll()
        self.lock.unlock()
    }
}

// MARK: - Image processing / segmentation and masking

extension ImageProcessor{
    
    func getRequest() -> VNCoreMLRequest{
        let request = VNCoreMLRequest(
            model: self.model,
            completionHandler: { [weak self] request, error in
                self?.processRequest(for: request, error: error)
        })
        request.imageCropAndScaleOption = .centerCrop
        return request
    }
    
    public func processFrames(){
        if !self.isProcessingImage{
            DispatchQueue.global(qos: .background).async {
                self.processesingNextFrame()
            }
        }
    }
    
    func processesingNextFrame(){
        self.isProcessingImage = true
        
        guard let nextFrame = self.getNextFrame() else{
            self.isProcessingImage = false
            return
        }
        
        // Resize and crop; start by calculating the appropriate offsets
        var ox : CGFloat = 0
        var oy : CGFloat = 0
        let frameSize = min(nextFrame.extent.width, nextFrame.extent.height)
        if nextFrame.extent.width > nextFrame.extent.height{
            ox = (nextFrame.extent.width - nextFrame.extent.height)/2
        } else if nextFrame.extent.width < nextFrame.extent.height{
            oy = (nextFrame.extent.height - nextFrame.extent.width)/2
        }
        guard let frame = nextFrame
            .crop(rect: CGRect(x: ox,
                               y: oy,
                               width: frameSize,
                               height: frameSize))?
            .resize(size: targetSize) else{
                self.isProcessingImage = false
                return
        }
        
        self.processedImages.append(frame)
        let handler = VNImageRequestHandler(ciImage: frame)
        
        do {
            try handler.perform([self.getRequest()])
        } catch {
            print("Failed to perform classification.\n\(error.localizedDescription)")
            self.isProcessingImage = false
            return
        }
    }
    
    func processRequest(for request:VNRequest, error: Error?){
        self.lock.lock()
        let framesReaminingCount = self.frames.count
        let processedFramesCount = self.processedImages.count
        self.lock.unlock()
        
        // Check that we have results
        // ... AND they are of type VNPixelBufferObservation
        // ... AND we have results (count > 0)
        guard let results = request.results,
            let pixelBufferObservations = results as? [VNPixelBufferObservation],
            pixelBufferObservations.count > 0 else {
                print("ImageProcessor", #function, "ERROR:",
                      String(describing: error?.localizedDescription))
                
                self.isProcessingImage = false
                
                DispatchQueue.main.async {
                    self.delegate?.onImageProcessorFinishedProcessingFrame(
                        status: -1,
                        processedFrames: processedFramesCount,
                        framesRemaining: framesReaminingCount)
                }
                return
        }
        
        let options = [
            kCIImageColorSpace:CGColorSpaceCreateDeviceGray()
            ] as [String:Any]
        
        let ciImage = CIImage(
            cvPixelBuffer: pixelBufferObservations[0].pixelBuffer,
            options: options)
        
        self.processedMasks.append(ciImage)
        
        DispatchQueue.main.async {
            self.delegate?.onImageProcessorFinishedProcessingFrame(
                status: 1,
                processedFrames: processedFramesCount,
                framesRemaining: framesReaminingCount)
        }
        
        if self.isFrameAvailable{
            self.processesingNextFrame()
        } else{
            self.isProcessingImage = false
        }
    }
}

// MARK: - Composite image

extension ImageProcessor{
    
    func compositeFrames(){
        
        // Filter frames based on bounding box positioning
        var selectedIndicies = self.getIndiciesOfBestFrames()
        
        // If no indicies we returned then exist, passing the final
        // image as a fallback
        if selectedIndicies.count == 0{
            DispatchQueue.main.async {
                self.delegate?.onImageProcessorFinishedComposition(
                    status: -1,
                    image: self.processedImages.last!)
            }
            
            return
        }
        
        // Iterate through all indicies compositing the final image
        var finalImage = self.processedImages[selectedIndicies.last!]
        selectedIndicies.removeLast()
        
        // TODO Composite final image using segments from intermediate frames
        
        DispatchQueue.main.async {
            self.delegate?.onImageProcessorFinishedComposition(
                status: 1,
                image: finalImage)
        }
    }

    func getIndiciesOfBestFrames() -> [Int]{
        // TODO; find best frames for the sequence i.e. avoid excessive overlapping
        return (0..<self.processedMasks.count).map({ (i) -> Int in
            return i
        })
    }

    func getDominantDirection() -> CGPoint{
        var dir = CGPoint(x: 0, y: 0)
        
        // TODO detected dominant direction
        
        return dir
    }
}
