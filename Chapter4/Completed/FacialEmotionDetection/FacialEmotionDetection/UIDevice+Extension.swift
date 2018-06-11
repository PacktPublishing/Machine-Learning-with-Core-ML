//
//  UIDevice+Extension.swift
//  FacialEmotionDetection
//
//  Created by Joshua Newnham on 09/06/2018.
//  Copyright © 2018 PacktPub. All rights reserved.
//

import UIKit

extension UIDevice{
    
    private func exifOrientationForDeviceOrientation(_ deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
        
        switch deviceOrientation {
        case .portraitUpsideDown:
            return .rightMirrored
            
        case .landscapeLeft:
            return .downMirrored
            
        case .landscapeRight:
            return .upMirrored
            
        default:
            return .leftMirrored
        }
    }
    
    var exifOrientationForCurrentDeviceOrientation : CGImagePropertyOrientation {
        get{
            return exifOrientationForDeviceOrientation(UIDevice.current.orientation)
        }
    }
    
}
