// Interface to GRPC

import Foundation
import Combine

import SwiftProtobuf
import NIO
import GRPC

class Backend: ObservableObject {

    static let shared = Backend()

    @Published var rooms = [RoomModel]()
    @Published var messages = [PostModel]()

    enum BackendError: LocalizedError {
        case authentication(message: String)
        case pscrud(message: String)
        case crypto(message: String)

        var errorDescription: String? {
            switch self {
            case let .authentication(message),
                 let .pscrud(message),
                 let .crypto(message):
                return message
            }
        }
    }

    init(host: String = "localhost", port: Int = 11912) {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        Backend.log("Connecting to \(host):\(port)")
        let configuration = ClientConnection.Configuration(
            target: .hostAndPort(host, port),
            eventLoopGroup: group
        )
        connection = ClientConnection(configuration: configuration)
        client = Grpc_PscrudClient(channel: connection)
    }

    deinit {
        try? group.syncShutdownGracefully()
    }

    func sendToPeer(recipient: String,
                    payload: Data,
                    _ completion: @escaping (Bool, Error?) -> Void) {

        let envelope : Chat_Envelope = .with {
            $0.from = username!
            $0.to = recipient
            $0.payload = payload
        }
        do {
            let request : Grpc_PublishRequest = try .with {
                $0.topic = recipient
                $0.data = try envelope.serializedData()
                $0.session = session!
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

    func close() {
        _ = connection.close()
    }

    static func log(_ string: String) {
        DispatchQueue.main.async {
            print(string)
        }
    }

    // private

    private let group: MultiThreadedEventLoopGroup
    private let client: Grpc_PscrudClient
    private let connection: ClientConnection
    private static let key_username = "username"

    private var username: String? {
        get {
            return UserDefaults.standard.string(forKey: Backend.key_username)
        }
        set (latest) {
            UserDefaults.standard.set(latest, forKey: Backend.key_username)
        }
    }

    private static func handleResult(_ result: Result<Grpc_Response, Error>,
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
}

extension Backend { // Authentication

    var session: String? {
        get {
            return UserDefaults.standard.string(forKey: Backend.key_session)
        }
        set (latest) {
            UserDefaults.standard.set(latest, forKey: Backend.key_session)
        }
    }

    func loggedIn() -> Bool {
        return (session?.isEmpty == false) && (username?.isEmpty == false)
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
        let request : Grpc_Request = .with {
            $0.session = session!
        }
        self.session = nil
        self.username = nil
        client.logout(request).response.whenComplete { result in
            Backend.handleResult(result, completion)
        }
    }

    func deregister( _ completion: @escaping (Bool, Error?) -> Void) {
        let request : Grpc_Request = .with {
            $0.session = session!
        }
        client.deregister(request).response.whenComplete { result in
            Backend.handleResult(result, completion)
        }
    }

    // private

    private static let key_session = "session"

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
                        self.authenticated(session: response.session,
                                           completion)
                    } else {
                        self.nauthenticate(completion)
                    }
                case .failure(_):
                    self.nauthenticate(completion)
                }
            }
        }
    }

    func reauthenticate(_ completion: @escaping (Bool, Error?) -> Void) {
        guard let session = session, let _ = username else {
            self.nauthenticate(completion)
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
                    self.nauthenticate(completion)
                }
            case .failure(_):
                self.nauthenticate(completion)
            }
        }
    }

    private func authenticated(session: String,
                               _ completion: @escaping (Bool, Error?) -> Void) {
        self.session = session
        download(completion)
        listen() { post in
            self.messages.append(post)
        }
        subscribe(topic: username!, completion)
    }

    private func nauthenticate(_ completion: @escaping (Bool, Error?) -> Void) {
        print("auth failed")
        session = nil
        username = nil
        completion(false, nil)
    }
}

// publish subscribe create read update delete
extension Backend {

//    private let client: Grpc_PscrudClient
//    private let auth: Authentication
    private static let key_publication = "publication"

//    init(_ client: Grpc_PscrudClient, _ auth: Authentication) {
//        self.client = client
//        self.auth = auth
//    }

    func publish(topic: String,
                 envelope : Chat_Envelope,
                 _ completion: @escaping (Bool, Error?) -> Void) {
        do {
            let request : Grpc_PublishRequest = try .with {
                $0.topic = topic
                $0.data = try envelope.serializedData()
                $0.session = session!
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
            $0.session = session!
            $0.topic = topic
        }
        client.subscribe(request).response.whenComplete { result in
            Backend.handleResult(result, completion)
        }
    }

    // returns true if successfully listening
    func listen(heard: @escaping (PostModel) -> Void) {
        let request : Grpc_Request = .with {
            $0.session = session!
        }
        DispatchQueue.global(qos: .background).async {
            do {
                let call = self.client.listen(request) { publication in
                    guard let envelope = try? Chat_Envelope(serializedData: publication.data) else {
                        Backend.log("Could not decode envelope")
                        return
                    }
                    DispatchQueue.main.async {
                        Backend.log("received \(envelope.payload)")
                        let post = PostModel(id: publication.id, envelope: envelope)
                        heard(post)
                    }
                }
                let status = try call.status.wait()
                Backend.log("listen finished: \(status)")
            } catch {
                Backend.log("listen error: \(error)")
            }
        }
    }

    private func download(_ completion: @escaping (Bool, Error?) -> Void) {
        storeLoad(key: Backend.key_publication) { success, data, error in
            guard success else {
                completion(false, error)
                return
            }
            self.rooms = RoomModel.from(data)
            self.messages = data.compactMap { try? PostModel.from($0) }
        }
    }

    // CRUD

    func storeCreate(key: String,
                     data: Data,
                     _ completion: @escaping (Bool, Error?) -> Void) {
        let request : Grpc_PutRequest = .with {
            $0.key = key
            $0.data = data
            $0.session = session!
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
            $0.session = session!
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

struct RoomModel: Identifiable, Hashable {
    var id: String

    static func from(_ data: [Grpc_Datum]) -> [RoomModel] {
        let roomNames = data.compactMap { (try? Chat_Envelope(serializedData: $0.data))?.from }
        return Set(roomNames).map { RoomModel(id: $0) }
    }
}

struct PostModel: Identifiable {
    var id: String
    var envelope: Chat_Envelope

    static func from(_ datum: Grpc_Datum) throws -> PostModel {
        let envelope = try Chat_Envelope(serializedData: datum.data)
        return PostModel(id: datum.id, envelope: envelope)
    }
}

struct MessageModel: Identifiable {
    var id: String
    var envelope: Chat_Envelope
}
