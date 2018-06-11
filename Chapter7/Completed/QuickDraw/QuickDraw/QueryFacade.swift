//
//  QueryFacade.swift
//  QuickDraw
//
//  Created by Joshua Newnham on 04/01/2018.
//  Copyright © 2018 Method. All rights reserved.
//

import UIKit
import Accelerate
import CoreML

protocol QueryDelegate : class{
    func onQueryCompleted(status: Int, result:QueryResult?)
}

struct QueryResult{
    var predictions = [(key:String, value:Double)]()
    var images = [CIImage]()
}

class QueryFacade{
    
    // Used for rendering image processing results and performing image analysis. Here we use
    // it for rendering out scaled and cropped captured frames in preparation for our model.
    let context = CIContext()
    
    // CoreML model responsible for classifying a given sketch
    let sketchClassifier = cnnsketchclassifier()
    
    // CoreML model responsible for extracting features from a given sketch
    let sketchFeatureExtractor = cnnsketchfeatureextractor()
    
    let queryQueue = DispatchQueue(label: "query_queue")
    
    var targetSize = CGSize(width: 256, height: 256)
    
    weak var delegate : QueryDelegate?
    
    var currentSketch : Sketch?{
        didSet{
            self.newQueryWaiting = true
            self.queryCanceled = false
        }
    }
    
    fileprivate var queryCanceled : Bool = false
    
    fileprivate var newQueryWaiting : Bool = false
    
    fileprivate var processingQuery : Bool = false
    
    var isProcessingQuery : Bool{
        get{
            return self.processingQuery
        }
    }
    
    /**
     Interrupt existing process if either a new query is waiting or the query
     has been canceled
     **/
    var isInterrupted : Bool{
        get{
            return self.queryCanceled || self.newQueryWaiting
        }
    }
    
    init() {
        
    }
    
    /**
     Call to cancel current query (being processed) and ignore
     any waiting query
    **/
    func cancel(){
        if self.isProcessingQuery || self.newQueryWaiting{
            self.currentSketch = nil
            self.newQueryWaiting = false
            self.processingQuery = false
            self.queryCanceled = true
        }
    }
    
    func asyncQuery(sketch:Sketch){
        self.currentSketch = sketch
        
        if !self.processingQuery{
            self.queryCurrentSketch()
        }
    }
    
    /**
     Process any waiting query
    **/
    fileprivate func processNextQuery(){
        self.queryCanceled = false
        
        if self.newQueryWaiting && !self.processingQuery{
            self.queryCurrentSketch()
        }
    }
    
    /**
     Start processing the current sketch; including prediction and
     performing image searches
    **/
    fileprivate func queryCurrentSketch(){
        guard let sketch = self.currentSketch else{
            self.processingQuery = false
            self.newQueryWaiting = false
            
            return
        }
        
        self.processingQuery = true
        self.newQueryWaiting = false
        
        queryQueue.async {
            
            guard let predictions = self.classifySketch(
                sketch: sketch) else{
                DispatchQueue.main.async{
                    self.processingQuery = false
                    self.delegate?.onQueryCompleted(status:-1, result:nil)
                    self.processNextQuery()
                }
                return
            }
            
            let searchTerms = predictions.map({ (key, value) -> String in
                return key
            })
            
            guard let images = self.downloadImages(
                searchTerms: searchTerms,
                searchTermsCount: 4) else{
                DispatchQueue.main.async{
                    self.processingQuery = false
                    self.delegate?.onQueryCompleted(status:-1, result:nil)
                    self.processNextQuery()
                }
                return
            }
            
            guard let sortedImage = self.sortByVisualSimilarity(
                images: images,
                sketch: sketch) else{
                DispatchQueue.main.async{
                    self.processingQuery = false
                    self.delegate?.onQueryCompleted(status:-1, result:nil)
                    self.processNextQuery()
                }
                return
            }
            
            DispatchQueue.main.async{
                self.processingQuery = false
                self.delegate?.onQueryCompleted(
                    status:self.isInterrupted ? -1 : 1,
                    result:QueryResult(
                        predictions: predictions,
                        images: sortedImage))
                self.processNextQuery()
            }
        }
    }
}

// MARK: - Classification

extension QueryFacade{
    
    func classifySketch(sketch:Sketch) -> [(key:String,value:Double)]?{
        // rasterize image, resize and then rescale pixels (multiplying
        // them by 1.0/255.0 as per training)
        if let img = sketch.exportSketch(size: nil)?
            .resize(size: self.targetSize).rescalePixels(){
            return self.classifySketch(image: img)
        }
        
        return nil
    }

    func classifySketch(image:CIImage) -> [(key:String,value:Double)]?{
        // obtain the CVPixelBuffer from the image
        if let pixelBuffer = image.toPixelBuffer(context: self.context, gray: true){
            // Try to make a prediction
            let prediction = try? self.sketchClassifier.prediction(image: pixelBuffer)
            
            if let classPredictions = prediction?.classLabelProbs{
                let sortedClassPredictions = classPredictions.sorted(by: { (kvp1, kvp2) -> Bool in
                    kvp1.value > kvp2.value
                })
                
                return sortedClassPredictions
            }
        }
        
        return nil
    }
}

// MARK: - Visual similarity search

extension QueryFacade{
    
