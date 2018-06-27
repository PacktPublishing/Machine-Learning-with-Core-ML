/*:
 ### Completed: Preprocessing for QuickDraw Data
 */
import UIKit
import PlaygroundSupport
import CoreML

/*:
 We will be using a small subset of the [ndjson](https://github.com/maxogden/ndjson) files for the airplane raw and simplified. The main dif
 */

/*:
 The format of a raw sample is:
 {
 "key_id":"5891796615823360",
 "word":"nose",
 "countrycode":"AE",
 "timestamp":"2017-03-01 20:41:36.70725 UTC",
 "recognized":true,
 "drawing":[[[129,128,129,129,130,130,131,132,132,133,133,133,133,...]]]
 }
 
 Where drawing is broken into:
 [
    [  // First stroke
    [x0, x1, x2, x3, ...],
    [y0, y1, y2, y3, ...],
    [t0, t1, t2, t3, ...]
 ],
    [  // Second stroke
    [x0, x1, x2, x3, ...],
    [y0, y1, y2, y3, ...],
    [t0, t1, t2, t3, ...]
 ],
    ... // Additional strokes
 ]
 
 The simplified version includes all the meta-data with the following adjustments
 made to the drawing path(s):
 - Align the drawing to the top-left corner, to have minimum values of 0.
 - Uniformly scale the drawing, to have a maximum value of 255.
 - Resample all strokes with a 1 pixel spacing.
 - Simplify all strokes using the [Ramer–Douglas–Peucker algorithm](https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm) with an epsilon value of 2.0.
- Remove time
 */

/*:
 Let's extend our StrokeSketch class to include a method for handling
 parsing the JSON files so we can preview them
 */
extension StrokeSketch{
    
    static func createFromJSON(json:[String:Any]?) -> StrokeSketch?{
        guard let json = json else{
            return nil
        }
        
        let sketch = StrokeSketch()
        
        if let tmp = json["word"] as? String{
            sketch.label = tmp
        }
        
        if let points = json["drawing"] as? Array<Array<Array<Float>>>{
            for strokePoints in points{
                var stroke : Stroke?
                
                for xyPair in zip(strokePoints[0], strokePoints[1]){
                    let point = CGPoint(x:CGFloat(xyPair.0),
                                        y:CGFloat(xyPair.1))
                    
                    if let stroke = stroke{
                        stroke.points.append(point)
                    } else{
                        stroke = Stroke(startingPoint: point)
                    }
                }
                
                if let stroke = stroke, stroke.points.count > 0{
                    sketch.addStroke(stroke: stroke)
                }
            }
        }
        
        return sketch
    }
}

/*:
 Next we want to create a function to render a given sketch - the task
 of this function is mainly concerned with rescaling and centering the sketch to the view.
 This function will instantiate an instance of SketchView which includes the re-scaled and re-centered sketch (of which we can preview)
 */
func drawSketch(sketch:Sketch) -> SketchView{
    let viewDimensions : CGFloat = 600
    // get bounding box
    let bbox = sketch.boundingBox
    
    // scale to fit into view
    if max(bbox.size.width,bbox.size.height) > viewDimensions{
        sketch.scale = viewDimensions / max(bbox.size.width,bbox.size.height)
    }
    
    // Center sketch in view (we take into account that the bounds have been scaled
    // therefore must inverse this by 'scaling up' i.e. 1.0 - sketch.scale;
    // the reason for this is that the points are transformed relative to their current
    // position (using the 'bounds' which is affected by the scale we set above)
    sketch.center = CGPoint(x:(viewDimensions - bbox.size.width * (1.0-sketch.scale)) / 2.0,
                            y:(viewDimensions - bbox.size.height * (1.0-sketch.scale)) / 2.0)
    
    // Instantiate the SketchView
    let sketchView = SketchView(frame: CGRect(
        x: 0, y: 0, width: viewDimensions, height: viewDimensions))
    
    // Now add our sketch to the sketches and nudge the view to update itself
    sketchView.sketches.append(sketch)
    sketchView.setNeedsDisplay()
    
    return sketchView
}

/*:
 Next we will load our category extracts (50 samples) that we have trained our model on; initially we will be focusing on small_raw_airplane.json and small_simplified_airplane.json before validating against the other categories.
 */

var dataFiles = [
    "small_raw_airplane",
    "small_raw_alarm_clock",
    "small_raw_angel",
    "small_raw_apple",
    "small_raw_bee",
    "small_raw_sailboat",
    "small_raw_train",
    "small_raw_truck",
    "small_simplified_airplane"
]

