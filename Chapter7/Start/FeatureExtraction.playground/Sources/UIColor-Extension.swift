import UIKit

/**
 Simple extension of the color
 */
extension UIColor {
    
    public convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat=1.0) {
        
        self.init(red: CGFloat(red)/255,
                  green: CGFloat(green)/255,
                  blue: CGFloat(blue)/255,
                  alpha: alpha)
    }
    
    public func getComponents() -> (r:CGFloat, g:CGFloat, b:CGFloat, a:CGFloat) {
        if (cgColor.numberOfComponents == 2) {
            let cc = cgColor.components!
            return (r:cc[0], g:cc[0], b:cc[0], a:cc[1])
        }
        else {
            let cc = cgColor.components!
            return (r:cc[0], g:cc[1], b:cc[2], a:cc[3])
        }
    }
    
    public static func lerp(start:UIColor, end: UIColor, t: CGFloat) -> UIColor {
        var tt = max(0, t)
        tt = min(1, t)
        
        let c1 = start.getComponents()
        let c2 = end.getComponents()
        
        let r = c1.r + (c2.r - c1.r) * tt
        let g = c1.g + (c2.g - c1.g) * tt
        let b = c1.b + (c2.b - c1.b) * tt
        let a = c1.a + (c2.a - c1.a) * tt
        
        return UIColor.init(red: r, green: g, blue: b, alpha: a)
    }
}
