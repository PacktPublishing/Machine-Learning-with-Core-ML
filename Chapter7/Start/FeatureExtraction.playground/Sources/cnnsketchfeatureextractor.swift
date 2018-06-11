//
// cnnsketchfeatureextractor.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class cnnsketchfeatureextractorInput : MLFeatureProvider {

    /// Input sketch (grayscale image) to be processed as grayscale (kCVPixelFormatType_OneComponent8) image buffer, 256 pixels wide by 256 pixels high
    var image: CVPixelBuffer
    
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
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class cnnsketchfeatureextractorOutput : MLFeatureProvider {

    /// Activations for a given image as 512 element vector of doubles
    public let classActivations: MLMultiArray
    
    public var featureNames: Set<String> {
        get {
            return ["classActivations"]
        }
    }
    
    public func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "classActivations") {
            return MLFeatureValue(multiArray: classActivations)
        }
        return nil
    }
    
    public init(classActivations: MLMultiArray) {
        self.classActivations = classActivations
    }
}


/// Class for model loading and prediction
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class cnnsketchfeatureextractor {
    var model: MLModel

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
        let bundle = Bundle(for: cnnsketchfeatureextractor.self)
        let assetPath = bundle.url(forResource: "cnnsketchfeatureextractor", withExtension:"mlmodelc")
        try! self.init(contentsOf: assetPath!)
    }

    /**
        Make a prediction using the structured interface
        - parameters:
           - input: the input to the prediction as cnnsketchfeatureextractorInput
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as cnnsketchfeatureextractorOutput
    */
    public func prediction(input: cnnsketchfeatureextractorInput) throws -> cnnsketchfeatureextractorOutput {
        let outFeatures = try model.prediction(from: input)
        let result = cnnsketchfeatureextractorOutput(classActivations: outFeatures.featureValue(for: "classActivations")!.multiArrayValue!)
        return result
    }

    /**
        Make a prediction using the convenience interface
        - parameters:
            - image: Input sketch (grayscale image) to be processed as grayscale (kCVPixelFormatType_OneComponent8) image buffer, 256 pixels wide by 256 pixels high
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as cnnsketchfeatureextractorOutput
    */
    public func prediction(image: CVPixelBuffer) throws -> cnnsketchfeatureextractorOutput {
        let input_ = cnnsketchfeatureextractorInput(image: image)
        return try self.prediction(input: input_)
    }
}
