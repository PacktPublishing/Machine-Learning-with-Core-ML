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

// MARK: - Classification

extension QueryFacade{
    
    func classifySketch(sketch:Sketch) -> [(key:String,value:Double)]?{
        // TODO 
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
