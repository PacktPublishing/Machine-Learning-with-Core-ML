//
//  CIImage+Extension.swift
//  ObjectDetection
//
//  Created by Joshua Newnham on 02/06/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit

public extension CIImage{
    
    public func centerCrop(size:CGSize) -> CIImage?{
        let ox = (self.extent.width - size.width)/2
        let oy = (self.extent.height - size.height)/2
        
        return self.crop(rect: CGRect(
            x: ox, y: oy,
            width: size.width, height: size.height)
        ) 
    }
    
    func crop(rect:CGRect) -> CIImage?{
        let context = CIContext()
        guard let img = context.createCGImage(self, from: rect) else{
            return nil
        }
        return CIImage(cgImage: img)
    }
    
    /**
     Return a resized version of this instance (centered)
     */
    func resize(size: CGSize) -> CIImage {
        // Calculate how much we need to scale down/up our image
        let scale = min(size.width,size.height) / min(self.extent.size.width, self.extent.size.height)
        
        let resizedImage = self.transformed(
            by: CGAffineTransform(
                scaleX: scale,
                y: scale))
        
        // Center the image
        let width = resizedImage.extent.width
        let height = resizedImage.extent.height
        let xOffset = (CGFloat(width) - size.width) / 2.0
        let yOffset = (CGFloat(height) - size.height) / 2.0
        let rect = CGRect(x: xOffset,
                          y: yOffset,
                          width: size.width,
                          height: size.height)
        
        return resizedImage
            .clamped(to: rect)
            .cropped(to: CGRect(
                x: 0, y: 0,
                width: size.width,
                height: size.height))
    }
}

// MARK : Byte array accessors

extension CIImage{
    
    func toPixelBuffer() -> CVPixelBuffer?{
        let colorSpace = self.colorSpace ?? CGColorSpaceCreateDeviceGray()
        return self.toPixelBuffer(
            pixelFormatType:colorSpace.name == CGColorSpaceCreateDeviceGray().name
                ? kCVPixelFormatType_OneComponent8
                : kCVPixelFormatType_32ARGB,
            colorSpace: colorSpace)
    }
    
    /**
     Return the byte array data representation of itself
     */
    func toPixelBuffer(pixelFormatType: OSType, colorSpace: CGColorSpace) -> CVPixelBuffer?{
        let context = CIContext()
        
        // Create a dictionary requesting Core Graphics compatibility
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey:kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey:kCFBooleanTrue
            ] as CFDictionary
        
        // Create a pixel buffer at the size our model needs
        var nullablePixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(self.extent.size.width),
                                         Int(self.extent.size.height),
                                         pixelFormatType,
                                         attributes,
                                         &nullablePixelBuffer)
        
        // Evaluate staus and unwrap nullablePixelBuffer
        guard status == kCVReturnSuccess, let pixelBuffer = nullablePixelBuffer
            else { return nil }
        
        // Render the CIImage to our CVPixelBuffer and return it
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        context.render(self,
                       to: pixelBuffer,
                       bounds: CGRect(x: 0,
                                      y: 0,
                                      width: self.extent.size.width,
                                      height: self.extent.size.height),
                       colorSpace:colorSpace)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}
