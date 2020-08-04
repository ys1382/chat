//
//  TinkHelper.swift
//  ClearKeep
//
//  Created by LuongTiem on 7/23/20.
//  Copyright © 2020 telred. All rights reserved.
//

import Foundation
import Tink
import SwiftyJSON
import CryptoKit
import Security


extension Data {
    var bytes : [UInt8]{
        return [UInt8](self)
    }
}


extension Array where Element == UInt8 {
    var data : Data{
        return Data(self)
    }
}

open class TinkHelper {
    
    init() {
        config()
        loadLocalKeySend()
    }

    static let shared: TinkHelper = TinkHelper()
    
    
    var secret_key: [UInt8] = []
    
    var sequence: UInt64 = 0
    
    
    struct KeySend {
        let sequence: UInt64
        let signing: Data?
        let agreement: Data
    }
    
    
    struct KeySet {
        var sequence: UInt64
        var ourSigning: Data
        var ourAgreement: Data
        var theirSigning: Data?
        var theirAgreement: Data?
    }
    
    
    func config() {
        
        guard let config = try? TINKAllConfig() else {
            return
        }

        do {
            
            try TINKConfig.register(config)
            
        } catch {
            print("")
        }
    }
    
    
    
    // MARK: -- List Key Pair
    
    private var keys: [String: KeySet] = [:]
    
    
    private func keySet(for recipient: String) throws -> KeySet {
        guard let key = keys[recipient] else {
            throw BackendTink.BackendError.googleTink(message: "No key for \(recipient)")
        }
        
        return key
    }
    
    
    
    // -- Get Key Send
    func get(for recipient: String) -> KeySend {
        sequence = sequence &+ 1
        
        if let key = keys[recipient] {
            
            return KeySend(sequence: sequence,
                           signing: key.ourSigning,
                           agreement: key.ourAgreement)
        } else {
            
            let signing = try! randomSecretKey()
            
            let agreement = createPublicKey(secret: signing)
            
            keys[recipient] = KeySet(sequence: sequence,
                                     ourSigning: signing,
                                     ourAgreement: agreement,
                                     theirSigning: nil,
                                     theirAgreement: nil)
            
            return KeySend(sequence: sequence,
                            signing: signing,
                            agreement: agreement)
        }
    }
    
    
    // -- Set Key Send
    func set(_ keySend: KeySend, from sender: String) -> Bool {
        
        if let key = keys[sender] {
            keys[sender]!.theirSigning = keySend.signing ?? key.theirSigning
            keys[sender]!.theirAgreement = keySend.agreement
            
            ListKeySendArchived.archivedData(dataTink: keys)
            
            return false
            
        } else {
            
            let signing = try! randomSecretKey()
            
            let agreement = createPublicKey(secret: signing)
            
            keys[sender] = KeySet(sequence: sequence,
                                  ourSigning: signing,
                                  ourAgreement: agreement,
                                  theirSigning: keySend.signing,
                                  theirAgreement: keySend.agreement)
            
            ListKeySendArchived.archivedData(dataTink: keys)
            
            return true
        }
    }
    
    
    /// -- Verify Handshake
    func verifyHandShakeExist(for recipient: String) -> Bool {
        
        if let key = keys[recipient] {
            
            return true
        } else {
            
            return false
        }
    }
    
    
    let aad = "Data".data(using: .utf8)
    
