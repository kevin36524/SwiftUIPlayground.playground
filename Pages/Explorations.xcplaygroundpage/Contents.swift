import UIKit
import Combine

var str = "Hello, playground"
print(str)

let json = ["data": "foo"]
let err = URLError(.badURL)


let pub = (1...3).publisher
    .delay(for: 1, scheduler: DispatchQueue.main)
    .map( { _ in return Int.random(in: 0...100) } )
    .print("Random")
    .share()
    .eraseToAnyPublisher()

let cancellable1 = pub
    .sink { print ("Stream 1 received: \($0)")}

DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    let cancellable2 = pub
        .sink(receiveCompletion: { (comp) in
            if case .finished = comp {
                print("KEVINDEBUG this is a comppletion")
            }
        }, receiveValue: {
            print ("Stream 2 received: \($0)")
        })
}

struct MyError: Error {
    let val: Int
}
var count = 0
let pub1 = (1...3).publisher
    .tryMap { (myVal) -> Any in
        if count == 0 {
            throw MyError.init(val: myVal)
        }
        return myVal+1
    }
    .handleEvents(receiveCompletion: { (comp) in
        if case .failure(let err) = comp {
            print("Got the error and will increment count")
            count = count+1
        }
    })
    .retry(1)
    .sink { (comp) in
        if case .failure(let err) = comp {
            print("KEVINDEBUG this is a failure \(err)")
        }
    } receiveValue: { (test) in
        print("KEVINDEBUG the data is \(test)")
    }


let valuesPerSecond = 1.0
let delayInSeconds = 1.5

// 1
let sourcePublisher = PassthroughSubject<Date, Never>()
// 2
let delayedPublisher =
sourcePublisher.delay(for: .seconds(delayInSeconds), scheduler: DispatchQueue.main)
// 3
let subscription = Timer
.publish(every: 1.0 / valuesPerSecond, on: .main, in: .common)
.autoconnect()
.subscribe(sourcePublisher)

let c1 = sourcePublisher.prefix(3)
    .sink { print ("Stream 1 received: \($0)")}

var c2: AnyCancellable? = nil
DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    c2 = sourcePublisher.prefix(3)
        .sink(receiveCompletion: { (comp) in
            if case .finished = comp {
                print("KEVINDEBUG this is a comppletion")
            }
        }, receiveValue: {
            print ("Stream 2 received: \($0)")
        })
}


let pub2 = CurrentValueSubject<Dictionary<String,String>, URLError>(json)
pub2.send(completion: .failure(err))

pub2
    .eraseToAnyPublisher()
    .handleEvents(receiveCompletion: { (err) in
        print("handle events \(err)")
    })
    .retry(2)
    .sink { (comp) in
        if case .failure(let err) = comp {
            print("KEVINDEBUG this is a comppletion \(err)")
        }
} receiveValue: { (test) in
    print("KEVINDEBUG the data is \(test)")
}

// Flatmap can also be used to chain publishers.
let arr = (1...3).publisher.map {
    return Just($0).eraseToAnyPublisher()
}.flatMap {
    return $0
}.print("Flatmap").sink { _ in }



//service.publisher()
//  // 4
//  .retry(1)
//  // 5
////  .decode(type: Joke.self, decoder: Self.decoder)
////   // 6
////  .replaceError(with: Joke.error)
////  // 7
//  .receive(on: DispatchQueue.main)
//  // 8
//    .sink(receiveValue: { (data) in
//
//        print("KEVINDEBUG the data is \(decoded)")
//    })
//
//  // 9
////  .filter { $0 != Joke.error }
////   // 10
////  .flatMap { [unowned self] joke in
////    self.fetchTranslation(for: joke, to: "es")
////  }
////  // 11
////  .receive(on: DispatchQueue.main)
////   // 12
////  .assign(to: \.joke, on: self)
////  .store(in: &jokeSubscriptions)

