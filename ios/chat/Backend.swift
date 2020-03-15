import Foundation
import SwiftProtobuf
import NIO
import GRPC

class Backend {

    private let port = 11912
    private let client: Grpc_ChatClient

    init() {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
//            try? group.syncShutdownGracefully()
        }
        let configuration = ClientConnection.Configuration(
            target: .hostAndPort("localhost", port),
            eventLoopGroup: group
        )
        let connection = ClientConnection(configuration: configuration)
        client = Grpc_ChatClient(channel: connection)
        
        register()
    }

    func register() {
        let registerRequest : Grpc_AuthRequest = .with {
            $0.username = "alice"
            $0.password = "apw"
        }
        client.register(registerRequest).response.whenComplete { result in
            switch result {
            case .success(let response):
                print("register \(response.ok)")
            case .failure(let error):
                print("register \(error)")
            }
        }
    }
}
