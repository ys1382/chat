// Interface to GRPC

import Foundation
import Combine

import SwiftProtobuf
import NIO
import GRPC


class Authenticator {

    init(_ client: Grpc_PscrudClient) {
        self.client = client
    }

    var username: String? {
        get {
            return UserDefaults.standard.string(forKey: Authenticator.key_username)
        }
        set (latest) {
            UserDefaults.standard.set(latest, forKey: Authenticator.key_username)
        }
    }

    var session: String? {
        get {
            return UserDefaults.standard.string(forKey: Authenticator.key_session)
        }
        set (latest) {
            UserDefaults.standard.set(latest, forKey: Authenticator.key_session)
        }
    }

    func loggedIn() -> Bool {
        return (session?.isEmpty == false) //&& (username?.isEmpty == false)
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

    private static let key_username = "username"
    private static let key_session = "session"

    private let client: Grpc_PscrudClient

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
        Backend.shared.authenticated(completion)
    }

    private func nauthenticate(_ completion: @escaping (Bool, Error?) -> Void) {
        print("auth failed")
        session = nil
        username = nil
        completion(false, nil)
    }
}
