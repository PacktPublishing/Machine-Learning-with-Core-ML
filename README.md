# Machine Learning with Core ML

<a href="https://www.packtpub.com/big-data-and-business-intelligence/machine-learning-core-ml?utm_source=github&utm_medium=repository&utm_campaign=9781788838290"><img src="https://www.packtpub.com/sites/default/files/B09544.png" alt="Machine Learning with Core ML" height="256px" align="right"></a>

This is the code repository for [Machine Learning with Core ML](https://www.packtpub.com/big-data-and-business-intelligence/machine-learning-core-ml?utm_source=github&utm_medium=repository&utm_campaign=9781788838290), published by Packt.

**An iOS developer's guide to implementing machine learning in mobile apps**

## What is this book about?

Core ML is a popular framework by Apple, with APIs designed to support various machine learning tasks. It allows you to train your machine learning models and then integrate them into your iOS apps.

This book covers the following exciting features: 
* Understand components of an ML project using algorithms, problems, and data
* Master Core ML by obtaining and importing machine learning model, and generate classes
* Prepare data for machine learning model and interpret results for optimized solutions
* Create and optimize custom layers for unsupported layers
* Apply CoreML to image and video data using CNN

If you feel this book is for you, get your [copy](https://www.amazon.com/dp/1788838297) today!

<a href="https://www.packtpub.com/?utm_source=github&utm_medium=banner&utm_campaign=GitHubBanner"><img src="https://raw.githubusercontent.com/PacktPublishing/GitHub/master/GitHub.png" 
alt="https://www.packtpub.com/" border="5" /></a>


## Instructions and Navigations
All of the code is organized into folders. For example, Chapter05.

The code will look like the following:
```
coreml_model = coremltools.converters.keras.convert(
    'tinyyolo_voc2007_modelweights.h5',
    input_names='image',
    image_input_names='image',
    output_names='output',
    image_scale=1./255.)
```

**Following is what you need for this book:**
Machine Learning with Core ML is for you if you are an intermediate iOS developer interested in applying machine learning to your mobile apps. This book is also for those who are machine learning developers or deep learning practitioners who want to bring the power of neural networks in their iOS apps. Some exposure to machine learning concepts would be beneficial but not essential, as this book acts as a launchpad into the world of machine learning for developers.

With the following software and hardware list you can run all code files present in the book (Chapter 1-10).

### Software and Hardware List

| Chapter  | OS required                   | Software required                        |
| -------- | ------------------------------------| -----------------------------------|
| 1-10        |macOS 10.13 or higher                    |Xcode 9.2 or higher  |


We also provide a PDF file that has color images of the screenshots/diagrams used in this book. [Click here to download it](http://www.packtpub.com/sites/default/files/downloads/MachineLearningwithCoreML_ColorImages.pdf).

### Related products <Paste books from the Other books you may enjoy section>
* Mastering Machine Learning Algorithms [[Packt]](https://www.packtpub.com/big-data-and-business-intelligence/mastering-machine-learning-algorithms?utm_source=github&utm_medium=repository&utm_campaign=9781788621113) [[Amazon]](https://www.amazon.com/dp/1788621115)

* Machine Learning with Swift [[Packt]](https://www.packtpub.com/big-data-and-business-intelligence/machine-learning-swift?utm_source=github&utm_medium=repository&utm_campaign=9781787121515) [[Amazon]](https://www.amazon.com/dp/1787121518)

## Get to Know the Author
**Joshua Newnham**

Joshua Newnham is a technology lead at a global design firm, Method, focusing on the intersection of design and artificial intelligence (AI), specifically in the areas of computational design and human computer interaction. Prior to this, he was a technical director at Masters of Pie, a virtual reality (VR) and augmented reality (AR) studio focused on building collaborative tools for engineers and creatives.



## Other books by the author
* [Microsoft HoloLens By Example](https://www.packtpub.com/web-development/microsoft-hololens-example?utm_source=github&utm_medium=repository&utm_campaign=9781787126268)


### Suggestions and Feedback
[Click here](https://docs.google.com/forms/d/e/1FAIpQLSdy7dATC6QmEL81FIUuymZ0Wy9vH1jHkvpY57OiMeKGqib_Ow/viewform) if you have any feedback or suggestions.
