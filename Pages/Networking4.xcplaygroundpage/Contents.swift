//: [Previous](@previous)

import Foundation
import Combine

var str = "Hello, playground"


enum Endpoint {
    case get
    case increment
    case getWithFailureRate(Int)
    
    func url() -> URL? {
        let url = "https://us-central1-fbconfig-90755.cloudfunctions.net/"
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


enum NetworkError: Error {
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

class NetworkCounter: ObservableObject {
    
    enum States {
        case loading
        case error(String)
        case success
    }
    
    @Published var count: Int = 0
    @Published var state = States.success
    
    var res: Result<Int, NetworkError> {
        didSet {
            print("res is \(res)")
            switch res {
            case .success(let count):
                self.count = count
            case .failure(let err):
                self.state = States.error(err.description)
            }
        }
    }
    
    init() {
        res = Result.success(0)
    }
}

protocol UseCase {
    func start()
}

class GetNetworkCountUseCase: UseCase {
    
    var counter: NetworkCounter
    struct OutputRes : Codable {
        var result: Count
        
        struct Count: Codable {
            var count: Int
        }
    }
    
    var subscriptions = Set<AnyCancellable>()
    let endPoint: Endpoint
    
    func start() {
        URLSession.shared.dataTaskPublisher(for: endPoint.url()!)
            .map(\.data)
            .decode(type: OutputRes.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .map {
                return Result<Int, NetworkError>.success($0.result.count)
            }
            .replaceError(with: Result<Int, NetworkError>.failure(.unknown))
            .assign(to: \.res, on: counter)
            .store(in: &subscriptions)
    }
    
    init(endpoint:Endpoint, networkCounter: NetworkCounter) {
        self.endPoint = endpoint
        self.counter = networkCounter
    }
}

/// Implementation
let counter = NetworkCounter()
let subs = counter.$count.sink { print("Counter updated to \($0)") }
let useCase = GetNetworkCountUseCase(endpoint: .get, networkCounter: counter)

useCase.start()

//: [Next](@next)
