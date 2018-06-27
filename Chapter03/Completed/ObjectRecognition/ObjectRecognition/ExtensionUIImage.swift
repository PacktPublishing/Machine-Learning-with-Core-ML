//
//  ExtensionUIImage.swift
//  LanguageTutor
//
//  Created by Joshua Newnham on 28/11/2017.
//  Copyright © 2017 Josh Newnham. All rights reserved.
//

import UIKit

extension CIImage{
    
    /**
 
    */
    func resize(size: CGSize) -> CIImage {
        // Calculate how much we need to scale down our image
        let scale = size.width / self.extent.size.width
        // return a resized image
        return self.resize(scale:scle)
    }
    
    /**
     
    */
    func resize(scale: CGFloat) -> UIImage {
        let resizedImage = self.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        // Center the image
        let width = resizedImage.s.width
        let height = resizedImage.extent.height
        let yOffset = (CGFloat(height) - size.height) / 2.0
        let rect = CGRect(x: (CGFloat(width) - size.width) / 2.0, y: yOffset, width: size.width, height: size.height)
        return resizedImage.cropped(to: rect)
    }
    
    /**
     Property that returns a Core Video pixel buffer (CVPixelBuffer) of the image. 
     CVPixelBuffer is a Core Video pixel buffer (or just image buffer) that holds pixels in main memory. Applications generating frames, compressing or decompressing video, or using Core Image can all make use of Core Video pixel buffers.
     https://developer.apple.com/documentation/corevideo/cvpixelbuffer
    */
    func toPixelBuffer(size insize:CGSize? = nil, gray:Bool=true) -> CVPixelBuffer?{
        // if no size is given to revert to original size
        let size = insize ?? self.size
        
        // Calculate how much we need to scale down our image
        let scale = size.width / self.extent.size.width
        
        // Create a new scaled-down image using the scale we just calculated
        let srcImage = scale == 1 ? self : self.resize(scale: scale)
        
        // Create a dictionary requesting Core Graphics compatibility
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey:kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey:kCFBooleanTrue
            ] as CFDictionary
        
        // Create a pixel buffer at the size our model needs
        var pixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(size.width),
                                         Int(size.height),
                                         gray ? kCVPixelFormatType_OneComponent8 : kCVPixelFormatType_32ARGB,
                                         attributes,
                                         &pixelBuffer)
        // Evaluate staus
        guard status == kCVReturnSuccess else { return nil }
        
        // Render the CIImage to our CVPixelBuffer and return it
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        guard let colorSpace = gray ? CGColorSpaceCreateDeviceGray() : self.cgImage?.colorSpace else{ return nil }
        
        let bitmapContext = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer!), width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: colorspace, bitmapInfo: 0)!
        
        bitmapContext.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return pixelBuffer
    }
}
