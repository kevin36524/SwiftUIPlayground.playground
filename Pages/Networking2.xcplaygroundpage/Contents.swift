//: [Previous](@previous)
// Check for errors
// Handle errors and retry
// Also have only 1 subscription and prevent making the second call

import Foundation
import Combine

var str = "Hello, playground"

enum Endpoints {
    case get
    case increment
    case getWithFailureRate(Int)
    
    func url() -> URL? {
        let url = "http://localhost:5000/fbconfig-90755/us-central1/"
        switch self {
        case .get:
            return URL(string: url+"swiftUIGetCounter")
        case .increment:
            return URL(string: url+"swiftUIUpdateCounter")
        case .getWithFailureRate(let failureRate):
            return URL(string: url+"swiftUIGetCounter?failureRate=\(failureRate)")
        }
    }
}

struct Result : Codable {
    var result: Count
    
    struct Count: Codable {
        var count: Int
    }
}

struct ErrorResult: Codable {
    var result: String
    
    static func errorResultFrom(data: Data) -> ErrorResult {
        if let retVal = try? decoder.decode(ErrorResult.self, from: data)  {
            return retVal
        }
        return ErrorResult(result: "Unknown Error")
    }
    static let defaultError = ErrorResult(result: "Error in connecting to the Server")
}

enum ErrorOutput: Error {
    case failure(String)
    case encodingError
    case serverConnectionError
    case unknown
    
    var localizedDescription: String {
        return self.description
    }
    
    var description: String {
        switch self {
        case .serverConnectionError:
            return "Server Connection Error"
        case .unknown:
            return "Unknown"
        case .encodingError:
            return "EncodingError"
        case .failure(let res):
            return res
        }
    }
}

let decoder = JSONDecoder()
let encoder = JSONEncoder()

func getUrlPublisher(url: URL) ->  AnyPublisher<(data: Data, response: URLResponse), URLError> {
    return URLSession.shared.dataTaskPublisher(for:url).eraseToAnyPublisher()
}

class SingleSourcePublisher {
    let url: URL
    
    var urlPublisher: AnyPublisher<(data: Data, response: URLResponse), ErrorOutput>? = nil
    
    private func makeNewPublisher() -> AnyPublisher<(data: Data, response: URLResponse), ErrorOutput>{
        let newPublisher = getUrlPublisher(url: url)
        print ("Making new publisher")
        
        let foo =  newPublisher
            .retry(2)
            .mapError{ (_) -> ErrorOutput in
                return ErrorOutput.serverConnectionError
            }
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.urlPublisher = nil
            }).eraseToAnyPublisher()
        
        urlPublisher = foo
        return foo
    }
    
    init(url: URL) {
        self.url = url
    }
    
    func getPublisher() -> AnyPublisher<Result, ErrorOutput> {
        let pub = urlPublisher == nil ? makeNewPublisher() : urlPublisher!
        return pub
            .tryMap { (data, response) -> Result in
                guard let httpRes = response as? HTTPURLResponse  else {
                    throw ErrorOutput.unknown
                }
                if httpRes.statusCode != 200 {
                    print("KEVINDEBUG the statusCode is \(ErrorResult.errorResultFrom(data: data).result)")

                    throw ErrorOutput.failure("Failed to get the result")
                }
                
                guard let res = try? decoder.decode(Result.self, from: data) else {
                    throw ErrorOutput.encodingError
                }
                
                return res
            }
            .mapError{ (err) -> ErrorOutput in
                if let err = err as? ErrorOutput {
                    err
                    return err
                }
                return ErrorOutput.unknown
            }
            .retry(3)
            .share()
            .eraseToAnyPublisher()
    }
}

let singleSource = SingleSourcePublisher(url: Endpoints.getWithFailureRate(50).url()!)
var cancellable: Set<AnyCancellable> = []

 singleSource
    .getPublisher()
    .print("SUB1")
    .sink(receiveCompletion: { (_) in
        
    }, receiveValue: { (_) in
        
    })
    .store(in: &cancellable)

singleSource
    .getPublisher()
    .print("SUB2")
    .sink(receiveCompletion: { (_) in
        
    }, receiveValue: { (_) in
        
    })
    .store(in: &cancellable)


DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    singleSource
        .getPublisher()
        .print("SUB3")
        .sink(receiveCompletion: { (_) in
            
        }, receiveValue: { (_) in
            
        })
        .store(in: &cancellable)
    
}
