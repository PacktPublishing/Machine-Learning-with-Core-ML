//
//  YOLOFacade.swift
//  ObjectDetection
//
//  Created by Joshua Newnham on 17/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit
import Photos
import CoreML
import Vision

class YOLOFacade{
    
    // TODO add input size (of image)
    
    // TODO add grid size
    
    // TODO add number of classes
    
    // TODO add number of anchor boxes
    
    // TODO add anchor shapes (describing aspect ratio)
    
    lazy var model : VNCoreMLModel? = {
        do{
            // TODO add model
            return nil
        } catch{
            fatalError("Failed to obtain tinyyolo_voc2007")
        }
    }()
    
    func asyncDetectObjects(photo:UIImage, completionHandler: @escaping (_ result:[ObjectBounds]?) -> Void){
        DispatchQueue.global(qos: .background).sync {
            
            self.detectObjects(photo: photo, completionHandler: { (result) -> Void in
                DispatchQueue.main.async {
                    completionHandler(result)
                }
            })
        }
    }
    
}

// MARK: - Core ML

extension YOLOFacade{
    
    func detectObjects(photo:UIImage, completionHandler:(_ result:[ObjectBounds]?) -> Void){
        guard let cgImage = photo.cgImage else{
            completionHandler(nil)
            return
        }
        
        // TODO preprocess image and pass to model
        
        // TODO pass models results to detectObjectsBounds(::)
        
        completionHandler(nil)
    }
    
    func detectObjectsBounds(array:MLMultiArray, objectThreshold:Float = 0.3) -> [ObjectBounds]?{
        
        // TODO interpret the models output
        
        return nil
    }
}

// MARK: - Non-Max Suppression

extension YOLOFacade{
    
    func filterDetectedObjects(objectsBounds:[ObjectBounds],
                                 objectsConfidence:[Float],
                                 nmsThreshold : Float = 0.3) -> [ObjectBounds]?{
        
        // If there are no bounding boxes do nothing
        guard objectsBounds.count > 0 else{
            return []
        }
        
        // TODO implement Non-Max Suppression
        
        return nil
    }
}
