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
    
    var model : MLModel?
    
    let queryQueue = DispatchQueue(label: "query_queue")
    
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
        syncModel()
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
            
            DispatchQueue.main.async{
                self.processingQuery = false
                self.delegate?.onQueryCompleted(
                    status:self.isInterrupted ? -1 : 1,
                    result:QueryResult(
                        predictions: predictions,
                        images: images))
                self.processNextQuery()
            }
        }
    }
}

// MARK: - Model loading

extension QueryFacade{
    
    /**
     Key used to store the timestamp of when the model was updated in the UserPrefs
     */
    private var SyncTimestampKey : String{
        get{
            return "model_sync_timestamp"
        }
    }

    private var ModelUrlKey : String{
        get{
            return "model_url"
        }
    }

    /**
     Test if we need to download the model; this is the case if we haven't yet downloaded the model or
     the model is considered 'stale'
    */
    private var isModelStale : Bool{
        get{
            // Check if file exists
            if let modelUrl = UserDefaults.standard.string(forKey: self.ModelUrlKey){
                if !FileManager.default.fileExists(atPath: modelUrl){
                    return true
                }
            }
            
            // Number of days we want to refresh our model
            let daysToUpdate : Int = 10

            // Get the last time this model was updated (0 if it hasn't been)
            let lastUpdated = Date(timestamp:UserDefaults.standard.integer(forKey: SyncTimestampKey))

            // Get the number of elasped days between today and the last time the model was updated
            guard let numberOfDaysSinceUpdate = NSCalendar.current.dateComponents([.day], from: lastUpdated, to: Date()).day else{
                fatalError("Failed to calculated elapsed days since the model was updated")
            }

            // Test if we need to update the model
            return numberOfDaysSinceUpdate >= daysToUpdate
        }
    }
    
    private func syncModel(){
        queryQueue.async {
            
            // Test if our model is stale (if so; then proceed to download it and replace our existing model
            if self.isModelStale{
                guard let tempModelUrl = self.downloadModel() else{
                    return
                }

                guard let compiledUrl = try? MLModel.compileModel(
                    at: tempModelUrl) else{
                    fatalError("Failed to compile model")
                }
                
                let appSupportDirectory = try! FileManager.default.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: compiledUrl,
                    create: true)

                // Create a permanent URL in the app support directory
                let permanentUrl = appSupportDirectory.appendingPathComponent(
                    compiledUrl.lastPathComponent)
                do {
                    // If the file exists, replace it. Otherwise, copy the file to the destination.
                    if FileManager.default.fileExists(
                        atPath: permanentUrl.absoluteString) {
                        _ = try FileManager.default.replaceItemAt(
                            permanentUrl,
                            withItemAt: compiledUrl)
                    } else {
                        try FileManager.default.copyItem(
                            at: compiledUrl,
                            to: permanentUrl)
                    }
                } catch {
                    fatalError("Error during copy: \(error.localizedDescription)")
                }

                // Save timestamp
                UserDefaults.standard.set(Date.timestamp,
                                          forKey: self.SyncTimestampKey)
                // Save Url
                UserDefaults.standard.set(permanentUrl.absoluteString,
                                          forKey:self.ModelUrlKey)
            }
            
            guard let modelUrl = URL(
                string:UserDefaults.standard.string(forKey: self.ModelUrlKey) ?? "")
                else{
                fatalError("Invalid model Url")
            }
            
            self.model = try? MLModel(contentsOf: modelUrl)
        }
    }
    
    /**
     Syncronous method used to download the model; if successful then will reutrn the URL of the
     temporary file
    */
    private func downloadModel() -> URL?{
        guard let modelUrl = URL(
            string:"https://github.com/joshnewnham/MachineLearningWithCoreML/blob/master/CoreMLModels/Chapter8/quickdraw.mlmodel?raw=true") else{
                fatalError("Invalid URL")
        }
        
        var tempUrl : URL?
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        let request = URLRequest(url:modelUrl)
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                tempUrl = tempLocalUrl
            } else {
                fatalError("Error downloading model \(String(describing: error?.localizedDescription))")
            }
            
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        
        return tempUrl
    }
}

// MARK: - Classification

/**:
 Copied from the generated file
 **/
class ModelInput : MLFeatureProvider {
    
    /// Sequence of strokes - flattened (75,3) to (255) as 225 element vector of doubles
    var strokeSeq: MLMultiArray
    
    var featureNames: Set<String> {
        get {
            return ["strokeSeq"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "strokeSeq") {
            return MLFeatureValue(multiArray: strokeSeq)
        }
        return nil
    }
    
    init(strokeSeq: MLMultiArray) {
        self.strokeSeq = strokeSeq
    }
}

extension QueryFacade{
    
    func classifySketch(sketch:Sketch) -> [(key:String,value:Double)]?{
        if let strokeSketch = sketch as? StrokeSketch, let
            x = StrokeSketch.preprocess(strokeSketch){
            
            if let modelOutput = try! model?.prediction(from:ModelInput(strokeSeq:x)){
                if let classPredictions = modelOutput.featureValue(
                    for: "classLabelProbs")?.dictionaryValue as? [String:Double]{
                    let sortedClassPredictions = classPredictions.sorted(
                        by: { (kvp1, kvp2) -> Bool in
                        kvp1.value > kvp2.value
                    })
                    
                    return sortedClassPredictions
                }
            }
        }

        return nil
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
