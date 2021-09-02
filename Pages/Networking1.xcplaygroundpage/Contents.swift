//: [Previous](@previous)
// Using share()
// Using cancel
// Showing how the subscribing works.
// How decoding works.

import Foundation
import Combine
import PlaygroundSupport

var str = "Hello, playground"

enum Endpoints: String {
    case get = "swiftUIGetCounter"
    case increment = "swiftUIUpdateCounter"
    
    func url() -> URL? {
        return URL.init(string: "https://us-central1-fbconfig-90755.cloudfunctions.net/\(self.rawValue)")
    }
}

var subscriptions: Set<AnyCancellable> = []
var pub2: AnyCancellable? = nil
var getEndpoint = Endpoints.get
var incrementEndpoint = Endpoints.increment

enum Err: Error {
    case failure
}

struct Response : Decodable {
    var result: Count
    
    struct Count: Decodable {
        var count: Int
    }
}
let decoder = JSONDecoder()

if let endpointURL = incrementEndpoint.url() {
    var pub = URLSession.shared.dataTaskPublisher(for: endpointURL)
    
    var newPub = pub.handleEvents { (subs) in
        print("KEVINDEBUG handleEvent I am subscribing")
    } receiveOutput: { (arg0) in
        let (data, response) = arg0
        print("KEVINDEBUG handleEvent I am receiveOutput")
    } receiveCompletion: { (comp) in
        print("KEVINDEBUG handleEvent I am receiveCompletion")
    } receiveCancel: {
        print("KEVINDEBUG handleEvent I am receiveCancel")
    }.share()
    
    newPub.map(\.data)
        .decode(type: Response.self, decoder: decoder)
        .sink { (_) in
            
        } receiveValue: { (res) in
            print("Got res \(res.result.count)")
        }.store(in: &subscriptions)

    pub2 = newPub.map(\.data)
        .decode(type: Response.self, decoder: decoder)
        .sink { (_) in
            
        } receiveValue: { (res) in
            print("Got res \(res.result.count)")
        }
    
    
    newPub.map(\.data)
        .decode(type: Response.self, decoder: decoder)
        .map {  Result<Response,Err>.success($0) }
        .replaceError(with: Result<Response, Err>.failure(Err.failure))
        .print()
        .sink{ _ in }
        .store(in: &subscriptions)
    
    //pub2?.cancel()

}

PlaygroundPage.current.needsIndefiniteExecution = true
//: [Next](@next)
