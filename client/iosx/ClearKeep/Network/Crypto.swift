import CryptoKit
import Foundation

class Crypto {

    struct SealedMessage {
        let senderAgreement: Data
        let ciphertext: Data
        let signature: Data
    }

    struct KeySend {
        let signing: Curve25519.Signing.PublicKey?
        let agreement: Curve25519.KeyAgreement.PublicKey
    }

    static let shared = Crypto()

    func get(for recipient: String) -> KeySend {
        if let key = keys[recipient] {
            let agreement = Curve25519.KeyAgreement.PrivateKey()
            keys[recipient]!.ourAgreement = agreement
            return KeySend(signing: key.ourSigning.publicKey, agreement: agreement.publicKey)
        } else {
            let signing = Curve25519.Signing.PrivateKey()
            let agreement = Curve25519.KeyAgreement.PrivateKey()
            keys[recipient] = KeySet(ourSigning: signing,
                                     ourAgreement: agreement,
                                     theirSigning: nil,
                                     theirAgreement: nil)
            return KeySend(signing: signing.publicKey, agreement: agreement.publicKey)
        }
    }

    func set(_ keySend: KeySend, from sender: String) -> KeySend {
        if let key = keys[sender] {
            keys[sender]!.theirSigning = keySend.signing ?? key.theirSigning
            keys[sender]!.theirAgreement = keySend.agreement
            return KeySend(signing: key.ourSigning.publicKey,
                           agreement: key.ourAgreement.publicKey)
        } else {
            let signing = Curve25519.Signing.PrivateKey()
            let agreement = Curve25519.KeyAgreement.PrivateKey()
            keys[sender] = KeySet(ourSigning: signing,
                                  ourAgreement: agreement,
                                  theirSigning: keySend.signing,
                                  theirAgreement: keySend.agreement)
            return KeySend(signing: signing.publicKey, agreement: agreement.publicKey)
        }
    }

    func encrypt(_ data: Data, for recipient: String) throws -> SealedMessage {
        let key = try keySet(for: recipient)
        return try encrypt(data,
                           to: key.theirAgreement!,
                           using: key.ourAgreement,
                           signedBy: key.ourSigning)
    }

    func decrypt(_ sealedMessage: SealedMessage, from recipient: String) throws -> Data {
        let key = try keySet(for: recipient)
        return try decrypt(sealedMessage,
                           using: key.ourAgreement,
                           from: key.theirSigning!)
    }

    // private
    
    private struct KeySet {
        var ourSigning: Curve25519.Signing.PrivateKey
        var ourAgreement: Curve25519.KeyAgreement.PrivateKey
        var theirSigning: Curve25519.Signing.PublicKey?
        var theirAgreement: Curve25519.KeyAgreement.PublicKey?
    }

    private static let protocolSalt = "barnacle".data(using: .utf8)!

    private var keys = [String: KeySet]()

    private func keySet(for recipient: String) throws -> KeySet {
        guard let key = keys[recipient] else {
            throw Backend.BackendError.crypto(message: "no key for \(recipient)")
        }

        return key
    }

    internal func encrypt(_ data: Data,
                          to theirAgreement: Curve25519.KeyAgreement.PublicKey,
                          using ourAgreementPrivate: Curve25519.KeyAgreement.PrivateKey,
                          signedBy ourSigning: Curve25519.Signing.PrivateKey) throws
                          -> SealedMessage {

        let ourAgreementPublicBytes = ourAgreementPrivate.publicKey.rawRepresentation
        let sharedSecret = try ourAgreementPrivate.sharedSecretFromKeyAgreement(with: theirAgreement)

        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: Crypto.protocolSalt,
                sharedInfo: ourAgreementPublicBytes
                            + theirAgreement.rawRepresentation
                            + ourSigning.publicKey.rawRepresentation,
                    outputByteCount: 32)

        let ciphertext = try ChaChaPoly.seal(data, using: symmetricKey).combined
        let signature = try ourSigning.signature(
                for: ciphertext
                     + ourAgreementPublicBytes
                     + theirAgreement.rawRepresentation)

        return SealedMessage(senderAgreement: ourAgreementPublicBytes,
                             ciphertext: ciphertext,
                             signature: signature)
    }

    internal func decrypt(_ sealedMessage: SealedMessage,
                          using ourAgreement: Curve25519.KeyAgreement.PrivateKey,
                          from theirSigning: Curve25519.Signing.PublicKey) throws -> Data {

        let data = sealedMessage.ciphertext +
                   sealedMessage.senderAgreement +
                   ourAgreement.publicKey.rawRepresentation
        guard theirSigning.isValidSignature(sealedMessage.signature, for: data) else {
            throw Backend.BackendError.crypto(message: "Invalid signature")
        }

        let senderAgreement = try Curve25519.KeyAgreement.PublicKey(
                rawRepresentation: sealedMessage.senderAgreement)
        let sharedSecret = try ourAgreement.sharedSecretFromKeyAgreement(with: senderAgreement)

        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: Crypto.protocolSalt,
                sharedInfo: senderAgreement.rawRepresentation
                            + ourAgreement.publicKey.rawRepresentation
                            + theirSigning.rawRepresentation,
                outputByteCount: 32)

        let sealedBox = try! ChaChaPoly.SealedBox(combined: sealedMessage.ciphertext)
        return try ChaChaPoly.open(sealedBox, using: symmetricKey)
    }
}
