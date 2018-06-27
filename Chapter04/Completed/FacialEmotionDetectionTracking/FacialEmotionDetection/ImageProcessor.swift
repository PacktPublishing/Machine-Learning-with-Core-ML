//
//  ImageProcessor.swift
//  FacialEmotionDetection
//
//  Created by Joshua Newnham on 03/03/2018.
//  Copyright © 2018 PacktPub. All rights reserved.
//

import UIKit
import Vision

protocol ImageProcessorDelegate : class{
    func onImageProcessorCompleted(status: Int, faces:[MLMultiArray]?)
}

class ImageProcessor{
    
    weak var delegate : ImageProcessorDelegate?
    
    /*
     VNDetectFaceRectanglesRequest:
     https://developer.apple.com/documentation/vision/VNDetectFaceRectanglesRequest
     An image analysis request that finds faces within an image.
     */
    let faceDetection = VNDetectFaceRectanglesRequest()

    /*
     VNSequenceRequestHandler:
     https://developer.apple.com/documentation/vision/VNSequenceRequestHandler
     An object that processes image analysis requests pertaining to a
     sequence of multiple images.
     */
    let faceDetectionRequest = VNSequenceRequestHandler()
    
    init(){
        
    }
    
    public func getFaces(pixelBuffer:CVPixelBuffer){
        DispatchQueue.global(qos: .background).sync {
            
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let width = ciImage.extent.width
            let height = ciImage.extent.height

            // Perform face detection
            try? self.faceDetectionRequest.perform(
                [self.faceDetection],
                on: ciImage)

            var facesData = [MLMultiArray]()
            
            /*
             VNFaceObservation:
             https://developer.apple.com/documentation/vision/vnfaceobservation
             Face or facial-feature information detected by an image analysis request.
             */
            if let faceDetectionResults = self.faceDetection.results as? [VNFaceObservation]{
                for face in faceDetectionResults{
                    let bbox = face.boundingBox

                    let imageSize = CGSize(width:width,
                                           height:height)

                    /*
                     The face's bounding box is normalised in respect to the
                     size of the image i.e. is in a range of 0.0 - 1.0 where
                     this is a ratio of the overall image size e.g. width = 0.5 would
                     be half of the width of the source image.
                     */
                    let w = bbox.width * imageSize.width
                    let h = bbox.height * imageSize.height
                    let x = bbox.origin.x * imageSize.width
                    let y = bbox.origin.y * imageSize.height

                    /*
                     Along with inverting the face bounds we want to pad it out
                     (to include the top of the head and some surplus padding around
                     the face/head).
                     */
                    let paddingTop = h * 0.2
                    let paddingBottom = h * 0.55
                    let paddingWidth = w * 0.15

                    let faceRect = CGRect(x: max(x - paddingWidth, 0),
                                          y: max(0, y - paddingTop),
                                          width: min(w + (paddingWidth * 2), imageSize.width),
                                          height: min(h + paddingBottom, imageSize.height))
                    
                    // 1. Crop, 2. Resize, 3. Obtain and rescaled pixel data
                    if let pixelData = ciImage.crop(rect: faceRect)?
                        .resize(size: CGSize(width:48, height:48))
                        .getGrayscalePixelData()?.map({ (pixel) -> Double in
                            return Double(pixel)/255.0 // rescale
                        }){
                        // Create a MLMultiArray (for our model) and copy across the pixel data
                        if let array = try? MLMultiArray(shape: [1, 48, 48], dataType: .double) {
                            for (index, element) in pixelData.enumerated() {
                                array[index] = NSNumber(value: element)
                            }
                            facesData.append(array)
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.delegate?.onImageProcessorCompleted(status: 1, faces: facesData)
                }
            } else{
                DispatchQueue.main.async {
                    print("Found no faces")
                    self.delegate?.onImageProcessorCompleted(status: -1, faces: nil)
                }
            }
        }
    }
}
