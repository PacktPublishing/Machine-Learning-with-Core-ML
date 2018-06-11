//
// quickdraw.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class quickdrawInput : MLFeatureProvider {
    
    /// Sequence of strokes - flattened (75,3) to (255) as 225 element vector of doubles
    public var strokeSeq: MLMultiArray
    
    /// lstm_0_h_in as optional 128 element vector of doubles
    var lstm_0_h_in: MLMultiArray? = nil
    
    /// lstm_0_c_in as optional 128 element vector of doubles
    var lstm_0_c_in: MLMultiArray? = nil
    
    /// lstm_0_h_in_rev as optional 128 element vector of doubles
    var lstm_0_h_in_rev: MLMultiArray? = nil
    
    /// lstm_0_c_in_rev as optional 128 element vector of doubles
    var lstm_0_c_in_rev: MLMultiArray? = nil
    
    /// lstm_1_h_in as optional 128 element vector of doubles
    var lstm_1_h_in: MLMultiArray? = nil
    
    /// lstm_1_c_in as optional 128 element vector of doubles
    var lstm_1_c_in: MLMultiArray? = nil
    
    /// lstm_1_h_in_rev as optional 128 element vector of doubles
    var lstm_1_h_in_rev: MLMultiArray? = nil
    
    /// lstm_1_c_in_rev as optional 128 element vector of doubles
    var lstm_1_c_in_rev: MLMultiArray? = nil
    
    /// lstm_2_h_in as optional 128 element vector of doubles
    var lstm_2_h_in: MLMultiArray? = nil
    
    /// lstm_2_c_in as optional 128 element vector of doubles
    var lstm_2_c_in: MLMultiArray? = nil
    
    /// lstm_2_h_in_rev as optional 128 element vector of doubles
    var lstm_2_h_in_rev: MLMultiArray? = nil
    
    /// lstm_2_c_in_rev as optional 128 element vector of doubles
    var lstm_2_c_in_rev: MLMultiArray? = nil
    
    public var featureNames: Set<String> {
        get {
            return ["strokeSeq", "lstm_0_h_in", "lstm_0_c_in", "lstm_0_h_in_rev", "lstm_0_c_in_rev", "lstm_1_h_in", "lstm_1_c_in", "lstm_1_h_in_rev", "lstm_1_c_in_rev", "lstm_2_h_in", "lstm_2_c_in", "lstm_2_h_in_rev", "lstm_2_c_in_rev"]
        }
    }
    
    public func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "strokeSeq") {
            return MLFeatureValue(multiArray: strokeSeq)
        }
        if (featureName == "lstm_0_h_in") {
            return lstm_0_h_in == nil ? nil : MLFeatureValue(multiArray: lstm_0_h_in!)
        }
        if (featureName == "lstm_0_c_in") {
            return lstm_0_c_in == nil ? nil : MLFeatureValue(multiArray: lstm_0_c_in!)
        }
        if (featureName == "lstm_0_h_in_rev") {
            return lstm_0_h_in_rev == nil ? nil : MLFeatureValue(multiArray: lstm_0_h_in_rev!)
        }
        if (featureName == "lstm_0_c_in_rev") {
            return lstm_0_c_in_rev == nil ? nil : MLFeatureValue(multiArray: lstm_0_c_in_rev!)
        }
        if (featureName == "lstm_1_h_in") {
            return lstm_1_h_in == nil ? nil : MLFeatureValue(multiArray: lstm_1_h_in!)
        }
        if (featureName == "lstm_1_c_in") {
            return lstm_1_c_in == nil ? nil : MLFeatureValue(multiArray: lstm_1_c_in!)
        }
        if (featureName == "lstm_1_h_in_rev") {
            return lstm_1_h_in_rev == nil ? nil : MLFeatureValue(multiArray: lstm_1_h_in_rev!)
        }
        if (featureName == "lstm_1_c_in_rev") {
            return lstm_1_c_in_rev == nil ? nil : MLFeatureValue(multiArray: lstm_1_c_in_rev!)
        }
        if (featureName == "lstm_2_h_in") {
            return lstm_2_h_in == nil ? nil : MLFeatureValue(multiArray: lstm_2_h_in!)
        }
        if (featureName == "lstm_2_c_in") {
            return lstm_2_c_in == nil ? nil : MLFeatureValue(multiArray: lstm_2_c_in!)
        }
        if (featureName == "lstm_2_h_in_rev") {
            return lstm_2_h_in_rev == nil ? nil : MLFeatureValue(multiArray: lstm_2_h_in_rev!)
        }
        if (featureName == "lstm_2_c_in_rev") {
            return lstm_2_c_in_rev == nil ? nil : MLFeatureValue(multiArray: lstm_2_c_in_rev!)
        }
        return nil
    }
    
    public init(strokeSeq: MLMultiArray, lstm_0_h_in: MLMultiArray? = nil, lstm_0_c_in: MLMultiArray? = nil, lstm_0_h_in_rev: MLMultiArray? = nil, lstm_0_c_in_rev: MLMultiArray? = nil, lstm_1_h_in: MLMultiArray? = nil, lstm_1_c_in: MLMultiArray? = nil, lstm_1_h_in_rev: MLMultiArray? = nil, lstm_1_c_in_rev: MLMultiArray? = nil, lstm_2_h_in: MLMultiArray? = nil, lstm_2_c_in: MLMultiArray? = nil, lstm_2_h_in_rev: MLMultiArray? = nil, lstm_2_c_in_rev: MLMultiArray? = nil) {
        self.strokeSeq = strokeSeq
        self.lstm_0_h_in = lstm_0_h_in
        self.lstm_0_c_in = lstm_0_c_in
        self.lstm_0_h_in_rev = lstm_0_h_in_rev
        self.lstm_0_c_in_rev = lstm_0_c_in_rev
        self.lstm_1_h_in = lstm_1_h_in
        self.lstm_1_c_in = lstm_1_c_in
        self.lstm_1_h_in_rev = lstm_1_h_in_rev
        self.lstm_1_c_in_rev = lstm_1_c_in_rev
        self.lstm_2_h_in = lstm_2_h_in
        self.lstm_2_c_in = lstm_2_c_in
        self.lstm_2_h_in_rev = lstm_2_h_in_rev
        self.lstm_2_c_in_rev = lstm_2_c_in_rev
    }
}