var loadedJSON = [String:[Any]]()

for dataFile in dataFiles{
    do{
        if let fileUrl = Bundle.main.url(
            forResource: "data/\(dataFile)",
            withExtension: "json"){
            
            if let data = try? Data(contentsOf: fileUrl){
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [Any]
                loadedJSON[dataFile] = json
            }
        }
    } catch{
        fatalError(error as! String)
    }
}

/*:
 Let's peek at some of the sketches we have; we will first preview the sketches from the
 raw dataset and then the simplified
 */

if let rJson = loadedJSON["small_raw_airplane"],
    let sJson = loadedJSON["small_simplified_airplane"]{
    
    if let rSketch = StrokeSketch.createFromJSON(json: rJson[0] as? [String:Any]),
        let sSketch = StrokeSketch.createFromJSON(json: sJson[0] as? [String:Any]){
        drawSketch(sketch: rSketch)
        drawSketch(sketch: sSketch)
    }
    
    if let rSketch = StrokeSketch.createFromJSON(json: rJson[1] as? [String:Any]),
        let sSketch = StrokeSketch.createFromJSON(json: sJson[1] as? [String:Any]){
        drawSketch(sketch: rSketch)
        drawSketch(sketch: sSketch)
    }
    
    if let rSketch = StrokeSketch.createFromJSON(json: rJson[2] as? [String:Any]),
        let sSketch = StrokeSketch.createFromJSON(json: sJson[2] as? [String:Any]){
        drawSketch(sketch: rSketch)
        drawSketch(sketch: sSketch)
    }
}

/*:
 The model has been based on the tensorflow tutorial [Recurrent Neural Networks for Drawing Classification](https://www.tensorflow.org/tutorials/recurrent_quickdraw) which speculates (and dictates) how the data needs to be prepared.
 The first is that the training samples were taken from the simplified dataset; therefore we must apply the same pre-processing steps on the user input as was performed on the raw training data (as listed above).
 Secondly; the tutorial (and therefore model) introduced a further step before feeding the data into the model; this included:
 - Introduce another dimension to indicate if a point is the end of not
 - Size normalization i.e. such that the minimum stroke point is 0 (on both axis) and maximum point is 1.0.
 - Compute deltas; the model was trained on deltas rather than absolutes positions
 */

/*:
 We will tackle each of these in turn; starting with the simplification pre-process; our litmus test will be to take a sample from the raw dataset and re-created the simplified equivalent.
 */

public extension StrokeSketch{
    
    /**
     - Align the drawing to the top-left corner, to have minimum values of 0.
     - Uniformly scale the drawing, to have a maximum value of 255.
     - Resample all strokes with a 1 pixel spacing.
     - Simplify all strokes using the [Ramer–Douglas–Peucker algorithm](https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm) with an epsilon value of 2.0.
    */
    public func simplify() -> StrokeSketch{
        let copy = self.copy() as! StrokeSketch
        copy.scale = 1.0

        let minPoint = copy.minPoint
        let maxPoint = copy.maxPoint
        let scale = CGPoint(x: maxPoint.x-minPoint.x, y:maxPoint.y-minPoint.y)

        var width : CGFloat = 255.0
        var height : CGFloat = 255.0

        // adjust aspect ratio
        if scale.x > scale.y{
            height *= scale.y/scale.x
        } else{
            width *= scale.y/scale.x
        }
        
        // for each point, subtract the min and divide by the max
        for i in 0..<copy.strokes.count{
            copy.strokes[i].points = copy.strokes[i].points.map({ (pt) -> CGPoint in
                // Normalise point and then scale based on adjusted dimension above
                // (also casting to an Int then back to a CGFloat to get 1 pixel precision)
                let x : CGFloat = CGFloat(Int(((pt.x - minPoint.x)/scale.x) * width))
                let y : CGFloat = CGFloat(Int(((pt.y - minPoint.y)/scale.y) * height))
                
                return CGPoint(x:x, y:y)
            })
        }
        
        // perform line simplification
        copy.strokes = copy.strokes.map({ (stroke) -> Stroke in
            return stroke.simplify()
        })

        return copy
    }
}

/*:
 Line simplification using Ramer–Douglas–Peucker algorithm;
 https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm
 https://commons.wikimedia.org/wiki/File%3ADouglas-Peucker_animated.gif
 */
