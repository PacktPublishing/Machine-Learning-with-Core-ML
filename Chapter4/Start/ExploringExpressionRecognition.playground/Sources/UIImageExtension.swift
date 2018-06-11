import UIKit

public extension UIImage{
    
    public var colorSpace : CGColorSpace?{
        get{
            return self.cgImage?.colorSpace
        }
    }
    
    /**
     Property that returns a Core Video pixel buffer (CVPixelBuffer) of the image.
     CVPixelBuffer is a Core Video pixel buffer (or just image buffer) that holds pixels in main memory. Applications generating frames, compressing or decompressing video, or using Core Image can all make use of Core Video pixel buffers.
     https://developer.apple.com/documentation/corevideo/cvpixelbuffer
     */
    public func toPixelBuffer(verticalFlip:Bool = true, gray:Bool=true) -> CVPixelBuffer?{
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        
        // Create a dictionary requesting Core Graphics compatibility
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
        
        // Create a pixel buffer at the size our model needs
        var nullablePixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            gray ? kCVPixelFormatType_OneComponent8 : kCVPixelFormatType_32ARGB,
            attributes as CFDictionary, &nullablePixelBuffer)
        
        // Evaluate staus and unwrap nullablePixelBuffer
        guard status == kCVReturnSuccess, let pixelBuffer = nullablePixelBuffer else {
            return nil
        }
        
        // Render the CIImage to our CVPixelBuffer and return it
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let imageData =  CVPixelBufferGetBaseAddress(pixelBuffer)
        
        guard let context = CGContext(
            data: imageData,
            width: width,
            height:height,
            bitsPerComponent: gray ? 8 : 32,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: gray ? CGColorSpaceCreateDeviceGray()
                : self.colorSpace ?? CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
                return nil
        }
        
        // Flip
        if verticalFlip{
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1, y: -1)
        }
        
        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x:0, y:0, width: width, height: height) )
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}
