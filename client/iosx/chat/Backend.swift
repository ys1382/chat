// Interface to GRPC

import Foundation
import SwiftUI
import Combine

import SwiftProtobuf
import NIO
import GRPC

class Backend: ObservableObject {
    @Published var messages = [PostModel]()

    static let shared = Backend()
//    @Published var transcript = Transcript()

    func loggedIn() -> Bool {
        return session != nil && !session!.isEmpty
    }

    private init(host: String = "localhost", port: Int = 11912) {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        Backend.log("Connecting to \(host):\(port)")
        let configuration = ClientConnection.Configuration(
            target: .hostAndPort(host, port),
            eventLoopGroup: group
        )
        let connection = ClientConnection(configuration: configuration)
        client = Grpc_PscrudClient(channel: connection)
        reauthenticate() {_,_ in }
    }

    deinit {
        try? group.syncShutdownGracefully()
    }

    func register(_ username: String,
                  _ password: String,
                  _ completion: @escaping (Bool, Error?) -> Void) {
        authenticate(username, password, completion, submit: client.register)
    }

    func login(_ username: String,
               _ password: String,
               _ completion: @escaping (Bool, Error?) -> Void) {
        authenticate(username, password, completion, submit: client.login)
    }

    func logout( _ completion: @escaping (Bool, Error?) -> Void) {
        guard let session = session else {
            Backend.log("logout: no session")
            completion(false, nil)
            return
        }
        let request : Grpc_Request = .with {
            $0.session = session
        }
        self.session = nil
        client.logout(request).response.whenComplete { result in
            self.handleResult(result, completion)
        }
    }

    func deregister( _ completion: @escaping (Bool, Error?) -> Void) {
        guard let session = session else {
            Backend.log("deregister: no session")
            completion(false, nil)
            return
        }
        let request : Grpc_Request = .with {
            $0.session = session
        }
        client.deregister(request).response.whenComplete { result in
            self.handleResult(result, completion)
        }
    }

