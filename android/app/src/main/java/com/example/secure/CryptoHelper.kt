package com.example.secure

import android.util.Base64
import android.util.Log
import java.nio.charset.StandardCharsets
import java.util.*
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec


class CryptoHelper {
    companion object{
    private val key = "passwo"
    private val CIPHER_ALGORITHM = "AES/CBC/PKCS7Padding";
    var iv = ByteArray(16)
    fun test() {
        val value = "Hello Jetpack of Việt Nam Team"
        val enC = encrypt(value, key)
        val deC = decrypt(enC, key)
        Log.e("Sucurity", "Enc : $enC")
        Log.e("Sucurity", "DyC : $deC")
    }

    fun encrypt(message: String, key: String): String {
        val srcBuff = message.toByteArray(charset("UTF8"))
        val skeySpec = getKey(key)
        val ivSpec = IvParameterSpec(iv)
        val ecipher = Cipher.getInstance(CIPHER_ALGORITHM)
        ecipher.init(Cipher.ENCRYPT_MODE, skeySpec, ivSpec)
        val dstBuff = ecipher.doFinal(srcBuff)
        return Base64.encodeToString(dstBuff, Base64.DEFAULT)
    }


    fun decrypt(encrypted: String, key: String): String {
        val skeySpec = getKey(key)
        val ivSpec = IvParameterSpec(iv)
        val ecipher = Cipher.getInstance(CIPHER_ALGORITHM)
        ecipher.init(Cipher.DECRYPT_MODE, skeySpec, ivSpec)
        val raw =
            Base64.decode(encrypted, Base64.DEFAULT)
        val originalBytes = ecipher.doFinal(raw)
        return String(originalBytes, StandardCharsets.UTF_8)
    }

    private fun getKey(Key: String): SecretKeySpec {
        val keyLength = 256
        val keyBytes = ByteArray(keyLength / 8)
        Arrays.fill(keyBytes, 0x0.toByte())
        val passwordBytes: ByteArray = Key.toByteArray(StandardCharsets.UTF_8)
        val length = Math.min(passwordBytes.size, keyBytes.size)
        System.arraycopy(passwordBytes, 0, keyBytes, 0, length)
        return SecretKeySpec(keyBytes, "AES")
    }

}
}