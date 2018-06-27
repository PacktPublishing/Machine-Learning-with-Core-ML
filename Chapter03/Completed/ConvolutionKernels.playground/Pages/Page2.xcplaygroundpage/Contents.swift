//: Playground - noun: a place where people can play

/*
 
 https://developer.apple.com/library/content/documentation/GraphicsImaging/Reference/CIKernelLangRef/Introduction/Introduction.html
 */

import UIKit
import PlaygroundSupport

// Create the view to present our digit
var imageView = UIImageView(frame:CGRect(
    x: 0, y: 0,
    width: 200, height: 200))
// Set the scale mode to fill the view size while repsecting
// it's aspect ratio
imageView.contentMode = .scaleAspectFill

// Methods for creating our kernels

func applyKernel(image:UIImage,
                 kernelFunc:()->CIKernel?,
                 insetBy:CGSize = CGSize(width: -1, height: -1)) -> CIImage?{
    guard let kernel = kernelFunc() else { return nil }
    guard let inputImage = CIImage(image:image) else { return nil }
    
    let args = [inputImage as AnyObject]
    let dod = inputImage.extent.insetBy(dx: insetBy.width, dy: insetBy.height)
    
    return kernel.apply(extent: dod, roiCallback: { (index, rect) -> CGRect in
        return rect.insetBy(dx: -1, dy: -1)
    }, arguments: args)
}

func createHorizontalKernel() -> CIKernel? {
    let kernelString =
        "kernel vec4 hKernel (sampler image) {\n" +
            "  mat3 kernelMat = mat3( -1, -1, -1, 2, 2, 2, -1, -1, -1 );\n" +
            "  float runningTotal = 0.0;\n" +
            "  vec2 dc = destCoord();\n" +
            "  for (int i=-1; i <= 1; i++) {\n" +
            "    for (int j=-1; j <= 1; j++) {\n" +
            "      vec4 currentSample = sample(image, samplerTransform(image, dc + vec2(i,j)));" +
            "      runningTotal += kernelMat[j+1][i+1] * currentSample.r;\n" +
            "    }\n" +
            "  }\n" +
            "  return vec4(runningTotal, runningTotal, runningTotal, 1.0);\n" +
    "}"
    return CIKernel(source: kernelString)
}

func createVerticalKernel() -> CIKernel? {
    let kernelString =
        "kernel vec4 vKernel (sampler image) {\n" +
            "  mat3 kernelMat = mat3( -1, 2, -1, -1, 2, -1, -1, 2, -1 );\n" +
            "  float runningTotal = 0.0;\n" +
            "  vec2 dc = destCoord();\n" +
            "  for (int i=-1; i <= 1; i++) {\n" +
            "    for (int j=-1; j <= 1; j++) {\n" +
            "      vec4 currentSample = sample(image, samplerTransform(image, dc + vec2(i,j)));" +
            "      runningTotal += kernelMat[j+1][i+1] * currentSample.r;\n" +
            "    }\n" +
            "  }\n" +
            "  return vec4(runningTotal, runningTotal, runningTotal, 1.0);\n" +
    "}"
    return CIKernel(source: kernelString)
}

imageView.image = UIImage(named:"digit_0")

if let image = UIImage(named:"digit_0"){
    if let processedImage = applyKernel(image:image,
                                        kernelFunc: createHorizontalKernel,
                                        insetBy: CGSize(width: 0, height: 0)){
        
        imageView.image = UIImage(ciImage: processedImage)
    }
}



// Present the view controller in the Live View window
PlaygroundPage.current.liveView = imageView

