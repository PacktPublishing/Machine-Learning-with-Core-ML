import UIKit

public typealias Vector = [CGFloat]

public extension Array where Element == CGFloat {
    
    public func sum() -> CGFloat{
        return self.reduce(0, {$0 + $1})
    }
    
    static public func +(left: [CGFloat], right: [CGFloat]) -> [CGFloat] {
        precondition(left.count == right.count)
        
        var v = [CGFloat](repeatElement(0.0, count: left.count))
        for i in 0..<left.count {
            v[i] = left[i] + right[i]
        }
        
        return v
    }
    
    static public func -(left: [CGFloat], right: [CGFloat]) -> [CGFloat] {
        precondition(left.count == right.count)
        
        var v = [CGFloat](repeatElement(0.0, count: left.count))
        for i in 0..<left.count {
            v[i] = left[i] - right[i]
        }
        
        return v
    }
}

public class Matrix{
    public var data:Array<CGFloat>
    
    public var rows: Int
    public var cols: Int
    
    public var shape : (Int,Int){
        get{
            return (rows, cols)
        }
    }
    
    public init(_ data:Array<Array<CGFloat>>) {
        self.data = data.flatMap { $0 }
        self.rows = data.count
        self.cols = data[0].count 
    }
    
    public init(_ data:Array<CGFloat>, rows:Int, cols:Int) {
        self.data = data
        self.rows = rows
        self.cols = cols
    }
    
    public init(rows:Int, cols:Int) {
        self.data = [CGFloat](repeating: 0.0, count: rows*cols)
        self.rows = rows
        self.cols = cols
    }
    
    public subscript(row: Int, col: Int) -> CGFloat {
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
        var r = [CGFloat]()
        for col in 0..<cols {
            r.append(self[index,col])
        }
        return Matrix(r, rows:1, cols:r.count)
    }
    
    public func col(index:Int) -> Matrix {
        var c = [CGFloat]()
        for row in 0..<rows {
            c.append(self[row,index])
        }
        return Matrix(c, rows:c.count, cols:1)
    }
    
    public func copy(with zone: NSZone? = nil) -> Matrix {
        return Matrix(self.data, rows:self.rows, cols:self.cols)
    }
}

/**
 Operations
 */
extension Matrix{
    
    public func transpose() -> Matrix{
        let t = Matrix(rows:self.cols, cols:self.rows)
        for row in 0..<self.rows {
            for col in 0..<self.cols {
                t[col,row] = self[row,col]
            }
        }
        return t
    }
    
    /**
     Aggregation operation; return the total sum of the matrix as a scalar
     */
    public func sum() -> CGFloat{
        return self.data.reduce(0, {$0 + $1})
    }
    
    static public func +(left: Matrix, right: Matrix) -> Matrix {
        precondition(left.rows == right.rows && left.cols == right.cols)
        
        let m = Matrix(left.data, rows: left.rows, cols: left.cols)
        for row in 0..<left.rows {
            for col in 0..<left.cols {
                m[row,col] += right[row,col]
            }
        }
        return m
    }
    
    static public func +=(left: Matrix, right: Matrix) -> Matrix {
        precondition(left.rows == right.rows && left.cols == right.cols)
        
        let m = left
        for row in 0..<left.rows {
            for col in 0..<left.cols {
                m[row,col] += right[row,col]
            }
        }
        return m
    }
    
    static public func -(left: Matrix, right: Matrix) -> Matrix {
        precondition(left.rows == right.rows && left.cols == right.cols)
        
        let m = Matrix(left.data, rows: left.rows, cols: left.cols)
        
        for row in 0..<left.rows {
            for col in 0..<left.cols {
                m[row,col] -= right[row,col]
            }
        }
        return m
    }
    
    static public func -=(left: Matrix, right: Matrix) -> Matrix {
        precondition(left.rows == right.rows && left.cols == right.cols)
        
        let m = left
        for row in 0..<left.rows {
            for col in 0..<left.cols {
                m[row,col] -= right[row,col]
            }
        }
        return m
    }
    
    static public func ==(left:Matrix, right:Matrix) -> Bool {
        if left.rows != right.rows {
            return false
        }
        if left.cols != right.cols {
            return false
        }
        for i in 0..<left.rows {
            for j in 0..<left.cols {
                if left[i,j] != right[i,j] {
                    return false
                }
            }
        }
        return true
    }
    
    static public func *(left:Matrix, right:Matrix) -> Matrix {
        
        var lcp = left.copy()
        var rcp = right.copy()
        
        if (lcp.rows == 1 && rcp.rows == 1) && (lcp.cols == rcp.cols) { // exception for single row matrices (inspired by numpy)
            rcp = rcp.transpose()
        }
        else if (lcp.cols == 1 && rcp.cols == 1) && (lcp.rows == rcp.rows) { // exception for single row matrices (inspired by numpy)
            lcp = lcp.transpose()
        }
        
        precondition(lcp.cols == rcp.rows, "Failed to multiply matrices")
        
        let dot = Matrix(rows:lcp.rows, cols:rcp.cols)
        
        for i in 0..<lcp.rows {
            for j in 0..<rcp.cols {
                let lcpRow = lcp.row(index: i)
                let rcpCol = rcp.col(index: j)
                
                precondition(lcpRow.data.count == rcpCol.data.count, "Failed to multiply matrices")
                
                var sum : CGFloat = 0
                
                for k in 0..<lcpRow.data.count {
                    sum += lcpRow.data[k] * rcpCol.data[k]
                }
                
                dot[i,j] = sum
            }
        }
        return dot
    }
    
    static public func *(left:Matrix, right:Vector) -> Matrix {
        
        let mat = left.copy()
        let vec = right
        
        precondition(mat.cols == vec.count, "Failed to multiply matrices")
        
        let result = Matrix(rows:mat.rows, cols:1)
        
        for i in 0..<mat.rows {
            let matRow = mat.row(index: i)
            
            var sum : CGFloat = 0
            
            for j in 0..<matRow.data.count{
                sum += matRow.data[j] * vec[j]
            }
            
            result[0,i] = sum
        }
        
        return result
    }
    
    static public func *(left:Vector, right:Matrix) -> Matrix {
        
        let vec = left
        let mat = right.copy()
        
        precondition(mat.cols == vec.count, "Failed to multiply matrices")
        
        let result = Matrix(rows:mat.rows, cols:1)
        
        for i in 0..<mat.rows {
            let matRow = mat.row(index: i)
            
            var sum : CGFloat = 0
            
            for j in 0..<matRow.data.count{
                sum += matRow.data[j] * vec[j]
            }
            
            result[0,i] = sum
        }
        
        return result
    }
    
    static public func *(left:Matrix, scalar:CGFloat) -> Matrix {
        
        let result = left.copy()
        
        for r in 0..<result.rows{
            for c in 0..<result.cols{
                result[r,c] = result[r,c] * scalar
            }
        }
        
        return result
    }
}

extension Matrix: CustomStringConvertible {
    
    public var description: String {
        var dsc = ""
        for row in 0..<rows {
            for col in 0..<cols {
                let s = String(format: "%.1f", self[row,col])
                dsc += s + " "
            }
            dsc += "\n"
        }
        return dsc
    }
}
