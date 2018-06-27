import UIKit


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

func cleanRows(contents:String) -> String{
    var cleanContents = contents
    
    cleanContents = cleanContents.replacingOccurrences(of: "\r", with: "\n")
    cleanContents = cleanContents.replacingOccurrences(of: "\n\n", with: "\n")
    
    return cleanContents
}

/**
 
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

public func extractDataPoints(data:[String:[CGFloat]], xKey:String, yKey:String, tag:String="default") -> [DataPoint] {
    var dataPoints = [DataPoint]()
    
    for i in 0..<data[yKey]!.count{
        dataPoints.append(DataPoint(tag: tag, x: CGFloat(data[xKey]![i]), y: CGFloat(data[yKey]![i])))
    }
    
    return dataPoints
}
