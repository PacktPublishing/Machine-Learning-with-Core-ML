import CreateML
import Foundation

let trainingDir = URL(fileURLWithPath: "PATH TO TRAINING DATA")

let model = try MLImageClassifier(
    trainingData: .labeledDirectories(at: trainingDir))

let validationDir = URL(fileURLWithPath: "PATH TO VALIDATION DATA")

model.evaluation(on: .labeledDirectories(at: validationDir))

let strawberryUrl = URL(
    fileURLWithPath: "<PATH TO EXAMPLE STRAWBERRY IMAGE>")

print(try model.prediction(from: strawberryUrl))

try model.write(toFile: "<PATH TO FILE>")

MLModelMetadata(

/*
import CreateMLUI

let builder = MLImageClassifierBuilder()
builder.showInLiveView()
*/
