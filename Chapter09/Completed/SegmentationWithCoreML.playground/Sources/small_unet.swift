//
// small_unet.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
//@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class small_unetInput : MLFeatureProvider {

    /// Content image (RGB) as color (kCVPixelFormatType_32BGRA) image buffer, 448 pixels wide by 448 pixels high
    public var image: CVPixelBuffer

    public var featureNames: Set<String> {
        get {
            return ["image"]
        }
    }
    
    public func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "image") {
            return MLFeatureValue(pixelBuffer: image)
        }
        return nil
    }
    
    public init(image: CVPixelBuffer) {
        self.image = image
    }
}

/// Model Prediction Output Type
//@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class small_unetOutput : MLFeatureProvider {

    /// Source provided by CoreML

    private let provider : MLFeatureProvider


    /// Binary mask of detected person as grayscale (kCVPixelFormatType_OneComponent8) image buffer, 448 pixels wide by 448 pixels high
    public lazy var output: CVPixelBuffer = {
        [unowned self] in return self.provider.featureValue(for: "output")!.imageBufferValue
    }()!

    public var featureNames: Set<String> {
        return self.provider.featureNames
    }
    
    public func featureValue(for featureName: String) -> MLFeatureValue? {
        return self.provider.featureValue(for: featureName)
    }

    public init(output: CVPixelBuffer) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["output" : MLFeatureValue(pixelBuffer: output)])
    }

    public init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
//@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class small_unet {
    public var model: MLModel

    /**
        Construct a model with explicit path to mlmodel file
        - parameters:
           - url: the file url of the model
           - throws: an NSError object that describes the problem
    */
    public init(contentsOf url: URL) throws {
        self.model = try MLModel(contentsOf: url)
    }

    /// Construct a model that automatically loads the model from the app's bundle
    public convenience init() {
        let bundle = Bundle(for: small_unet.self)
        let assetPath = bundle.url(forResource: "small_unet", withExtension:"mlmodelc")
        try! self.init(contentsOf: assetPath!)
    }

    /**
        Make a prediction using the structured interface
        - parameters:
           - input: the input to the prediction as small_unetInput
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as small_unetOutput
    */
    public func prediction(input: small_unetInput) throws -> small_unetOutput {
        return try self.prediction(input: input, options: MLPredictionOptions())
    }

    /**
        Make a prediction using the structured interface
        - parameters:
           - input: the input to the prediction as small_unetInput
           - options: prediction options 
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as small_unetOutput
    */
    public func prediction(input: small_unetInput, options: MLPredictionOptions) throws -> small_unetOutput {
        let outFeatures = try model.prediction(from: input, options:options)
        return small_unetOutput(features: outFeatures)
    }

    /**
        Make a prediction using the convenience interface
        - parameters:
            - image: Content image (RGB) as color (kCVPixelFormatType_32BGRA) image buffer, 448 pixels wide by 448 pixels high
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as small_unetOutput
    */
    public func prediction(image: CVPixelBuffer) throws -> small_unetOutput {
        let input_ = small_unetInput(image: image)
        return try self.prediction(input: input_)
    }

    /**
        Make a batch prediction using the structured interface
        - parameters:
           - inputs: the inputs to the prediction as [small_unetInput]
           - options: prediction options 
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as [small_unetOutput]
    */
    public func predictions(inputs: [small_unetInput], options: MLPredictionOptions) throws -> [small_unetOutput] {
        if #available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *) {
            let batchIn = MLArrayBatchProvider(array: inputs)
            let batchOut = try model.predictions(from: batchIn, options: options)
            var results : [small_unetOutput] = []
            results.reserveCapacity(inputs.count)
            for i in 0..<batchOut.count {
                let outProvider = batchOut.features(at: i)
                let result =  small_unetOutput(features: outProvider)
                results.append(result)
            }
            return results
        } else {
            var results : [small_unetOutput] = []
            results.reserveCapacity(inputs.count)
            for input in inputs {
                let result = try self.prediction(input: input, options: options)
                results.append(result)
            }
            return results
        }
    }
}
