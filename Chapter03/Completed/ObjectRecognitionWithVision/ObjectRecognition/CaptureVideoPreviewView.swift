//
//  CaptureVideoPreviewView.swift
//  LanguageTutor
//
//  Created by Joshua Newnham on 30/11/2017.
//  Copyright © 2017 Josh Newnham. All rights reserved.
//

import AVFoundation
import UIKit

class CapturePreviewView: UIView {
    
    /**
     Wrapping the AVCaptureVideoPreviewLayer layer inside a view to make it more convenient to work with
    */
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
