import UIKit

/**
 Data structure for a 2D Matrix
 */
struct Matrix<T : Numeric>{
    public var data:Array<T>
    
    public var rows: Int
    public var cols: Int
    
    public var shape : (Int,Int){
        get{
            return (rows, cols)
        }
    }
    
    public init(_ data:Array<Array<T>>) {
        self.data = data.flatMap { $0 }
        self.rows = data.count
        self.cols = data[0].count
    }
    
    public init(_ data:Array<T>, rows:Int, cols:Int) {
        self.data = data
        self.rows = rows
        self.cols = cols
    }
    
    public init(rows:Int, cols:Int) {
        self.data = Array<T>(repeating: 0, count: rows*cols)
        self.rows = rows
        self.cols = cols
    }
    
    public subscript(row: Int, col: Int) -> T {
        get {
            return data[(row * cols) + col]
        }
        set {
            self.data[(row * cols) + col] = newValue
        }
    }
    
    public subscript(row: Int) -> Matrix {
        get {
            return self.row(index: row)
        }
    }
    
    public func row(index:Int) -> Matrix {
        var r = [T]()
        for col in 0..<cols {
            r.append(self[index,col])
        }
        return Matrix(r, rows:1, cols:r.count)
    }
    
    public func col(index:Int) -> Matrix {
        var c = [T]()
        for row in 0..<rows {
            c.append(self[row,index])
        }
        return Matrix(c, rows:c.count, cols:1)
    }
    
    public func copy(with zone: NSZone? = nil) -> Matrix {
        return Matrix(self.data, rows:self.rows, cols:self.cols)
    }
}

extension Matrix: CustomStringConvertible {
    
    public var description: String {
        var dsc = ""
        for row in 0..<rows {
            for col in 0..<cols {
                let s = String(describing:self[row,col])
                dsc += s + " "
            }
            dsc += "\n"
        }
        return dsc
    }
}

func applyKernel<T>(image:Matrix<T>, kernel:Matrix<T>) -> Matrix<T>{
    var results = [[T]]()
    
    for r in 0..<image.rows{
        if r-1 < 0 || r+1 >= image.rows{
            continue
        }
        results.append([T]())
        for c in 0..<image.cols{
            if c-1 < 0 || c+1 >= image.cols{
                continue
            }
            
            var sum : T = 0
            
            for r2 in [-1, 0, 1]{
                for c2 in [-1, 0, 1]{
                    var pixel = image[r+r2, c+c2]
                    var kernelValue = kernel[r2+1, c2+1]
                    sum += pixel * kernelValue
                }
            }
            
            results[results.count-1].append(sum)
        }
    }
    
    return Matrix(results)
}
