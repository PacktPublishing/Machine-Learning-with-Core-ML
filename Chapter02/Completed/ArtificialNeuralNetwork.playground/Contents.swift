//: Playground - noun: a place where people can play
/*:
 In this Playground we explore one of the 'Hello World' examples for Machine Learning - the MNIST dataset. The MNIST data is composed of handwritten digits. The dataset consists of 60,000 training examples and 10,000 test examples. Each example is a fixed 28x28 single channel (gray) digit (0-9) that has been size-normalized and centered in a fixed-size image.
 
 This is considered a supervised multi-class classification problem, supervised because we have labels for each example and multi-class because we have 10 classes (0-9).
 
 It is comprised of 63 observations with 1 input variable and 1 output variable. The variable names are as follows:
 - Number of claims.
 - Total payment for all claims in thousands of Swedish Kronor.
 
 Further details can be found [here.](http://college.cengage.com/mathematics/brase/understandable_statistics/7e/students/datasets/slr/frames/slr06.html)
 The original dataset can be found [here.](https://www.math.muni.cz/~kolacek/docs/frvs/M7222/data/AutoInsurSweden.txt)
 */

// http://yann.lecun.com/exdb/mnist/

import UIKit
import PlaygroundSupport

// Create a view that we will use to render the digits (and their weights)
let view = DigitView(frame: CGRect(x: 20, y: 20, width: 500, height: 500))

// Load the data; limiting number to sampleSize
let sampleSize : UInt32 = 20

let dataset = MNIST.loadData(limit:sampleSize)

// Pull out a example we will use for demonstration purposes
let testLabel = 7
let testIndex = Int(dataset.labels.indices.filter({dataset.labels[$0] == UInt8(testLabel)})[0])

// lets display the first label and corresponding image
print("Displaying digital \(dataset.labels[testIndex])")
view.setPixels(pixels: dataset.images[testIndex])

let (trainX, trainY, testX, testY) = MNIST.splitData(labels:dataset.labels, images:dataset.images)

// wrap a matrix around the training
let x = Matrix(trainX)
let y = Matrix(trainY)

// train our model
let w = train(x: x, y: y, learnignRate: 0.005, epochs: 500)

// make a prediction
let (prob, pred) = predict(x: x.row(index: testIndex), w: w)

// prob => probabilities, pred => prediction i.e. the output with the highest probability
print(prob)
print(pred)

// lets now visualise these weights, first by obtaining the weights for a 
// specific label. Then we'll normalise it and multiple by 255 (pixel intensity range)
//let labelWeights = w.transpose().row(index: testIndex)
let labelWeights = w.transpose().row(index: testLabel)
let labelMaxWeight = labelWeights.data.max() ?? 0
let labelMinWeight = labelWeights.data.min() ?? 0
let weightPixels = labelWeights.data.map({ (w) -> UInt8 in
    // normalise
    let normalW = (w - labelMinWeight) / (labelMaxWeight - labelMinWeight)
    return UInt8(255 * normalW)
})

// update mode of view then pass on the new pixels 
view.mode = .heat
view.setPixels(pixels: weightPixels)


// Present the view controller in the Live View window
PlaygroundPage.current.liveView = view
