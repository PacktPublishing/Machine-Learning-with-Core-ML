//: Playground - noun: a place where people can play

import UIKit


func calcSimilarity(userRatingsA: [String:Float], userRatingsB:[String:Float]) -> Float{
    let distance = userRatingsA.map( { (movieRating) -> Float in
        if userRatingsB[movieRating.key] == nil{
            return 0
        }
        let diff = movieRating.value - (userRatingsB[movieRating.key] ?? 0)
        return diff * diff
    }).reduce(0) { (prev, curr) -> Float in
        return prev + curr
    }.squareRoot()
    return 1 / (1 + distance)
}

let jo : [String:Float] = ["Monsters Inc." : 5.0, "The Bourne Identity" : 2.0, "The Martian" : 2.0, "Blade Runner" : 1.0]

let sam : [String:Float] = ["The Martian" : 4.0, "Blade Runner" : 4.0, "The Matrix" : 4.0, "Inception" : 5.0]

let chris : [String:Float] = ["The Bourne Identity" : 4.0, "The Martian" : 5.0, "Blade Runner" : 5.0, "Inception" : 4.0]

print(calcSimilarity(
    userRatingsA: sam,
    userRatingsB: jo
))

print(calcSimilarity(
    userRatingsA: sam,
    userRatingsB: sam
))

print(calcSimilarity(
    userRatingsA: sam,
    userRatingsB: chris
))
