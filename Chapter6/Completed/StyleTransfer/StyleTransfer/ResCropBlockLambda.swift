//
//  ResCropBlockLambda.swift
//  StyleTransfer
//
//  Created by Joshua Newnham on 19/04/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import Foundation
import CoreML
import Accelerate

/**
 Implement the Lambda function
 def res_crop(x):
    return x[:, 2:-2, 2:-2]
 */
@objc(ResCropBlockLambda) class ResCropBlockLambda: NSObject, MLCustomLayer {
    
    required init(parameters: [String : Any]) throws {
        print("ResCropBlockLambda", #function, parameters)
        super.init()
    }
    
    func setWeightData(_ weights: [Data]) throws {
        print("ResCropBlockLambda", #function, weights)
    }
    
    func outputShapes(forInputShapes inputShapes: [[NSNumber]]) throws
        -> [[NSNumber]] {
            print("ResCropBlockLambda", #function, inputShapes)
            
            return [[NSNumber(value:inputShapes[0][0].intValue),
                     NSNumber(value:inputShapes[0][1].intValue),
                     NSNumber(value:inputShapes[0][2].intValue),
                     NSNumber(value:inputShapes[0][3].intValue - 4),
                     NSNumber(value:inputShapes[0][4].intValue - 4)]];
    }        
    
    func evaluate(inputs: [MLMultiArray], outputs: [MLMultiArray]) throws {
        for (i, input) in inputs.enumerated(){
            
            let shape = input.shape // expecting [1, 1, Channels, Kernel Width, Kernel Height]
            for c in 0..<shape[2].intValue{
                for w in 2...(shape[3].intValue-4){
                    for h in 2...(shape[4].intValue-4){
                        let inputIndex = [NSNumber(value: 0),
                                          NSNumber(value: 0),
                                          NSNumber(value: c),
                                          NSNumber(value: w),
                                          NSNumber(value: h)]
                        
                        let outputIndex = [NSNumber(value: 0),
                                           NSNumber(value: 0),
                                           NSNumber(value: c),
                                           NSNumber(value: w-2),
                                           NSNumber(value: h-2)]
                        
                        outputs[i][outputIndex] = input[inputIndex]
                    }
                }
            }
        }
    }
}
