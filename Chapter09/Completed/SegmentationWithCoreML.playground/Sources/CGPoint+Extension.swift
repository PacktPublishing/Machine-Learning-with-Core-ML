import UIKit

public extension CGPoint{
    
    public var length : CGFloat{
        get{
            return sqrt(self.x * self.x + self.y * self.y)
        }
    }
    
    public var normalised : CGPoint{
        get{
            return CGPoint(x: self.x/self.length, y: self.y/self.length)
        }
    }
    
    public func distance(other:CGPoint) -> CGFloat{
        let dx = (self.x - other.x)
        let dy = (self.y - other.y)
        
        return sqrt(dx*dx + dy*dy)
    }
    
    public static func -(left: CGPoint, right: CGPoint) -> CGPoint{
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
}
