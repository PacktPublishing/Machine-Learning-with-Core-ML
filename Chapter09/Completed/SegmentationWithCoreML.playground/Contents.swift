import UIKit
import Vision
import AVFoundation
import CoreVideo
import CoreML
import CoreImage
import PlaygroundSupport
import XCPlayground

// Required to run tasks in the background
PlaygroundPage.current.needsIndefiniteExecution = true

/**
 Extracts frames from a video file
 
 - Parameters:
    - url: Path to video file
    - framesPerSecond: number of frames to extract per second
 
 - Returns: An array of extracted frames from the video
 */
func extractFrames(url:URL, framesPerSecond:Int=4) -> [UIImage]{
    print("Extracting frames from \(url)")
    var frames = [UIImage]()
    
    let asset = AVAsset(url: url)
    
    // Calculate now long and now frequently we sample along
    // with a variable to track the time for the current frame
    let duration = asset.duration
    let tick = 1.0 / Double(framesPerSecond)
    var currentTime : Double = 0.0
    
    // Create a generator which we'll use to extract the frames
    let generator = AVAssetImageGenerator.init(asset: asset)
    generator.requestedTimeToleranceAfter = CMTime.zero
    generator.requestedTimeToleranceBefore = CMTime.zero
    
    // Loop through extracting the frames
    while currentTime < duration.getSeconds(){
        
        do {
            let cgImage = try generator.copyCGImage(
                at: CMTime.init(seconds: currentTime,
                                preferredTimescale: asset.duration.timescale),
                actualTime: nil)
            
            frames.append(UIImage(cgImage: cgImage))
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
        }
        
        currentTime += tick
    }
    
    print("Extracted \(frames.count) frames")
    
    return frames
}

/**
 Use our UNet model to create masks from the given frames
 
 - Parameters:
 - frames: Frames to perform segmentation and extract the **mask**
 
 - Returns: (If successful) a array of tuples when the resized original (to match the
            mask) and mask
 */
func createMasksFromFrames(frames:[UIImage]) -> [(source:UIImage, mask:UIImage)]{
    // We will use a ColorKernel to create a binary mask
    // from the generate image of the model (predicated values, from the model,
    // are between 0.0 - 1.0; here we're mapping anything greater than 0 to 1.0
    // so we can easily see the mask for each frame.
    let kernelString = """
            kernel vec4 binaryFilter(__sample mask)
            {
                if(mask.r > 0.0){
                    return vec4(1.0, 1.0, 1.0,1.0);
                }
                
                return vec4(0.0, 0.0, 0.0, 0.0);
            }
        """
    guard let binraryKernel = CIColorKernel(source:kernelString) else{
        return []
    }
    
    // Size we need to resize our images to to feed the model
    let targetSize = CGSize(width: 448, height: 448)
    
    // Create our the results from the model
    var results = [(source:UIImage, mask:UIImage)]()
    
    if #available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *) {
        
        // Create an instance of our model to perform segmentation
        // (wrapping it in VNCoreMLModel so we can leverage the Vision framework)
        guard let model = try? VNCoreMLModel(
            for: small_unet().model
            ) else{
            return results
        }
        
        // Create the request responsible for the pre-processing and
        // interfacing with the model
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .centerCrop
        
        // Iterate through each frame; passing them into our model
        for frame in frames{
            // Resize; VNCoreMLRequest would typically handle this but we
            // are wanting to return the image and mask pair back to the caller
            // and having them the same size
            let ciImage = CIImage(image: frame)
            
            guard let croppedAndResizedFrame = ciImage?.centerCropAndResize(size:targetSize)
                else{ continue }
            
            // Create the handler to perform the inference
            let handler = VNImageRequestHandler(ciImage: croppedAndResizedFrame)
            
            do {
                // Perform inference
                try handler.perform([request])
            } catch {
                continue
            }
            
            // Get the result from our model and convert it to a CIImage to pass to our
            // filter and then append to our results array
            if let pixelBufferObservations = request.results as? [VNPixelBufferObservation]{
                if let ciImage = pixelBufferObservations[0].pixelBuffer.toCIImage(){
                    let extent = ciImage.extent
                    let arguments = [ciImage] as [Any]
                    if let binaryFrame = binraryKernel.apply(
                        extent: extent,
                        arguments: arguments){
                        if let croppedAndResizedUIImage = croppedAndResizedFrame.toUIImage(),
                            let maskUIImage = binaryFrame.toUIImage(){
                            results.append(
                                (source:croppedAndResizedUIImage, mask:maskUIImage)
                            )
                        }
                    }
                }
            }
        }
    }
    
    return results
}

