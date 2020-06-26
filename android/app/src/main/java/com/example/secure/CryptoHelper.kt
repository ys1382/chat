package com.example.secure

import chat.Chat
import com.google.crypto.tink.subtle.X25519
import com.google.protobuf.ByteString
import net.vrallev.android.ecc.Ecc25519Helper
import net.vrallev.android.ecc.KeyHolder
import java.util.*


object CryptoHelper {
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

    fun signing(data: Chat.Handshake): ByteString {
        return data.signing
    }

    fun agreement(data: Chat.Handshake): ByteString {
        return data.agreement
    }

    fun checkHandShaked(id: String): Boolean {
        val keyset = getKeySet(id)
        if (keyset != null && keyset.theirAgreement != null) {
            return true
        }
        return false
    }


    // returns false if this is a response to the handshake we sent
    fun set(keySend: KeySend, sender: String): Boolean {
        val key = getKeySet(sender)
        if (key != null) {
            if (null != keySend.signing) {
                keys[sender]!!.theirSigning = keySend.signing
            }
            keys[sender]!!.theirAgreement = keySend.agreement
            return false
        } else {
            val privateKey = X25519.generatePrivateKey();
            val publishKey = X25519.publicFromPrivate(privateKey);

            keys[sender] = KeySet(
                privateKey,
                publishKey,
                keySend.signing,
                keySend.agreement
            )
        }
        return true
    }

    fun getKeySendTo(recipient: String): KeySend {
        val key = keys[recipient]
        if (null != key) {
            return KeySend(key.ourSigning, key.ourAgreement)
        } else {
            // Generate my KeyPair
            val privateKey = X25519.generatePrivateKey()
            val publishKey = X25519.publicFromPrivate(privateKey);

            keys[recipient] = KeySet(privateKey, publishKey, null, null)
            return KeySend(privateKey, publishKey)
        }
    }

    fun getSecretKey(keySet: KeySet): ByteArray? {
        return X25519.computeSharedSecret(keySet.ourSigning, keySet.theirAgreement)
    }
}
