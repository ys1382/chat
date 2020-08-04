import CryptoKit
import Foundation

open class Crypto {
    
    static let shared: Crypto = Crypto()

    struct SealedMessage {
        let senderAgreement: Data
        let ciphertext: Data
        let signature: Data
    }

    struct KeySend {
        let sequence: UInt64
        let signing: Curve25519.Signing.PublicKey?
        let agreement: Curve25519.KeyAgreement.PublicKey
    }

    static func signing(from data: Data) throws -> Curve25519.Signing.PublicKey {
        return try Curve25519.Signing.PublicKey(rawRepresentation: data)
    }

    static func agreement(from data: Data) throws -> Curve25519.KeyAgreement.PublicKey {
        return try Curve25519.KeyAgreement.PublicKey(rawRepresentation: data)
    }

    func get(for recipient: String) -> KeySend {
        sequence = sequence &+ 1
        if let key = keys[recipient] {
//            let agreement = Curve25519.KeyAgreement.PrivateKey()
//            keys[recipient]!.ourAgreement = agreement
            return KeySend(sequence: sequence,
                           signing: key.ourSigning.publicKey,
                           agreement: key.ourAgreement.publicKey)
        } else {
            let signing = Curve25519.Signing.PrivateKey()
            let agreement = Curve25519.KeyAgreement.PrivateKey()
            keys[recipient] = KeySet(sequence: sequence,
                                     ourSigning: signing,
                                     ourAgreement: agreement,
                                     theirSigning: nil,
                                     theirAgreement: nil)
            return KeySend(sequence: sequence,
                           signing: signing.publicKey,
                           agreement: agreement.publicKey)
        }
    }
    

    
    // -- check
    func getHandshakeExist(for recipient: String) -> Bool {
        if let key = keys[recipient] {
            
            return true
        } else {
            return false
        }
    }
    
    
    func loadKeySend() {
        
        ListKeySendArchived.unarchiveData().forEach { (model) in

            guard let object = model.object,
                let ourSigning = object.ourSigning,
                let ourAgreement = object.ourAgreement,
                let theirAgreement = object.theirAgreement else {

                return
            }

            do {
                let signingPrivate = try Curve25519.Signing.PrivateKey(rawRepresentation: ourSigning)

                let agreementPrivate = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: ourAgreement)

                let agreementPublic = try! Crypto.agreement(from: theirAgreement)

                let keySet = KeySet(sequence: object.sequence,
                                    ourSigning: signingPrivate,
                                    ourAgreement: agreementPrivate,
                                    theirSigning: nil,
                                    theirAgreement: agreementPublic)

                keys[model.key] = keySet
            } catch {

                print(error.localizedDescription)
            }
        }
    }

    // returns false if this is a response to the handshake we sent
    func set(_ keySend: KeySend, from sender: String) -> Bool {
        if let key = keys[sender] {
            keys[sender]!.theirSigning = keySend.signing ?? key.theirSigning
            keys[sender]!.theirAgreement = keySend.agreement
            
            ListKeySendArchived.archivedData(data: keys)
//            if key.sequence == keySend.sequence {
                return false
//            }
//            keys[sender]!.sequence = sequence
        } else {
            let signing = Curve25519.Signing.PrivateKey()
            let agreement = Curve25519.KeyAgreement.PrivateKey()
            keys[sender] = KeySet(sequence: sequence,
                                  ourSigning: signing,
                                  ourAgreement: agreement,
                                  theirSigning: keySend.signing,
                                  theirAgreement: keySend.agreement)
            
            ListKeySendArchived.archivedData(data: keys)
        }
        return true
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

    var sequence: UInt64 = 0

    struct KeySet {
        var sequence: UInt64
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

//        let data = sealedMessage.ciphertext +
//                   sealedMessage.senderAgreement +
//                   ourAgreement.publicKey.rawRepresentation
//        guard theirSigning.isValidSignature(sealedMessage.signature, for: data) else {
//            throw Backend.BackendError.crypto(message: "Invalid signature")
//        }

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

class SealedMessageArchived: NSObject, NSCoding {
    
    var senderAgreement: Data?
    
    var ciphertext: Data?
    
    var signature: Data?
    
    
    override init() {
        super.init()
    }
    
    
    init(senderAgreement: Data?, ciphertext: Data?, signature: Data?) {
        self.senderAgreement = senderAgreement
        self.ciphertext = ciphertext
        self.signature = signature
    }
    
    
    func encode(with coder: NSCoder) {
        coder.encode(self.senderAgreement, forKey: "senderAgreement")
        coder.encode(self.ciphertext, forKey: "ciphertext")
        coder.encode(self.signature, forKey: "signature")
    }

    
    required init?(coder: NSCoder) {
        self.senderAgreement = coder.decodeObject(forKey: "senderAgreement") as? Data
        self.ciphertext = coder.decodeObject(forKey: "ciphertext") as? Data
        self.signature = coder.decodeObject(forKey: "signature") as? Data
    }
    
}

 // MARK: Convent Model ---> Data
extension SealedMessageArchived {
   
    static func archivedData(model: SealedMessageArchived) -> Data? {
        
        guard let result = try? NSKeyedArchiver.archivedData(withRootObject: model, requiringSecureCoding: false) else {
            print("Archived Data Fail -----> 😂")
            return nil
        }
        
        return result
    }
    
    
    static func unarchiveData(data: Data) -> SealedMessageArchived? {
        
        guard let model = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? SealedMessageArchived else {
            print("Unarchive Data Fail -----> 😂")
            return nil
        }
        
        return model
    }
}

class ListKeySendArchived: NSObject, NSCoding {
    
    var key: String = ""
    
    var object: KeySendArchivedData?
    
    
    init(key: String, value: KeySendArchivedData?) {
        self.key = key
        self.object = value
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.key, forKey: "key")
        coder.encode(self.object, forKey: "obj")
    }
    
    required init?(coder: NSCoder) {
        self.key = coder.decodeObject(forKey: "key") as? String ?? ""
        self.object = coder.decodeObject(forKey: "obj") as? KeySendArchivedData
    }
    
    
    // MARK: Save Key
    static func archivedData(data: [String: Crypto.KeySet]) {
        
        let mapObj = data.map { ListKeySendArchived(key: $0.key, value: KeySendArchivedData(sequence: $0.value.sequence,
                                                                                            ourSigning: $0.value.ourSigning.rawRepresentation,
                                                                                            ourAgreement: $0.value.ourAgreement.rawRepresentation,
                                                                                            theirSigning: $0.value.theirSigning?.rawRepresentation,
                                                                                            theirAgreement: $0.value.theirAgreement?.rawRepresentation))}
        
        guard let saveData = try? NSKeyedArchiver.archivedData(withRootObject: mapObj, requiringSecureCoding: false) else {
            print("Fail store data")
            return
        }
        
        let manager = UserDefaults.standard
        manager.set(saveData, forKey: "keyStore")
    }
    
    
    static func unarchiveData() -> [ListKeySendArchived] {
        
        guard let loadData = UserDefaults.standard.object(forKey: "keyStore") as? Data,
            let decodeKeySendArchiveData = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(loadData) as? [ListKeySendArchived] else {
                print("Load data fail")
                return []
        }
        
        
        return decodeKeySendArchiveData
    }
    
    
}

// MARK: Save Key Google Tink
extension ListKeySendArchived {
    
    static func archivedData(dataTink: [String: TinkHelper.KeySet]) {
        
        let mapObj = dataTink.map { ListKeySendArchived(key: $0.key, value: KeySendArchivedData(sequence: $0.value.sequence,
                                                                                            ourSigning: $0.value.ourSigning,
                                                                                            ourAgreement: $0.value.ourAgreement,
                                                                                            theirSigning: $0.value.theirSigning,
                                                                                            theirAgreement: $0.value.theirAgreement))}
        
        guard let saveData = try? NSKeyedArchiver.archivedData(withRootObject: mapObj, requiringSecureCoding: false) else {
            print("Fail store data")
            return
        }
        
        let manager = UserDefaults.standard
        manager.set(saveData, forKey: "keyStore")
    }
}


class KeySendArchivedData: NSObject, NSCoding {

    var sequence: UInt64 = UInt64()
    
    var ourSigning: Data?
    
    var ourAgreement: Data?
    
    var theirSigning: Data?

    var theirAgreement: Data?
    
    
    override init() {
        super.init()
    }
    
    
    init(sequence: UInt64, ourSigning: Data, ourAgreement: Data, theirSigning: Data?, theirAgreement: Data?) {
        self.sequence = sequence
        self.ourSigning = ourSigning
        self.ourAgreement = ourAgreement
        self.theirSigning = theirSigning
        self.theirAgreement = theirAgreement
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.sequence, forKey: "sequence")
        coder.encode(self.ourSigning, forKey: "ourSigning")
        coder.encode(self.ourAgreement, forKey: "ourAgreement")
        coder.encode(self.theirSigning, forKey: "theirSigning")
        coder.encode(self.theirAgreement, forKey: "theirAgreement")
    }
    
    required init?(coder: NSCoder) {
        self.sequence = coder.decodeObject(forKey: "sequence") as? UInt64 ?? UInt64()
        self.ourSigning = coder.decodeObject(forKey: "ourSigning") as? Data
        self.ourAgreement = coder.decodeObject(forKey: "ourAgreement") as? Data
        self.theirSigning = coder.decodeObject(forKey: "theirSigning") as? Data
        self.theirAgreement = coder.decodeObject(forKey: "theirAgreement") as? Data
    }
}