/**
 Return cropped frames using their associated masks
 
 - Parameters:
 - frames: Source frames for cropping
 - masks: Binary images where a value of 1.0 indicates cropping region otherwise
            it's ignored
 
 - Returns: An array cropped frames
 */
func cropFramesWithMasks(frames:[UIImage], masks:[UIImage]) -> [UIImage]{
    var results = [UIImage]()
    
    // Create the kernel responsible for cropping the frames
    let kernelString = """
            kernel vec4 thresholdFilter(__sample image, __sample mask)
            {
                if(mask.r > 0.0){
                    return vec4(image.rgb, 1.0);
                }
                
                return vec4(0.0, 0.0, 0.0, 0.0);
            }
        """
    guard let maskKernel = CIColorKernel(source:kernelString) else{
        return results
    }
    
    // Iterate through all frames
    for i in 0..<frames.count{
        // Convert the frame and mask to CIImage's
        guard let frame = CIImage(image: frames[i]),
            let mask = CIImage(image: masks[i]) else{
                continue
        }
        
        let extent = frame.extent
        let arguments = [frame, mask] as [Any]
        
        // Pass the frame and mask to the filter and add the result to the results to be
        // returned
        if let segmentedFrame = maskKernel.apply(extent: extent, arguments: arguments){
            if let uiImage = segmentedFrame.toUIImage(){
                results.append(uiImage)
            }
        }
    }
    
    return results
}

/**
 Using the image blobs of the mask - find the dominant direction; i.e.
 Find the center of mass of a blob (via the bounding box) from the start and end
 frames. Use this to calculate the dominant direction
 
 - Parameters:
 - masks: Mask images
 - minMaskArea: Must occupy an area larger than a percentage of the actual frame; this value
    represent that *percentage*
 
 - Returns: Normalised point vector indicating the dominant direction
 */
func getDominantDirection(masks:[UIImage], minMaskArea:CGFloat = 0.005) -> CGPoint{
    var dir = CGPoint(x: 0, y: 0)
    
    // Convert masks (UIImage) to CIImage's
    let ciImageMasks = masks.map({ (mask) -> CIImage in
        guard let ciImage = CIImage(image: mask) else{
            fatalError("Failed to convert UIImage to CIImage")
        }
        
        return ciImage
    })
    
    //  Create some placeholder variables
    var startIdx : Int = 0
    var startCenter : CGPoint?
    var endCenter : CGPoint?
    
    // Find startCenter
    for i in 0..<ciImageMasks.count{
        let mask = ciImageMasks[i]
        
        guard let maskBB = mask.getContentBoundingBox(),
            (maskBB.width * maskBB.height) >=
                (mask.extent.width * mask.extent.height) * minMaskArea
            else {
                continue
        }
        
        startCenter = maskBB.center
        startIdx = i
        break
    }
    
    // Find endCenter
    for i in (startIdx..<ciImageMasks.count).reversed(){
        let mask = ciImageMasks[i]
        
        guard let maskBB = mask.getContentBoundingBox(),
            (maskBB.width * maskBB.height) >=
                (mask.extent.width * mask.extent.height) * minMaskArea
            else {
                continue
        }
        
        endCenter = maskBB.center
        break
    }
    
    // Calculate the direction
    if let startCenter = startCenter, let endCenter = endCenter, startCenter != endCenter{
        dir = (endCenter - startCenter).normalised
    }
    
    return dir
}

/**
 Iterate through each mask (in the direction of the dominant direction) to
 find candiate frames (frames which doesn't overlap)
 
 - Parameters:
 - masks: Mask images
 - dir: Dominant direction
 - minMaskArea: Must occupy an area larger than a percentage of the actual frame; this value
 represent that *percentage*
 
 - Returns: An array of indicies of the candiate frames
 */
func getCandiateFrameIndicies(masks:[UIImage], dir:CGPoint, minMaskArea:CGFloat = 0.005) -> [Int]{
    guard masks.count > 1 else{
        return [0]
    }
    
    // Convert masks (UIImage) to CIImage's
    let ciImageMasks = masks.map({ (mask) -> CIImage in
        guard let ciImage = CIImage(image: mask) else{
            fatalError("Failed to convert UIImage to CIImage")
        }
        
        return ciImage
    })
    
    var selectedIndicies = [Int]()
    
    var previousBoundingBox : CGRect?
    
    // Assume the last frame is the 'Hero' frame i.e. work backwards
    for i in (0..<ciImageMasks.count).reversed(){
        let mask = ciImageMasks[i]
        
        // Ignore any frame with the subject doesn't dominate the image
        guard let maskBB = mask.getContentBoundingBox(),
            (maskBB.width * maskBB.height) >= (mask.extent.width * mask.extent.height) * minMaskArea
            else {
                continue
        }
        
        if previousBoundingBox == nil{
            previousBoundingBox = maskBB
            selectedIndicies.append(i)
        } else{
            // Test that displacement is greater than 1/2 directional size
            let distance = abs(dir.x) >= abs(dir.y)
                ? abs(previousBoundingBox!.center.x - maskBB.center.x)
                : abs(previousBoundingBox!.center.y - maskBB.center.y)
            let bounds = abs(dir.x) >= abs(dir.y)
                ? (previousBoundingBox!.width + maskBB.width) / 2.0
                : (previousBoundingBox!.height + maskBB.height) / 2.0
            
            // Add threshold to allow for overlap and account for
            // padding
            if distance > bounds * 0.15{
                previousBoundingBox = maskBB
                selectedIndicies.append(i)
            }
        }
        
    }
    
    return selectedIndicies.reversed()
}

