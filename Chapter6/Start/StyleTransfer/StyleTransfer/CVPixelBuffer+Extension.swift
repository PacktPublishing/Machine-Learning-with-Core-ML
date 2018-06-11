//
//  CVPixelBuffer+Extension.swift
//  StyleTransfer
//
//  Created by Joshua Newnham on 22/04/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit
import CoreImage

extension CVPixelBuffer{
    
    func toCGImage() -> CGImage?{
        CVPixelBufferLockBaseAddress(self, .readOnly)
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        let data = CVPixelBufferGetBaseAddress(self)!
        
        let outContext = CGContext(data: data,
                                   width: width,
                                   height: height,
                                   bitsPerComponent: 8,
                                   bytesPerRow: CVPixelBufferGetBytesPerRow(self),
                                   space: CGColorSpaceCreateDeviceRGB(),
                                   bitmapInfo: CGImageByteOrderInfo.order32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)!
        let outImage = outContext.makeImage()!
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        
        return outImage
    }
    
}
