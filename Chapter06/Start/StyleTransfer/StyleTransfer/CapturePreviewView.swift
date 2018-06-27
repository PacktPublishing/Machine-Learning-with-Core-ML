//
//  CapturePreviewView.swift
//  StyleTransfer
//
//  Created by Joshua Newnham on 19/04/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit
import AVFoundation

class CapturePreviewView: UIView {
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
