//
//  StrokeSketchExtension.swift
//  QuickDrawRNN
//
//  Created by Joshua Newnham on 18/02/2018.
//  Copyright © 2018 PacktPub. All rights reserved.
//

import UIKit
import CoreML

extension StrokeSketch{
    
    /**
     - Align the drawing to the top-left corner, to have minimum values of 0.
     - Uniformly scale the drawing, to have a maximum value of 255.
     - Resample all strokes with a 1 pixel spacing.
     - Simplify all strokes using the [Ramer–Douglas–Peucker algorithm](https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm) with an epsilon value of 2.0.
     */
    public func simplify() -> StrokeSketch{
        let copy = self.copy() as! StrokeSketch
        copy.scale = 1.0
        
        let minPoint = copy.minPoint
        let maxPoint = copy.maxPoint
        let scale = CGPoint(x: maxPoint.x-minPoint.x,
                            y:maxPoint.y-minPoint.y)
        
        var width : CGFloat = 255.0
        var height : CGFloat = 255.0
        
        // adjust aspect ratio
        if scale.x > scale.y{
            height *= scale.y/scale.x
        } else{
            width *= scale.y/scale.x
        }
        
        // for each point, subtract the min and divide by the max
        for i in 0..<copy.strokes.count{
            copy.strokes[i].points = copy.strokes[i].points.map({
                (pt) -> CGPoint in
                // Normalise point and then scale based on adjusted dimension above
                // (also casting to an Int then back to a CGFloat to get 1 pixel precision)
                let x : CGFloat = CGFloat(
                    Int(((pt.x - minPoint.x)/scale.x) * width)
                )
                let y : CGFloat = CGFloat(
                    Int(((pt.y - minPoint.y)/scale.y) * height)
                )
                
                return CGPoint(x:x, y:y)
            })
        }
        
        // perform line simplification
        copy.strokes = copy.strokes.map({ (stroke) -> Stroke in
            return stroke.simplify()
        })
        
        return copy
    }
}

/*:
 Pre-processing, as used in training, which requires the following steps:
 - Introduce another dimension to indicate if a point is the end of not
 - Size normalization i.e. such that the minimum stroke point is 0 (on both axis) and maximum point is 1.0.
 - Compute deltas; the model was trained on deltas rather than absolutes positions
 */
extension StrokeSketch{
    
    public static func preprocess(_ sketch:StrokeSketch)
        -> MLMultiArray?{
        let arrayLen = NSNumber(value:75 * 3) // flattened (75,3) tensor
        
        let simplifiedSketch = sketch.simplify()
        
        // Create our MLMultiArray to store the results
        guard let array = try? MLMultiArray(shape: [arrayLen],
                                            dataType: .double)
            else{ return nil }
        
        
        // Flatten all points into a single array and:
        // a. Normalise
        // b. Append our EOS (End Of Stroke) flag
        let minPoint = simplifiedSketch.minPoint
        let maxPoint = simplifiedSketch.maxPoint
        let scale = CGPoint(x: maxPoint.x-minPoint.x,
                            y:maxPoint.y-minPoint.y)
        
        var data = Array<Double>()
        for i in 0..<simplifiedSketch.strokes.count{
            for j in 0..<simplifiedSketch.strokes[i].points.count{
                let point = simplifiedSketch.strokes[i].points[j]
                let x = (point.x-minPoint.x)/scale.x
                let y = (point.y-minPoint.y)/scale.y
                let z = j == simplifiedSketch.strokes[i].points.count-1 ?
                    1 : 0
                
                data.append(Double(x))
                data.append(Double(y))
                data.append(Double(z))
            }
        }
        
        // compute the deltas (nb; each sample has a stride of 3)
        let dataStride : Int = 3
        for i in stride(from: dataStride, to:data.count, by: dataStride){
            data[i - dataStride] = data[i] - data[i - dataStride] // delta x
            data[i - (dataStride-1)] = data[i+1] - data[i - (dataStride-1)] // delta y
            data[i - (dataStride-2)] = data[i+2] // EOS
        }
        
        // remove the last sample
        data.removeLast(3)
        
        // Pad (to the end) and copy our flattened array to the array
        var dataIdx : Int = 0
        let startAddingIdx = max(array.count-data.count, 0)
        
        for i in 0..<array.count{
            if i >= startAddingIdx{
                array[i] = NSNumber(value:data[dataIdx])
                dataIdx = dataIdx + 1
            } else{
                array[i] = NSNumber(value:0)
            }
        }
        
        return array
    }
}
