// Interface to GRPC

import Foundation
import Combine
import CryptoKit

import SwiftProtobuf
import NIO
import GRPC

class Backend: ObservableObject {

    static let shared = Backend()

    var authenticator: Authenticator
    var pscrud: Pscrud

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

        authenticator = Authenticator(client)
        pscrud = Pscrud(client, authenticator)
        
        crypto.loadKeySend()
        
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
            if crypto.getHandshakeExist(for: recipient) {
                
                self.encryptMessage(message: message, to: recipient) { (result) in
                    
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

    private func encryptMessage(message: String, to recipient: String, _ completion: @escaping (Data?) -> Void) {
        
        guard let messageUTF8 = message.data(using: .utf8) else {
            print("Could not datify \(message)")
            completion(nil)
            return
        }
        
        guard let encrypt = try? crypto.encrypt(messageUTF8, for: recipient) else {
            print("Could not datify \(message)")
            completion(nil)
            return
        }
        
        let archivedModel = SealedMessageArchived(senderAgreement: encrypt.senderAgreement,
                                                  ciphertext: encrypt.ciphertext,
                                                  signature: encrypt.signature)
        
        guard let payload = SealedMessageArchived.archivedData(model: archivedModel) else {
            print("Could encode data SealedMessageArchived")
            completion(nil)
            return
        }
        
        completion(payload)
    }

    private let group: MultiThreadedEventLoopGroup
    private let client: Grpc_PscrudClient
    private let connection: ClientConnection
    private let crypto = Crypto()
    private var queue: [String:Data] = [:]
    
    private var queueHandShake: [String: String] = [:]

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

    private func heard(_ id: String, _ chit: Chat_Chit) {
        switch chit.what {
        case  .handshake:
            print("Heard handshake")
            receivedHandshake(chit.sequence, chit.handshake)
            break
        case .envelope:
            print("Heard envelope")
            
            if let modelArchived: SealedMessageArchived = SealedMessageArchived.unarchiveData(data: chit.envelope.payload),
                let senderAgreement = modelArchived.senderAgreement,
                let ciphertext = modelArchived.ciphertext,
                let signature = modelArchived.signature {
                
                let model = Crypto.SealedMessage.init(senderAgreement: senderAgreement, ciphertext: ciphertext, signature: signature)
                
                do {
                    
                    let message = try crypto.decrypt(model, from: chit.envelope.from)
                    
                    var tempEnvelope: Chat_Envelope = chit.envelope
                    tempEnvelope.payload = message
                    
                    let post = PostModel(id: id, envelope: tempEnvelope, from: chit.envelope.from)
                    Backend.log("received \(tempEnvelope.payload)")
                    self.messages.append(post)
                    
                } catch {
                    print(error.localizedDescription)
                }
                
            } else {
                print("SealedMessageUnarchived error ---> 😂")
                let post = PostModel(id: id, envelope: chit.envelope, from: chit.envelope.from)
                Backend.log("received \(chit.envelope.payload)")
                self.messages.append(post)
            }
            
        case .UNRECOGNIZED(_):
            Backend.log("Error: unrecognized chit")
        }
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

    private func sendHandshake(to recipient: String,
                               _ completion: @escaping (Bool, Error?) -> Void) {
        print("Send handshake to \(recipient)")
        let keySend = crypto.get(for: recipient)
        let handshake : Chat_Handshake = .with {
            $0.from = authenticator.username!
            if let signing = keySend.signing?.rawRepresentation {
                $0.signing = signing
            }
            $0.agreement = keySend.agreement.rawRepresentation
        }
        let chit: Chat_Chit = .with {
            $0.what = .handshake
            $0.handshake = handshake
        }
        do {
            let data = try chit.serializedData()
            try send(data, to: recipient, completion)
        } catch {
            Backend.log("Backend send handshake error: \(error)")
            completion(false, error)
        }
    }
    
    private func receivedHandshake(_ sequence: UInt64, _ handshake: Chat_Handshake) {
        do {
            let peer = handshake.from
            print("Received handshake from \(peer)")

            let signing = try Crypto.signing(from: handshake.signing)
            let agreement = try Crypto.agreement(from: handshake.agreement)
            let keySend = Crypto.KeySend(sequence: sequence,
                                         signing: signing,
                                         agreement: agreement)
            if crypto.set(keySend, from: peer) {
                
                sendHandshake(to: peer) { success, error in
                    if !success {
                        Backend.log("Error: failed to respond to handshake: \(String(describing: error))")
                    } else {
                        print("-----------> ss")
                    }
                }
                
                
            } else {
                
                guard let message = queueHandShake[peer] else {
                    return
                }
                
                self.encryptMessage(message: message, to: peer) { (result) in
                    
                    do {
                        let envelope : Chat_Envelope = .with {
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
            
        } catch {
            Backend.log("Error: could not use handshake \(sequence) from \(handshake.from)")
        }
    }

    private func send(_ data: Data,
                        to recipient: String,
                        _ completion: ((Bool, Error?) -> Void)? = nil) throws {

        let request : Grpc_PublishRequest = .with {
            $0.topic = recipient
            $0.data = data
            $0.session = authenticator.session!
        }
        client.publish(request).response.whenComplete { result in
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
    var newID = UUID().uuidString
    var from: String
    
    static func from(_ datum: Grpc_Datum) throws -> PostModel {
        let envelope = try Chat_Envelope(serializedData: datum.data)
        return PostModel(id: datum.id, envelope: envelope, from: envelope.from)
    }
}

struct MessageModel: Identifiable {
    var id: String
    var envelope: Chat_Envelope
}
