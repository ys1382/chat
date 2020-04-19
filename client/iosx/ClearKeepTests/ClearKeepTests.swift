//
//  ClearKeepTests.swift
//  ClearKeepTests
//
//  Created by Saib, Yusuf on 4/3/20.
//  Copyright © 2020 telred. All rights reserved.
//

import XCTest
import CryptoKit

@testable import ClearKeep

class ClearKeepTests: XCTestCase {

    private let me = "me"
    private var backend = TestBackend()

    func testCryptoLocal() {
        //Create a message to send.
        let message = "This is my testCryptoLocal message.".data(using: .utf8)!
        // Create the sender's signing and agreement keys.
        let senderSigningKey = Curve25519.Signing.PrivateKey()
        let senderSigningPublicKey = senderSigningKey.publicKey
        let senderAgreementPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        // Create the receiver's encryption key.
        let receiverEncryptionKey = Curve25519.KeyAgreement.PrivateKey()
        let receiverEncryptionPublicKey = receiverEncryptionKey.publicKey
        // The sender encrypts the message using the receiver’s public encryption key, and signs with the sender’s private signing key.
        let sealedMessage = try! Crypto.shared.encrypt(message,
                                                       to: receiverEncryptionPublicKey,
                                                       using: senderAgreementPrivateKey,
                                                       signedBy: senderSigningKey)
        // The receiver decrypts the message with the private encryption key, and verifies the signature with the sender’s public signing key.
        let decryptedMessage = try? Crypto.shared.decrypt(sealedMessage,
                                                          using: receiverEncryptionKey,
                                                          from: senderSigningPublicKey)
        XCTAssert(decryptedMessage == message, "Mismatch")
    }

    func testCryptoPeers() {

        self.measure {

            let message = "This is my testCryptoPeers message.".data(using: .utf8)!

            let alice = Crypto()
            let bob = Crypto()

            let aliceKeysForBob = alice.get(for: "bob")
            let bobKeysForAlice = bob.set(aliceKeysForBob, from:"alice")
            _ = alice.set(bobKeysForAlice, from: "bob")

            do {
                let sealedMessage = try alice.encrypt(message, for: "bob")
                let decryptedMessage = try bob.decrypt(sealedMessage, from: "alice")
                XCTAssert(decryptedMessage == message, "Mismatch")
            } catch {
                XCTAssert(false, "Decryption failed: \(error)")
            }
        }
    }

    func testMessaging() {
        let expectation = XCTestExpectation(description: "Received message")
        let message = "iosx test message".data(using: .utf8)!

        backend.sendToPeer(recipient: me, payload: message) { success, error in
            expectation.fulfill()
            XCTAssert(success, "Message arrived back")
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
