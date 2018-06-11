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
        
    lazy var vanCoghModel : VNCoreMLModel = {
        do{
            let model = try VNCoreMLModel(
                for: FastStyleTransferVanGoghStarryNight().model)
            return model
        } catch{
            fatalError("Failed to obtain VanCoghModel")
        }
    }()
    
    var model : VNCoreMLModel{
        get{
            if self.style == .VanCogh{
                return self.vanCoghModel
            }
            
            // default
            return self.vanCoghModel
        }
    }
    
    func getRequest() -> VNCoreMLRequest{
        let request = VNCoreMLRequest(model: self.model, completionHandler: { [weak self] request, error in
            self?.processRequest(for: request, error: error)
        })
        request.imageCropAndScaleOption = .centerCrop
        return request
    }
    
    init(){
        
    }
    
    public func processImage(pixelBuffer:CVPixelBuffer){
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        processImage(ciImage: ciImage)
    }
    
    public func processImage(ciImage:CIImage){
        DispatchQueue.global(qos: .background).async {
            let handler = VNImageRequestHandler(ciImage: ciImage)
            
            do {
                try handler.perform([self.getRequest()])
            } catch {
                /*
                 This handler catches general image processing errors. The `classificationRequest`'s
                 completion handler `processClassifications(_:error:)` catches errors specific
                 to processing that request.
                 */
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    func processRequest(for request:VNRequest, error: Error?){
        guard let results = request.results else {
            print("ImageProcess", #function, "ERROR:",
                  String(describing: error?.localizedDescription))
            self.delegate?.onImageProcessorCompleted(
                status: -1,
                stylizedImage: nil)
            return
        }
        
        let stylizedPixelBufferObservations = results as! [VNPixelBufferObservation]
        
        guard stylizedPixelBufferObservations.count > 0 else {
            print("ImageProcess", #function,"ERROR:", "No Results")
            self.delegate?.onImageProcessorCompleted(
                status: -1,
                stylizedImage: nil)
            return
        }
        
        guard let cgImage = stylizedPixelBufferObservations[0].pixelBuffer.toCGImage() else{
            print("ImageProcess", #function, "ERROR:", "Failed to convert CVPixelBuffer to CGImage")
            self.delegate?.onImageProcessorCompleted(
                status: -1,
                stylizedImage: nil)
            return
        }
        
        DispatchQueue.main.sync {
            self.delegate?.onImageProcessorCompleted(
                status: 1,
                stylizedImage:cgImage)
        }        
    }
}