public extension Stroke{
    
    /**
     Perform line simplification using Ramer-Douglas-Peucker algorithm
    */
    public func simplify(epsilon:CGFloat=3.0) -> Stroke{
        
        var simplified: [CGPoint] = [self.points.first!]
        
        self.simplifyDPStep(points: self.points,
                            first: 0, last: self.points.count-1,
                            tolerance: epsilon * epsilon,
                            simplified: &simplified)
        
        simplified.append(self.points.last!)
        
        let copy = self.copy() as! Stroke
        copy.points = simplified
        
        return copy
    }
    
    func simplifyDPStep(points:[CGPoint], first:Int, last:Int,
                        tolerance:CGFloat, simplified: inout [CGPoint]){
        
        var maxSqDistance = tolerance
        var index = 0
        
        for i in first + 1..<last{
            let sqDist = CGPoint.getSquareSegmentDistance(
                p0: points[i],
                p1: points[first],
                p2: points[last])
            
            if sqDist > maxSqDistance {
                maxSqDistance = sqDist
                index = i
            }
        }
        
        if maxSqDistance > tolerance{
            if index - first > 1 {
                simplifyDPStep(points: points,
                               first: first,
                               last: index,
                               tolerance: tolerance,
                               simplified: &simplified)
            }
            
            simplified.append(points[index])
            
            if last - index > 1{
                simplifyDPStep(points: points,
                               first: index,
                               last: last,
                               tolerance: tolerance,
                               simplified: &simplified)
            }
        }
    }
}

public extension CGPoint{
    
    public static func getSquareSegmentDistance(p0:CGPoint, p1:CGPoint, p2:CGPoint) -> CGFloat{
        let x0 = p0.x, y0 = p0.y
        var x1 = p1.x, y1 = p1.y
        let x2 = p2.x, y2 = p2.y
        var dx = x2 - x1
        var dy = y2 - y1
        
        if dx != 0.0 && dy != 0.0{
            let numerator = (x0 - x1) * dx + (y0 - y1) * dy
            let denom = dx * dx + dy * dy
            let t =  numerator / denom
            
            if t > 1.0{
                x1 = x2
                y1 = y2
            } else{
                x1 += dx * t
                y1 += dy * t
            }
        }
        
        dx = x0 - x1
        dy = y0 - y1
        
        return dx * dx + dy * dy
    }
}

/*:
 Let's have another peek - this time comparing our simplification to that of the simplified dataset
 */

if let rJson = loadedJSON["small_raw_airplane"],
    let sJson = loadedJSON["small_simplified_airplane"]{
    if let rSketch = StrokeSketch.createFromJSON(json: rJson[0] as? [String:Any]),
        let sSketch = StrokeSketch.createFromJSON(json: sJson[0] as? [String:Any]){
        drawSketch(sketch: rSketch)
        drawSketch(sketch: sSketch)
        drawSketch(sketch: rSketch.simplify())
    }
    
    if let rSketch = StrokeSketch.createFromJSON(json: rJson[1] as? [String:Any]),
        let sSketch = StrokeSketch.createFromJSON(json: sJson[1] as? [String:Any]){
        drawSketch(sketch: rSketch)
        drawSketch(sketch: sSketch)
        drawSketch(sketch: rSketch.simplify())
    }
    
    if let rSketch = StrokeSketch.createFromJSON(json: rJson[2] as? [String:Any]),
        let sSketch = StrokeSketch.createFromJSON(json: sJson[2] as? [String:Any]){
        drawSketch(sketch: rSketch)
        drawSketch(sketch: sSketch)
        drawSketch(sketch: rSketch.simplify())
    }
}

/*:
 Let's now handle the final piece of pre-processing, as used in training, which requires the following steps:
 - Introduce another dimension to indicate if a point is the end of not
 - Size normalization i.e. such that the minimum stroke point is 0 (on both axis) and maximum point is 1.0.
 - Compute deltas; the model was trained on deltas rather than absolutes positions
 */

extension StrokeSketch{
    
