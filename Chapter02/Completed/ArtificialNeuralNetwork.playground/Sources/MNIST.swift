import UIKit

/**
 http://yann.lecun.com/exdb/mnist/
 */
public class MNIST{
    
    public static func loadData(limit:UInt32=UInt32.max) -> (labels:[UInt8], images:[[UInt8]]){
        let labels_ = MNIST.loadLabels(limit:limit)
        let images_ = MNIST.loadImages(limit:limit)
        
        guard let labels = labels_, let images = images_ else{
            return (labels:[UInt8](), images:[[UInt8]]())
        }
        
        return (labels:labels, images:images)
    }
    
    /**
     Headering description
     0000     32 bit integer  0x00000801(2049) magic number (MSB first)
     0004     32 bit integer  60000            number of items
     0008     unsigned byte   ??               label
     0009     unsigned byte   ??               label
     */
    static func loadLabels(limit:UInt32=UInt32.max) -> [UInt8]?{
        guard let filepath = Bundle.main.path(forResource: "t10k-labels-idx1-ubyte", ofType: "bin") else{
            return nil
        }
        
        guard let data = NSData(contentsOfFile: filepath) else{
            return nil
        }
        
        var labels = [UInt8]()
        
        var location = 0
        
        var value32 : UInt32 = 0
        var value8 : UTF8Char = 0
        let size32 = MemoryLayout<UInt32>.size
        let size8 = MemoryLayout<UInt8>.size
        
        // magic number
        data.getBytes(&value32, range: NSRange(location: location, length:size32))
        let _ = UInt32(bigEndian: value32)
        location += size32
        
        // number of observations
        data.getBytes(&value32, range: NSRange(location: location, length:size32))
        let numberOfObservations = UInt32(bigEndian: value32)
        location += size32
        
        // labels
        for _ in 0..<min(numberOfObservations, limit){
            data.getBytes(&value8, range: NSRange(location: location, length:size8))
            labels.append(value8)
            
            location += size8
        }
        
        
        return labels
    }
    
    /**
     Header description
     0000     32 bit integer  0x00000803(2051) magic number
     0004     32 bit integer  60000            number of images
     0008     32 bit integer  28               number of rows
     0012     32 bit integer  28               number of columns
     0016     unsigned byte   ??               pixel
     0017     unsigned byte   ??               pixel
     ........
     xxxx     unsigned byte   ??               pixel
     Pixels are organized row-wise. Pixel values are 0 to 255. 0 means background (white), 255 means foreground (black).
     */
    static func loadImages(limit:UInt32=UInt32.max) -> [[UInt8]]?{
        guard let filepath = Bundle.main.path(forResource: "t10k-images-idx3-ubyte", ofType: "bin") else{
            return nil
        }
        
        guard let data = NSData(contentsOfFile: filepath) else{
            return nil
        }
        
        var pixelRows = [[UInt8]]()
        
        var location = 0
        
        var value32 : UInt32 = 0
        var value8 : UTF8Char = 0
        let size32 = MemoryLayout<UInt32>.size
        let size8 = MemoryLayout<UInt8>.size
        
        // magic number
        data.getBytes(&value32, range: NSRange(location: location, length:size32))
        let _ = UInt32(bigEndian: value32)
        location += size32
        
        // number of observations
        data.getBytes(&value32, range: NSRange(location: location, length:size32))
        let numberOfObservations = UInt32(bigEndian: value32)
        location += size32
        
        // number of observations
        data.getBytes(&value32, range: NSRange(location: location, length:size32))
        let rows = UInt32(bigEndian: value32)
        location += size32
        
        // number of observations
        data.getBytes(&value32, range: NSRange(location: location, length:size32))
        let cols = UInt32(bigEndian: value32)
        location += size32
        
        for _ in 0..<min(numberOfObservations, limit){
            var pixels = [UInt8]()
            
            for _ in 0..<cols*rows{
                data.getBytes(&value8, range: NSRange(location: location, length:size8))
                // invert the pixel i.e. we want 255 for on (white) and 0 to be off (black)
                pixels.append(value8)
                location += size8
            }
            
            pixelRows.append(pixels)
        }
        
        return pixelRows
    }
}

extension MNIST{
    
    static public func splitData(labels:[UInt8], images:[[UInt8]], split:Float=0.8) -> ([[CGFloat]], [[CGFloat]], [[CGFloat]], [[CGFloat]]){
        let sampleSize : Int = labels.count
        let trainSize : Int = Int(Float(sampleSize) * split)
        
        // We need to 'one-hot encode' the labels such that the label 7 will be represented as [0,0,0,0,0,0,0,1,0,0]
        // (and similarly 1 would be encoded as [0,1,0,0,0,0,0,0,0,0]). We do his becuase we are creating a 'model'
        // for each digit and selecting the one with the highest probability
        let y = labels.map({ (label) -> [CGFloat] in
            var encodedLabel = Array<CGFloat>(repeating: 0.0, count: 10)
            encodedLabel[Int(label)] = 1.0
            return encodedLabel
        })
        
        // split our labels into training and testing
        let trainY = y[0..<trainSize]
        let testY = y[trainSize..<y.count]
        
        // lets normalise the digits; covnerting 0-255 to 0-1.0
        let x = images.map({ (image) -> [CGFloat] in
            return image.map({ (pixel) -> CGFloat in
                return CGFloat(pixel) / 255.0
            })
        })
        
        // as we did before, split our images into training and test
        let trainX = x[0..<trainSize]
        let testX = x[trainSize..<x.count]
        
        return (Array(trainX), Array(trainY), Array(testX), Array(testY))
    }
}
