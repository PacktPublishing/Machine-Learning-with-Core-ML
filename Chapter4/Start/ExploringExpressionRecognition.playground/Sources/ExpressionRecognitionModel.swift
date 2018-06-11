//
// ExpressionRecognitionModelRaw.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class ExpressionRecognitionModelRawInput : MLFeatureProvider {
    
    /// Input image; grayscale 48x48 of a face as 1 x 48 x 48 3-dimensional array of doubles
    public var image: MLMultiArray
    
    public var featureNames: Set<String> {
        get {
            return ["image"]
        }
    }
    
    public func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "image") {
            return MLFeatureValue(multiArray: image)
        }
        return nil
    }
    
    public init(image: MLMultiArray) {
        self.image = image
    }
}


/// Model Prediction Output Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class ExpressionRecognitionModelRawOutput : MLFeatureProvider {
    
    /// Probability of each expression as dictionary of strings to doubles
    public let classLabelProbs: [String : Double]
    
    /// Most likely expression as string value
    public let classLabel: String
    
    public var featureNames: Set<String> {
        get {
            return ["classLabelProbs", "classLabel"]
        }
    }
    
    public func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "classLabelProbs") {
            return try! MLFeatureValue(dictionary: classLabelProbs as [NSObject : NSNumber])
        }
        if (featureName == "classLabel") {
            return MLFeatureValue(string: classLabel)
        }
        return nil
    }
    
    public init(classLabelProbs: [String : Double], classLabel: String) {
        self.classLabelProbs = classLabelProbs
        self.classLabel = classLabel
    }
}


/// Class for model loading and prediction
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class ExpressionRecognitionModelRaw {
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
        let bundle = Bundle(for: ExpressionRecognitionModelRaw.self)
        let assetPath = bundle.url(forResource: "ExpressionRecognitionModelRaw", withExtension:"mlmodelc")
        try! self.init(contentsOf: assetPath!)
    }
    
    /**
     Make a prediction using the structured interface
     - parameters:
     - input: the input to the prediction as ExpressionRecognitionModelRawInput
     - throws: an NSError object that describes the problem
     - returns: the result of the prediction as ExpressionRecognitionModelRawOutput
     */
    public func prediction(input: ExpressionRecognitionModelRawInput) throws -> ExpressionRecognitionModelRawOutput {
        let outFeatures = try model.prediction(from: input)
        let result = ExpressionRecognitionModelRawOutput(classLabelProbs: outFeatures.featureValue(for: "classLabelProbs")!.dictionaryValue as! [String : Double], classLabel: outFeatures.featureValue(for: "classLabel")!.stringValue)
        return result
    }
    
    /**
     Make a prediction using the convenience interface
     - parameters:
     - image: Input image; grayscale 48x48 of a face as 1 x 48 x 48 3-dimensional array of doubles
     - throws: an NSError object that describes the problem
     - returns: the result of the prediction as ExpressionRecognitionModelRawOutput
     */
    public func prediction(image: MLMultiArray) throws -> ExpressionRecognitionModelRawOutput {
        let input_ = ExpressionRecognitionModelRawInput(image: image)
        return try self.prediction(input: input_)
    }
}
