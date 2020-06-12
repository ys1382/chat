package com.example.secure

import net.vrallev.android.ecc.Ecc25519Helper


object Crypto {
    val keys = mutableMapOf<String, KeySet>()

    data class KeySend(
        var signing: ByteArray?, //Curve25519.Signing.PublicKey?
        var agreement: ByteArray //Curve25519.KeyAgreement.PublicKey
    )

    data class KeySet(
        var ourSigning: ByteArray,  //Signing.PrivateKey
        var ourAgreement: ByteArray, //KeyAgreement.PrivateKey
        var theirSigning: ByteArray?, //Signing.PublicKey?
        var theirAgreement: ByteArray? //KeyAgreement.PublicKey?
    )

    fun getKeySet(id: String): KeySet? {
        return keys.get(id)
    }

    // returns false if this is a response to the handshake we sent
    fun set(keySend: KeySend, sender: String): Boolean {
        val key = getKeySet(sender)

        if (key != null) {
//            key.theirSigning = keySend.signing ?? key.theirSigning
            key.theirAgreement = keySend.agreement
//            if key.sequence == keySend.sequence {
            return false
//            }
//            keys[sender]!.sequence = sequence
        } else {
            val helper = Ecc25519Helper()
            keys[sender] = KeySet(
                helper.keyHolder.publicKeySignature,
                helper.keyHolder.publicKeyDiffieHellman,
                keySend.signing, keySend.agreement
            )
        }
        return true
    }

    fun getKeySend(recipient: String): KeySend {
        val key = keys[recipient]
        val helper = Ecc25519Helper()
        val agreement = helper.keyHolder.publicKeySignature
        if (null != key) {

            key.ourAgreement = agreement
            return KeySend(key.ourSigning, agreement)
        } else {
            val signing = helper.keyHolder.privateKey
            keys[recipient] = KeySet(signing, agreement, null, null)
            return KeySend(signing, agreement)
        }
    }
}
