//
//  ImageProcessor.swift
//  StyleTransfer
//
//  Created by Joshua Newnham on 19/04/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import Foundation
import Vision

protocol ImageProcessorDelegate : class{
    func onImageProcessorCompleted(status: Int, stylizedImage:CGImage?)
}

class ImageProcessor{
    
    enum ImageStyle : Int{
        case None = 0,
        AndyWarhol,
        Hokusai,
        Picasso,
        VanCogh
    }
    
    weak var delegate : ImageProcessorDelegate?
    
    var style : ImageStyle = ImageStyle.None
    
    init(){
        
    }
    
    public func processImage(pixelBuffer:CVPixelBuffer){
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        processImage(ciImage: ciImage)
    }
    
    public func processImage(ciImage:CIImage){
        DispatchQueue.global(qos: .background).async {
            // TODO 
        }
    }
    
    func processRequest(for request:VNRequest, error: Error?){
        guard let results = request.results else {
            print("ImageProcess", #function, "ERROR:", String(describing: error?.localizedDescription))
            self.delegate?.onImageProcessorCompleted(status: -1, stylizedImage: nil)
            return
        }
        
        let stylizedPixelBufferObservations = results as! [VNPixelBufferObservation]
        
        guard stylizedPixelBufferObservations.count > 0 else {
            print("ImageProcess", #function, "ERROR:", "No Results")
            self.delegate?.onImageProcessorCompleted(status: -1, stylizedImage: nil)
            return
        }
        
        guard let cgImage = stylizedPixelBufferObservations[0].pixelBuffer.toCGImage() else{
            print("ImageProcess", #function, "ERROR:", "Failed to convert CVPixelBuffer to CGImage")
            self.delegate?.onImageProcessorCompleted(status: -1, stylizedImage: nil)
            return
        }
        
        DispatchQueue.main.async {
            self.delegate?.onImageProcessorCompleted(status: 1, stylizedImage:cgImage)
        }        
    }
}
