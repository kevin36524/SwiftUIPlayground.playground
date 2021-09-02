//: [Previous](@previous)
// Explore SSE(Server Side Events) with firebase where we can get realTime updates.


import Foundation
import Combine

var str = "Hello, playground"

//https://fbconfig-90755.firebaseio.com/counter.json

class NetworkManager : NSObject, URLSessionDataDelegate {
    
    static var shared = NetworkManager()
    
    struct StreamingData: Codable {
        let path: String
        let data: Int
    }
    let decoder = JSONDecoder()
    
    private var session: URLSession! = nil
    private let cvs = CurrentValueSubject<Int, Never>(0)
        
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }
    
    private var streamingTask: URLSessionDataTask? = nil
    private var numberOfSubscriptions = 0 {
        didSet {
            if (numberOfSubscriptions > 0) {
                startStreaming()
            } else {
                stopStreaming()
            }
            
        }
    }
    
    var isStreaming: Bool { return self.streamingTask != nil }
    
    func startStreaming() {
        precondition( !self.isStreaming )
        
        let url = URL(string: "https://fbconfig-90755.firebaseio.com/counter.json")!
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        let task = self.session.dataTask(with: request)
        self.streamingTask = task
        task.resume()
    }
    
    func stopStreaming() {
        guard let task = self.streamingTask else {
            return
        }
        self.streamingTask = nil
        task.cancel()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("KEVINDEBUG I am getting the data")
        if let str = String(data: data, encoding: .utf8),
           let payloadData = str.split(separator: "\n")[1].dropFirst(5).data(using: .utf8),
           let streamingData = try? decoder.decode(StreamingData.self, from: payloadData) {
            cvs.send(streamingData.data)
        }
//        NSLog("task data: %@", data as NSData)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as NSError? {
            NSLog("task error: %@ / %d", error.domain, error.code)
        } else {
            NSLog("task complete")
        }
    }
    
    func getPublisher() -> AnyPublisher<Int, Never> {
        return cvs.eraseToAnyPublisher()
            .handleEvents { [weak self] _ in
                self?.numberOfSubscriptions  +=  1
            }  receiveCancel: { [weak self] in
                self?.numberOfSubscriptions -= 1
            }
            .eraseToAnyPublisher()
    }
}

let pub = URLSession.shared
    .dataTaskPublisher(for: URLRequest(url: URL(string: "https://fbconfig-90755.firebaseio.com/counter.json")!))
    .map(\.data)
    .map({ (data) -> String in
        return String.init(data: data, encoding: .utf8) ?? ""
    })
    .print("DEBUG NORMAL")
    .sink { (_) in
        
    } receiveValue: { (_) in
        
    }

let pub2 = NetworkManager.shared.getPublisher()
    .print("DEBUG SSE")
    .sink { (_) in
    }

DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
    pub2.cancel()
}

let pub3 = NetworkManager.shared.getPublisher()
    .print("DEBUG pub3")
    .sink { (_) in
    }

pub3.cancel()
//: [Next](@next)
