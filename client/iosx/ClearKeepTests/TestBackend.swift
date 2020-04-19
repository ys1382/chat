import Foundation
@testable import ClearKeep

class TestBackend: ClearKeep.Backend {

    private let me = "iosx-test-username"

    override func sendToPeer(recipient: String,
                             payload: Data,
                             _ completion: @escaping (Bool, Error?) -> Void) {
        let envelope : ClearKeep.Chat_Envelope = .with {
            $0.from = me
            $0.to = recipient
            $0.payload = payload
        }
        let post = ClearKeep.PostModel(id: "iosx-test-publication-id", envelope: envelope)
        messages.append(post)
        completion(true, nil)
    }
}
