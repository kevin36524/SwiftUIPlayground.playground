//: [Previous](@previous)

import Foundation
import Combine
import PlaygroundSupport

var globalCounter = 0

enum MyErr: Error {
    case wait
}

var subs : Set<AnyCancellable> = []

let pub = (1...4)
    .publisher
    .delay(for: 3, scheduler: DispatchQueue.main)
    .tryMap{ (o) -> String in
        o
        if globalCounter < 3 {
            globalCounter += 1
            throw MyErr.wait
        }
        return "Success \(o)"
    }
//    .print("PUB")
    .retry(1)
    .replaceError(with: "null")
    .share()
    .eraseToAnyPublisher()


pub
    .print("DEBUG1")
    .sink(receiveCompletion: { (_) in
        
    }, receiveValue: { (_) in
        
    }).store(in: &subs)

pub
    .print("DEBUG2")
    .sink { (_) in
        
    } receiveValue: { (_) in
        
    }
    .store(in: &subs)



//
//pub.sink { (comp) in
//    comp
//    print(comp)
//} receiveValue: { (val) in
//    print(val)
//}.store(in: &subs)


