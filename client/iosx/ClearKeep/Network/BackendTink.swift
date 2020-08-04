//
//  BackendTink.swift
//  ClearKeep
//
//  Created by LuongTiem on 7/29/20.
//  Copyright © 2020 telred. All rights reserved.
//

import Foundation
import Combine
import SwiftProtobuf
import NIO
import GRPC
import CryptoKit


class BackendTink: ObservableObject {
    
    static let shared = BackendTink()
    
    var authenticator: Authenticator
    
    var pscrud: Pscrud
    
    private let group: MultiThreadedEventLoopGroup
    private let client: Grpc_PscrudClient
    private let connection: ClientConnection
    private let tink = TinkHelper()
    
    private var queueHandShake: [String: String] = [:]
    
    
    @Published var rooms = [RoomModel]()
    @Published var messages = [PostModel]()
    
    enum BackendError: LocalizedError {
        case authentication(message: String)
        case pscrud(message: String)
        case googleTink(message: String)
        case curve25519(message: String)

        var errorDescription: String? {
            switch self {
            case let .authentication(message),
                 let .pscrud(message),
                 let .googleTink(message),
                 let .curve25519(message):
                return message
            }
        }
    }
    
    
    init(host: String = "jetpack.tel.red", port: Int = 11912) {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        Backend.log("Connecting to \(host):\(port)")
        let configuration = ClientConnection.Configuration(
            target: .hostAndPort(host, port),
            eventLoopGroup: group
        )
        connection = ClientConnection(configuration: configuration)
        client = Grpc_PscrudClient(channel: connection)

        authenticator = Authenticator(client)
        pscrud = Pscrud(client, authenticator)
        
    }

    
    deinit {
        try? group.syncShutdownGracefully()
    }
    
    
    func close() {
        _ = connection.close()
    }

    static func log(_ string: String) {
        DispatchQueue.main.async {
            print(string)
        }
    }
    
    
    func send(_ message: String,
              to recipient: String,
              _ completion: @escaping (Bool, Error?) -> Void) {
        
        // -- check user handshake exist
        if tink.verifyHandShakeExist(for: recipient) {
    
            self.encryptMessage(message, to: recipient) { (result) in
                
                let envelope : Chat_Envelope = .with {
                    $0.from = self.authenticator.username!
                    $0.to = recipient
                    $0.payload = result!
                }
                
                let chit: Chat_Chit = .with {
                    $0.what = .envelope
                    $0.envelope = envelope
                }
                
                do {
                    let data = try chit.serializedData()
                    try self.send(data, to: recipient)
                } catch {
                    print(error.localizedDescription)
                }
            }
            
        } else {
            queueHandShake[recipient] = message
            sendHandshake(to: recipient, completion)
        }
    }
    
}

extension BackendTink {
    
    internal static func handleResult(_ result: Result<Grpc_Response, Error>,
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

    internal func authenticated(_ completion: @escaping (Bool, Error?) -> Void) {
        download(completion)
        pscrud.listen(heard: heard)
        pscrud.subscribe(topic: authenticator.username!, completion)
    }
    
    
    private func download(_ completion: @escaping (Bool, Error?) -> Void) {
    //        pscrud.storeLoad(key: Pscrud.key_publication) { success, data, error in
    //            guard success else {
    //                completion(false, error)
    //                return
    //            }
    //            self.rooms = RoomModel.from(data)
    //            self.messages = data.compactMap { try? PostModel.from($0) }
    //        }
        }
    
    private func heard(_ id: String, _ chit: Chat_Chit) {
        switch chit.what {
        case .handshake:
            print("Heard handshake")
            receivedHandshake(chit.sequence, chit.handshake)
            break
        case .envelope:
            do {
                
                let message = try tink.decrypt(data: chit.envelope.payload, for: chit.envelope.from)
                
                var tempEnvelope: Chat_Envelope = chit.envelope
                tempEnvelope.payload = message
                
                let post = PostModel(id: id, envelope: tempEnvelope, from: chit.envelope.from)
                Backend.log("received \(tempEnvelope.payload)")
                self.messages.append(post)
                
            } catch {
                print(error.localizedDescription)
            }
            break
        case .UNRECOGNIZED(_):
            Backend.log("Error: unrecognized chit")
        }
    }
    
    
    private func receivedHandshake(_ sequence: UInt64, _ handshake: Chat_Handshake) {
        
        let peer = handshake.from
        print("Received handshake from \(peer)")
        
        let keySend = TinkHelper.KeySend(sequence: sequence,
                                         signing: handshake.signing,
                                         agreement: handshake.agreement)
        
        if tink.set(keySend, from: peer) {
            
            sendHandshake(to: peer) { (success, error) in
                if !success {
                    Backend.log("Error: failed to respond to handshake: \(String(describing: error))")
                } else {
                    print("-----------> ss")
                }
            }
            
        } else {
            // -- send message encrypt only first
            guard let message = queueHandShake[peer] else {
                return
            }
            
            self.encryptMessage(message, to: peer) { (result) in
                
                do {
                    let envelope: Chat_Envelope = .with {
                        $0.from = self.authenticator.username!
                        $0.to = peer
                        $0.payload = result!
                    }
                    
                    let chit: Chat_Chit = .with {
                        $0.what = .envelope
                        $0.envelope = envelope
                    }
                    
                    let dataBackend = try chit.serializedData()
                    
                    try self.send(dataBackend, to: peer)
                    self.queueHandShake.removeValue(forKey: peer)
                } catch {
                    print(error.localizedDescription, " ----->")
                }
            }
        }
    }
    
    private func encryptMessage(_ message: String, to recipient: String, _ completion: @escaping (Data?) -> Void) {
        
        guard let messageUTF8 = message.data(using: .utf8) else {
            print("Could not datify \(message)")
            completion(nil)
            return
        }
        
        guard let encrypt = try? tink.encrypt(data: messageUTF8, for: recipient) else {
            print("Could not datify \(message)")
            completion(nil)
            return
        }
        
        completion(encrypt)
    }
    
    
    private func sendHandshake(to recipient: String, _ completion: @escaping (Bool, Error?) -> Void) {
        
        print("Send handshake to \(recipient)")
        
        let keySend = tink.get(for: recipient)
        
        let handshare: Chat_Handshake = .with {
            $0.from = authenticator.username!
            
            if let signing = keySend.signing {
                $0.signing = signing
            }
            
            $0.agreement = keySend.agreement
        }
        
        let chit: Chat_Chit = .with {
            $0.what = .handshake
            $0.handshake = handshare
        }
        
        do {
            let data = try chit.serializedData()
            
            try send(data, to: recipient, completion)
            
        } catch {
            Backend.log("Backend send handshake error: \(error)")
            completion(false, error)
        }
    }
    
}


extension BackendTink {
    
    private func send(_ data: Data,
                      to recipient: String,
                      _ completion: ((Bool, Error?) -> Void)? = nil) throws {
        
        let request: Grpc_PublishRequest = .with {
            $0.topic = recipient
            $0.data = data
            $0.session = authenticator.session!
        }
        
        client.publish(request).response.whenComplete { (result) in
            switch result {
            case .success(let response):
                if response.ok {
                    Backend.log("Backend publish succeeded")
                } else {
                    Backend.log("Backend publish failed")
                    completion?(false, nil)
                }
            case .failure(let error):
                Backend.log("Backend publish error \(error)")
                completion?(false, error)
            }
        }
    }
}
