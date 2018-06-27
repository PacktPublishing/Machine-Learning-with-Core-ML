//
//  DataObjects.swift
//
//  Created by Joshua Newnham on 13/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit

// MARK: - DetectableObject

struct DetectableObject{
    public var classIndex : Int
    public var label : String
    
    static let objects = [
        DetectableObject(classIndex:19, label:"tvmonitor"),
        DetectableObject(classIndex:18, label:"train"),
        DetectableObject(classIndex:17, label:"sofa"),
        DetectableObject(classIndex:14, label:"person"),
        DetectableObject(classIndex:11, label:"dog"),
        DetectableObject(classIndex:7, label:"cat"),
        DetectableObject(classIndex:6, label:"car"),
        DetectableObject(classIndex:5, label:"bus"),
        DetectableObject(classIndex:4, label:"bottle"),
        DetectableObject(classIndex:3, label:"boat"),
        DetectableObject(classIndex:2, label:"bird"),
        DetectableObject(classIndex:1, label:"bicycle")
    ]
}

// MARK: UI Extension to DetectableObject

extension DetectableObject{
    
    public static func getColor(classIndex:Int) -> UIColor{
        switch(classIndex){
        case 1: return UIColor(hex:0x76C379)
        case 2: return UIColor(hex:0xDBDA91)
        case 3: return UIColor(hex:0x3683BB)
        case 4: return UIColor(hex:0xA0DAE4)
        case 5: return UIColor(hex:0xC7C7C7)
        case 6: return UIColor(hex:0xF6B7D2)
        case 7: return UIColor(hex:0xC39C95)
        case 11: return UIColor(hex:0xC39C95)
        case 14: return UIColor(hex:0xFD9898)
        case 17: return UIColor(hex:0x9ADE8D)
        case 18: return UIColor(hex:0xFDBB7D)
        case 19: return UIColor(hex:0xAFC8E7)
        default: return UIColor(hex:0xFFFFFF)
        }
    }
}

// MARK: - ObjectBounds

struct ObjectBounds {
    public var object : DetectableObject
    public var origin : CGPoint
    public var size : CGSize
    
    var bounds : CGRect{
        return CGRect(origin: self.origin, size: self.size)
    }
}

extension ObjectBounds : Equatable{
    
    static func ==(lhs: ObjectBounds, rhs: ObjectBounds) -> Bool {
        return lhs.object.classIndex == rhs.object.classIndex &&
            abs((lhs.origin - rhs.origin).length) < 0.01 &&
            abs(lhs.size.width - rhs.size.width) < 0.01 &&
            abs(lhs.size.height - rhs.size.height) < 0.01
    }
}

extension ObjectBounds{
    
    /**
     
    */
    func transformFromCenteredCropping(from:CGSize, to:CGSize, normalise:Bool=true) -> ObjectBounds{
        var ox : CGFloat = 0.0
        var oy : CGFloat = 0.0
        var cropSize = from
        
        // Cropped image size
        if from.width > from.height{
            ox = (from.width - from.height)/2
            oy = 0.0
            cropSize = CGSize(width:from.height, height:from.height)
        }
        else if from.height > from.width{
            ox = 0.0
            oy = (from.height - from.width)/2
            cropSize = CGSize(width:from.width, height:from.width)
        }
        
        let origin = self.origin
        let size = self.size
        
        // Calcualte bounds size
        let w = size.width * cropSize.width
        let h = size.height * cropSize.height
        let x = ox + origin.x * cropSize.width
        let y = oy + origin.y * cropSize.height
        
        if normalise{
            return ObjectBounds(object: self.object,
                                origin: CGPoint(x: x/from.width, y: y/from.height),
                                size: CGSize(width:w/from.width, height:h/from.height))
        } else{
            return ObjectBounds(object: self.object,
                                origin: CGPoint(x: x, y: y),
                                size: CGSize(width:w, height:h))
        }
    }
}

// MARK: - SearchResult

struct SearchResult{
    
    /* Associated image **/
    public var image : UIImage
    
    /* Detected objects */
    public var detectedObjects : [ObjectBounds]
    
    /* Distance/cost from search critiera */
    public var cost : Float
}


