//: Playground - noun: a place where people can play

import UIKit


func calcSimilarity(userRatingsA: [String:Float], userRatingsB:[String:Float]) -> Float{
    // Only compare movies that both users have in common
    let matches = Set(Array(userRatingsA.keys)).intersection(Set(Array(userRatingsB.keys)))
    
    // Guard against instances where there are no shared movies (return 0.0
    // indicating low similarity)
    guard matches.count > 0 else{
        return 0.0
    }
    
    let distance = matches.map { (sharedMovieTitle) -> Float in
        guard let userARating = userRatingsA[sharedMovieTitle],
            let userBRating = userRatingsB[sharedMovieTitle] else{
                fatalError("Invalid state")
        }
        
        return  pow(userARating - userBRating, 2)
    }.reduce(0) { (acc, val) -> Float in
        return acc + val
    }.squareRoot() // squareRoot can be omitted (ie optional)
    
    // Return the inverse such that 1.0 represents a perfect match and 0.0 no match 
    return 1 / (1 + distance)
}

let jo : [String:Float] = ["Monsters Inc." : 5.0, "The Bourne Identity" : 2.0, "The Martian" : 2.0, "Blade Runner" : 1.0]

let sam : [String:Float] = ["The Martian" : 4.0, "Blade Runner" : 4.0, "The Matrix" : 4.0, "Inception" : 5.0]

let chris : [String:Float] = ["The Bourne Identity" : 4.0, "The Martian" : 5.0, "Blade Runner" : 5.0, "Inception" : 4.0]

let lisa : [String:Float] = ["Titanic" : 5.0, "The wold on Wall Street" : 2.0, "The Beach" : 5.0, "Catch Me If You Can" : 3.0]

print(calcSimilarity(
    userRatingsA: sam,
    userRatingsB: jo
))

print(calcSimilarity(
    userRatingsA: jo,
    userRatingsB: sam
))

print(calcSimilarity(
    userRatingsA: sam,
    userRatingsB: sam
))

print(calcSimilarity(
    userRatingsA: sam,
    userRatingsB: chris
))

print(calcSimilarity(
    userRatingsA: sam,
    userRatingsB: lisa
))