/// Model Prediction Output Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class quickdrawOutput : MLFeatureProvider {
    
    /// Probability of each category (Dict where the key is the category and value is the probability) as dictionary of strings to doubles
    public let classLabelProbs: [String : Double]
    
    /// lstm_0_h_out as 128 element vector of doubles
    let lstm_0_h_out: MLMultiArray
    
    /// lstm_0_c_out as 128 element vector of doubles
    let lstm_0_c_out: MLMultiArray
    
    /// lstm_0_h_out_rev as 128 element vector of doubles
    let lstm_0_h_out_rev: MLMultiArray
    
    /// lstm_0_c_out_rev as 128 element vector of doubles
    let lstm_0_c_out_rev: MLMultiArray
    
    /// lstm_1_h_out as 128 element vector of doubles
    let lstm_1_h_out: MLMultiArray
    
    /// lstm_1_c_out as 128 element vector of doubles
    let lstm_1_c_out: MLMultiArray
    
    /// lstm_1_h_out_rev as 128 element vector of doubles
    let lstm_1_h_out_rev: MLMultiArray
    
    /// lstm_1_c_out_rev as 128 element vector of doubles
    let lstm_1_c_out_rev: MLMultiArray
    
    /// lstm_2_h_out as 128 element vector of doubles
    let lstm_2_h_out: MLMultiArray
    
    /// lstm_2_c_out as 128 element vector of doubles
    let lstm_2_c_out: MLMultiArray
    
    /// lstm_2_h_out_rev as 128 element vector of doubles
    let lstm_2_h_out_rev: MLMultiArray
    
    /// lstm_2_c_out_rev as 128 element vector of doubles
    let lstm_2_c_out_rev: MLMultiArray
    
    /// classLabel as string value
    public let classLabel: String
    
    public var featureNames: Set<String> {
        get {
            return ["classLabelProbs", "lstm_0_h_out", "lstm_0_c_out", "lstm_0_h_out_rev", "lstm_0_c_out_rev", "lstm_1_h_out", "lstm_1_c_out", "lstm_1_h_out_rev", "lstm_1_c_out_rev", "lstm_2_h_out", "lstm_2_c_out", "lstm_2_h_out_rev", "lstm_2_c_out_rev", "classLabel"]
        }
    }
    
    public func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "classLabelProbs") {
            return try! MLFeatureValue(dictionary: classLabelProbs as [NSObject : NSNumber])
        }
        if (featureName == "lstm_0_h_out") {
            return MLFeatureValue(multiArray: lstm_0_h_out)
        }
        if (featureName == "lstm_0_c_out") {
            return MLFeatureValue(multiArray: lstm_0_c_out)
        }
        if (featureName == "lstm_0_h_out_rev") {
            return MLFeatureValue(multiArray: lstm_0_h_out_rev)
        }
        if (featureName == "lstm_0_c_out_rev") {
            return MLFeatureValue(multiArray: lstm_0_c_out_rev)
        }
        if (featureName == "lstm_1_h_out") {
            return MLFeatureValue(multiArray: lstm_1_h_out)
        }
        if (featureName == "lstm_1_c_out") {
            return MLFeatureValue(multiArray: lstm_1_c_out)
        }
        if (featureName == "lstm_1_h_out_rev") {
            return MLFeatureValue(multiArray: lstm_1_h_out_rev)
        }
        if (featureName == "lstm_1_c_out_rev") {
            return MLFeatureValue(multiArray: lstm_1_c_out_rev)
        }
        if (featureName == "lstm_2_h_out") {
            return MLFeatureValue(multiArray: lstm_2_h_out)
        }
        if (featureName == "lstm_2_c_out") {
            return MLFeatureValue(multiArray: lstm_2_c_out)
        }
        if (featureName == "lstm_2_h_out_rev") {
            return MLFeatureValue(multiArray: lstm_2_h_out_rev)
        }
        if (featureName == "lstm_2_c_out_rev") {
            return MLFeatureValue(multiArray: lstm_2_c_out_rev)
        }
        if (featureName == "classLabel") {
            return MLFeatureValue(string: classLabel)
        }
        return nil
    }
    
    public init(classLabelProbs: [String : Double], lstm_0_h_out: MLMultiArray, lstm_0_c_out: MLMultiArray, lstm_0_h_out_rev: MLMultiArray, lstm_0_c_out_rev: MLMultiArray, lstm_1_h_out: MLMultiArray, lstm_1_c_out: MLMultiArray, lstm_1_h_out_rev: MLMultiArray, lstm_1_c_out_rev: MLMultiArray, lstm_2_h_out: MLMultiArray, lstm_2_c_out: MLMultiArray, lstm_2_h_out_rev: MLMultiArray, lstm_2_c_out_rev: MLMultiArray, classLabel: String) {
        self.classLabelProbs = classLabelProbs
        self.lstm_0_h_out = lstm_0_h_out
        self.lstm_0_c_out = lstm_0_c_out
        self.lstm_0_h_out_rev = lstm_0_h_out_rev
        self.lstm_0_c_out_rev = lstm_0_c_out_rev
        self.lstm_1_h_out = lstm_1_h_out
        self.lstm_1_c_out = lstm_1_c_out
        self.lstm_1_h_out_rev = lstm_1_h_out_rev
        self.lstm_1_c_out_rev = lstm_1_c_out_rev
        self.lstm_2_h_out = lstm_2_h_out
        self.lstm_2_c_out = lstm_2_c_out
        self.lstm_2_h_out_rev = lstm_2_h_out_rev
        self.lstm_2_c_out_rev = lstm_2_c_out_rev
        self.classLabel = classLabel
    }
}


