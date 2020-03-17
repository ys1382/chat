// Interface to GRPC

import Foundation
import SwiftProtobuf
import NIO
import GRPC

class Backend {

    static let shared = Backend()

    private let port = 11912
    private let group: MultiThreadedEventLoopGroup
    private let client: Grpc_ChatClient
    private static let key_session = "session"

    private var session: String? {
        get {
            return UserDefaults.standard.string(forKey: Backend.key_session)
        }
        set (latest) {
            UserDefaults.standard.set(latest, forKey: Backend.key_session)
        }
    }

    func loggedIn() -> Bool {
        return session != nil
    }

    init(host: String = "localhost") {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        print("Connecting to \(host):\(port)")
        let configuration = ClientConnection.Configuration(
            target: .hostAndPort(host, port),
            eventLoopGroup: group
        )
        let connection = ClientConnection(configuration: configuration)
        client = Grpc_ChatClient(channel: connection)
    }

    deinit {
        try? group.syncShutdownGracefully()
    }

    func registerWithServer(_ username: String, _ password: String, _ completion: @escaping (Bool, Error?) -> Void) {
        auth(username, password, completion, submit: client.register)
    }

    func loginWithServer(_ username: String, _ password: String, _ completion: @escaping (Bool, Error?) -> Void) {
        auth(username, password, completion, submit: client.login)
    }

    private func auth(_ username: String,
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
                }
                completion(response.ok, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }

    func sendToPeer(recipient: String, payload: String, _ completion: @escaping (Bool, Error?) -> Void) {
        guard let session = session else {
            print("sendToPeer: no session")
            completion(false, nil)
            return
        }
        let request : Grpc_Envelope = .with {
            $0.recipient = recipient
            $0.payload = payload
            $0.session = session
        }
        client.send(request).response.whenComplete { result in
            switch result {
            case .success(let response):
                completion(response.ok, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
}
