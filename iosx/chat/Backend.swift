// Interface to GRPC

import Foundation
import SwiftProtobuf
import NIO
import GRPC

class Backend {

    static let shared = Backend()

    func loggedIn() -> Bool {
        return session != nil
    }

    private init(host: String = "localhost", port: Int = 11912) {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        print("Connecting to \(host):\(port)")
        let configuration = ClientConnection.Configuration(
            target: .hostAndPort(host, port),
            eventLoopGroup: group
        )
        let connection = ClientConnection(configuration: configuration)
        client = Grpc_ChatClient(channel: connection)
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

    func login(_ username: String, _ password: String, _ completion: @escaping (Bool, Error?) -> Void) {
        authenticate(username, password, completion, submit: client.login)
    }

    func logout( _ completion: @escaping (Bool, Error?) -> Void) {
        guard let session = session else {
            print("logout: no session")
            completion(false, nil)
            return
        }
        let request : Grpc_Request = .with {
            $0.session = session
        }
        client.logout(request).response.whenComplete { result
            in self.handleResult(result, completion)
        }
    }

    func deregister( _ completion: @escaping (Bool, Error?) -> Void) {
        guard let session = session else {
            print("deregister: no session")
            completion(false, nil)
            return
        }
        let request : Grpc_Request = .with {
            $0.session = session
        }
        client.deregister(request).response.whenComplete { result
            in self.handleResult(result, completion)
        }
    }

    func sendToPeer(recipient: String,
                    payload: String,
                    _ completion: @escaping (Bool, Error?) -> Void) {
        guard let session = session else {
            print("sendToPeer: no session")
            completion(false, nil)
            return
        }
        let envelope : Grpc_Envelope = .with {
            $0.to = recipient
            $0.payload = payload
        }
        let request : Grpc_SendRequest = .with {
            $0.envelope = envelope
            $0.session = session
        }
        client.send(request).response.whenComplete { result in
            switch result {
            case .success(let response):
                if response.ok {
                    self.storeMessage(envelope, completion)
                } else {
                    completion(false, nil)
                }
            case .failure(let error):
                completion(false, error)
            }
        }
    }

    // private

    private let group: MultiThreadedEventLoopGroup
    private let client: Grpc_ChatClient
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
            switch result {
            case .success(let response):
                if response.ok {
                    self.session = response.session
                    self.listen(completion)
                } else {
                    completion(false, nil)
                }
            case .failure(let error):
                completion(false, error)
            }
        }
    }

    private func reauthenticate(_ completion: @escaping (Bool, Error?) -> Void) {
        guard let session = session else {
            print("authenticate: no session")
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
                    self.listen(completion)
                } else {
                    completion(false, nil)
                }
            case .failure(let error):
                completion(false, error)
            }
        }
    }

    private func listen(_ completion: @escaping (Bool, Error?) -> Void) {
        guard let session = session else {
            print("listen: no session")
            completion(false, nil)
            return
        }
        let request : Grpc_Request = .with {
            $0.session = session
        }
        DispatchQueue.global(qos: .background).async {
            let call = self.client.listen(request) { envelope in
                DispatchQueue.main.async {
                    self.storeMessage(envelope, completion)
                    print("received \(envelope.payload)")
                }
            }
            do {
                let status = try call.status.wait()
                print("listen finished: \(status)")
            } catch {
                DispatchQueue.main.async {
                    print("listen error: \(error)")
                    completion(false, error)
                }
            }
        }
    }

    private func handleResult(_ result: Result<Grpc_Response, Error>,
                              _ completion: @escaping (Bool, Error?) -> Void) {
        switch result {
        case .success(let response):
            completion(response.ok, nil)
        case .failure(let error):
            completion(false, error)
        }
    }

    private func storeCreate(key: String,
                     data: [Data],
                     _ completion: @escaping (Bool, Error?) -> Void) {
        guard let session = session else {
            print("store: no session")
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
            print("load: no session")
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
}
