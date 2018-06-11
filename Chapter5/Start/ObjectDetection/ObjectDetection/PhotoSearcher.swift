//
//  PhotoSearcher.swift
//  ObjectDetection
//
//  Created by Joshua Newnham on 14/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit
import Photos
import CoreML
import Vision
import Darwin

protocol PhotoSearcherDelegate : class{
    func onPhotoSearcherCompleted(status: Int, result:[SearchResult]?)
}

class PhotoSearcher{
    
    weak var delegate : PhotoSearcherDelegate?
    
    let yolo = YOLOFacade()
    
    public func asyncSearch(searchCriteria : [ObjectBounds]?, costThreshold : Float = 5){
        DispatchQueue.global(qos: .background).sync {
            let photos = getPhotosFromPhotosLibrary()
            
            let unscoredSearchResults = self.detectObjects(photos: photos)
            
            var sortedSearchResults : [SearchResult]?
            
            if let unscoredSearchResults = unscoredSearchResults{
                sortedSearchResults = self.calculateCostForObjects(
                    detectedObjects:unscoredSearchResults ,
                    searchCriteria: searchCriteria).filter({ (searchResult) -> Bool in
                        return searchResult.cost < costThreshold
                    }).sorted(by: { (a, b) -> Bool in
                        return a.cost < b.cost
                    })
            }
            
            DispatchQueue.main.async {
                self.delegate?.onPhotoSearcherCompleted(
                    status: 1,
                    result: sortedSearchResults)
            }
        }
    }
}

// MARK: - Photo DataSource

extension PhotoSearcher{
    
    func getPhotosFromPhotosLibrary() -> [UIImage]{
        var photos = [UIImage]()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        for i in 0..<fetchResult.count{
            PHImageManager.default().requestImage(
                for: fetchResult.object(at: i) as PHAsset,
                targetSize: CGSize(width:416, height:416),
                contentMode: .aspectFill,
                options: requestOptions,
                resultHandler: { (image, bundle) in
                    if let image = image{
                        photos.append(image)
                    }
            }
            )
        }
        
        return photos
    }
}

// MARK: - CoreML

extension PhotoSearcher{
    
    func detectObjects(photos:[UIImage]) -> [SearchResult]?{
        var results = [SearchResult]()
        
        for photo in photos{
            
            yolo.detectObjects(photo: photo) { (result) in
                if let result = result{
                    results.append(SearchResult(image: photo, detectedObjects: result, cost: 0.0))
                }
            }
        }
        
        return results
    }
}

// MARK: Photo Ordering

extension PhotoSearcher{
    
    private func calculateCostForObjects(detectedObjects:[SearchResult], searchCriteria:[ObjectBounds]?) -> [SearchResult]{
        guard let searchCriteria = searchCriteria else{
            return detectedObjects
        }
        
        var result = [SearchResult]()
        
        for searchResult in detectedObjects{
            let cost = self.costForObjectPresences(
                detectedObject: searchResult,
                searchCriteria: searchCriteria) +
                self.costForObjectRelativePositioning(
                    detectedObject: searchResult,
                    searchCriteria: searchCriteria) +
                self.costForObjectSizeRelativeToImageSize(
                    detectedObject: searchResult,
                    searchCriteria: searchCriteria) +
                self.costForObjectSizeRelativeToOtherObjects(
                    detectedObject: searchResult,
                    searchCriteria: searchCriteria)
            
            let searchResult = SearchResult(
                image: searchResult.image,
                detectedObjects:searchResult.detectedObjects,
                cost: cost)
            
            result.append(searchResult)
        }
        
        return result
    }
    
    private func costForObjectPresences(
        detectedObject:SearchResult,
        searchCriteria:[ObjectBounds],
        weight:Float=2.0) -> Float{
        
        var cost : Float = 0.0
        
        // TODO implement cost function for object presence
        
        return cost * weight
    }
    
    private func costForObjectRelativePositioning(
        detectedObject:SearchResult,
        searchCriteria:[ObjectBounds],
        weight:Float=1.5) -> Float{
        
        var cost : Float = 0.0
        
        // TODO implement cost function for relative positioning 
        
        return cost * weight
    }
    
    private func costForObjectSizeRelativeToImageSize(
        detectedObject:SearchResult,
        searchCriteria:[ObjectBounds],
        weight:Float=1.0) -> Float{
        
        var cost : Float = 0.0
        
        // TODO implement
        
        return cost * weight
    }
    
    private func costForObjectSizeRelativeToOtherObjects(
        detectedObject:SearchResult,
        searchCriteria:[ObjectBounds],
        weight:Float=0.5) -> Float{
        
        var cost : Float = 0.0
        
        // TODO implement
        
        return cost * weight
    }
}