/**
 Finally put it all together; using the frames, masks and candiate indicies - create a
 composited image
 
 - Parameters:
 - masks: Mask images
 - frames: Frame images
 - candiateFrames: Candiate frames obtained from the function getCandiateFrameIndicies
 
 - Returns: An composited image
 */
func compositeFrames(masks:[UIImage], frames:[UIImage], candiateFrames:[Int]) -> UIImage?{
    let kernelString = """
            kernel vec4 compositeFilter(
                __sample image,
                __sample overlay,
                __sample overlay_mask,
                float alpha){
                float overlayStrength = 0.0;

                if(overlay_mask.r > 0.0){
                    overlayStrength = 1.0;
                }

                overlayStrength *= alpha;
                
                return vec4(image.rgb * (1.0-overlayStrength), 1.0)
                    + vec4(overlay.rgb * (overlayStrength), 1.0);
            }
        """
    guard let compositeKernel = CIColorKernel(source:kernelString) else{
        return nil
    }
    
    // Convert the UIImage to CIImages (mask)
    let ciImageMasks = masks.map({ (mask) -> CIImage in
        guard let ciImage = CIImage(image: mask) else{
            fatalError()
        }
        
        return ciImage
    })
    
    // Convert the UIImage to CIImages (frame)
    var ciImageFrames = frames.map({ (frame) -> CIImage in
        guard let ciImage = CIImage(image: frame) else{
            fatalError()
        }
        
        return ciImage
    })
    
    // Iterate through all indicies compositing the final image
    var finalImage = ciImageFrames.last!
    ciImageFrames.removeLast()
    
    let alphaStep : CGFloat = 1.0 / CGFloat(ciImageFrames.count)
    
    for i in candiateFrames{
        let image = ciImageFrames[i]
        let mask = ciImageMasks[i]
        
        let extent = image.extent
        let alpha = CGFloat(i + 1) * alphaStep
        let arguments = [finalImage, image, mask, min(alpha, 1.0)] as [Any]
        if let compositeFrame = compositeKernel.apply(extent: extent, arguments: arguments){
            finalImage = compositeFrame
        }
    }
    
    return finalImage.toUIImage()
}

// Get reference to your mov file
// ADD YOUR MOV FILE TO THE RESOURCES FOLDER AND ASSIGN THE FILENAME TO THE moveFileName variable
let movFileName = "Motion-Still-2018-07-29_B"

guard let videoURL = Bundle.main.url(forResource: movFileName, withExtension: "MOV") else{
    fatalError("Missing file")
}

// 1. Get the frames from the video
let frames = extractFrames(url: videoURL)

// 2. Create the masks from each frame
let framesAndMasks = createMasksFromFrames(frames: frames)

// 3. Extract segment from the frameAndMasks tuple array
let segmentedFrames = cropFramesWithMasks(
    frames: framesAndMasks.map({ (frameMaskPair) -> UIImage in
        return frameMaskPair.source
    }), masks: framesAndMasks.map({ (frameMaskPair) -> UIImage in
        return frameMaskPair.mask
    }))

// 4. Get dominate direction
let dominantDirection = getDominantDirection(masks: framesAndMasks.map({ (frameMaskPair) -> UIImage in return frameMaskPair.mask }))
print("Dominant direction \(dominantDirection)")

// 5. Get candiate frames
let candiateFrames = getCandiateFrameIndicies(masks: framesAndMasks.map({ (frameMaskPair) -> UIImage in
    return frameMaskPair.mask
}), dir:dominantDirection)
print("Candiate frames \(candiateFrames)")

// 6 . Composite frame
let compositeFrame = compositeFrames(
    masks: framesAndMasks.map({ (frameMaskPair) -> UIImage in
        return frameMaskPair.mask
    }),
    frames: framesAndMasks.map({ (frameMaskPair) -> UIImage in
        return frameMaskPair.source
    }),
    candiateFrames: candiateFrames)
