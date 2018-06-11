//
//  CVPixelBuffer+Extension.swift
//  ActionShot
//
//  Created by Joshua Newnham on 01/06/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit
import CoreImage

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