    func sendToPeer(recipient: String,
                    payload: String,
                    _ completion: @escaping (Bool, Error?) -> Void) {
        guard let session = session else {
            Backend.log("sendToPeer: no session")
            completion(false, nil)
            return
        }
        let envelope : Chat_Envelope = .with {
            $0.to = recipient
            $0.payload = payload
        }
        do {
            let request : Grpc_PublishRequest = try .with {
                $0.topic = recipient
                $0.data = try envelope.serializedData()
                $0.session = session
            }
            client.publish(request).response.whenComplete { result in
                switch result {
                case .success(let response):
                    if response.ok {
                        Backend.log("Backend publish succeeded")
    //                    self.storeMessage(envelope, completion)
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

    // private

    private let group: MultiThreadedEventLoopGroup
    private let client: Grpc_PscrudClient
    private static let key_username = "username"
    private static let key_session = "session"
    private static let key_messages = "messages"

    private var session: String? {
        get {
            return UserDefaults.standard.string(forKey: Backend.key_session)
        }
        set (latest) {
            UserDefaults.standard.set(latest, forKey: Backend.key_session)
        }
    }

    private var username: String? {
        get {
            return UserDefaults.standard.string(forKey: Backend.key_username)
        }
        set (latest) {
            UserDefaults.standard.set(latest, forKey: Backend.key_username)
        }
    }

    private static func log(_ string: String) {
        DispatchQueue.main.async {
            print(string)
        }
    }

    // calls register or login
    private func authenticate(_ username: String,
                              _ password: String,
                              _ completion: @escaping (Bool, Error?) -> Void,
                              submit: @escaping (Grpc_AuthRequest, CallOptions?)
                                      -> UnaryCall<Grpc_AuthRequest, Grpc_AuthResponse>) {
        let request : Grpc_AuthRequest = .with {
            $0.username = username
            $0.password = password
        }
        submit(request, nil).response.whenComplete { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.ok {
                        self.username = username
                        self.authenticated(session: response.session, completion)
                    } else {
                        completion(false, nil)
                    }
                case .failure(let error):
                    completion(false, error)
                }
            }
        }
    }

    private func authenticated(session: String,
                               _ completion: @escaping (Bool, Error?) -> Void) {
        guard let username = username else {
            Backend.log("Backend missing username")
            completion(false, nil)
            return
        }
        self.session = session
        self.subscribe(topic: username) { success, error in
            print("subscribe \(username): \(success)")
            if success {
                if self.listen(completion) {
                    DispatchQueue.main.async {
                        completion(true, nil)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(false, nil)
                }
            }
        }
    }

    private func reauthenticate(_ completion: @escaping (Bool, Error?) -> Void) {
        guard let session = session, !session.isEmpty else {
            Backend.log("authenticate: no session")
            completion(false, nil)
            return
        }
        let request : Grpc_Request = .with {
            $0.session = session
        }
        client.authenticate(request).response.whenComplete { result in
            switch result {
            case .success(let response):
                if response.ok {
                    self.authenticated(session: session,
                                       completion)
                } else {
                    completion(false, nil)
                }
            case .failure(let error):
                completion(false, error)
            }
        }
    }

    private func subscribe(topic: String, _ completion: @escaping (Bool, Error?) -> Void) {
        guard let session = self.session else {
            Backend.log("subscribe: no session")
            completion(false, nil)
            return
        }
        let request : Grpc_SubscribeRequest = .with {
            $0.session = session
            $0.topic = topic
        }
        client.subscribe(request).response.whenComplete { result in
            self.handleResult(result, completion)
        }
    }

    // returns true if successfully listening
    private func listen(_ completion: @escaping (Bool, Error?) -> Void) -> Bool {
        guard let session = session else {
            Backend.log("listen: no session")
            return false
        }
        let request : Grpc_Request = .with {
            $0.session = session
        }
        DispatchQueue.global(qos: .background).async {
            let call = self.client.listen(request) { publication in
                do {
                    let envelope = try Chat_Envelope(serializedData: publication.data)
                        DispatchQueue.main.async {
        //                    self.storeMessage(envelope, completion)
                            Backend.log("received \(envelope.payload)")

                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
                            let now = dateFormatter.string(from: Date())

                            let post = PostModel(id: now, envelope: envelope)
                            self.messages.append(post)
                    }
                } catch {
                    DispatchQueue.main.async {
                        Backend.log("listen error: \(error)")
                    }
                }
            }
            do {
                let status = try call.status.wait()
                Backend.log("listen finished: \(status)")
            } catch {
                DispatchQueue.main.async {
                    Backend.log("listen error: \(error)")
                }
            }
        }
        return true
    }

    private func handleResult(_ result: Result<Grpc_Response, Error>,
                              _ completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.main.async {
            switch result {
            case .success(let response):
                completion(response.ok, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
/*
    private func storeCreate(key: String,
                     data: [Data],
                     _ completion: @escaping (Bool, Error?) -> Void) {
        guard let session = session else {
            Backend.log("store: no session")
            completion(false, nil)
            return
        }
        let request : Grpc_StoreRequest = .with {
            $0.verb = Grpc_StoreRequest.Verb.create
            $0.key = key
            $0.data = data
            $0.session = session
        }
        client.store(request).response.whenComplete { result in
            switch result {
            case .success(let response):
                completion(response.ok, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }

    private func storeLoad(key: String,
                   skip: Int?,
                   limit: Int?,
                   _ completion: @escaping (Bool, [Data]?, Error?) -> Void) {
        guard let session = session else {
            Backend.log("load: no session")
            completion(false, nil, nil)
            return
        }
        let request : Grpc_StoreRequest = .with {
            $0.verb = Grpc_StoreRequest.Verb.read
            $0.key = key
            if let skip = skip, let limit = limit {
                $0.skip = UInt32(skip)
                $0.limit = UInt32(limit)
            }
            $0.session = session
        }
        client.store(request).response.whenComplete { result in
            switch result {
            case .success(let response):
                completion(response.ok, response.data, nil)
            case .failure(let error):
                completion(false, nil, error)
            }
        }
    }

    private func storeMessage(_ envelope: Grpc_Envelope,
                              _ completion: @escaping (Bool, Error?) -> Void) {
        do {
            let data = try envelope.serializedData()
            storeCreate(key: Backend.key_messages, data: [data], completion)
        } catch {
            completion(false, error)
        }
    }
 */
}

struct PostModel: Identifiable {
    var id: String
    var envelope: Chat_Envelope
}

struct MessageModel: Identifiable {
    var id: String
    var envelope: Chat_Envelope
}
