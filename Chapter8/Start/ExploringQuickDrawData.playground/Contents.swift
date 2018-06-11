/*:
 ### Start: Preprocessing for QuickDraw Data
 */
import UIKit
import PlaygroundSupport
import CoreML

/*:
 We will be using a small subset of the [ndjson])https://github.com/maxogden/ndjson) of some of the files from the QuickData dataset.
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
 parsing the JSON files so we can preview them (*NB: this is for explorational purposes only and we won't be porting this across to our application*)
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
 of this function is mainly concerned with rescaling and centering the sketch to the view (for presentation purposes).
 This function will instantiate an instance of SketchView which includes the re-scaled
 and re-centered sketch (of which we can preview)
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
 ## START HERE
 */

