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
            
            DispatchQueue.main.async{
                self.processingQuery = false
                self.delegate?.onQueryCompleted(status:self.isInterrupted ? -1 : -1,
                                                result:nil)
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
        if let img = sketch.exportSketch(size: nil)?.resize(size: self.targetSize).rescalePixels(){
            return self.classifySketch(image: img)
        }
        
        return nil
    }
    
    func classifySketch(image:CIImage) -> [(key:String,value:Double)]?{
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
        return images
    }
}

// MARK: - Bing Search

extension QueryFacade{
    
    func downloadImages(searchTerms:[String], searchTermsCount:Int=4, searchResultsCount:Int=2) -> [CIImage]?{
        return nil
    }
    
}
