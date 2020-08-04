package com.example.secure

import java.util.*

class Curve25519Donna {
    companion object {
        // Used to load the 'native-lib' library on application startup.
        init {
            System.loadLibrary("native-lib")
        }
    }

    external fun curve25519_donna(privateKey: ByteArray, baseOption: ByteArray): ByteArray

    fun getPrivateKey(): ByteArray {
        val privateKey = ByteArray(32)
        Random().nextBytes(privateKey)
        return privateKey
    }

    fun getPublicKey(privateKey: ByteArray): ByteArray {
        val baseOption = ByteArray(32);
        baseOption[0] = 9;
        return curve25519_donna(privateKey, baseOption)
    }

    fun getSharedKey(privateKey: ByteArray, publickey: ByteArray): ByteArray {
        return curve25519_donna(privateKey, publickey)
    }
}