    func sortByVisualSimilarity(images:[CIImage], sketch:Sketch) -> [CIImage]?{
        if let img = sketch.exportSketch(size: nil)?.resize(size: self.targetSize).rescalePixels(){
            return self.sortByVisualSimilarity(images: images, sketchImage: img)
        }
        
        return nil
    }
    
    /**
     Given a sketch image; iterate through seach of the suggested images, comparing their
     similarity to the target image (sketch) and return a list of sorted list
    */
    func sortByVisualSimilarity(images:[CIImage], sketchImage:CIImage) -> [CIImage]?{
        // Extract features from the sketch to be compared with with the other images
        guard let sketchFeatures = self.extractFeaturesFromImage(image: sketchImage) else{
            return nil
        }
        
        // Create array of scores that we will populate with their corresponding consine similarity scores
        var similatiryScores = Array<Double>(repeating:1.0, count:images.count)
        
        // Iterate through each Image, calculating and storing the similarity score
        for i in 0..<images.count{
            var similarityScore : Double = 1.0
            
            if let imageFeatures = self.extractFeaturesFromImage(image: images[i]){
                similarityScore = self.cosineSimilarity(
                    vecA: sketchFeatures,
                    vecB: imageFeatures)
            }
            
            similatiryScores[i] = similarityScore
            
            // exit early if the query has been canceled or new query is waiting
            if self.isInterrupted{
                return nil
            }
        }
        
        // sort images based on their similarity score
        return images.enumerated().sorted { (elemA, elemB) -> Bool in
            return similatiryScores[elemA.offset] < similatiryScores[elemB.offset]
            }.map { (item) -> CIImage in
                return item.element
        }
    }
    
    fileprivate func extractFeaturesFromImage(image:CIImage) -> MLMultiArray?{
        // obtain the CVPixelBuffer from the image
        guard let imagePixelBuffer = image.resize(size: self.targetSize).rescalePixels()?.toPixelBuffer(context: self.context, gray: true) else {
            return nil
        }
        
        // extract features from the image which we we compare each image with
        guard let features = try? self.sketchFeatureExtractor.prediction(image: imagePixelBuffer) else{
            return nil
        }
        
        return features.classActivations
    }

    /**
     Check out the link below for more details about calculating cosine between 2 vectors
     https://docs.scipy.org/doc/scipy/reference/generated/scipy.spatial.distance.cosine.html
     
     Here to leverage the vDSP API (Digital Signal Processing) to perform the calculations to
     improve performance. You can learn more about vDSP via the official vDSP Programming Guide https://developer.apple.com/library/content/documentation/Performance/Conceptual/vDSP_Programming_Guide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40005147
    */
    fileprivate func cosineSimilarity(vecA: MLMultiArray, vecB: MLMultiArray) -> Double {
        return 1.0 - self.dot(vecA:vecA, vecB:vecB) / (self.magnitude(vec: vecA) * self.magnitude(vec: vecB))
    }

    fileprivate func dot(vecA: MLMultiArray, vecB: MLMultiArray) -> Double {
        guard vecA.shape.count == 1 && vecB.shape.count == 1 else{
            fatalError("Expecting vectors (tensor with 1 rank)")
        }
        
        guard vecA.count == vecB.count else {
            fatalError("Excepting count of both vectors to be equal")
        }
        
        let count = vecA.count
        let vecAPtr = UnsafeMutablePointer<Double>(OpaquePointer(vecA.dataPointer))
        let vecBPptr = UnsafeMutablePointer<Double>(OpaquePointer(vecB.dataPointer))
        var output: Double = 0.0
        
        vDSP_dotprD(vecAPtr, 1, vecBPptr, 1, &output, vDSP_Length(count))
        
        var x: Double = 0
        
        for i in 0..<vecA.count{
            x += vecA[i].doubleValue * vecB[i].doubleValue
        }
        
        return x
    }

    fileprivate func magnitude(vec: MLMultiArray) -> Double {
        guard vec.shape.count == 1 else{
            fatalError("Expecting a vector (tensor with 1 rank)")
        }
        
        let count = vec.count
        let vecPtr = UnsafeMutablePointer<Double>(OpaquePointer(vec.dataPointer))
        var output: Double = 0.0
        vDSP_svsD(vecPtr, 1, &output, vDSP_Length(count))
        
        return sqrt(output)
    }    
}

// MARK: - Bing Search

extension QueryFacade{
    
    func downloadImages(searchTerms:[String],
                        searchTermsCount:Int=4,
                        searchResultsCount:Int=2) -> [CIImage]?{
        var bingResults = [BingServiceResult]()

        // synchronously query for each image
        for i in 0..<min(searchTermsCount, searchTerms.count){
            let results = BingService.sharedInstance.syncSearch(
                searchTerm: searchTerms[i], count:searchResultsCount)
            
            for bingResult in results{
                bingResults.append(bingResult)
            }
            
            // exit early if the query has been canceled or new query is waiting
            if self.isInterrupted{
                return nil
            }
        }
        
        var images = [CIImage]()
        
        // synchronously download each image
        for bingResult in bingResults{
            if let image = BingService.sharedInstance.syncDownloadImage(
                bingResult: bingResult){
                images.append(image)
            }
            
            // exit early if the query has been canceled or new query is waiting
            if self.isInterrupted{
                return nil
            }
        }
        
        return images
    }
    
}