    // --> Load TinkKeysetHandle
    private func loadKeyHandler() -> TINKKeysetHandle? {
        
        guard let jsonData = json() else {
            print("Load json fail !!!")
            return nil
        }
        
        do {
            let jsonKeysetReader: TINKJSONKeysetReader = try TINKJSONKeysetReader.init(serializedKeyset: jsonData)
            
            let keysetHandle = try TINKKeysetHandle(cleartextKeysetHandleWith: jsonKeysetReader)
            
            return keysetHandle
            
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
}

// MARK: Encrypt + Decrypt message
extension TinkHelper {
    
    func encrypt(data: Data, for recipient: String) throws -> Data? {
        
        let key = try keySet(for: recipient)
        
        guard let theirAgreement = key.theirAgreement else {
            return nil
        }
        
        guard let keysetHandler: TINKKeysetHandle = loadKeyHandler() else {
            print("Load fail")
            return nil
        }
        
        do {
            let aead = try TINKAeadFactory.primitive(with: keysetHandler)
            
            let keyShared: Data = createShareKey(secretData: key.ourSigning, publicData: theirAgreement)
            
            let ciphertext = try aead.encrypt(data, withAdditionalData: keyShared)
            
            return ciphertext
            
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    
    func decrypt(data: Data, for recipient: String) throws -> Data {
        
        guard let keysetHandler = loadKeyHandler() else {
            throw BackendTink.BackendError.googleTink(message: "Load KeysetHander Fail")
        }
        
        do {
            
            let aeadFactory = try TINKAeadFactory.primitive(with: keysetHandler)
            
            let key = try keySet(for: recipient)
            
            guard let theirAgreement = key.theirAgreement else {
                throw BackendTink.BackendError.googleTink(message: "Fail")
            }
            

            let keyShared: Data = createShareKey(secretData: key.ourSigning, publicData: theirAgreement)
            
            guard let plaintext = try? aeadFactory.decrypt(data, withAdditionalData: keyShared) else {
                throw BackendTink.BackendError.googleTink(message: "Decrypt message fail")
            }
            
            return plaintext
            
        } catch {
            throw BackendTink.BackendError.googleTink(message: error.localizedDescription)
        }
        
    }
}

extension TinkHelper {
    
    // -- params bytes 32 bit
    private func randomSecretKey(bytes: Int = 32) throws -> Data {
        
        let random = [UInt8](repeating: 0, count: bytes)
        let result = SecRandomCopyBytes(nil, bytes, UnsafeMutableRawPointer(mutating: random))
        
        guard result == errSecSuccess else {
            throw BackendTink.BackendError.curve25519(message: "Create Public Key Fail!")
        }
        return Data(random)
    }
    
    
    /// -- Create Public Key
    private func createPublicKey(secret: Data) -> Data {
        var secretKey: [UInt8] = secret.bytes
        var publicKey: [UInt8] = [UInt8](repeating: 0, count: 32)
        var baseOption: [UInt8] = [UInt8](repeating: 0, count: 32)
        baseOption[0] = 9
        
        curve25519_donna(&publicKey, &secretKey, &baseOption)
        
        let result: Data = publicKey.data
        
        return result
    }
    
    
    /// -- Create Share Key
    private func createShareKey(secretData: Data, publicData: Data) -> Data {
        
        var shareKey: [UInt8] = [UInt8](repeating: 0, count: 32)
        var secretKey: [UInt8] = secretData.bytes
        var publicKey: [UInt8] = publicData.bytes
        
        curve25519_donna(&shareKey, &secretKey, &publicKey)
        
        let result: Data = shareKey.data
        
        return result
    }
}


// MARK: Load Json Data

extension TinkHelper {
    
    private func json() -> Data? {
            let text = "{\n    \"primaryKeyId\": 1234567,\n    \"key\": [{\n        \"keyData\": {\n            \"typeUrl\": \"type.googleapis.com/google.crypto.tink.AesGcmKey\",\n            \"keyMaterialType\": \"SYMMETRIC\",\n            \"value\": \"GiDA9kdJH43/rE5j7MmH2qBqIpJhXVJ54+ILE0A7McB1Hw==\"\n        },\n        \"outputPrefixType\": \"TINK\",\n        \"keyId\": 1234567,\n        \"status\": \"ENABLED\"\n    }]\n}"
            let json = JSON(parseJSON: text)
            
            
    //        var keyData: [String: Any] = [:]
    //        keyData["typeUrl"] = "type.googleapis.com/google.crypto.tink.AesGcmKey"
    //        keyData["keyMaterialType"] = "SYMMETRIC"
    //        keyData["value"] = "GiDA9kdJH43/rE5j7MmH2qBqIpJhXVJ54+ILE0A7McB1Hw=="
    //
    //        var key: [String: Any] = [:]
    //        key["outputPrefixType"] = "TINK"
    //        key["keyId"] = 1234567
    //        key["status"] = "ENABLED"
    //        key["keyData"] = keyData
    //
    //        var params: [String: Any] = [:]
    //        params["primaryKeyId"] = 1234567
    //        params["key"] = key
    //

            return try? json.rawData()
        }
}

// MARK: -- Load Local KeySend
extension TinkHelper {
    
    
    private func loadLocalKeySend() {
        
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
                                    ourSigning: signingPrivate.rawRepresentation,
                                    ourAgreement: agreementPrivate.rawRepresentation,
                                    theirSigning: nil,
                                    theirAgreement: agreementPublic.rawRepresentation)

                keys[model.key] = keySet
                
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

// MARK: More Support
extension TinkHelper {
    
    func aeadKeyTemplate() {
        
        guard let tpl = try? TINKAeadKeyTemplate(keyTemplate: TINKAeadKeyTemplates.TINKAes128Gcm) else {
            return
        }
        
        guard let handle = try? TINKKeysetHandle(keyTemplate: tpl) else {
            return
        }
        
        
        let keysetName = "om.yourcompany.yourapp.uniqueKeysetName"
        
        do {
            try handle.writeToKeychain(withName: keysetName, overwrite: false)
        } catch {
            print(error.localizedDescription)
        }
        
        
        // ---
        
        guard let handleLoad = try? TINKKeysetHandle(fromKeychainWithName: keysetName) else {
            return
        }
        
    }
    
    func createKeysetHander() -> TINKKeysetHandle? {
        
        guard let tpl = try? TINKAeadKeyTemplate(keyTemplate: TINKAeadKeyTemplates.TINKAes128Gcm) else {
            return nil
        }
        
        guard let handle = try? TINKKeysetHandle(keyTemplate: tpl) else {
            return nil
        }
        
        return handle
    }
}
