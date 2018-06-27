import UIKit

/**
 Point to display on the plot
 */
public struct DataPoint{
    public var tag : String = "default"
    public var x : CGFloat = 0
    public var y : CGFloat = 0
    
    public init(tag:String="default", x:CGFloat=0, y:CGFloat=0){
        self.x = x
        self.y = y
        self.tag = tag
    }
}
