/*:
Here we are using the Swedish Auto Insurance Dataset; a regression problem that involves predicting the total payment for all claims in thousands of Swedish Kronor, given the total number of claims.

It is comprised of 63 observations with 1 input variable and 1 output variable. The variable names are as follows:
- Number of claims.
- Total payment for all claims in thousands of Swedish Kronor.

Further details can be found [here.](http://college.cengage.com/mathematics/brase/understandable_statistics/7e/students/datasets/slr/frames/slr06.html)
The original dataset can be found [here.](https://www.math.muni.cz/~kolacek/docs/frvs/M7222/data/AutoInsurSweden.txt)
*/

import UIKit
import PlaygroundSupport

// create view to render our scatter plot
let view = ScatterPlotView(frame: CGRect(x: 20, y: 20, width: 300, height: 300))

// present the view controller in the Live View window
PlaygroundPage.current.liveView = view

// create a palette for our scatter plot
let viewPalette = [
    UIColor(red:217, green:94, blue:89, alpha:1.0),
    UIColor(red:218, green:193, blue:94, alpha:0.5),
    UIColor(red:147, green:218, blue:94, alpha:0.5),
    UIColor(red:92, green:218, blue:130, alpha:0.5),
    UIColor(red:92, green:211, blue:218, alpha:0.5),
    UIColor(red:87, green:114, blue:216, alpha:0.5),
    UIColor(red:159, green:91, blue:216, alpha:0.5),
    UIColor(red:217, green:89, blue:177, alpha:0.5)
]

// add some styles for 'training' lines
for i in 1..<viewPalette.count{
    let color = viewPalette[i]
    view.styles["prediction_line_\(i)"] = DataPointStyle(size: 2, color: color.cgColor)
}

// add 'style' for our predictions (used by the view to render the data points)
view.styles["prediction"] = DataPointStyle(size: 5, color: viewPalette[0].cgColor)

// add a 'style' for the best fit line (used by the view to render a line)
view.styles["prediction_line"] = DataPointStyle(size: 2, color: viewPalette[0].cgColor)

/*:
 Train model using Gradient Descent;
 
 Gradient descent is essentially an algorithm that minimizes functions. Given a function defined by a set of parameters, gradient descent starts with an initial set of parameter values and iteratively moves toward a set of parameter values that minimize the function. This iterative minimization is achieved by calculating the partial derivate with respect to the error for each of our coefficents (in our case b and w); because we're descenting we take the negative of this which is used to steer the search in the direction to minimize the error. [gradient](https://en.wikipedia.org/wiki/Gradient).
 We control the descent with a learing rate, this is used to avoid our step 'overshooting' the minimum.
 
 - returns:
 The model from training (bias and weight) 
 
 - parameters:
    - x: training x 
    - y: training y
    - b: pre-initilised b value
    - w: pre-initilised w value 
    - learningRate: determines how quickly we adjust the coefficients based on the error 
    - epochs: numbers of training iterations
 */
func train(
    x:[CGFloat],
    y:[CGFloat],
    b:CGFloat=0.0,
    w:CGFloat=0.0,
    learningRate:CGFloat=0.00001,
    epochs:Int=100,
    trainingCallback: ((Int, Int, CGFloat, CGFloat) -> Void)? = nil) -> (b:CGFloat, w:CGFloat){
    
    var B = b // bias
    var W = w // weight
    
    let N = CGFloat(x.count) // number of data points
    
    for epoch in 0..<epochs{
        // TODO: create variable to store this epoch's gradient for b and w
        
        /**
         iterate through each data point
         */
        for i in 0..<x.count{
            // TODO: make a prediction (using the linear equation y = b + x * w
            
            // TODO: calculate the absolute error (prediction - actual value)
            
            // TODO: calculate the gradient with respect to the error and b (); adding it to the epochs bias gradient
            
            // TODO: calculate the gradient with respect to the error and w (); adding it to the epochs weight gradient
            
        }
        
        // TODO: update the bias (B) using the learningRate
        
        // TODO: update the weight (W) using the learningRate
        
        // notify the observer of the latest model coefficents
        // and sum of error
        if let trainingCallback = trainingCallback{
            trainingCallback(epoch, epochs, W, B)
        }
    }
    
    return (b:B, w:W)
}

// load dataset
let csvData = parseCSV(contents:loadCSV(file:"SwedishAutoInsurance"))

// create structure for our plot
let dataPoints = extractDataPoints(data: csvData, xKey: "claims", yKey: "payments")

// add and view data points from our dataset
view.scatter(dataPoints)

/*:
 By visualising the datapoints, we intuitively see signs of a correlation between the number of claims and amount of claims. To
 We will use a simple linear equation to model this relationship and use it to make predictions i.e. find the best fit line (remember the equation for a line - y=mx+b; m and b are the coefficents that we search for that will give us a line that best fits our data).
 */

// initilize our coefficents using some random variables
let b = CGFloat(arc4random()) / CGFloat(UINT32_MAX)
let w = CGFloat(arc4random()) / CGFloat(UINT32_MAX)

/**
 Training callback function; we segment our training into the number of colors within predictionLinePalette and plot the current model to illustrate how gradient search moves towards the minima
 */
func trainingCallback(epoch:Int,
                      epochs:Int,
                      W:CGFloat,
                      B:CGFloat){
    
    let segments = epochs / (viewPalette.count-2)
    
    if epoch % segments == 0{   
        plotLine(view: view,
                 dataPoints: dataPoints,
                 model:(b:B, w:W),
                 styleTag: "prediction_line_\(view.lineCount + 1)")
    }
}

// search for our coefficents for our linear regression model using gradient descent (introduced above)
let model = train(x:csvData["claims"]!,
                   y:csvData["payments"]!,
                   b:b, w:w,
                   trainingCallback:trainingCallback)

// print the equation - line of best fit aka our model
print("model = \(model.b) + \(model.w)  * x")

// make predictions using our model (line best fit)
var predDataPoints = dataPoints.map({ (dp) -> DataPoint in
    let y = model.b + dp.x * model.w
    return DataPoint(tag: "prediction", x: dp.x, y: y)
});

// visualise our predicted data points (along with the actual values)
//view.scatter(predDataPoints)

// plot the line of best fitfrom minX to maxX (this is our best fit line)
plotLine(view: view,
         dataPoints: dataPoints,
         model:model,
         styleTag: "prediction_line")
