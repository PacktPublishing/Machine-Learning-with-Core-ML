import UIKit

extension CGRect{
    
    public var center : CGPoint{
        get{
            return CGPoint(x: self.origin.x + self.size.width/2,
                           y: self.origin.y + self.size.height/2)
        }
    }
}
