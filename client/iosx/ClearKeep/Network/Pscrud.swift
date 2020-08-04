// Interface to GRPC

import Foundation
import Combine

import SwiftProtobuf
import NIO
import GRPC

// publish subscribe create read update delete
class Pscrud {

    private let client: Grpc_PscrudClient
    private let authenticator: Authenticator
    static let key_publication = "publication"

    init(_ client: Grpc_PscrudClient, _ authenticator: Authenticator) {
        self.client = client
        self.authenticator = authenticator
    }

    func publish(topic: String,
                 envelope : Chat_Envelope,
                 _ completion: @escaping (Bool, Error?) -> Void) {
        do {
            let request : Grpc_PublishRequest = try .with {
                $0.topic = topic
                $0.data = try envelope.serializedData()
                $0.session = authenticator.session!
            }
            client.publish(request).response.whenComplete { result in
                switch result {
                case .success(let response):
                    if response.ok {
                        Backend.log("Backend publish succeeded")
                    } else {
                        Backend.log("Backend publish failed")
                        completion(false, nil)
                    }
                case .failure(let error):
                    Backend.log("Backend publish error \(error)")
                    completion(false, error)
                }
            }
        } catch {
            Backend.log("Backend publish error: \(error)")
            completion(false, error)
        }
    }

    func subscribe(topic: String,
                   _ completion: @escaping (Bool, Error?) -> Void) {
        print("subscribe to \(topic)")
        let request : Grpc_SubscribeRequest = .with {
            $0.session = authenticator.session!
            $0.topic = topic
        }
        client.subscribe(request).response.whenComplete { result in
//            Backend.handleResult(result, completion)
            BackendTink.handleResult(result, completion)
        }
    }

    // returns true if successfully listening
    func listen(heard: @escaping (String, Chat_Chit) -> Void) {
        let request : Grpc_Request = .with {
            $0.session = authenticator.session!
        }
        DispatchQueue.global(qos: .background).async {
            do {
                let call = self.client.listen(request) { publication in
                    guard let chit = try? Chat_Chit(serializedData: publication.data) else {
                        Backend.log("Could not decode envelope")
                        return
                    }
                    DispatchQueue.main.async {
                        heard(publication.id, chit)
                    }
                }
                let status = try call.status.wait()
                Backend.log("listen finished: \(status)")
            } catch {
                Backend.log("listen error: \(error)")
            }
        }
    }

    // CRUD

    func storeCreate(key: String,
                     data: Data,
                     _ completion: @escaping (Bool, Error?) -> Void) {
        let request : Grpc_PutRequest = .with {
            $0.key = key
            $0.data = data
            $0.session = authenticator.session!
        }
        client.create(request).response.whenComplete { result in
            switch result {
            case .success(let response):
                completion(response.ok, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }

    func storeLoad(key: String,
//                   skip: Int?,
//                   limit: Int?,
                   _ completion: @escaping (Bool, [Grpc_Datum], Error?) -> Void) {
        let request : Grpc_GetRequest = .with {
            $0.key = key
//            if let skip = skip, let limit = limit {
//                $0.skip = UInt32(skip)
//                $0.limit = UInt32(limit)
//            }
            $0.session = authenticator.session!
        }
        client.read(request).response.whenComplete { result in
            switch result {
            case .success(let response):
                completion(response.ok, response.data, nil)
            case .failure(let error):
                completion(false, [], error)
            }
        }
    }
}
