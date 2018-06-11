//
//  RescaleOutputLambda.swift
//  StyleTransfer
//
//  Created by Joshua Newnham on 19/04/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import Foundation
import CoreML
import Accelerate
#if !(targetEnvironment(simulator))
import Metal
#endif

/**
  ((x+1)*127.5.
 */
@objc(RescaleOutputLambda) class RescaleOutputLambda: NSObject, MLCustomLayer {
    
    #if !(targetEnvironment(simulator))
    let computePipeline: MTLComputePipelineState
    #endif 
    
    required init(parameters: [String : Any]) throws {
        #if !(targetEnvironment(simulator))
        // Create the Metal compute kernels
        let device = MTLCreateSystemDefaultDevice()!
        let library = device.makeDefaultLibrary()!
        let rescaleFunction = library.makeFunction(name: "rescale")!
        self.computePipeline = try! device.makeComputePipelineState(function: rescaleFunction)
        #endif
        super.init()
    }
    
    func setWeightData(_ weights: [Data]) throws {
        print(#function, weights)
    }
    
    func outputShapes(forInputShapes inputShapes: [[NSNumber]]) throws
        -> [[NSNumber]] {
            print("RescaleOutputLambda", #function, inputShapes)
            return inputShapes
    }
    
    /**

    */
//    func evaluate(inputs: [MLMultiArray], outputs: [MLMultiArray]) throws {
//        print("ResCropBlockLambda", #function, inputs.count, outputs.count)
//
//        let rescaleAddition = 1.0
//        let rescaleMulitplier = 127.5
//
//        for (i, input) in inputs.enumerated(){
//
//            let shape = input.shape // expecting [1, 1, Channels, Kernel Width, Kernel Height]
//            for c in 0..<shape[2].intValue{
//                for w in 0..<shape[3].intValue{
//                    for h in 0..<shape[4].intValue{
//                        let index = [NSNumber(value: 0),
//                                     NSNumber(value: 0),
//                                     NSNumber(value: c),
//                                     NSNumber(value: w),
//                                     NSNumber(value: h)]
//                        let outputValue = NSNumber(
//                            value:(input[index].floatValue + rescaleAddition) * rescaleMulitplier)
//
//                        outputs[i][index] = outputValue
//                    }
//                }
//            }
//        }
//    }
    
    func evaluate(inputs: [MLMultiArray], outputs: [MLMultiArray]) throws {
        print("ResCropBlockLambda", #function, inputs.count, outputs.count)
        
        var rescaleAddition : Float = 1.0
        var rescaleMulitplier : Float = 127.5
        
        for (i, _) in inputs.enumerated(){
            
            let input = inputs[i]
            let output = outputs[i]
            
            let count = input.count
            let inputPointer = UnsafeMutablePointer<Float>(OpaquePointer(input.dataPointer))
            let outputPointer = UnsafeMutablePointer<Float>(OpaquePointer(output.dataPointer))
            
            // output = input + 1
            vDSP_vsadd(inputPointer, 1, &rescaleAddition, outputPointer, 1, vDSP_Length(count))
            
            // output = output * 127.5
            vDSP_vsmul(outputPointer, 1, &rescaleMulitplier, outputPointer, 1, vDSP_Length(count))
        }
    }
    
    #if !(targetEnvironment(simulator))
    func encode(commandBuffer: MTLCommandBuffer,
                inputs: [MTLTexture],
                outputs: [MTLTexture]) throws {
        if let encoder = commandBuffer.makeComputeCommandEncoder() {
            let w = computePipeline.threadExecutionWidth
            let h = computePipeline.maxTotalThreadsPerThreadgroup / w
            let threadGroupSize = MTLSizeMake(w, h, 1)
            
            for i in 0..<inputs.count {
                let threadGroups = MTLSizeMake(
                    (inputs[i].width       + threadGroupSize.width  - 1) / threadGroupSize.width,
                    (inputs[i].height      + threadGroupSize.height - 1) / threadGroupSize.height,
                    (inputs[i].arrayLength + threadGroupSize.depth  - 1) / threadGroupSize.depth)
                
                encoder.setTexture(inputs[i], index: 0)
                encoder.setTexture(outputs[i], index: 1)
                encoder.setComputePipelineState(computePipeline)
                encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
                encoder.endEncoding()
            }
        }
    }
    #endif
}
