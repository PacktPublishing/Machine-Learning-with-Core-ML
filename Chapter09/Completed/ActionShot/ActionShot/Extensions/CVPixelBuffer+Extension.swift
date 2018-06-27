//
//  CVPixelBuffer+Extension.swift
//  ActionShot
//
//  Created by Joshua Newnham on 01/06/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit
import CoreImage
import Accelerate

extension CVPixelBuffer{
    
    func toByteArray() -> [UInt8]{
        CVPixelBufferLockBaseAddress(self, .readOnly)
        let height = CVPixelBufferGetHeight(self)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        let data = CVPixelBufferGetBaseAddress(self)!
        
        let output = Data(bytes: data, count: height * bytesPerRow)
        let pixelArray = output.map { (pixel) -> UInt8 in
            return pixel
        }
        
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        
        return pixelArray
    }
    
    func toCGImage() -> CGImage?{
        CVPixelBufferLockBaseAddress(self, .readOnly)
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        let data = CVPixelBufferGetBaseAddress(self)!
        
        let numberOfChannels = Int(height/bytesPerRow)
        
        let outContext = CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: numberOfChannels > 1 ?
                CGColorSpaceCreateDeviceRGB() :
                CGColorSpaceCreateDeviceGray(),
            bitmapInfo: numberOfChannels > 1 ?
                (CGImageByteOrderInfo.order32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue) :
                CGImageByteOrderInfo.orderDefault.rawValue)!
        let outImage = outContext.makeImage()!
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        
        return outImage
    }
    
    func toCIImage() -> CIImage?{
        guard let cgImage = self.toCGImage() else{
            return nil
        }
        
        return CIImage(cgImage: cgImage)
    }
}

extension CVPixelBuffer{
    
    func clone() -> CVPixelBuffer?{
        CVPixelBufferLockBaseAddress(self, .readOnly)
        
        guard let srcData = CVPixelBufferGetBaseAddress(self) else {
            print("Failed to get pixel buffer base address")
            return nil
        }
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        let pixelFormat = CVPixelBufferGetPixelFormatType(self)
        
        guard let destData = malloc(height * bytesPerRow) else {
            print("Out of memory")
            return nil
        }
        
        memcpy(destData, srcData, height * bytesPerRow)
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        
        let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
            if let ptr = ptr {
                free(UnsafeMutableRawPointer(mutating: ptr))
            }
        }
        
        var dstPixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreateWithBytes(nil, width, height,
                                                  pixelFormat, destData,
                                                  bytesPerRow, releaseCallback,
                                                  nil, nil, &dstPixelBuffer)
        if status != kCVReturnSuccess {
            print("Failed to create new pixel buffer")
            free(destData)
            return nil
        }
        return dstPixelBuffer
    }
    
}
