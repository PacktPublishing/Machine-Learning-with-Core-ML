import UIKit


public func train(x:Matrix, y:Matrix, learnignRate:CGFloat=0.001, epochs:Int=500) -> Matrix{
    
    let inputSize : Int = x.cols // input into our network will be the number of pixels (28x28 -> 784)
    let outputSize : Int = y.cols // number of labels (0-9 -> 10)
    // create weights vector
    var w = Matrix(rows:inputSize, cols:outputSize) // 1 because we are training one instance at a time
    
    // initilise the weights
    for r in 0..<w.rows{
        for c in 0..<w.cols{
            w[r,c] = CGFloat(Float(arc4random()) / Float(UINT32_MAX) * 0.01)
        }
    }
    
    for epoch in 0..<epochs{
        
        var error : CGFloat = 0.0
        var correctCnt : Int = 0
        
        for i in 0..<x.rows{
            let yInstance = y.row(index: i)
            
            // forward
            let layer0 = x.row(index: i) // our input layer aka pixels of our image
            //let layer1 = layer0 * w // our output layer aka prediction
            let layer1 = sigmoid(layer0 * w)
            
            // backwards - update weights
            //let layer1Delta = yInstance - layer1
            let layer1Delta = sigmoid(yInstance - layer1, deriv: true)
            
            w += (layer0.transpose() * layer1Delta) * learnignRate
            
            // calculate the error (error squared)
            let errorSum = (yInstance - layer1).sum()
            error += errorSum  * errorSum
            
            // calculate how many we have right
            let layer1Max = layer1.data.max() ?? 0
            let yHat = layer1.data.indices.filter {layer1.data[$0] == layer1Max }
            let yInstanceMax = yInstance.data.max() ?? 0
            let Y = yInstance.data.indices.filter {yInstance.data[$0] == yInstanceMax }
            correctCnt += Y == yHat ? 1 : 0
        }
        
        let mse = error / CGFloat(x.rows)
        
        if epoch % 20 == 0 || epoch == epochs-1{
            print("Epoch: \(epoch), Mean Squared Error: \(mse), Correct Predictions: \(correctCnt)")
        }
    }
    
    return w
}

public func predict(x:Matrix, w:Matrix) -> (prob:Matrix, pred:Int){
    let logits = x * w
    let prob = softmax(logits)
    
    // find the matrix
    let probMax = prob.data.max() ?? 0
    let pred = prob.data.indices.filter {prob.data[$0] == probMax }[0]
    
    return (prob:prob, pred:pred)
}

public func sigmoid(_ mat:Matrix, deriv:Bool=false) -> Matrix{
    var result = mat.copy()
    
    for r in 0..<result.rows{
        for c in 0..<result.cols{
            result[r, c] = deriv
                ? result[r, c] * (1 - result[r, c])
                : 1.0 / (1.0 + exp(-result[r, c]))
        }
    }
    
    return result
}

public func softmax(_ mat:Matrix, t:CGFloat=1.0) -> Matrix {
    var result = mat.copy()
    result.data = result.data.map({ (v) -> CGFloat in
        return exp(v)
    })
    
    let sum = result.sum()
    
    for r in 0..<result.rows{
        for c in 0..<result.cols{
            result[r, c] = result[r, c] / sum
        }
    }
    
    return result
}

public func relu(_ mat:Matrix) -> Matrix{
    var result = mat.copy()
    
    for r in 0..<result.rows{
        for c in 0..<result.cols{
            result[r, c] = result[r, c] < 0
                ? 0
                : result[r, c]
        }
    }
    
    return result
}
