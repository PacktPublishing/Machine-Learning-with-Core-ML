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
    
    public func asyncSearch(searchCriteria : [ObjectBounds]?, costThreshold : Float = 5.0){
        DispatchQueue.global(qos: .background).async {
            let photos = self.getPhotosFromPhotosLibrary()
            
            let unscoredSearchResults = self.detectObjects(photos: photos)
            
            var sortedSearchResults : [SearchResult]?
            
            if let unscoredSearchResults = unscoredSearchResults{
                sortedSearchResults = self.calculateCostForObjects(
                    detectedObjects:unscoredSearchResults ,
                    searchCriteria: searchCriteria).filter({ (searchResult) -> Bool in
                        print(searchResult.cost)
                        return searchResult.cost < costThreshold
                    }).sorted(by: { (a, b) -> Bool in
                        return a.cost < b.cost
                    })
            }
            
            DispatchQueue.main.sync {
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
                targetSize: yolo.targetSize,
                contentMode: .aspectFill,
                options: requestOptions,
                resultHandler: { (image, bundle) in
                    if let image = image{
                        photos.append(image)
                    }
                }
            )
        }
        
//        photos.removeAll()
//        photos.append(UIImage(named:"test_image_2")!)
        
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
            let cost = self.costForObjectPresences(detectedObject: searchResult, searchCriteria: searchCriteria) +
                self.costForObjectRelativePositioning(detectedObject: searchResult, searchCriteria: searchCriteria) +
                self.costForObjectSizeRelativeToImageSize(detectedObject: searchResult, searchCriteria: searchCriteria) +
                self.costForObjectSizeRelativeToOtherObjects(detectedObject: searchResult, searchCriteria: searchCriteria)
            
            result.append(SearchResult(image: searchResult.image,
                                                      detectedObjects:searchResult.detectedObjects,
                                                      cost: cost))
        }
        
        return result
    }
    
    private func costForObjectPresences(detectedObject:SearchResult, searchCriteria:[ObjectBounds], weight:Float=2.0) -> Float{
        var cost : Float = 0.0
        
        var searchObjectCounts = searchCriteria.map { (detectedObject) -> String in
            return detectedObject.object.label
            }.reduce([:]) { (counter:[String:Float] , label) -> [String:Float] in
                var counter = counter
                counter[label] = counter[label]?.advanced(by: 1) ?? 1
                return counter
        }
        
        var detectedObjectCounts = detectedObject.detectedObjects.map { (detectedObject) -> String in
            return detectedObject.object.label
            }.reduce([:]) { (counter:[String:Float] , label) -> [String:Float] in
                var counter = counter
                counter[label] = counter[label]?.advanced(by: 1) ?? 1
                return counter
        }
        
        // Iterate through all possible labels and compute the cost based on the
        // difference between the two dictionaries
        for detectableObject in DetectableObject.objects{
            let label = detectableObject.label
            
            let searchCount = searchObjectCounts[label] ?? 0
            let detectedCount = detectedObjectCounts[label] ?? 0
            
            cost += abs(searchCount - detectedCount)
        }
        return cost * weight
    }
    
    private func costForObjectRelativePositioning(detectedObject:SearchResult,
                                                  searchCriteria:[ObjectBounds],
                                                  weight:Float=1.5) -> Float{
        
        func indexOfClosestObject(objects:[ObjectBounds], forObjectAtIndex i:Int) -> Int{
            let searchACenter = objects[i].bounds.center
            
            var closestDistance = Float.greatestFiniteMagnitude
            var closestObjectIndex : Int = -1
            
            for j in 0..<objects.count{
                guard i != j else{
                    continue
                }
                
                let searchBCenter = objects[j].bounds.center
                let distance = Float(searchACenter.distance(other: searchBCenter))
                if distance < closestDistance{
                    closestObjectIndex = j
                    closestDistance = distance
                }
            }
            
            return closestObjectIndex
        }
        
        var cost : Float = 0.0
        
        for si in 0..<searchCriteria.count{
            let closestObjectIndex = indexOfClosestObject(objects: searchCriteria,
                                                          forObjectAtIndex: si)
            if closestObjectIndex < 0{
                continue
            }
            
            // Get object types
            let searchAClassIndex = searchCriteria[si].object.classIndex
            let searchBClassIndex = searchCriteria[closestObjectIndex].object.classIndex
            
            // Get centers of objects
            let searchACenter = searchCriteria[si].bounds.center
            let searchBCenter = searchCriteria[closestObjectIndex].bounds.center
            
            // Calcualte the normalised vector from A -> B
            let searchDirection = (searchACenter - searchBCenter).normalised
            
            // Find comparable objects in detected objects
            let detectedA = detectedObject.detectedObjects.filter { (objectBounds) -> Bool in
                return objectBounds.object.classIndex == searchAClassIndex
            }
            
            let detectedB = detectedObject.detectedObjects.filter { (objectBounds) -> Bool in
                return objectBounds.object.classIndex == searchBClassIndex
            }
            
            // Check that we have matching pairs
            guard detectedA.count > 0, detectedB.count > 0 else{
                continue
            }
            
            // Give the 'benefit of doubt' and find the closest dot product
            // between similar products
            var closestDotProduct : Float = Float.greatestFiniteMagnitude
            for i in 0..<detectedA.count{
                for j in 0..<detectedB.count{
                    if detectedA[i] == detectedB[j]{
                        continue
                    }
                    
                    // Find the direction between detected object i and detected object j
                    let detectedDirection = (detectedA[i].bounds.center - detectedB[j].bounds.center).normalised
                    let dotProduct = Float(searchDirection.dot(other: detectedDirection))
                    if closestDotProduct > 10 ||
                        (dotProduct < closestDotProduct &&
                            dotProduct >= 0) {
                        closestDotProduct = dotProduct
                    }
                }
            }
            
            // Calcualte cost based on dot product
            cost += abs((1.0-closestDotProduct))
        }
        
        return cost * weight
    }
    
    private func costForObjectSizeRelativeToImageSize(detectedObject:SearchResult,
                                                      searchCriteria:[ObjectBounds],
                                                      weight:Float=1.0) -> Float{
        return 0.0
    }
    
    private func costForObjectSizeRelativeToOtherObjects(detectedObject:SearchResult,
                                                         searchCriteria:[ObjectBounds],
                                                         weight:Float=0.5) -> Float{
        return 0.0
    }
}