    public static func preprocess(_ sketch:StrokeSketch) -> MLMultiArray?{
        let arrayLen = NSNumber(value:75 * 3) // flattened (75,3) tensor

        let simplifiedSketch = sketch.simplify()
        
        // Create our MLMultiArray to store the results
        guard let array = try? MLMultiArray(shape: [arrayLen],
                                            dataType: .double)
            else{ return nil }
        
        
        // Flatten all points into a single array and:
        // a. Normalise
        // b. Append our EOS (End Of Stroke) flag
        let minPoint = simplifiedSketch.minPoint
        let maxPoint = simplifiedSketch.maxPoint
        let scale = CGPoint(x: maxPoint.x-minPoint.x, y:maxPoint.y-minPoint.y)
        
        var data = Array<Double>()
        for i in 0..<simplifiedSketch.strokes.count{
            for j in 0..<simplifiedSketch.strokes[i].points.count{
                let point = simplifiedSketch.strokes[i].points[j]
                let x = (point.x-minPoint.x)/scale.x
                let y = (point.y-minPoint.y)/scale.y
                let z = j == simplifiedSketch.strokes[i].points.count-1 ? 1 : 0
                
                data.append(Double(x))
                data.append(Double(y))
                data.append(Double(z))
            }
        }
        
        // compute the deltas (nb; each sample has a stride of 3)
        let dataStride : Int = 3
        for i in stride(from: dataStride, to:data.count, by: dataStride){
            data[i - dataStride] = data[i] - data[i - dataStride] // delta x
            data[i - (dataStride-1)] = data[i+1] - data[i - (dataStride-1)] // delta y
            data[i - (dataStride-2)] = data[i+2] // EOS
        }
        
        // remove the last sample
        data.removeLast(3)
        
        // Pad (to the end) and copy our flattened array to the array
        var dataIdx : Int = 0
        let startAddingIdx = max(array.count-data.count, 0)
        
        for i in 0..<array.count{
            if i >= startAddingIdx{
                array[i] = NSNumber(value:data[dataIdx])
                dataIdx = dataIdx + 1
            } else{
                array[i] = NSNumber(value:0)
            }
        }
        
        return array
    }
}


// Let's now test our model out
let model = quickdraw()

if let json = loadedJSON["small_raw_airplane"]{
    if let sketch = StrokeSketch.createFromJSON(json: json[0] as? [String:Any]){
        if let x = StrokeSketch.preprocess(sketch){
            if let predictions = try? model.prediction(input:quickdrawInput(strokeSeq:x)){
                print("Class label \(predictions.classLabel)")
                print("Class label probability/confidence \(predictions.classLabelProbs["airplane"] ?? 0)")
            }
        }
    }
}

// Let's now test with the other cateogies; we will create a function to handle making
// a prediction given a file and index

func makePrediction(key:String, index:Int) -> String{
    if let json = loadedJSON[key]{
        if let sketch = StrokeSketch.createFromJSON(
            json: json[index] as? [String:Any]){
            if let x = StrokeSketch.preprocess(sketch){
                if let predictions = try? model.prediction(input:quickdrawInput(strokeSeq:x)){
                    return "\(predictions.classLabel) \(predictions.classLabelProbs[predictions.classLabel] ?? 0)"
                }
            }
        }
    }
    
    return "None"
}

print(makePrediction(key: "small_raw_airplane", index: 0))
print(makePrediction(key: "small_raw_alarm_clock", index: 1))
print(makePrediction(key: "small_raw_bee", index: 2))
print(makePrediction(key: "small_raw_sailboat", index: 3))
print(makePrediction(key: "small_raw_train", index: 4))
print(makePrediction(key: "small_raw_truck", index: 5))
print(makePrediction(key: "small_simplified_airplane", index: 6))

/*:
 Last test; let's see how prediction performs during the progression of a drawing
 */

if let json = loadedJSON["small_raw_bee"]{
    if let sketch = StrokeSketch.createFromJSON(json: json[2] as? [String:Any]){
        let strokeCount = sketch.strokes.count
        print("\(sketch.label ?? "" ) sketch has \(strokeCount) strokes")
        
        // let's build up the sketch and perform prediction after each additional
        // stroke
        for i in (0..<strokeCount-1).reversed(){
            let copyOfSketch = sketch.copy() as! StrokeSketch
            copyOfSketch.strokes.removeLast(i)
            if let x = StrokeSketch.preprocess(copyOfSketch){
                if let predictions = try? model.prediction(input:quickdrawInput(strokeSeq:x)){
                    let label = predictions.classLabel
                    let probability = String(format: "%.2f", predictions.classLabelProbs[predictions.classLabel] ?? 0)
                    
                    print("Guessing \(label) with probability of \(probability) using \(copyOfSketch.strokes.count) strokes")
                }
            }
        }
    }
}