/// Class for model loading and prediction
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class quickdraw {
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
        let bundle = Bundle(for: quickdraw.self)
        let assetPath = bundle.url(forResource: "quickdraw", withExtension:"mlmodelc")
        try! self.init(contentsOf: assetPath!)
    }
    
    /**
     Make a prediction using the structured interface
     - parameters:
     - input: the input to the prediction as quickdrawInput
     - throws: an NSError object that describes the problem
     - returns: the result of the prediction as quickdrawOutput
     */
    public func prediction(input: quickdrawInput) throws -> quickdrawOutput {
        let outFeatures = try model.prediction(from: input)
        let result = quickdrawOutput(classLabelProbs: outFeatures.featureValue(for: "classLabelProbs")!.dictionaryValue as! [String : Double], lstm_0_h_out: outFeatures.featureValue(for: "lstm_0_h_out")!.multiArrayValue!, lstm_0_c_out: outFeatures.featureValue(for: "lstm_0_c_out")!.multiArrayValue!, lstm_0_h_out_rev: outFeatures.featureValue(for: "lstm_0_h_out_rev")!.multiArrayValue!, lstm_0_c_out_rev: outFeatures.featureValue(for: "lstm_0_c_out_rev")!.multiArrayValue!, lstm_1_h_out: outFeatures.featureValue(for: "lstm_1_h_out")!.multiArrayValue!, lstm_1_c_out: outFeatures.featureValue(for: "lstm_1_c_out")!.multiArrayValue!, lstm_1_h_out_rev: outFeatures.featureValue(for: "lstm_1_h_out_rev")!.multiArrayValue!, lstm_1_c_out_rev: outFeatures.featureValue(for: "lstm_1_c_out_rev")!.multiArrayValue!, lstm_2_h_out: outFeatures.featureValue(for: "lstm_2_h_out")!.multiArrayValue!, lstm_2_c_out: outFeatures.featureValue(for: "lstm_2_c_out")!.multiArrayValue!, lstm_2_h_out_rev: outFeatures.featureValue(for: "lstm_2_h_out_rev")!.multiArrayValue!, lstm_2_c_out_rev: outFeatures.featureValue(for: "lstm_2_c_out_rev")!.multiArrayValue!, classLabel: outFeatures.featureValue(for: "classLabel")!.stringValue)
        return result
    }
    
    /**
     Make a prediction using the convenience interface
     - parameters:
     - strokeSeq: Sequence of strokes - flattened (75,3) to (255) as 225 element vector of doubles
     - lstm_0_h_in as optional 128 element vector of doubles
     - lstm_0_c_in as optional 128 element vector of doubles
     - lstm_0_h_in_rev as optional 128 element vector of doubles
     - lstm_0_c_in_rev as optional 128 element vector of doubles
     - lstm_1_h_in as optional 128 element vector of doubles
     - lstm_1_c_in as optional 128 element vector of doubles
     - lstm_1_h_in_rev as optional 128 element vector of doubles
     - lstm_1_c_in_rev as optional 128 element vector of doubles
     - lstm_2_h_in as optional 128 element vector of doubles
     - lstm_2_c_in as optional 128 element vector of doubles
     - lstm_2_h_in_rev as optional 128 element vector of doubles
     - lstm_2_c_in_rev as optional 128 element vector of doubles
     - throws: an NSError object that describes the problem
     - returns: the result of the prediction as quickdrawOutput
     */
    public func prediction(strokeSeq: MLMultiArray, lstm_0_h_in: MLMultiArray?, lstm_0_c_in: MLMultiArray?, lstm_0_h_in_rev: MLMultiArray?, lstm_0_c_in_rev: MLMultiArray?, lstm_1_h_in: MLMultiArray?, lstm_1_c_in: MLMultiArray?, lstm_1_h_in_rev: MLMultiArray?, lstm_1_c_in_rev: MLMultiArray?, lstm_2_h_in: MLMultiArray?, lstm_2_c_in: MLMultiArray?, lstm_2_h_in_rev: MLMultiArray?, lstm_2_c_in_rev: MLMultiArray?) throws -> quickdrawOutput {
        let input_ = quickdrawInput(strokeSeq: strokeSeq, lstm_0_h_in: lstm_0_h_in, lstm_0_c_in: lstm_0_c_in, lstm_0_h_in_rev: lstm_0_h_in_rev, lstm_0_c_in_rev: lstm_0_c_in_rev, lstm_1_h_in: lstm_1_h_in, lstm_1_c_in: lstm_1_c_in, lstm_1_h_in_rev: lstm_1_h_in_rev, lstm_1_c_in_rev: lstm_1_c_in_rev, lstm_2_h_in: lstm_2_h_in, lstm_2_c_in: lstm_2_c_in, lstm_2_h_in_rev: lstm_2_h_in_rev, lstm_2_c_in_rev: lstm_2_c_in_rev)
        return try self.prediction(input: input_)
    }
}
