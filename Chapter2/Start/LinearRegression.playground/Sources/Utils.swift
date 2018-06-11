import UIKit

/**
 Takes in 2 arrays and calcualtes the squared error between the two. Used by meanSquaredError.
 */
public func squaredError(y:[CGFloat], y_:[CGFloat]) -> CGFloat{
    if y.count != y_.count{
        return 0
    }
    
    let sumSqErr = Array(zip(y, y_)).map({ (a, b) -> CGFloat in
        return (a-b) * (a-b)
    }).reduce(0, { (res, a) -> CGFloat in
        return res + a
    })
    
    return sumSqErr
}

/*:
 In many cases; calculating the mean squared error provides us with a better gauge than absolute error for the reasons:
 - Avoid having the sign cancel out errors i.e. errors for 2 data points of-100 and 100 will result in an asbolute error of 0.
 - Prioritises large errors over small errors.
 */
public func meanSquaredError(y:[CGFloat], y_:[CGFloat]) -> CGFloat{
    if y.count != y_.count{
        return 0
    }
    
    return squaredError(y: y, y_: y_) / CGFloat(y.count)
}

/**
 function to plot line given a scatter plot view (where the line will be rendered), datapoints and model
 */
public func plotLine(view:ScatterPlotView, dataPoints:[DataPoint], model:(b:CGFloat, w:CGFloat), styleTag:String){
    // find the minX
    let minX = dataPoints.map({ (dp) -> CGFloat in
        return dp.x
    }).min()!
    // find the maxX
    let maxX = dataPoints.map({ (dp) -> CGFloat in
        return dp.x
    }).max()!
    
    // plot a line of best fit from minX to maxX using the linear equation
    // Y = b + w * X
    view.line(pointA: DataPoint(tag: styleTag,
                                x: minX,
                                y: model.b + minX * model.w),
              pointB: DataPoint(tag: styleTag,
                                x: maxX,
                                y: model.b + maxX * model.w))
}

/**
 load a .csv files and returns it's contents (string)
 */
public func loadCSV(file:String)-> String!{
    guard let filepath = Bundle.main.path(forResource: file, ofType: "csv") else{
        return nil
    }
    
    do{
        let contents = try String(contentsOfFile: filepath)
        return contents
    } catch{
        print("Failed to load file \(filepath)")
        return nil
    }
}

/**
 'normalize' the carriage return
 */
func cleanRows(contents:String) -> String{
    var cleanContents = contents
    
    cleanContents = cleanContents.replacingOccurrences(of: "\r", with: "\n")
    cleanContents = cleanContents.replacingOccurrences(of: "\n\n", with: "\n")
    
    return cleanContents
}

/**
 given the contents of a csv file; return an array of columns and their associated rows
 */
public func parseCSV(contents:String, delimiter:String=",", firstRowIsColumnHeaders:Bool=true) -> [String:[CGFloat]]{
    
    var columnTitles : [String]?
    var data = [String:[CGFloat]]()
    
    let rows = cleanRows(contents:contents).components(separatedBy:"\n")
    if rows.count > 0{
        if firstRowIsColumnHeaders{
            columnTitles = rows.first!.components(separatedBy:delimiter)
            
            for i in 0..<columnTitles!.count{
                if columnTitles![i].characters.count == 0{
                    columnTitles![i] = "index"
                }
                
                data[columnTitles![i]] = [CGFloat]()
            }
        }
        
        for row in rows{
            let rowValues = row.components(separatedBy:delimiter)
            // no columns exists so create a placeholder index for each column
            if columnTitles == nil{
                columnTitles = [String]()
                for i in 0..<rowValues.count{
                    columnTitles?.append("\(i)")
                    data[columnTitles![i]] = [CGFloat]()
                }
            }
            
            if rowValues.count != columnTitles!.count{
                continue
            }
            
            for i in 0..<columnTitles!.count{
                if let rowValue = Float(rowValues[i]){
                    data[columnTitles![i]]?.append(CGFloat(rowValue))
                } else{
                    data[columnTitles![i]]?.append(CGFloat(0.0))
                }
            }
        }
    }
    
    return data
}

/**
 convert a loaded and parsed csv (via parseCSV) file into an array of type DataPoint 
 */
public func extractDataPoints(data:[String:[CGFloat]], xKey:String, yKey:String, tag:String="default") -> [DataPoint] {
    var dataPoints = [DataPoint]()
    
    for i in 0..<data[yKey]!.count{
        dataPoints.append(DataPoint(tag: tag, x: CGFloat(data[xKey]![i]), y: CGFloat(data[yKey]![i])))
    }
    
    return dataPoints
}
