//
//  DateExtension.swift
//  QuickDrawRNN
//
//  Created by Joshua Newnham on 19/02/2018.
//  Copyright © 2018 PacktPub. All rights reserved.
//

import Foundation

extension Date {
    
    /**
     Get the current time, in milliseconds, since 1970 (Unix)
    */
    static var timestamp:Int {
        get{
            return Int((Date().timeIntervalSince1970 * 1000.0).rounded())
        }
    }
    
    /**
     Instantiate the Date given a timestamp (since 1970)
    */
    init(timestamp:Int) {
        self = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
    }
}
