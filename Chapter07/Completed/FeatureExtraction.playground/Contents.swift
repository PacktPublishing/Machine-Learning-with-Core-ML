//: (Completed) Playground to explore feature extraction

import UIKit
import Accelerate
import CoreML

let histogramViewFrame = CGRect(
    x: 0, y: 0,
    width: 600, height: 300)

let heatmapViewFrame = CGRect(
    x: 0, y: 0,
    width: 600, height: 600)

// CoreML model responsible for extracting features from a given sketch
let sketchFeatureExtractor = cnnsketchfeatureextractor()
// Size of our expected network inputs
let targetSize = CGSize(width: 256, height: 256)
// Context used for rendering
let context = CIContext()

/**
 Create an CIImage and passes to extractFeaturesFromImage(:CIImage)
 */
func extractFeaturesFromImage(image:UIImage) -> MLMultiArray?{
    guard let image = CIImage(
        image: image) else{
        return nil
    }
    
    return extractFeaturesFromImage(image: image)
}

/**
 Extract the features from a given image; this is done by running
 it through our modified network (sketch classification model with
 it's last layer removed)
 */
func extractFeaturesFromImage(image:CIImage) -> MLMultiArray?{
    // obtain the CVPixelBuffer from the image
    guard let imagePixelBuffer = image.resize(
        size: targetSize)
        .rescalePixels()?
        .toPixelBuffer(context: context,
                       gray: true) else {
        return nil
    }

    // extract features from the image which we we compare each image with
    guard let features = try? sketchFeatureExtractor.prediction(
        image: imagePixelBuffer) else{
        return nil
    }

    return features.classActivations
}

// Arrays to hold the images and extracted features
var images = [UIImage]()
var imageFeatures = [MLMultiArray]()
// Load all images and extract their features
for i in 1...6{
    guard let image = UIImage(named:"images/cat_\(i).png"),
        let features = extractFeaturesFromImage(image:image) else{
            fatalError("Failed to extract features")
    }
    
    images.append(image)
    imageFeatures.append(features)
}

// Inspect the images and their features

// cat front view
let img1 = images[0]
let hist1 = HistogramView(frame:histogramViewFrame, data:imageFeatures[0])

let img2 = images[1]
let hist2 = HistogramView(frame:histogramViewFrame, data:imageFeatures[1])

// cat head
let img3 = images[2]
let hist3 = HistogramView(frame:histogramViewFrame, data:imageFeatures[2])

let img4 = images[3]
let hist4 = HistogramView(frame:histogramViewFrame, data:imageFeatures[3])

// cats side view
let img5 = images[4]
let hist5 = HistogramView(frame:histogramViewFrame, data:imageFeatures[4])

let img6 = images[5]
let hist6 = HistogramView(frame:histogramViewFrame, data:imageFeatures[5])

// Let's now measure the distance between each of these images

// We will use the cosine distance to calculate the similarity between
// features

/**
 Calculate the cosine distance between 2 vectors (the extracted features from the images)
 */
func cosineSimilarity(vecA: MLMultiArray, vecB: MLMultiArray) -> Double {
    return 1.0 - dot(vecA:vecA, vecB:vecB) / (magnitude(vec: vecA) * magnitude(vec: vecB))
}

/**
 Calculates the dot product of 2 vectors (arrays); utilising Accelerate vDSP (vector digital signal processing) functions for parallel processing.
 https://developer.apple.com/documentation/accelerate/1450313-vdsp_dotpr?language=objc
 */
func dot(vecA: MLMultiArray, vecB: MLMultiArray) -> Double {
    guard vecA.shape.count == 1 && vecB.shape.count == 1 else{
        fatalError("Expecting vectors (tensor with 1 rank)")
    }
    
    guard vecA.count == vecB.count else {
        fatalError("Excepting count of both vectors to be equal")
    }
    
    let count = vecA.count
    let vecAPtr = UnsafeMutablePointer<Double>(OpaquePointer(vecA.dataPointer))
    let vecBPptr = UnsafeMutablePointer<Double>(OpaquePointer(vecB.dataPointer))
    var output: Double = 0.0
    
    vDSP_dotprD(vecAPtr, 1, vecBPptr, 1, &output, vDSP_Length(count))
    
    var x: Double = 0
    
    for i in 0..<vecA.count{
        x += vecA[i].doubleValue * vecB[i].doubleValue
    }
    
    return x
}

/**
 Calcualtes the magnitude of a vector utilising the Acclerate frameworks vDSP (vector digital signal processing) functions.
 https://developer.apple.com/documentation/accelerate/1450862-vdsp_svsd?language=objc
 */
func magnitude(vec: MLMultiArray) -> Double {
    guard vec.shape.count == 1 else{
        fatalError("Expecting a vector (tensor with 1 rank)")
    }
    
    let count = vec.count
    let vecPtr = UnsafeMutablePointer<Double>(OpaquePointer(vec.dataPointer))
    var output: Double = 0.0
    vDSP_svsD(vecPtr, 1, &output, vDSP_Length(count))
    
    return sqrt(output)
}

// Lets calculate the distance between each of the images
var similarities = Array(repeating: Array(repeating: 0.0, count: images.count), count: images.count)

for i in 0..<imageFeatures.count{
    for j in 0..<imageFeatures.count{
        let sim = cosineSimilarity(
            vecA: imageFeatures[i],
            vecB: imageFeatures[j])
        similarities[i][j] = sim
    }
}

let heatmap = HeatmapView(
    frame:heatmapViewFrame,
    images:images,
    data:similarities)

